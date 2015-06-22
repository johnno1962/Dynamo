//
//  OSDependant.swift
//  Dynamo
//
//  Created by John Holdsworth on 22/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/OSDependant.swift#5 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: Bundle based, reloading processors

/**
This processor is sessoin based and also loads it's application code from a code bundle with a ".ssp" extension.
If the module includes the Utilities/AutoLoader.m code it will reload and swizzle it'a new implementation when
the bundle is rebuilt/re-deployed for hot-swapping in the code. Existing instances/sessions receive the new code
but retain their state. This does not work for changes to the layout or number of properties in the class.
*/

public class DynamoReloadingProcessor : DynamoSessionProcessor {

    var bundleName: String
    var loaded: NSTimeInterval
    let bundlePath: String
    let binaryPath: String
    let fileManager = NSFileManager.defaultManager()
    let mainBundle = NSBundle.mainBundle()
    var loadNumber = 0

    public convenience init( pathPrefix: String, bundleName: String ) {
        let bundlePath = NSBundle.mainBundle().pathForResource( bundleName, ofType: "ssp" )!
        self.init( pathPrefix: pathPrefix, bundleName: bundleName, bundlePath: bundlePath )
    }

    public init( pathPrefix: String, bundleName: String, bundlePath: String ) {
        self.bundlePath = bundlePath
        let bundle = NSBundle( path: bundlePath )!
        bundle.load()
        self.bundleName = bundleName
        self.loaded = NSDate().timeIntervalSinceReferenceDate
        self.binaryPath = "\(bundlePath)/Contents/MacOS/\(bundleName)"
        let appClass = bundle.classNamed( "\(bundleName)Processor" ) as! DynamoSessionBasedApplication.Type
        super.init( pathPrefix: pathPrefix, appClass: appClass )
    }

    public override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

        if let attrs = fileManager.attributesOfItemAtPath( binaryPath, error: nil ),
            lastModified = (attrs[NSFileModificationDate] as? NSDate)?.timeIntervalSinceReferenceDate {
                if lastModified > loaded {
                    let nextPath = "/tmp/\(bundleName)V\(loadNumber++).ssp"

                    fileManager.removeItemAtPath( nextPath, error: nil )
                    fileManager.copyItemAtPath( bundlePath, toPath: nextPath, error: nil )

                    if let bundle = NSBundle( path: nextPath ) {
                        bundle.load() // AutoLoader.m Swizzles new implementation
                        self.loaded = lastModified
                    }
                    else {
                        dynamoLog( "Could not load bundle \(nextPath)" )
                    }
                }
        }

        super.processRequest(out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
    }

}

// MARK: Reloading processor based in bundle inside documentRoot

/**
A specialisation of a bundle reloading, session based processor where the bundle is loaded
from the web document directory. As before it reloads and hot-swaps in the new code if the
bundle is updated.
*/

public class DynamoSwiftServerPagesProcessor : DynamoApplicationProcessor {

    let documentRoot: String
    var reloaders = [String:DynamoReloadingProcessor]()
    let sspRegexp = NSRegularExpression(pattern: "^(.*/(\\w+)\\.ssp)(.*)", options: nil, error: nil )!
    let fileManager = NSFileManager.defaultManager()

    public init( documentRoot: String ) {
        self.documentRoot = documentRoot
        super.init( pathPrefix: "/**.ssp" )
    }

    override public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        let path = httpClient.uri as NSString, range = NSMakeRange( 0, path.length )

        if let host = httpClient.requestHeaders["Host"] {

            if let sspMatch = sspRegexp.firstMatchInString( httpClient.uri, options: nil, range: range ) {
                let sspPath = path.substringWithRange( sspMatch.rangeAtIndex(1) )

                if sspPath != path && fileManager.fileExistsAtPath( "\(documentRoot)/\(host)\(path)") {
                    return .NotProcessed
                }

                let sspFullPath = "\(documentRoot)/\(host)\(sspPath)"
                var reloader = reloaders[sspPath]

                if reloader == nil && fileManager.fileExistsAtPath( sspFullPath ) {
                    let bundleName = path.substringWithRange( sspMatch.rangeAtIndex(2) )
                    reloaders[sspPath] = DynamoReloadingProcessor( pathPrefix: sspPath,
                        bundleName: bundleName, bundlePath: sspFullPath )
                }

                if let reloader = reloaders[sspPath] {
                    return reloader.process( httpClient )
                }
                else {
                    dynamoLog( "Missing .ssp bundle for path \(path)" )
                }
            }
        }
        
        return .NotProcessed
    }
}

private var dynamoRunLoop: NSRunLoop?

/**
    NSStreams implementation of a DynamoHTTPConnection - not used - seems to stall under many connections
*/

public class DynamoStreamHTTPConnection : DynamoHTTPConnection, NSStreamDelegate {

    private let newDataAvailable = dispatch_semaphore_create(0)
    private let readStream: NSInputStream
    private let writeStream: NSOutputStream
    private let readBuffer = NSMutableData()

    required public init?( clientSocket: Int32 ) {

        var readCFStream:  Unmanaged<CFReadStream>?
        var writeCFStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocket( nil, clientSocket, &readCFStream, &writeCFStream )

        readStream = readCFStream!.takeRetainedValue()
        writeStream = writeCFStream!.takeRetainedValue()

        super.init( clientSocket: clientSocket )

        readStream.delegate = self

        if dynamoRunLoop == nil {
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                dynamoRunLoop = NSRunLoop.currentRunLoop()
                dynamoRunLoop!.addPort( NSPort(), forMode: NSDefaultRunLoopMode )
                dynamoRunLoop!.run()
            } )
        }

        while dynamoRunLoop == nil {
            NSThread.sleepForTimeInterval( 0.01 )
        }

        readStream.scheduleInRunLoop( dynamoRunLoop!, forMode: NSDefaultRunLoopMode )

        readStream.open()
        writeStream.open()

        let certs: [AnyObject]? = nil
        if certs != nil {
            let sslSettings: [NSString:AnyObject] = [
                kCFStreamSSLIsServer: NSNumber( bool: true ),
                kCFStreamSSLLevel: kCFStreamSSLLevel,
                kCFStreamSSLCertificates: certs!
            ]

            CFReadStreamSetProperty( readStream, kCFStreamPropertySSLSettings, sslSettings )
            CFWriteStreamSetProperty( writeStream, kCFStreamPropertySSLSettings, sslSettings )
        }
    }

    required public convenience init?( url: NSURL ) {
        if let host = url.host {
            let port = UInt16(url.port?.intValue ?? 80)

            if var addr = addressForHost( host, port ) {

                let remoteSocket = socket( Int32(addr.sa_family), SOCK_STREAM, 0 )
                if remoteSocket < 0 {
                    Strerror( "Could not obtain socket" )
                }
                else if connect( remoteSocket, &addr, socklen_t(addr.sa_len) ) < 0 {
                    Strerror( "Could not connect to: \(host):\(port)" )
                }
                else {
                    setupSocket( remoteSocket )
                    self.init( clientSocket: remoteSocket )
                    return
                }
            }
        }

        self.init( clientSocket: -1 )
        return nil
    }

    public func stream( aStream: NSStream, handleEvent eventCode: NSStreamEvent ) {
        switch eventCode {

        case NSStreamEvent.HasBytesAvailable:
            var buffer = [UInt8](count: 8192, repeatedValue: 0)
            let bytesRead = (aStream as! NSInputStream).read( &buffer, maxLength: buffer.count )
            if bytesRead > 0 {
                readBuffer.appendBytes( buffer, length: bytesRead )
                dispatch_semaphore_signal( newDataAvailable )
                return
            }
            fallthrough

        case NSStreamEvent.EndEncountered:
            readEOF = true
            dispatch_semaphore_signal( newDataAvailable )

        case NSStreamEvent.ErrorOccurred:
            println( "ErrorOccurred: \(aStream) \(eventCode)" )
            fallthrough

        default:
            break
        }
    }

    override func readLine() -> String? {
        while true {
            if readEOF && readBuffer.length == 0 {
                return nil
            }
            let endOfLine = memchr( readBuffer.bytes, Int32(nl), readBuffer.length )
            if endOfLine != nil || readEOF {
                var lengthOfLine = readEOF ? readBuffer.length : endOfLine-readBuffer.bytes
                if endOfLine != nil && UnsafePointer<Int8>(endOfLine-1).memory == cr {
                    lengthOfLine--
                }
                if let line = NSString( bytes: readBuffer.bytes, length: lengthOfLine, encoding: NSUTF8StringEncoding ) {
                    readBuffer.replaceBytesInRange( NSMakeRange( 0, readEOF ? readBuffer.length : endOfLine-readBuffer.bytes+1 ), withBytes: nil, length: 0 )
                    return line as String
                }
                else {
                    return nil
                }
            }
            dispatch_semaphore_wait( newDataAvailable, DISPATCH_TIME_FOREVER )
        }
    }

    override func read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        var ptr = 0
        while ptr < count {
            let remaining = buffer+ptr
            let available = count-ptr < readBuffer.length ? count-ptr : readBuffer.length
            memcpy( remaining, readBuffer.bytes, available )
            ptr += available
            readBuffer.replaceBytesInRange( NSMakeRange( 0, available ), withBytes: nil, length: 0 )

            if ptr < count {
                dispatch_semaphore_wait( newDataAvailable, DISPATCH_TIME_FOREVER )
            }
        }
        return ptr
    }

    override func write(buffer: UnsafePointer<Void>, count: Int) -> Int {
        var ptr = 0
        while ptr < count {
            let remaining = UnsafePointer<UInt8>(buffer)+ptr
            let bytesWritten = writeStream.write( remaining, maxLength: count-ptr )
            if bytesWritten <= 0 {
                dynamoLog( "Short write on SSL relay" )
                return 0
            }
            ptr += bytesWritten
        }
        return ptr
    }

    override public func flush() {
    }

    override class func relay( label: String, from: DynamoHTTPConnection, to: DynamoHTTPConnection, _ logger: ((String) -> ())? ) {
        dispatch_async( dynamoQueue, {
            let from = from as! DynamoStreamHTTPConnection, to = to as! DynamoStreamHTTPConnection
            var writeError = false

            while !writeError {

                while from.readBuffer.length == 0 && !from.readEOF && !to.readEOF {
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10.1 * Double(NSEC_PER_SEC)))
                    dispatch_semaphore_wait( from.newDataAvailable, delayTime )
                }

                if from.readEOF {
                    break
                }

                let buffer = from.readBuffer.bytes
                let bytesRead = from.readBuffer.length

                if logger != nil {
                    logger!( "\(label) \(bytesRead) bytes (\(to.clientSocket))" )
                }

                var ptr = 0
                while ptr < bytesRead {
                    let remaining = UnsafePointer<UInt8>(buffer)+ptr
                    let bytesWritten = to.writeStream.write( remaining, maxLength: bytesRead-ptr )
                    if bytesWritten <= 0 {
                        dynamoLog( "Short write on relay" )
                        writeError = true
                        break
                    }
                    from.readBuffer.replaceBytesInRange( NSMakeRange( 0, bytesWritten ), withBytes: nil, length: 0 )
                    ptr += bytesWritten
                }
            }

            from.readEOF = true
            to.readEOF = true

            dispatch_semaphore_signal( from.newDataAvailable )
            dispatch_semaphore_signal( to.newDataAvailable )

            from.writeStream.close()
            from.readStream.close()
            close( from.clientSocket )

            to.writeStream.close()
            to.readStream.close()
            close( to.clientSocket )
        } )
    }
    
    deinit {
        println( "Close: "+uri )
        readStream.removeFromRunLoop( dynamoRunLoop!, forMode: NSDefaultRunLoopMode )
        writeStream.close()
        readStream.close()
    }

}

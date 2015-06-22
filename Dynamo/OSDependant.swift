//
//  OSDependant.swift
//  Dynamo
//
//  Created by John Holdsworth on 22/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/OSDependant.swift#4 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

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

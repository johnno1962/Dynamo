//
//  Servers.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Servers.swift#24 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

#if os(Linux)
import Dispatch
import Glibc
#endif

// MARK: Private queues and missing IP functions

let dynamoRequestQueue = DispatchQueue( label: "DynamoRequestThread", attributes: DispatchQueue.Attributes.concurrent )

// MARK: Basic http: Web server

/**
     Basic http protocol web server running on the specified port. Requests are presented to each of a set
     of swiftlets provided in a connecton thread until one is encountered that has processed the request.
 */

open class DynamoWebServer: _NSObject_ {

    fileprivate let swiftlets: [DynamoSwiftlet]
    fileprivate let serverSocket: Int32

    /** port allocated for server if specified as 0 */
    open var serverPort: UInt16 = 0

    /** basic initialiser for Swift web server processing using array of swiftlets */
    @objc public convenience init?( portNumber: UInt16, swiftlets: [DynamoSwiftlet], localhostOnly: Bool = false ) {

        self.init( portNumber, swiftlets: swiftlets, localhostOnly: localhostOnly )

        DispatchQueue.global(qos: .default).async(execute: {
            self.runConnectionHandler( self.httpConnectionHandler )
        } )
    }

    @objc init?( _ portNumber: UInt16, swiftlets: [DynamoSwiftlet], localhostOnly: Bool ) {

        #if os(Linux)
        signal( SIGPIPE, SIG_IGN )
        #endif

        self.swiftlets = swiftlets

        var ip4addr = sockaddr_in()

        #if !os(Linux)
        ip4addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        ip4addr.sin_family = sa_family_t(AF_INET)
        ip4addr.sin_port = htons( portNumber )
        ip4addr.sin_addr = in_addr( s_addr: INADDR_ANY )

        if localhostOnly {
            inet_aton( "127.0.0.1", &ip4addr.sin_addr )
        }

        serverSocket = socket( Int32(ip4addr.sin_family), sockType, 0 )

        var yes: u_int = 1, yeslen = socklen_t(MemoryLayout<u_int>.size)
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        super.init()

        if serverSocket < 0 {
            dynamoStrerror( "Could not get server socket" )
        }
        else if setsockopt( serverSocket, SOL_SOCKET, SO_REUSEADDR, &yes, yeslen ) < 0 {
            dynamoStrerror( "Could not set SO_REUSEADDR" )
        }
        else if bind( serverSocket, sockaddr_cast(&ip4addr), addrLen ) < 0 {
            dynamoStrerror( "Could not bind service socket on port \(portNumber)" )
        }
        else if listen( serverSocket, 100 ) < 0 {
            dynamoStrerror( "Server socket would not listen" )
        }
        else if getsockname( serverSocket, sockaddr_cast(&ip4addr), &addrLen ) == 0 {
            serverPort = ntohs( ip4addr.sin_port )
            #if os(Linux)
            let s = ""
            #else
            let s = type(of: self) === DynamoSSLWebServer.self ? "s" : ""
            #endif
            dynamoLog( "Server available on http\(s)://localhost:\(serverPort)" )
            return
        }

        return nil
    }

    func runConnectionHandler( _ connectionHandler: @escaping (Int32) -> Void ) {
        while self.serverSocket >= 0 {

            let clientSocket = accept( self.serverSocket, nil, nil )

            if clientSocket >= 0 {
                dynamoRequestQueue.async(execute: {
                    connectionHandler( clientSocket )
                } )
            }
            else {
                Thread.sleep( forTimeInterval: 0.5 )
            }
        }
    }

    func wrapConnection( _ clientSocket: Int32 ) -> DynamoHTTPConnection? {
        return DynamoHTTPConnection( clientSocket: clientSocket )
    }

    open func httpConnectionHandler( _ clientSocket: Int32 ) {

        if let httpClient = wrapConnection( clientSocket ) {

            while httpClient.readHeaders() {
                var processed = false

                for swiftlet in swiftlets {

                    switch swiftlet.present( httpClient: httpClient ) {
                    case .notProcessed:
                        continue
                    case .processed:
                        return
                    case .processedAndReusable:
                        httpClient.flush()
                        processed = true
                    }

                    break
                }

                if !processed {
                    httpClient.status = 400
                    httpClient.response( text: "Invalid request: \(httpClient.method) \(httpClient.path) \(httpClient.version)" )
                    return
                }
            }
        }
    }

}

#if os(Linux)
/**
    Pre-forked worker model version e.g. https://github.com/kylef/Curassow
 */

public class DynamoWorkerServer : DynamoWebServer {

    public init?( portNumber: UInt16, swiftlets: [DynamoSwiftlet], workers: Int, localhostOnly: Bool = false ) {

        super.init( portNumber, swiftlets: swiftlets, localhostOnly: localhostOnly )

        DispatchQueue.global(qos: .default).async {
            var wcount = 0, status: Int32 = 0
            while true {
                if (wcount < workers || wait( &status ) != 0) && fork() == 0 {
                    self.runConnectionHandler( self.httpConnectionHandler )
                }
                wcount += 1
            }
        }
    }

}
#else

// MARK: SSL https: Web Server

/**
    Subclass of DynamoWebServer for accepting https: SSL encoded requests. Create a proxy on the provided
    port to a surrogate DynamoWebServer on a random port on the localhost to actually process the requests.
*/

open class DynamoSSLWebServer: DynamoWebServer {

    fileprivate let certs: [AnyObject]

    /**
        default initialiser for SSL server. Can proxy a "surrogate" non-SSL server given it's URL
    */
    @objc public init?( portNumber: UInt16, swiftlets: [DynamoSwiftlet] = [], certs: [AnyObject], surrogate: String? = nil ) {

        self.certs = certs

        super.init( portNumber, swiftlets: swiftlets, localhostOnly: false )

        DispatchQueue.global(qos: .default).async(execute: {
            if surrogate == nil {
                    self.runConnectionHandler( self.httpConnectionHandler )
            }
            else if let surrogateURL = URL( string: surrogate! ) {
                    self.runConnectionHandler( {
                        (clientSocket: Int32) in
                        if let sslConnection = self.wrapConnection( clientSocket ),
                            let surrogateConnection = DynamoHTTPConnection( url: surrogateURL ) {
                                DynamoSelector.relay( "surrogate", from: sslConnection, to: surrogateConnection, dynamoTrace )
                        }
                    } )
            }
            else {
                dynamoLog( "Invalid surrogate URL: \(String(describing: surrogate))" )
            }
        } )
    }

    override func wrapConnection( _ clientSocket: Int32 ) -> DynamoHTTPConnection? {
        return DynamoSSLConnection( sslSocket: clientSocket, certs: certs )
    }

}

class DynamoSSLConnection: DynamoHTTPConnection {

    let inputStream: InputStream
    let outputStream: OutputStream

    init?( sslSocket: Int32, certs: [AnyObject]? ) {

        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocket( nil, sslSocket, &readStream, &writeStream )

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream.open()
        outputStream.open()

        super.init(clientSocket: sslSocket,
        readFP: funopen(readStream!.toOpaque(), {
            (cookie, buffer, count) in
            let inputStream = Unmanaged<InputStream>
                .fromOpaque(cookie!).takeUnretainedValue()
//            Swift.print("READ", count)
            return Int32(inputStream.read( buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(count)) {$0}, maxLength: Int(count) ))
        }, nil, nil, {cookie -> Int32 in
            Unmanaged<InputStream>.fromOpaque(cookie!)
                .takeUnretainedValue().close()
            return 0
        }),
        writeFP: funopen(writeStream!.toOpaque(), nil, {
            (cookie, buffer, count) in
            let outputStream = Unmanaged<OutputStream>
                .fromOpaque(cookie!).takeUnretainedValue()
//            Swift.print("WRITE", count)
            return Int32(outputStream.write( buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(count)) {$0}, maxLength: Int(count) ))
        }, nil, {cookie -> Int32 in
            Unmanaged<OutputStream>.fromOpaque(cookie!)
                .takeUnretainedValue().close()
            return 0
        }))

        if certs != nil {
            let sslSettings: [NSString:AnyObject] = [
                kCFStreamSSLIsServer: NSNumber(value: true as Bool),
                kCFStreamSSLLevel: kCFStreamSSLLevel,
                kCFStreamSSLCertificates: certs! as AnyObject
            ]

            CFReadStreamSetProperty( inputStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySSLSettings), sslSettings as CFTypeRef )
            CFWriteStreamSetProperty( outputStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySSLSettings), sslSettings as CFTypeRef )
        }
    }

    override var hasBytesAvailable: Bool {
        return inputStream.hasBytesAvailable
    }

    override func _read( buffer: UnsafeMutableRawPointer, count: Int ) -> Int {
        return inputStream.read( buffer.assumingMemoryBound(to: UInt8.self), maxLength: count )
    }

    override func _write( buffer: UnsafeRawPointer, count: Int ) -> Int {
        return outputStream.write( buffer.assumingMemoryBound(to: UInt8.self), maxLength: count )
    }

    override func receive( buffer: UnsafeMutableRawPointer, count: Int ) -> Int? {
        return inputStream.hasBytesAvailable ? _read( buffer: buffer, count: count ) :  nil
    }

    override func forward( buffer: UnsafeRawPointer, count: Int ) -> Int? {
        return outputStream.hasSpaceAvailable ? _write( buffer: buffer, count: count ) : nil
    }
}
#endif

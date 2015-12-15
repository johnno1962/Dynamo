//
//  Servers.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Servers.swift#14 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

#if os(Linux)
import Glibc
import NSLinux
#endif

// MARK: Private queues and missing IP functions

let dynamoRequestQueue = dispatch_queue_create( "DynamoRequestThread", DISPATCH_QUEUE_CONCURRENT )

// MARK: Basic http: Web server

/**
     Basic http protocol web server running on the specified port. Requests are presented to each of a set
     of swiftlets provided in a connecton thread until one is encountered that has processed the request.
 */

public class DynamoWebServer: _NSObject_ {

    private let swiftlets: [DynamoSwiftlet]
    private let serverSocket: Int32

    /** port allocated for server if specified as 0 */
    public var serverPort: UInt16 = 0

    /** basic initialiser for Swift web server processing using array of swiftlets */
    public convenience init?( portNumber: UInt16, swiftlets: [DynamoSwiftlet], localhostOnly: Bool = false ) {

        self.init( portNumber, swiftlets: swiftlets, localhostOnly: localhostOnly )

        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            self.runConnectionHandler( self.httpConnectionHandler )
        } )
    }

    init?( _ portNumber: UInt16, swiftlets: [DynamoSwiftlet], localhostOnly: Bool ) {

        #if os(Linux)
        signal( SIGPIPE, SIG_IGN )
        #endif

        self.swiftlets = swiftlets

        var ip4addr = sockaddr_in()

        #if !os(Linux)
        ip4addr.sin_len = UInt8(sizeof(sockaddr_in))
        #endif
        ip4addr.sin_family = sa_family_t(AF_INET)
        ip4addr.sin_port = htons( portNumber )
        ip4addr.sin_addr = in_addr( s_addr: INADDR_ANY )

        if localhostOnly {
            inet_aton( "127.0.0.1", &ip4addr.sin_addr )
        }

        serverSocket = socket( Int32(ip4addr.sin_family), sockType, 0 )

        var yes: u_int = 1, yeslen = socklen_t(sizeof(yes.dynamicType))
        var addrLen = socklen_t(sizeof(ip4addr.dynamicType))

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
            let s = self.dynamicType === DynamoSSLWebServer.self ? "s" : ""
            #endif
            dynamoLog( "Server available on http\(s)://localhost:\(serverPort)" )
            return
        }

        return nil
    }

    func runConnectionHandler( connectionHandler: (Int32) -> Void ) {
        while self.serverSocket >= 0 {

            let clientSocket = accept( self.serverSocket, nil, nil )

            if clientSocket >= 0 {
                dispatch_async( dynamoRequestQueue, {
                    connectionHandler( clientSocket )
                } )
            }
            else {
                NSThread.sleepForTimeInterval( 0.5 )
            }
        }
    }

    func wrapConnection( clientSocket: Int32 ) -> DynamoHTTPConnection? {
        return DynamoHTTPConnection( clientSocket: clientSocket )
    }

    public func httpConnectionHandler( clientSocket: Int32 ) {

        if let httpClient = self.wrapConnection( clientSocket ) {

            while httpClient.readHeaders() {
                var processed = false

                for swiftlet in swiftlets {

                    switch swiftlet.present( httpClient ) {
                    case .NotProcessed:
                        continue
                    case .Processed:
                        return
                    case .ProcessedAndReusable:
                        httpClient.flush()
                        processed = true
                        break
                    }

                    break
                }

                if !processed {
                    httpClient.status = 400
                    httpClient.response( "Invalid request: \(httpClient.method) \(httpClient.path) \(httpClient.version)" )
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

        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            var wcount = 0
            while true {
                let status = __WAIT_STATUS()
                if (wcount < workers || wait( status ) != 0) && fork() == 0 {
                    self.runConnectionHandler( self.httpConnectionHandler )
                }
                wcount++
            }
        } )
    }

}
#else

// MARK: SSL https: Web Server

/**
    Subclass of DynamoWebServer for accepting https: SSL encoded requests. Create a proxy on the provided
    port to a surrogate DynamoWebServer on a random port on the localhost to actually process the requests.
*/

public class DynamoSSLWebServer: DynamoWebServer {

    private let certs: [AnyObject]

    /**
        default initialiser for SSL server. Can proxy a "surrogate" non-SSL server given it's URL
    */
    public init?( portNumber: UInt16, swiftlets: [DynamoSwiftlet] = [], certs: [AnyObject], surrogate: String? = nil ) {

        self.certs = certs

        super.init( portNumber, swiftlets: swiftlets, localhostOnly: false )

        if surrogate == nil {
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                self.runConnectionHandler( self.httpConnectionHandler )
            } )
        }
        else if let surrogateURL = NSURL( string: surrogate! ) {
            runConnectionHandler( {
                (clientSocket: Int32) in
                if let sslConnection = self.wrapConnection( clientSocket ),
                    surrogateConnection = DynamoHTTPConnection( url: surrogateURL ) {
                        DynamoSelector.relay( "surrogate", from: sslConnection, to: surrogateConnection, dynamoTrace )
                }
            } )
        }
        else {
            dynamoLog( "Invalid surrogate URL: \(surrogate)" )
        }
    }

    override func wrapConnection( clientSocket: Int32 ) -> DynamoHTTPConnection? {
        return DynamoSSLConnection( sslSocket: clientSocket, certs: certs )
    }

}

class DynamoSSLConnection: DynamoHTTPConnection {

    let inputStream: NSInputStream
    let outputStream: NSOutputStream

    init?( sslSocket: Int32, certs: [AnyObject]? ) {

        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocket( nil, sslSocket, &readStream, &writeStream )

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        super.init( clientSocket: sslSocket )

        inputStream.open()
        outputStream.open()

        if certs != nil {
            let sslSettings: [NSString:AnyObject] = [
                kCFStreamSSLIsServer: NSNumber( bool: true ),
                kCFStreamSSLLevel: kCFStreamSSLLevel,
                kCFStreamSSLCertificates: certs!
            ]

            CFReadStreamSetProperty( inputStream, kCFStreamPropertySSLSettings, sslSettings )
            CFWriteStreamSetProperty( outputStream, kCFStreamPropertySSLSettings, sslSettings )
        }
    }

    override var hasBytesAvailable: Bool {
        return inputStream.hasBytesAvailable
    }

    override func _read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        return inputStream.read( UnsafeMutablePointer<UInt8>(buffer), maxLength: count )
    }

    override func _write( buffer: UnsafePointer<Void>, count: Int ) -> Int {
        return outputStream.write( UnsafePointer<UInt8>(buffer), maxLength: count )
    }

    override func receive( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int? {
        return inputStream.hasBytesAvailable ? _read( buffer, count: count ) :  nil
    }

    override func forward( buffer: UnsafePointer<Void>, count: Int ) -> Int? {
        return outputStream.hasSpaceAvailable ? _write( buffer, count: count ) : nil
    }

    deinit {
        flush()
        outputStream.close()
        inputStream.close()
    }

}

#endif


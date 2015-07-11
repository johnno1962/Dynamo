//
//  Servers.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Servers.swift#39 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: Private functions

let dynamoQueue = dispatch_queue_create( "DynamoThread", DISPATCH_QUEUE_CONCURRENT )
let dynamoSSLQueue = dispatch_queue_create( "DynamoSSLThread", DISPATCH_QUEUE_CONCURRENT )

let INADDR_ANY = in_addr_t(0)
let htons = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16 : { $0 }
let ntohs = htons

/**
     Result returned by a swiftlet to indicate whether it has handled the request. If a "Content-Length"
     header has been provided the connection can be reused in the HTTP/1.1 protocol and the connection
     will be kept open and recycled.
 */

@objc public enum DynamoProcessed : Int {
    case
        NotProcessed, // does not recogise the request
        Processed, // has processed the request
        ProcessedAndReusable // "" and connection may be reused
}

/**
     Basic protocol that switlets implement to pick up and process requests from a client.
 */

@objc public protocol DynamoSwiftlet {

    /**
        each request is presented ot each swiftlet until one indicates it has processed the request
     */
    @objc func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed    
}

// MARK: Basic http: Web server

/**
     Basic http protocol web server running on the specified port. Requests are presented to each of a set
     of swiftlets provided in a connecton thread until one is encountered that has processed the request.
 */

public class DynamoWebServer : NSObject, NSStreamDelegate {

    private let serverSocket: Int32
    public var serverPort: UInt16 = 0

    public convenience init?( portNumber: UInt16, swiftlets: [DynamoSwiftlet], localhostOnly: Bool = false ) {

        self.init( portNumber, localhostOnly: localhostOnly )

        if serverPort != 0 {
            runConnectionHandler( {
                (clientSocket: Int32) in

                if let httpClient = DynamoHTTPConnection( clientSocket: clientSocket ) {

                    while httpClient.readHeaders() {
                        var processed = false

                        for swiftlet in swiftlets {

                            switch swiftlet.process( httpClient ) {
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
            } )
        }
        else {
            return nil
        }
    }

    init( _ portNumber: UInt16, localhostOnly: Bool ) {

        var ip4addr = sockaddr_in(sin_len: UInt8(sizeof(sockaddr_in)),
            sin_family: sa_family_t(AF_INET),
            sin_port: htons(portNumber),
            sin_addr: in_addr(s_addr: INADDR_ANY),
            sin_zero: (Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0)))

        if localhostOnly {
            inet_aton( "127.0.0.1", &ip4addr.sin_addr )
        }

        serverSocket = socket( Int32(ip4addr.sin_family), SOCK_STREAM, 0 )
        var yes: u_int = 1, yeslen = socklen_t(sizeof(yes.dynamicType))

        if serverSocket < 0 {
            Strerror( "Could not get server socket" )
        }
        else if setsockopt( serverSocket, SOL_SOCKET, SO_REUSEADDR, &yes, yeslen ) < 0 {
            Strerror( "Could not set SO_REUSEADDR" )
        }
        else if Darwin.bind( serverSocket, sockaddr_cast(&ip4addr), socklen_t(ip4addr.sin_len) ) < 0 {
            Strerror( "Could not bind service socket on port \(portNumber)" )
        }
        else if listen( serverSocket, 100 ) < 0 {
            Strerror( "Server socket would not listen" )
        }
        else {
            var addrLen = socklen_t(sizeof(ip4addr.dynamicType))
            if getsockname( serverSocket, sockaddr_cast(&ip4addr), &addrLen ) == 0 {
                serverPort = ntohs( ip4addr.sin_port )
                dynamoLog( "Server available on http(s)://localhost:\(serverPort)" )
            }
        }

        super.init()
    }

    func runConnectionHandler( connectionHandler: (Int32) -> Void ) {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            while self.serverSocket >= 0 {

                let clientSocket = accept( self.serverSocket, nil, nil )

                if clientSocket >= 0 {
                    dispatch_async( dynamoQueue, {
                        if setupSocket( clientSocket ) {
                            connectionHandler( clientSocket )
                        }
                    } )
                }
            }
        } )
    }

}

// MARK: SSL https: Web Server

/**
    Subclass of DynamoWebServer for accepting https: SSL encoded requests. Create a proxy on the provided
    port to a surrogate DynamoWebServer on a random port on the localhost to actually process the requests.
*/

public class DynamoSSLWebServer : DynamoWebServer {

    /**
        Creates a proxy SSL sever for the surroagte server at the url provided. If no url is provided
        Also runs up it's own surroate no a random port on localhost to serve proxied requests. The 
        certs argument is the array returned from DDKeychain.SSLIdentityAndCertificates( keyName )
        where keyName is the name of hte SSL certificate in the local keychain.
     */

    public init?( portNumber: UInt16, swiftlets: [DynamoSwiftlet], certs: [AnyObject]?, surrogate: String? = nil ) {
        var surrogate = surrogate

        if surrogate == nil {
            // port number 0 uses any available port
            if let surrogateServer = DynamoWebServer( portNumber: 0, swiftlets: swiftlets, localhostOnly: true ) {
                dynamoLog( "Surrogate server on port \(surrogateServer.serverPort)" )
                surrogate = "http://localhost:\(surrogateServer.serverPort)"
            }
        }

        super.init( portNumber, localhostOnly: false )

        if serverPort != 0 {
            let surrogateURL = NSURL( string: surrogate! )!

            runConnectionHandler( {
                (clientSocket: Int32) in

                if let sslConnection = DynamoSSLConnection( clientSocket, certs: certs ),
                    localConnection = DynamoHTTPConnection( url: surrogateURL ) {
                        DynamoSelector.relay( "surrogate", from: sslConnection, to: localConnection, dynamoTrace )
                }
            } )
        }
        else {
            return nil
        }
    }

}

class DynamoSSLConnection: DynamoHTTPConnection, NSStreamDelegate {

    let inputStream: NSInputStream
    let outputStream: NSOutputStream

    init?( _ sslSocket: Int32, certs: [AnyObject]? ) {

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

    override func read(buffer: UnsafeMutablePointer<Void>, count: Int) -> Int {
        return inputStream.read( UnsafeMutablePointer<UInt8>(buffer), maxLength: count )
    }

    override func write(buffer: UnsafePointer<Void>, count: Int) -> Int {
        return outputStream.write( UnsafePointer<UInt8>(buffer), maxLength: count )
    }

    override func receive( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int? {
        return inputStream.hasBytesAvailable ? read( buffer, count: count ) :  nil
    }

    override func forward( buffer: UnsafePointer<Void>, count: Int ) -> Int? {
        return outputStream.hasSpaceAvailable ? write( buffer, count: count ) : nil
    }
    
    deinit {
        outputStream.close()
        inputStream.close()
    }
    
}

// MARK: Functions

func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

func sockaddr_in_cast(p: UnsafeMutablePointer<sockaddr>) -> UnsafeMutablePointer<sockaddr_in> {
    return UnsafeMutablePointer<sockaddr_in>(p)
}

func setupSocket( socket: Int32 ) -> Bool {
    var yes: u_int = 1, yeslen = socklen_t(sizeof(yes.dynamicType))
    if setsockopt( socket, SOL_SOCKET, SO_NOSIGPIPE, &yes, yeslen ) < 0 {
        Strerror( "Could not set SO_NOSIGPIPE" )
        return false
    }
    else if setsockopt( socket, IPPROTO_TCP, TCP_NODELAY, &yes, yeslen ) < 0 {
        Strerror( "Could not set TCP_NODELAY" )
        return false
    }
    return true
}

public func dynamoTrace<T>( msg: T ) {
    println( msg )
}

func dynamoLog<T>( msg: T ) {
    NSLog( "DynamoWebServer: %@", "\(msg)" )
}

func Strerror( msg: String ) {
    dynamoLog( msg+" - "+String( UTF8String: strerror(errno) )! )
}

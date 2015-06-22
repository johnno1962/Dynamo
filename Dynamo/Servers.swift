//
//  Servers.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Servers.swift#21 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: Private functions

let dynamoQueue = dispatch_queue_create( "DynamoThread", DISPATCH_QUEUE_CONCURRENT )
let dynamoSSLQueue = dispatch_queue_create( "DynamoSSLThread", DISPATCH_QUEUE_CONCURRENT )
let dynamoConnectionClass = DynamoHTTPConnection.self
let dynamoRelayImplementation = DynamoSelector.self


let INADDR_ANY = in_addr_t(0)
let htons = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16 : { $0 }
let ntohs = htons

func sockaddr_cast(p: UnsafeMutablePointer<sockaddr_in>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

func sockaddr_cast6(p: UnsafeMutablePointer<sockaddr_in6>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

func sockaddr_cast_in(p: UnsafeMutablePointer<sockaddr>) -> UnsafeMutablePointer<sockaddr_in> {
    return UnsafeMutablePointer<sockaddr_in>(p)
}

func setupSocket( socket: Int32 ) {
    var yes: u_int = 1, yeslen = socklen_t(sizeof(yes.dynamicType))
    if setsockopt( socket, SOL_SOCKET, SO_NOSIGPIPE, &yes, yeslen ) < 0 {
        Strerror( "Could not set SO_NOSIGPIPE" )
    }
    if setsockopt( socket, IPPROTO_TCP, TCP_NODELAY, &yes, yeslen ) < 0 {
        Strerror( "Could not set TCP_NODELAY" )
    }
}

public func dynamoTrace<T>( msg: T ) {
    println( msg )
}

func dynamoLog<T>( msg: T ) {
    println( "DynamoWebServer: \(msg)" )
}

func Strerror( msg: String ) {
    dynamoLog( msg+" - "+String( UTF8String: strerror(errno) )! )
}

/**
 Result returned by a processor to indicate whether it has handled the request. If a "Content-Length"
 header has been provided the connection can be reused in the HTTP/1.1 protocol and the connection
 will be recyled.
 */

@objc public enum DynamoProcessed : Int {
    case
        NotProcessed, // does not recogise the request
        Processed, // has processed the request
        ProcessedAndReusable // "" and connection may be reused
}

/*
 Basic protocol that processors must implement to pick up and process requests from a client.
 */

@objc public protocol DynamoProcessor {

    @objc func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed    
}

// MARK: Basic http: Web server

/**
 Basic http protocol web server running on the specified port. Requests are presented to each of a set
 of proessors provided in a connecton thread until one is encountered that can process the request.
 */

public class DynamoWebServer : NSObject, NSStreamDelegate {

    private let serverSocket: Int32
    public var serverPort: UInt16 = 0

    public convenience init?( portNumber: UInt16, processors: [DynamoProcessor], localhostOnly: Bool = false ) {

        self.init( portNumber, localhostOnly: localhostOnly )

        if serverPort != 0 {
            runConnectionHandler( {
                (clientSocket: Int32) in

                if let httpClient = dynamoConnectionClass( clientSocket: clientSocket ) {

                    while httpClient.readHeaders() {
                        var processed = false

                        for processor in processors {

                            switch processor.process( httpClient ) {
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
                            httpClient.print( "Invalid request: \(httpClient.method) \(httpClient.uri) \(httpClient.httpVersion)" )
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
            Strerror( "Could not get mutlicast socket" )
        }
        else if setsockopt( serverSocket, SOL_SOCKET, SO_REUSEADDR, &yes, yeslen ) < 0 {
            Strerror( "Could not set SO_REUSEADDR" )
        }
        else if Darwin.bind( serverSocket, sockaddr_cast(&ip4addr), socklen_t(ip4addr.sin_len) ) < 0 {
            Strerror( "Could not bind service socket on port \(portNumber)" )
        }
        else if listen( serverSocket, 50 ) < 0 {
            Strerror( "Service socket would not listen" )
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
                        setupSocket( clientSocket )
                        connectionHandler( clientSocket )
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

public class DynamoSSLWebServer : DynamoWebServer, NSStreamDelegate {

    private var relayMap = [NSStream:DynamoSSLRelay]()

    public init?( portNumber: UInt16, pocessors: [DynamoProcessor], certs: [AnyObject]? ) {

        var nonSSLPortOnLocalhost = portNumber-1

        // port number 0 uses any available port
        if let surrogateServer = DynamoWebServer( portNumber: 0, processors: pocessors, localhostOnly: true ) {
            nonSSLPortOnLocalhost = surrogateServer.serverPort
            dynamoLog( "Surrogate server on port \(nonSSLPortOnLocalhost)" )
        }

        super.init( portNumber, localhostOnly: false )

        if serverPort != 0 {

            var ip4addr = sockaddr_in(sin_len: UInt8(sizeof(sockaddr_in)),
                sin_family: sa_family_t(AF_INET),
                sin_port: htons( nonSSLPortOnLocalhost ), sin_addr: in_addr(s_addr:INADDR_ANY),
                sin_zero: (Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0)))

            let localhost = "127.0.0.1"
            inet_aton( localhost, &ip4addr.sin_addr )

            runConnectionHandler( {
                (clientSocket: Int32) in

                let localSocket = socket( Int32(ip4addr.sin_family), SOCK_STREAM, 0 )
                if localSocket < 0 {
                    Strerror( "Could not obtain socket" )
                }
                else if connect( localSocket, sockaddr_cast(&ip4addr), socklen_t(ip4addr.sin_len) ) < 0 {
                    Strerror( "Could not connect to: \(localhost):\(nonSSLPortOnLocalhost)" )
                }
                else {
                    setupSocket( localSocket )

                    let outputStream = DynamoSSLRelay( clientSocket, localSocket, server: self, certs: certs ).outputStream

                    dispatch_async( dynamoSSLQueue, {
                        var buffer = [UInt8](count: 8192, repeatedValue: 0)
                        while true {
                            let bytesRead = recv( localSocket, &buffer, buffer.count, 0 )
                            if bytesRead <= 0 {
                                self.close( outputStream )
                                return
                            }
                            else {
                                var ptr = 0
                                while ptr < bytesRead {
                                    let remaining = UnsafePointer<UInt8>(buffer)+ptr
                                    let bytesWritten = outputStream.write( remaining, maxLength: bytesRead-ptr )
                                    if bytesWritten <= 0 {
                                        dynamoLog( "Short write on SSL relay" )
                                        self.close( outputStream )
                                        return
                                    }
                                    ptr += bytesWritten
                                }
                            }
                        }
                    } )
                }
            } )
        }
        else {
            return nil
        }
    }

    public func stream( aStream: NSStream, handleEvent eventCode: NSStreamEvent ) {
        switch eventCode {
        case NSStreamEvent.HasBytesAvailable:
            var buffer = [UInt8](count: 8192, repeatedValue: 0)
            let bytesRead = (aStream as! NSInputStream).read( &buffer, maxLength: buffer.count )
            if bytesRead < 0 {
                close( aStream )
            }
            else if let relay = relayMap[aStream] {
                if send( relay.localSocket, &buffer, bytesRead, 0 ) != bytesRead {
                    dynamoLog( "Short write to surrogate" )
                }
            }
        case NSStreamEvent.ErrorOccurred:
            println( "ErrorOccurred: \(aStream) \(eventCode)" )
            fallthrough
        case NSStreamEvent.EndEncountered:
            close( aStream )
        default:
            break
        }
    }

    func close( aStream: NSStream ) {
        if let relay = relayMap[aStream] {
            relayMap.removeValueForKey( relay.inputStream )
            relayMap.removeValueForKey( relay.outputStream )
            //            relay.closer()
        }
    }
}

private class DynamoSSLRelay {

    let clientSocket: Int32
    let localSocket: Int32
    let inputStream: NSInputStream
    let outputStream: NSOutputStream

    init( _ clientSocket: Int32, _ localSocket: Int32, server: DynamoSSLWebServer, certs: [AnyObject]? ) {

        self.clientSocket = clientSocket
        self.localSocket = localSocket

        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocket( nil, clientSocket, &readStream, &writeStream )

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        server.relayMap[outputStream] = self
        server.relayMap[inputStream] = self

        outputStream.delegate = server
        inputStream.delegate = server

        inputStream.scheduleInRunLoop( NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode )
        outputStream.scheduleInRunLoop( NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode )

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

    deinit {
        outputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream.close()
        inputStream.close()
        close( clientSocket )
        close( localSocket )
    }
    
}

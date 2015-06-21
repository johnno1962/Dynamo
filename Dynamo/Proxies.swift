//
//  Proxies.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

import Foundation

private let DynamoSSLQueue = dispatch_queue_create( "DynamoSSLThread", DISPATCH_QUEUE_CONCURRENT )

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

                    dispatch_async( DynamoSSLQueue, {
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

// MARK: Proxy Processors

/**
 Processor to allow a DynamoWebServer to act as a http: protocol proxy on the same port.
 */

public class DynamoProxyProcessor : NSObject, DynamoProcessor {

    var logger: ((String) -> ())?

    public init( logger: ((String) -> ())? = nil ) {
        self.logger = logger
    }

    @objc public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        if httpClient.url.host == dummyBase.host {
            return .NotProcessed
        }

        if let host = httpClient.url.host, remoteConnection = DynamoHTTPConnection( url: httpClient.url ) {

            var remotePath = httpClient.url.path ?? "/"
            if let query = httpClient.url.query {
                remotePath += "?"+query
            }

            remoteConnection.rawPrint( "\(httpClient.method) \(remotePath) HTTP/1.0\r\n" )
            for (name, value) in httpClient.requestHeaders {
                //if name != "Connection" {
                    remoteConnection.rawPrint( "\(name): \(value)\r\n" )
                //}
            }
            //remoteConnection.rawPrint( "Connection: close\r\n" )
            remoteConnection.rawPrint( "\r\n" )
            remoteConnection.flush()

            remoteConnection.relay( "<- \(host)", to: httpClient, logger )
            httpClient.relay( "-> \(host)", to: remoteConnection, logger )
        }
        
        return .Processed
    }
    
}

/**
    Processor to allow a DynamoWebServer to act as a https: SSL connection protocol proxy on the same port.
    This must be come before the DynamoProxyProcessor in the list of processors for the server for both to work.
*/

public class DynamoSSLProxyProcessor : DynamoProxyProcessor {

    public override func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        if httpClient.method != "CONNECT" {
            return .NotProcessed
        }

        if let urlForDestination = NSURL( string: "https://\(httpClient.uri)" ),
            remoteConnection = DynamoHTTPConnection( url: urlForDestination ) {
                httpClient.rawPrint( "HTTP/1.0 200 Connection established\r\nProxy-agent: Dynamo/1.0\r\n\r\n" )
                httpClient.flush()
                remoteConnection.relay( "<- \(httpClient.uri)", to: httpClient, logger )
                httpClient.relay( "-> \(httpClient.uri)", to: remoteConnection, logger )
        }

        return .Processed
    }
    
}


//
//  Proxies.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Proxies.swift#17 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation


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

        if let host = httpClient.url.host, remoteConnection = dynamoConnectionClass( url: httpClient.url ) {

            var remotePath = httpClient.url.path ?? "/"
            if !remotePath.hasSuffix( "/" ) && httpClient.uri.hasSuffix( "/" ) {
                remotePath += "/"
            }
            if let query = httpClient.url.query {
                remotePath += "?"+query
            }

            //println( "\(httpClient.method) \(remotePath) \(httpClient.httpVersion)" )
            remoteConnection.rawPrint( "\(httpClient.method) \(remotePath) \(httpClient.httpVersion)\r\n" )
            for (name, value) in httpClient.requestHeaders {
                //if name != "Connection" {
                //println( "\(name): \(value)" )
                remoteConnection.rawPrint( "\(name): \(value)\r\n" )
                //}
            }
            //remoteConnection.rawPrint( "Connection: close\r\n" )
            remoteConnection.rawPrint( "\r\n" )
            remoteConnection.flush()

            dynamoRelayImplementation.relay( "<- \(host)", from: remoteConnection, to: httpClient, logger )
            dynamoRelayImplementation.relay( "-> \(host)", from: httpClient, to: remoteConnection, logger )
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
            remoteConnection = dynamoConnectionClass( url: urlForDestination ) {
                httpClient.rawPrint( "HTTP/1.0 200 Connection established\r\nProxy-agent: Dynamo/1.0\r\n\r\n" )
                httpClient.flush()
                dynamoRelayImplementation.relay( "<- \(httpClient.uri)", from: remoteConnection, to: httpClient, logger )
                dynamoRelayImplementation.relay( "-> \(httpClient.uri)", from: httpClient, to: remoteConnection, logger )
        }

        return .Processed
    }
    
}

// MARK: "select()" based fd switching

private var dynamoSelector: DynamoSelector?
private var dynamorMapLock : OSSpinLock = OS_SPINLOCK_INIT

/**
    More efficient than relying on operating system to handle many reads on different threads when proxying
*/

final class DynamoSelector {

    var readMap = [Int32:DynamoHTTPConnection]()
    var writeMap = [Int32:DynamoHTTPConnection]()

    var timeout = timeval()
    let bitsPerFlag: Int32 = 32

    func FD_ZERO( flags: UnsafeMutablePointer<Int32> ) {
        memset( flags, 0, sizeof(fd_set) )
    }

    func FD_CLR( fd: Int32, _ flags: UnsafeMutablePointer<Int32> ) {
        let set = flags + Int( fd/bitsPerFlag )
        set.memory = set.memory & ~(1<<(fd%bitsPerFlag))
    }

    func FD_SET( fd: Int32, _ flags: UnsafeMutablePointer<Int32> ) {
        let set = flags + Int( fd/bitsPerFlag )
        set.memory = set.memory | (1<<(fd%bitsPerFlag))
    }

    func FD_ISSET( fd: Int32, _ flags: UnsafeMutablePointer<Int32> ) -> Bool {
        let set = flags + Int( fd/bitsPerFlag )
        return (set.memory & (1<<(fd%bitsPerFlag))) != 0
    }


    class func relay( label: String, from: DynamoHTTPConnection, to: DynamoHTTPConnection, _ logger: ((String) -> ())? ) {
        OSSpinLockLock( &dynamorMapLock )

        if dynamoSelector == nil {
            dynamoSelector = DynamoSelector()
            dispatch_async( dynamoSSLQueue, {
                dynamoSelector!.selectLoop( logger )
            } )
        }

        from.label = label
        dynamoSelector!.readMap[from.clientSocket] = to

        OSSpinLockUnlock( &dynamorMapLock )
    }

    func selectLoop( _ logger: ((String) -> Void)? = nil ) {
        var buffer = [Int8](count: 32*1024, repeatedValue: 0)
        var readFlags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )
        var writeFlags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )
        var errorFlags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )

        while true {
            FD_ZERO( readFlags )
            FD_ZERO( writeFlags )
            FD_ZERO( errorFlags )

            var maxfd: Int32 = -1
            for (fd,connection) in readMap {
                if let writer = readMap[fd],
                    reader = readMap[writer.clientSocket] {
                    if reader.readEOF || reader.clientSocket != fd {
                        continue
                    }
                }

                FD_SET( fd, readFlags )
                FD_SET( fd, errorFlags )
                if maxfd < fd {
                    maxfd = fd
                }
            }

            var hasWrite = false
            for (fd,connection) in writeMap {
                if connection.writeBuffer.length > 0 {
                    FD_SET( fd, writeFlags )
                    FD_SET( fd, errorFlags )
                    if maxfd < fd {
                        maxfd = fd
                    }
                    hasWrite = true
                }
            }

            timeout.tv_sec = 0
            timeout.tv_usec = 100*1000

            if select( maxfd+1,
                UnsafeMutablePointer<fd_set>( readFlags ),
                hasWrite ? UnsafeMutablePointer<fd_set>( writeFlags ) : nil,
                UnsafeMutablePointer<fd_set>( errorFlags ), &timeout ) < 0  {
                    Strerror( "Select error \(readMap)" )
                    readMap = [Int32:DynamoHTTPConnection]()
                    continue
            }

            if maxfd < 0 {
                continue
            }

            for readFD in 0..<maxfd {
                if FD_ISSET( readFD, readFlags ) {
                    let bytesRead = recv( readFD, &buffer, buffer.count, 0 )

                    if let writer = readMap[readFD] {

                        if logger != nil {
                            logger!( "\(writer.label) \(bytesRead) bytes (\(readFD))" )
                        }

                        if bytesRead <= 0 {
                            if writer.writeBuffer.length == 0 || writer.readEOF {
                                close( readFD )
                            }
                            else if let reader = readMap[writer.clientSocket] {
                                reader.readEOF = true
                            }
                        }
                        else {
                            writer.writeBuffer.appendBytes( buffer, length: bytesRead )
                            writeMap[writer.clientSocket] = writer
                        }
                    }
                    else {
                        dynamoLog( "NO WRITER" )
                    }
                }
            }

            for writeFD in 0..<maxfd {
                if FD_ISSET( writeFD, writeFlags ) {
                    if let writer = writeMap[writeFD] {

                        let bytesWritten = send( writeFD,
                            writer.writeBuffer.bytes,
                            writer.writeBuffer.length, 0 )

                        if bytesWritten <= 0 {
                            dynamoLog( "Short write on relay" )
                            close( writeFD )
                        }
                        else {
                            writer.writeBuffer.replaceBytesInRange( NSMakeRange( 0, bytesWritten ), withBytes: nil, length: 0 )
                            if writer.writeBuffer.length == 0 {
                                writeMap.removeValueForKey( writer.clientSocket )
                            }
                            if let reader = readMap[writeFD] {
                                if reader.readEOF {
                                    close( writeFD )
                                }
                            }
                        }
                    }
                }
            }

            for errorFD in 0..<maxfd {
                if FD_ISSET( errorFD, errorFlags ) {
                    dynamoLog( "ERROR on relay" )
                    close( errorFD )
                }
            }
        }
    }

    func close( fd: Int32 ) {
        if let writer = readMap[fd] {
            readMap.removeValueForKey( writer.clientSocket )
            writeMap.removeValueForKey( writer.clientSocket )
        }
        readMap.removeValueForKey( fd )
        writeMap.removeValueForKey( fd )
    }
    
}

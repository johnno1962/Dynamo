//
//  Proxies.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Proxies.swift#28 $
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

        if let host = httpClient.url.host, remoteConnection = DynamoHTTPConnection( url: httpClient.url ) {

            var remotePath = httpClient.url.path ?? "/"
            if !remotePath.hasSuffix( "/" ) && httpClient.path.hasSuffix( "/" ) {
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

            DynamoSelector.relay( host, from: remoteConnection, to: httpClient, logger )
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

        if let urlForDestination = NSURL( string: "https://\(httpClient.path)" ),
            remoteConnection = DynamoHTTPConnection( url: urlForDestination ) {
                httpClient.rawPrint( "HTTP/1.0 200 Connection established\r\nProxy-agent: Dynamo/1.0\r\n\r\n" )
                httpClient.flush()
                DynamoSelector.relay( httpClient.path, from: remoteConnection, to: httpClient, logger )
        }

        return .Processed
    }
    
}

// MARK: "select()" based fd switching

var dynamoSelector: DynamoSelector?
private let selectBitsPerFlag: Int32 = 32
private let selectShift: Int32 = 5
private let selectBitMask: Int32 = (1<<selectShift)-1
private var dynamoQueueLock: OSSpinLock = OS_SPINLOCK_INIT

func FD_ZERO( flags: UnsafeMutablePointer<Int32> ) {
    memset( flags, 0, sizeof(fd_set) )
}

func FD_CLR( fd: Int32, flags: UnsafeMutablePointer<Int32> ) {
    let set = flags + Int( fd>>selectShift )
    set.memory &= ~(1<<(fd&selectBitMask))
}

func FD_SET( fd: Int32, flags: UnsafeMutablePointer<Int32> ) {
    let set = flags + Int( fd>>selectShift )
    set.memory |= 1<<(fd&selectBitMask)
}

func FD_ISSET( fd: Int32, flags: UnsafeMutablePointer<Int32> ) -> Bool {
    let set = flags + Int( fd>>selectShift )
    return (set.memory & (1<<(fd&selectBitMask))) != 0
}

@asmname("fcntl")
func fcntl( filedesc: Int32, command: Int32, arg: Int32 ) -> Int32

/**
    More efficient than relying on operating system to handle many reads on different threads when proxying
*/

final class DynamoSelector {

    var readMap = [Int32:DynamoHTTPConnection]()
    var writeMap = [Int32:DynamoHTTPConnection]()
    var queue = [(String,DynamoHTTPConnection,DynamoHTTPConnection)]()

    class func relay( label: String, from: DynamoHTTPConnection, to: DynamoHTTPConnection, _ logger: ((String) -> ())? ) {
        OSSpinLockLock( &dynamoQueueLock )

        if dynamoSelector == nil {
            dynamoSelector = DynamoSelector()
            dispatch_async( dynamoSSLQueue, {
                dynamoSelector!.selectLoop( logger )
            } )
        }

        dynamoSelector!.queue.append( (label,from,to) )
        OSSpinLockUnlock( &dynamoQueueLock )
    }

    func selectLoop( _ logger: ((String) -> Void)? = nil ) {

        var readFlags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )
        var writeFlags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )
        var errorFlags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )

        var buffer = [Int8](count: 32*1024, repeatedValue: 0)
        var timeout = timeval()

        while true {

            OSSpinLockLock( &dynamoQueueLock )
            while queue.count != 0 {
                let (label,from,to) = queue.removeAtIndex(0)
                to.label = "<- \(label)"
                from.label = "-> \(label)"

                var flags = fcntl( to.clientSocket, F_GETFL, 0 )
                flags |= O_NONBLOCK
                fcntl( to.clientSocket, F_SETFL, flags )

                readMap[from.clientSocket] = to
                readMap[to.clientSocket] = from
            }
            OSSpinLockUnlock( &dynamoQueueLock )

            FD_ZERO( readFlags )
            FD_ZERO( writeFlags )
            FD_ZERO( errorFlags )

            var maxfd: Int32 = -1, fdcount = 0
            for (fd,connection) in readMap {
                FD_SET( fd, readFlags )
                FD_SET( fd, errorFlags )
                if maxfd < fd {
                    maxfd = fd
                }
                fdcount++
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
                    timeout.tv_sec = 0
                    timeout.tv_usec = 0
                    Strerror( "Select error \(readMap) \(writeMap)" )
                    for (fd,writer) in readMap {
                        FD_ZERO( readFlags )
                        FD_SET( fd, readFlags )
                        if  select( fd+1, UnsafeMutablePointer<fd_set>( readFlags ), nil, nil, &timeout ) < 0 {
                            dynamoLog( "Closing reader: \(fd)" )
                            close( fd )
                        }
                    }
                    for (fd,writer) in writeMap {
                        FD_ZERO( readFlags )
                        FD_SET( fd, readFlags )
                        if  select( fd+1, UnsafeMutablePointer<fd_set>( readFlags ), nil, nil, &timeout ) < 0 {
                            dynamoLog( "Closing writer: \(fd)" )
                            close( fd )
                        }
                    }
                    continue
            }

            if maxfd < 0 {
                continue
            }

            for readFD in 0...maxfd {
                if let writer = readMap[readFD], reader = readMap[writer.clientSocket] {
                    if FD_ISSET( readFD, readFlags ) ||
                        writer.writeCounter != 0 && reader.hasBytesAvailable {

                        if let bytesRead = reader.receive( &buffer, count: buffer.count ) {

                            if logger != nil {
                                logger!( "\(writer.label) \(writer.writeCounter)+\(writer.writeBuffer.length)+\(bytesRead) bytes (\(readFD)/\(readMap.count)/\(fdcount))" )
                            }

                            if bytesRead <= 0 {
                                if writer.readEOF || writer.writeBuffer.length == 0 {
                                    close( readFD )
                                }
                                else {
                                    reader.readEOF = true
                                }
                            }
                            else {
                                writer.writeBuffer.appendBytes( buffer, length: bytesRead )
                                writer.writeCounter += bytesRead
                            }

                            if writer.writeBuffer.length != 0 || reader.readEOF {
                                writeMap[writer.clientSocket] = writer
                            }
                        }
                    }
                }
            }

            for writeFD in 0...maxfd {
                if FD_ISSET( writeFD, writeFlags ) {
                    if let writer = writeMap[writeFD],
                        bytesWritten = writer.forward( writer.writeBuffer.bytes, count: writer.writeBuffer.length ) {

                        if bytesWritten <= 0 {
                            dynamoLog( "Short write on relay" )
                            close( writeFD )
                        }
                        else {
                            writer.writeBuffer.replaceBytesInRange( NSMakeRange( 0, bytesWritten ), withBytes: nil, length: 0 )
                        }
                        if writer.writeBuffer.length == 0 {
                            writeMap.removeValueForKey( writer.clientSocket )
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
    
    private func close( fd: Int32 ) {
        let writer = readMap[fd]
        let reader = writer != nil ? readMap[writer!.clientSocket] : nil
        if writer != nil {
            readMap.removeValueForKey( writer!.clientSocket )
            writeMap.removeValueForKey( writer!.clientSocket )
        }
        readMap.removeValueForKey( fd )
        writeMap.removeValueForKey( fd )
    }
    
}

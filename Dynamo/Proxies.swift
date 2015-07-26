//
//  Proxies.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Proxies.swift#51 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation


// MARK: Proxy Swiftlets

/**
     Swiftlet to allow a DynamoWebServer to act as a http: protocol proxy on the same port.
 */

public class ProxySwiftlet: NSObject, DynamoSwiftlet {

    var logger: ((String) -> ())?

    /** default initialiser with optional "tracer" for all traffic */
    public init( logger: ((String) -> ())? = nil ) {
        self.logger = logger
    }

    /** process as proxy request if request path has "host" */
    public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        if httpClient.url.host == dummyBase.host {
            return .NotProcessed
        }

        if let host = httpClient.url.host, remoteConnection = DynamoHTTPConnection( url: httpClient.url ) {

            var remotePath = httpClient.url.path ?? "/"
            if !remotePath.hasSuffix( "/" ) && (httpClient.path.hasSuffix( "/" ) || httpClient.path.rangeOfString( "/?" ) != nil) {
                remotePath += "/"
            }
            if let query = httpClient.url.query {
                remotePath += "?"+query
            }

            remoteConnection.rawPrint( "\(httpClient.method) \(remotePath) \(httpClient.version)\r\n" )
            for (name, value) in httpClient.requestHeaders {
                remoteConnection.rawPrint( "\(name): \(value)\r\n" )
            }
            remoteConnection.rawPrint( "\r\n" )

            if httpClient.readBuffer.length != 0 {
                let readBuffer = httpClient.readBuffer
                remoteConnection.write( readBuffer.bytes, count: readBuffer.length )
                readBuffer.replaceBytesInRange( NSMakeRange( 0, readBuffer.length ), withBytes: nil, length: 0 )
            }
            remoteConnection.flush()

            DynamoSelector.relay( host, from: httpClient, to: remoteConnection, logger )
        }

        return .Processed
    }

}

/**
    Swiftlet to allow a DynamoWebServer to act as a https: SSL connection protocol proxy on the same port.
    This must be come before the DynamoProxySwiftlet in the list of swiftlets for the server for both to work.
*/

public class SSLProxySwiftlet: ProxySwiftlet {

    /** connect socket through to destination SSL server for method "CONNECT" */
    public override func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        if httpClient.method == "CONNECT" {

            if let urlForDestination = NSURL( string: "https://\(httpClient.path)" ),
                remoteConnection = DynamoHTTPConnection( url: urlForDestination ) {
                    httpClient.rawPrint( "HTTP/1.0 200 Connection established\r\nProxy-agent: Dynamo/1.0\r\n\r\n" )
                    httpClient.flush()
                    DynamoSelector.relay( httpClient.path, from: httpClient, to: remoteConnection, logger )
            }

            return .Processed
        }

        return .NotProcessed
    }

}

// MARK: "select()" based fd switching

var dynamoSelector: DynamoSelector?
private let selectBitsPerFlag: Int32 = 32
private let selectShift: Int32 = 5
private let selectBitMask: Int32 = (1<<selectShift)-1
private var dynamoQueueLock = OS_SPINLOCK_INIT
private let dynamoProxyQueue = dispatch_queue_create( "DynamoProxyThread", DISPATCH_QUEUE_CONCURRENT )

/** polling interval for proxy relay */
public var dynamoPollingUsec: Int32 = 100*1000
private var maxReadAhead = 10*1024*1024
private var maxPacket = 2*1024

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
            dispatch_async( dynamoProxyQueue, {
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

        var buffer = [Int8](count: maxPacket, repeatedValue: 0)
        var timeout = timeval()

        while true {

            OSSpinLockLock( &dynamoQueueLock )
            while queue.count != 0 {
                let (label,from,to) = queue.removeAtIndex(0)
                to.label = "-> \(label)"
                from.label = "<- \(label)"

                if label == "surrogate" {
                    var flags = fcntl( to.clientSocket, F_GETFL, 0 )
                    flags |= O_NONBLOCK
                    fcntl( to.clientSocket, F_SETFL, flags )
                }

                readMap[from.clientSocket] = to
                readMap[to.clientSocket] = from
            }
            OSSpinLockUnlock( &dynamoQueueLock )

            FD_ZERO( readFlags )
            FD_ZERO( writeFlags )
            FD_ZERO( errorFlags )

            var maxfd: Int32 = -1, fdcount = 0
            for (fd,writer) in readMap {
                if writer.readBuffer.length < maxReadAhead {
                    FD_SET( fd, readFlags )
                }
                FD_SET( fd, errorFlags )
                if maxfd < fd {
                    maxfd = fd
                }
                fdcount++
            }

            var hasWrite = false
            for (fd,writer) in writeMap {
                FD_SET( fd, writeFlags )
                FD_SET( fd, errorFlags )
                if maxfd < fd {
                    maxfd = fd
                }
                hasWrite = true
            }

            timeout.tv_sec = 0
            timeout.tv_usec = dynamoPollingUsec

            if select( maxfd+1,
                    UnsafeMutablePointer<fd_set>( readFlags ),
                    hasWrite ? UnsafeMutablePointer<fd_set>( writeFlags ) : nil,
                    UnsafeMutablePointer<fd_set>( errorFlags ), &timeout ) < 0 {

                timeout.tv_sec = 0
                timeout.tv_usec = 0
                dynamoStrerror( "Select error \(readMap) \(writeMap)" )

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
                        writeMap.removeValueForKey( writer.clientSocket )
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
                if let writer = readMap[readFD], reader = readMap[writer.clientSocket]
                    where FD_ISSET( readFD, readFlags ) || writer.readTotal != 0 && reader.hasBytesAvailable {

                    if let bytesRead = reader.receive( &buffer, count: buffer.count ) {
                        let readBuffer = writer.readBuffer

                        logger?( "\(writer.label) \(writer.readTotal)+\(readBuffer.length)+\(bytesRead) bytes (\(readFD)/\(readMap.count)/\(fdcount))" )

                        if bytesRead <= 0 {
                            close( readFD )
                        }
                        else {
                            readBuffer.appendBytes( buffer, length: bytesRead )
                            writer.readTotal += bytesRead
                        }

                        if readBuffer.length != 0 {
                            writeMap[writer.clientSocket] = writer
                        }
                    }
                }
            }

            for (writeFD,writer) in writeMap {
                if FD_ISSET( writeFD, writeFlags ) {
                    let readBuffer = writer.readBuffer

                    if let bytesWritten = writer.forward( readBuffer.bytes, count: readBuffer.length ) {
                        if bytesWritten <= 0 {
                            writeMap.removeValueForKey( writer.clientSocket )
                            dynamoLog( "Short write on relay \(writer.label)" )
                            close( writeFD )
                        }
                        else {
                            readBuffer.replaceBytesInRange( NSMakeRange( 0, bytesWritten ), withBytes: nil, length: 0 )
                        }

                        if readBuffer.length == 0 {
                            writeMap.removeValueForKey( writer.clientSocket )
                        }
                    }
                }
            }

            for errorFD in 0..<maxfd {
                if FD_ISSET( errorFD, errorFlags ) {
                    writeMap.removeValueForKey( errorFD )
                    dynamoLog( "ERROR on relay" )
                    close( errorFD )
                }
            }
        }
    }

    private func close( fd: Int32 ) {
        if let writer = readMap[fd] {
            readMap.removeValueForKey( writer.clientSocket )
        }
        readMap.removeValueForKey( fd )
    }

}

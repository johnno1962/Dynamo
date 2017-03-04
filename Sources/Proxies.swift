//
//  Proxies.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Proxies.swift#13 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

#if os(Linux)
import Dispatch
import Glibc
#endif

// MARK: Proxy Swiftlets

/**
     Swiftlet to allow a DynamoWebServer to act as a http: protocol proxy on the same port.
 */

open class ProxySwiftlet: _NSObject_, DynamoSwiftlet {

    var logger: ((String) -> ())?

    /** default initialiser with optional "tracer" for all traffic */
    public init( logger: ((String) -> ())? = nil ) {
        self.logger = logger
    }

    /** process as proxy request if request path has "host" */
    open func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        if httpClient.url.host == dummyBase.host {
            return .notProcessed
        }

        if let host = httpClient.url.host {
            if let remoteConnection = DynamoHTTPConnection( url: httpClient.url ) {

                var remotePath = httpClient.url.path == "" ? "/" : httpClient.url.path
                if !remotePath.hasSuffix( "/" ) && (httpClient.path.hasSuffix( "/" ) || httpClient.path.range( of: "/?" ) != nil) {
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
                    remoteConnection.write( buffer: readBuffer.bytes, count: readBuffer.length )
                    readBuffer.replaceBytes( in: NSMakeRange( 0, readBuffer.length ), withBytes: nil, length: 0 )
                }
                remoteConnection.flush()

                DynamoSelector.relay( host, from: httpClient, to: remoteConnection, logger )
            }
            else {
                httpClient.sendResponse( resp: .ok( html: "Unable to resolve host \(host)" ) )
            }
        }
        return .processed
    }

}

/**
    Swiftlet to allow a DynamoWebServer to act as a https: SSL connection protocol proxy on the same port.
    This must be come before the DynamoProxySwiftlet in the list of swiftlets for the server for both to work.
*/

open class SSLProxySwiftlet: ProxySwiftlet {

    /** connect socket through to destination SSL server for method "CONNECT" */
    open override func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        if httpClient.method == "CONNECT" {

            if let urlForDestination = URL( string: "https://\(httpClient.path)" ),
                let remoteConnection = DynamoHTTPConnection( url: urlForDestination ) {
                    httpClient.rawPrint( "HTTP/1.0 200 Connection established\r\nProxy-agent: Dynamo/1.0\r\n\r\n" )
                    httpClient.flush()
                    DynamoSelector.relay( httpClient.path, from: httpClient, to: remoteConnection, logger )
            }

            return .processed
        }

        return .notProcessed
    }

}

// MARK: "select()" based fd switching

var dynamoSelector: DynamoSelector?
private let selectBitsPerFlag: Int32 = 32
private let selectShift: Int32 = 5
private let selectBitMask: Int32 = (1<<selectShift)-1
private var dynamoQueueLock = NSLock()
private let dynamoProxyQueue = DispatchQueue( label: "DynamoProxyThread", attributes: DispatchQueue.Attributes.concurrent )

/** polling interval for proxy relay */
public var dynamoPollingUsec: Int32 = 100*1000
private var maxReadAhead = 10*1024*1024
private var maxPacket = 2*1024

func FD_ZERO( _ flags: UnsafeMutablePointer<Int32> ) {
    memset( flags, 0, MemoryLayout<fd_set>.size )
}

func FD_CLR( _ fd: Int32, _ flags: UnsafeMutablePointer<Int32> ) {
    let set = flags + Int( fd>>selectShift )
    set.pointee &= ~(1<<(fd&selectBitMask))
}

func FD_SET( _ fd: Int32, _ flags: UnsafeMutablePointer<Int32> ) {
    let set = flags + Int( fd>>selectShift )
    set.pointee |= 1<<(fd&selectBitMask)
}

func FD_ISSET( _ fd: Int32, _ flags: UnsafeMutablePointer<Int32> ) -> Bool {
    let set = flags + Int( fd>>selectShift )
    return (set.pointee & (1<<(fd&selectBitMask))) != 0
}

//#if !os(Linux)
//@asmname("fcntl")
//func fcntl( filedesc: Int32, _ command: Int32, _ arg: Int32 ) -> Int32
//#endif

/**
    More efficient than relying on operating system to handle many reads on different threads when proxying
*/

final class DynamoSelector {

    var readMap = [Int32:DynamoHTTPConnection]()
    var writeMap = [Int32:DynamoHTTPConnection]()
    var queue = [(String,DynamoHTTPConnection,DynamoHTTPConnection)]()

    class func relay( _ label: String, from: DynamoHTTPConnection, to: DynamoHTTPConnection, _ logger: ((String) -> ())? ) {
        dynamoQueueLock.lock()

        if dynamoSelector == nil {
            dynamoSelector = DynamoSelector()
            dynamoProxyQueue.async(execute: {
                dynamoSelector!.selectLoop( logger )
            } )
        }

        dynamoSelector!.queue.append( (label,from,to) )
        dynamoQueueLock.unlock()
    }

    func selectLoop( _ logger: ((String) -> Void)? = nil ) {

        let readFlags = malloc( MemoryLayout<fd_set>.size ).assumingMemoryBound(to: Int32.self)
        let writeFlags = malloc( MemoryLayout<fd_set>.size ).assumingMemoryBound(to: Int32.self)
        let errorFlags = malloc( MemoryLayout<fd_set>.size ).assumingMemoryBound(to: Int32.self)

        var buffer = [Int8](repeating: 0, count: maxPacket)
        var timeout = timeval()

        while true {

	    dynamoQueueLock.lock()
            while queue.count != 0 {
                let (label,from,to) = queue.remove(at: 0)
                to.label = "-> \(label)"
                from.label = "<- \(label)"

//                #if !os(Linux)
//                if label == "surrogate" {
//                    var flags = fcntl( to.clientSocket, F_GETFL, 0 )
//                    flags |= O_NONBLOCK
//                    fcntl( to.clientSocket, F_SETFL, flags )
//                }
//                #endif

                readMap[from.clientSocket] = to
                readMap[to.clientSocket] = from
            }
	    dynamoQueueLock.unlock()

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
                fdcount += 1
            }

            var hasWrite = false
            for (fd,_) in writeMap {
                FD_SET( fd, writeFlags )
                FD_SET( fd, errorFlags )
                if maxfd < fd {
                    maxfd = fd
                }
                hasWrite = true
            }

            timeout.tv_sec = 0
            #if os(Linux)
            timeout.tv_usec = Int(dynamoPollingUsec)
            #else
            timeout.tv_usec = dynamoPollingUsec
            #endif

            func fd_set_ptr( _ p: UnsafeMutablePointer<Int32> ) -> UnsafeMutablePointer<fd_set> {
                return unsafeBitCast(p, to: UnsafeMutablePointer<fd_set>.self)
            }

            if select( maxfd+1,
                    fd_set_ptr( readFlags ),
                    hasWrite ? fd_set_ptr( writeFlags ) : nil,
                    fd_set_ptr( errorFlags ), &timeout ) < 0 {

                timeout.tv_sec = 0
                timeout.tv_usec = 0
                dynamoStrerror( "Select error \(readMap) \(writeMap)" )

                for (fd,_) in readMap {
                    FD_ZERO( readFlags )
                    FD_SET( fd, readFlags )
                    if  select( fd+1, fd_set_ptr( readFlags ), nil, nil, &timeout ) < 0 {
                        dynamoLog( "Closing reader: \(fd)" )
                        close( fd )
                    }
                }

                for (fd,writer) in writeMap {
                    FD_ZERO( readFlags )
                    FD_SET( fd, readFlags )
                    if  select( fd+1, fd_set_ptr( readFlags ), nil, nil, &timeout ) < 0 {
                        writeMap.removeValue( forKey: writer.clientSocket )
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
                if let writer = readMap[readFD], let reader = readMap[writer.clientSocket], FD_ISSET( readFD, readFlags ) || writer.readTotal != 0 && reader.hasBytesAvailable {

                    if let bytesRead = reader.receive( buffer: &buffer, count: buffer.count ) {
                        let readBuffer = writer.readBuffer

                        logger?( "\(writer.label) \(writer.readTotal)+\(readBuffer.length)+\(bytesRead) bytes (\(readFD)/\(readMap.count)/\(fdcount))" )

                        if bytesRead <= 0 {
                            close( readFD )
                        }
                        else {
                            readBuffer.append( buffer, length: bytesRead )
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

                    if let bytesWritten = writer.forward( buffer: readBuffer.bytes, count: readBuffer.length ) {
                       if bytesWritten <= 0 {
                            writeMap.removeValue( forKey: writer.clientSocket )
                            dynamoLog( "Short write on relay \(writer.label)" )
                            close( writeFD )
                        }
                        else {
                            readBuffer.replaceBytes( in: NSMakeRange( 0, bytesWritten ), withBytes: nil, length: 0 )
                        }

                        if readBuffer.length == 0 {
                            writeMap.removeValue( forKey: writer.clientSocket )
                        }
                    }
                }
            }

            for errorFD in 0..<maxfd {
                if FD_ISSET( errorFD, errorFlags ) {
                    writeMap.removeValue( forKey: errorFD )
                    dynamoLog( "ERROR from select on relay" )
                    close( errorFD )
                }
            }
        }
    }

    fileprivate func close( _ fd: Int32 ) {
        if let writer = readMap[fd] {
            readMap.removeValue( forKey: writer.clientSocket )
        }
        readMap.removeValue( forKey: fd )
    }

}

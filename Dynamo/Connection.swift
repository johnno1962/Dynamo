//
//  Connection.swift
//  Dynamo
//
//  Created by John Holdsworth on 22/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Connection.swift#5 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: HTTP request parser

let dummyBase = NSURL( string: "http://nohost" )!
private var dynamoRelayThreads = 0

/**
* HTTP return status mapping
*/
public var dynamoStatusText = [
    200: "OK",
    304: "Redirect",
    400: "Invalid request",
    404: "File not found",
    500: "Server error"
]

/**
Class representing a connection to a client web browser. One is created each time the server
connects to read the standard HTTP headers ready to present to each of the processors of the server.
*/
@objc public class DynamoHTTPConnection : NSObject {

    private let readFILE: UnsafeMutablePointer<FILE>, writeFILE: UnsafeMutablePointer<FILE>
    let clientSocket: Int32

    // data for DynamoSelector
    let writeBuffer = NSMutableData()
    var readEOF = false
    var label = ""

    public var method = "GET", uri = "/", httpVersion = "HTTP/1.1"
    public var url = dummyBase
    public var status = 200

    var requestHeaders = [String:String]()
    var responseHeaders = ""
    var sentHeaders = false

    required public init?( clientSocket: Int32 ) {
        self.clientSocket = clientSocket
        readFILE = fdopen( clientSocket, "r" )
        writeFILE = fdopen( clientSocket, "w" )
        super.init()
        if (readFILE == nil || writeFILE == nil) && clientSocket >= 0 {
            Strerror( "FILE open error on fd #\(clientSocket)" )
            return nil;
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

    func read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        return readFILE != nil ? fread( buffer, 1, count, readFILE ) : -1
    }

    func write( buffer: UnsafePointer<Void>, count: Int ) -> Int {
        return writeFILE != nil ? fwrite( buffer, 1, count, writeFILE ) : -1
    }

    func readHeaders() -> Bool {
        if let request = readLine() {

            let components = split( request, maxSplit: 2, allowEmptySlices: true, isSeparator: { $0 == " " } )
            if components.count < 3 {
                return false
            }

            method = components[0]
            uri = components[1]
            httpVersion = components[2]

            url = NSURL( string: uri, relativeToURL: dummyBase ) ?? dummyBase
            requestHeaders = [String: String]()
            responseHeaders = ""
            sentHeaders = false
            status = 200

            while let line = readLine() {
                //dynamoTrace( line )
                let nameValue = split( line, maxSplit: 1, allowEmptySlices: true, isSeparator: { $0 == ":" } )
                if nameValue.count < 2 {
                    return true
                }
                else {
                    let value = nameValue[1].substringFromIndex( advance(nameValue[1].startIndex,1) )
                    requestHeaders[nameValue[0]] = value
                }
            }
        }

        return false
    }

    private var buffer = [Int8](count: 100001, repeatedValue: 0)

    func readLine() -> String? {
        if readFILE != nil &&
            fgets( &buffer, Int32(buffer.count), readFILE ) != nil {
                return String( UTF8String: buffer )?
                    .stringByTrimmingCharactersInSet( NSCharacterSet.whitespaceAndNewlineCharacterSet() )
        }
        else {
            return nil
        }
    }

    let cr = Int8(("\r" as NSString).characterAtIndex(0)), nl = Int8(("\n" as NSString).characterAtIndex(0))

    func readLine2() -> String? {
        var ptr = 0
        while ptr < buffer.count-1 {
            if recv( clientSocket, &buffer[ptr], 1, 0 ) != 1 {
                return nil
            }
            if buffer[ptr] == cr {
                continue
            }
            if buffer[ptr] == nl {
                break
            }
            ptr++
        }
        buffer[ptr] = 0
        return String( UTF8String: buffer )?
            .stringByTrimmingCharactersInSet( NSCharacterSet.whitespaceAndNewlineCharacterSet() )
    }

    func readPost() -> String? {
        if let postLength = contentLength() {
            var buffer = [Int8](count: postLength+1, repeatedValue: 0)
            if read( &buffer, count: postLength ) == postLength {
                return String( UTF8String: buffer )?
                    .stringByTrimmingCharactersInSet( NSCharacterSet.whitespaceAndNewlineCharacterSet() )
            }
        }
        return nil
    }

    public func contentLength() -> Int? {
        return  (requestHeaders["Content-Length"] ?? requestHeaders["Content-length"])?.toInt()
    }

    public func addHeader( name: String, value: String ) {
        responseHeaders += "\(name): \(value)\r\n"
    }

    public func setCookie( name: String, value: String, domain: String? = nil, path: String? = nil, expires: Int? = nil ) {
        if !sentHeaders {
            var value = "\(name)=\(value.stringByAddingPercentEscapesUsingEncoding( NSUTF8StringEncoding )!)"

            if domain != nil {
                value += "; Domain="+domain!
            }
            if path != nil {
                value += "; Path="+path!
            }
            if expires != nil {
                let webDateFormatter = NSDateFormatter()
                webDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                addHeader( "Date", value: webDateFormatter.stringFromDate( NSDate() ) )
                let cookieDateFormatter = NSDateFormatter()
                cookieDateFormatter.dateFormat = "EEE, dd-MMM-yyyy HH:mm:ss zzz"
                let expires = NSDate().dateByAddingTimeInterval( NSTimeInterval(expires!) )
                value += "; Expires=" + cookieDateFormatter.stringFromDate( expires )
            }

            addHeader( "Set-Cookie", value: value )
        }
        else {
            dynamoLog( "Cookies must be set before the first HTML is sent" )
        }
    }

    private func writeHeaders() {
        if responseHeaders == "" {
            addHeader( "Content-Type", value: dynamoHtmlMimeType )
        }

        let statusText = dynamoStatusText[status] ?? "Unknown Status"
        rawPrint( "\(httpVersion) \(status) \(statusText)\r\n\(responseHeaders)\r\n" )
        sentHeaders = true
    }

    public func rawPrint( output: String ) {
        if let bytes = output.cStringUsingEncoding( NSUTF8StringEncoding ) {
            write( bytes, count: Int(strlen(bytes)) )
        }
        else {
            dynamoLog( "Could not encode: \(output)" )
        }
    }

    public func print( output: String ) {
        if !sentHeaders {
            writeHeaders()
        }
        rawPrint( output )
    }

    public func write( data: NSData ) {
        if !sentHeaders {
            writeHeaders()
        }
        write( data.bytes, count: data.length )
    }

    public func flush() {
        if writeFILE != nil {
            fflush( writeFILE )
        }
    }

    public func remoteAddr() -> String {
        var addr = sockaddr()
        var addrLen = socklen_t(sizeof(addr.dynamicType))

        if getpeername( clientSocket, &addr, &addrLen ) == 0 {
            if addr.sa_family == sa_family_t(AF_INET) {
                return String( UTF8String: inet_ntoa( sockaddr_cast_in(&addr).memory.sin_addr ) )!
            }
        }

        return "UNKNOWN"
    }

    class func relay( label: String, from: DynamoHTTPConnection, to: DynamoHTTPConnection, _ logger: ((String) -> ())? ) {
        dynamoRelayThreads++
        dispatch_async( dynamoQueue, {
            var buffer = [Int8](count: 32*1024, repeatedValue: 0)
            var writeError = false

            while !writeError {
                let bytesRead = recv( from.clientSocket, &buffer, buffer.count, 0 )
                if logger != nil {
                    logger!( "\(label) \(bytesRead) bytes (\(dynamoRelayThreads)/\(to.clientSocket))" )
                }
                if bytesRead <= 0 {
                    break
                }
                else {
                    var ptr = 0
                    while ptr < bytesRead {
                        let remaining = UnsafePointer<UInt8>(buffer)+ptr
                        let bytesWritten = send( to.clientSocket, remaining, bytesRead-ptr, 0 )
                        if bytesWritten <= 0 {
                            dynamoLog( "Short write on relay" )
                            writeError = true
                            break
                        }
                        ptr += bytesWritten
                    }
                }
            }

            dynamoRelayThreads--
            close( from.clientSocket )
            close( to.clientSocket )
        } )
    }

    deinit {
        fclose( writeFILE )
        fclose( readFILE )
        close( clientSocket )
    }

}

// MARK: Cached gethostbyname()

private var hostAddressCache = [String:UnsafeMutablePointer<sockaddr>]()

/**
Caching version of gethostbyname returning a sockaddr to use in a connect() call
*/
public func addressForHost( hostname: String, port: UInt16 ) -> sockaddr? {
    var addr: UnsafeMutablePointer<hostent> = nil
    var sockaddrTmp = hostAddressCache[hostname]?.memory
    if sockaddrTmp == nil {
        addr = gethostbyname( hostname.cStringUsingEncoding( NSUTF8StringEncoding )! )
        if addr == nil {
            dynamoLog( "Could not resolve \(hostname) - "+String( UTF8String: hstrerror(h_errno) )! )
            return nil
        }
    }

    if sockaddrTmp == nil {
        let addrList = addr.memory.h_addr_list
        let sockaddrPtr = UnsafeMutablePointer<sockaddr>(malloc(sizeof(sockaddr.self)))
        switch addr.memory.h_addrtype {
        case AF_INET:
            let addr0 = UnsafePointer<in_addr>(addrList.memory)
            var ip4addr = sockaddr_in(sin_len: UInt8(sizeof(sockaddr_in)),
                sin_family: sa_family_t(addr.memory.h_addrtype),
                sin_port: htons( port ), sin_addr: addr0.memory,
                sin_zero: (Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0)))
            sockaddrPtr.memory = sockaddr_cast(&ip4addr).memory
        case AF_INET6: // TODO... completely untested
            let addr0 = UnsafePointer<in6_addr>(addrList.memory)
            var ip6addr = sockaddr_in6(sin6_len: UInt8(sizeof(sockaddr_in6)),
                sin6_family: sa_family_t(addr.memory.h_addrtype),
                sin6_port: htons( port ), sin6_flowinfo: 0, sin6_addr: addr0.memory,
                sin6_scope_id: 0)
            sockaddrPtr.memory = sockaddr_cast6(&ip6addr).memory
        default:
            dynamoLog( "Unknown address family: \(addr.memory.h_addrtype)" )
            return nil
        }
        hostAddressCache[hostname] = sockaddrPtr
        sockaddrTmp = sockaddrPtr.memory
    }
    else {
        sockaddr_cast_in( &(sockaddrTmp!) ).memory.sin_port = htons( port )
    }
    
    return sockaddrTmp
}

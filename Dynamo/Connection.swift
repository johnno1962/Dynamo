//
//  Connection.swift
//  Dynamo
//
//  Created by John Holdsworth on 22/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Connection.swift#33 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: HTTP request parser

let dummyBase = NSURL( string: "http://nohost" )!
private var dynamoRelayThreads = 0

/**
    HTTP return status mapping
*/
public var dynamoStatusText = [
    200: "OK",
    304: "Redirect",
    400: "Invalid request",
    404: "File not found",
    500: "Server error"
]

var webDateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    return formatter
}()

/**
    Class representing a connection to a client web browser. One is created each time a browser
    connects to read the standard HTTP headers ready to present to each of the swiftlets of the server.
*/

@objc public class DynamoHTTPConnection : NSObject {

    let clientSocket: Int32

    /** reeust method received frmo browser */
    public var method = "GET"

    /** path to document requests */
    public var path = "/"

    /** HTTP version reported by browser */
    public var version = "HTTP/1.1"

    /** request epressed as NSURL */
    public var url = dummyBase

    /** status to be returned in response */
    public var status = 200

    /** HTTP request headers received */
    public var requestHeaders = [String:String]()

    private var responseHeaders = ""
    private var sentResponseHeaders = false

    /** "defalte" respose when possible - less bandwidth but slow */
    public var compressResponse = false

    /** whether Content-Length has bee supplied */
    var knowsResponseLength = false

    // data for DynamoSelector
    let readBuffer = NSMutableData()
    var readCounter = 0
    var readEOF = false
    var label = ""

    /** initialise connection to browser with socket */
    public init?( clientSocket: Int32 ) {
        self.clientSocket = clientSocket
        super.init()
    }

    /** initialise connection to reote host/port specified in URL */
    public convenience init?( url: NSURL ) {
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
                else if setupSocket( remoteSocket ) {
                    self.init( clientSocket: remoteSocket )
                    return
                }
            }
        }

        self.init( clientSocket: -1 )
        return nil
    }

    /** reports to IP address of remote user (if not proxied */
    public var remoteAddr: String {
        var addr = sockaddr()
        var addrLen = socklen_t(sizeof(addr.dynamicType))

        if getpeername( clientSocket, &addr, &addrLen ) == 0 {
            if addr.sa_family == sa_family_t(AF_INET) {
                return String( UTF8String: inet_ntoa( sockaddr_in_cast(&addr).memory.sin_addr ) )!
            }
        }

        return "address unknown"
    }

    /** read from browser/remote connection */
    func _read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        return recv( clientSocket, buffer, count, 0 )
    }

    /** write to browser/remote connection */
    func _write( buffer: UnsafePointer<Void>, count: Int ) -> Int {
        return send( clientSocket, buffer, count, 0 )
    }

    /** read the requested number of bytes */
    public func read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        var pos = 0, buffered = min( readBuffer.length, count )
        if buffered != 0 {
            memcpy( buffer, readBuffer.bytes, buffered )
            readBuffer.replaceBytesInRange( NSMakeRange( 0, buffered ), withBytes: nil, length: 0 )
            pos += count
        }
        while ( pos < count ) {
            let bytesRead = _read( buffer+pos, count: count-pos )
            if bytesRead <= 0 {
                break
            }
            pos += bytesRead
        }
        return pos
    }

    /** write the requested number of bytes */
    public func write( buffer: UnsafePointer<Void>, count: Int ) -> Int {
        var pos = 0
        while ( pos < count ) {
            let bytesWritten = _write( buffer+pos, count: count-pos )
            if bytesWritten <= 0 {
                break
            }
            pos += bytesWritten
        }
        return pos
    }

    /** add a HTTP header value to the response */
    public func addHeader( name: String, value: String ) {
        responseHeaders += "\(name): \(value)\r\n"
    }

    /** getter(request)/setter(response) for content mime type */
    public var contentType: String {
        get {
            return requestHeaders["Content-Type"] ?? requestHeaders["Content-type"] ?? "text/plain"
        }
        set {
            addHeader( "Content-Type", value: newValue )
        }
    }

    /** getter(rquest)/setter(response) for content length */
    public var contentLength: Int? {
        get {
            return (requestHeaders["Content-Length"] ?? requestHeaders["Content-length"])?.toInt()
        }
        set {
            addHeader( "Content-Length", value: String( newValue ?? 0 ) )
            knowsResponseLength = true
        }
    }

    /** read/parse standard HTTP headers from browser */
    func readHeaders() -> Bool {
        if let request = readLine() {

            let components = request.componentsSeparatedByString( " " )
            if components.count == 3 {

                method = components[0]
                path = components[1]
                version = components[2]

                url = NSURL( string: path, relativeToURL: dummyBase ) ?? dummyBase
                requestHeaders = [String: String]()
                responseHeaders = ""
                sentResponseHeaders = false
                knowsResponseLength = false
                compressResponse = false
                status = 200

                while let line = readLine() {
                    if let divider = line.rangeOfString( ": " )?.startIndex {
                        requestHeaders[line.substringToIndex( divider )] = line.substringFromIndex( advance( divider, 2 ) )
                    }
                    else {
                        return true
                    }
                }
            }
        }

        return false
    }

    var buffer = [Int8](count: 8192, repeatedValue: 0), eolChar = Int32(10)

    func readLine() -> String? {
        while true {
            let eol = memchr( readBuffer.bytes, eolChar, readBuffer.length )
            if eol != nil {
                UnsafeMutablePointer<Int8>(eol).memory = 0
                let line = String( UTF8String: UnsafePointer<Int8>(readBuffer.bytes) )?
                    .stringByTrimmingCharactersInSet( NSCharacterSet.whitespaceAndNewlineCharacterSet() )
                readBuffer.replaceBytesInRange( NSMakeRange(0,eol+1-readBuffer.bytes), withBytes:nil, length:0 )
                return line
            }

            let bytesRead = _read( UnsafeMutablePointer<Void>(buffer), count: buffer.count )
            if bytesRead <= 0 {
                break ///
            }
            readBuffer.appendBytes( buffer, length: bytesRead )
        }
        return nil
    }

    /** POST data as String */
    public func postString() -> String? {
        if let postLength = contentLength {
            var buffer = [Int8](count: postLength+1, repeatedValue: 0)
            if read( &buffer, count: postLength ) == postLength {
                return String( UTF8String: buffer )
            }
        }
        return nil
    }

    /** POST data as NSData */
    public func postData() -> NSData? {
        if let postLength = contentLength,
                data = NSMutableData( length: postLength ) {
            if read( UnsafeMutablePointer<Void>(data.bytes), count: postLength ) == postLength {
                return data
            }
        }
        return nil
    }

    /** POST data as JSON object */
    public func postJSON() -> AnyObject? {
        if let data = postData() {
            var error: NSError?
            if let json: AnyObject = NSJSONSerialization.JSONObjectWithData( data, options: nil, error: &error ) {
                return json
            }
            else {
                dynamoLog( "JSON parse error:: \(error)" )
            }
        }
        return nil
    }

    /** have broser set cookkie for this session/domain/path */
    public func setCookie( name: String, value: String, domain: String? = nil, path: String? = nil, expires: Int? = nil ) {
        if !sentResponseHeaders {
            var value = "\(name)=\(value.stringByAddingPercentEscapesUsingEncoding( NSUTF8StringEncoding )!)"

            if domain != nil {
                value += "; Domain="+domain!
            }
            if path != nil {
                value += "; Path="+path!
            }
            if expires != nil {
                let cookieDateFormatter = NSDateFormatter()
                cookieDateFormatter.dateFormat = "EEE, dd-MMM-yyyy HH:mm:ss zzz"
                let expires = NSDate().dateByAddingTimeInterval( NSTimeInterval(expires!) )
                value += "; Expires=" + cookieDateFormatter.stringFromDate( expires )
            }

            addHeader( "Set-Cookie", value: value )
        }
        else {
            dynamoLog( "Cookies must be set before the first HTML content is sent" )
        }
    }

    private func sendResponseHeaders() {
        if responseHeaders == "" {
            contentType = dynamoHtmlMimeType
        }

        addHeader( "Date", value: webDateFormatter.stringFromDate( NSDate() ) )
        addHeader( "Server", value: "Dynamo" )

        let statusText = dynamoStatusText[status] ?? "Unknown Status"
        rawPrint( "\(version) \(status) \(statusText)\r\n\(responseHeaders)\r\n" )
        sentResponseHeaders = true
    }

    /** print a sring directly to browser */
    public func rawPrint( output: String ) {
        if let bytes = output.cStringUsingEncoding( NSUTF8StringEncoding ) {
            write( bytes, count: Int(strlen(bytes)) )
        }
        else {
            dynamoLog( "Could not encode: \(output)" )
        }
    }

    /** print a string, sending HTTP headers if not already sent */
    public func print( output: String ) {
        if !sentResponseHeaders {
            sendResponseHeaders()
        }
        rawPrint( output )
    }

    /** set response as a whole from a String */
    public func response( output: String ) {
        if var bytes = output.cStringUsingEncoding( NSUTF8StringEncoding ) {
            responseData( NSData( bytesNoCopy: &bytes, length: Int(strlen(bytes)), freeWhenDone: false ) )
        }
        else {
            dynamoLog( "Could not encode: \(output)" )
        }
    }

    /** set response as a whole from JSON object */
    public func responseJSON( object: AnyObject ) {
        var error: NSError?
        if NSJSONSerialization.isValidJSONObject( object ) {
            if let json = NSJSONSerialization.dataWithJSONObject( object,
                    options: NSJSONWritingOptions.PrettyPrinted, error: &error ) {
                contentType = dynamoMimeTypeMapping["json"] ?? "application/json"
                responseData( json )
                return
            }
        }
        dynamoLog( "Could not encode: \(object) \(error)" )
    }

    /** set response as a whole from NSData */
    public func responseData( data: NSData ) {
        var dout = data
#if os(OSX)
        if compressResponse && requestHeaders["Accept-Encoding"] == "gzip, deflate" {
            if let deflated = dout.deflate() {
                dout = deflated
                addHeader( "Content-Encoding", value: "deflate" )
            }
        }
#endif
        contentLength = dout.length
        sendResponseHeaders()
        write( dout.bytes, count: dout.length )
    }

    /** flush any buffered print() output to browser */
    public func flush() {
    }

    var hasBytesAvailable: Bool {
        return false
    }

    func receive( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int? {
        return recv( clientSocket, buffer, count, 0 )
    }

    func forward( buffer: UnsafePointer<Void>, count: Int ) -> Int? {
        return send( clientSocket, buffer, count, 0 )
    }

    deinit {
        close( clientSocket )
    }

}

// MARK: Cached gethostbyname()

private var hostAddressCache = [String:UnsafeMutablePointer<sockaddr>]()

/**
    Caching version of gethostbyname() returning a struct sockaddr for use in a connect() call
*/
public func addressForHost( hostname: String, port: UInt16 ) -> sockaddr? {
    var addr: UnsafeMutablePointer<hostent> = nil
    var sockaddrTmp = hostAddressCache[hostname]?.memory
    if sockaddrTmp == nil {
        if let hostString = hostname.cStringUsingEncoding( NSUTF8StringEncoding ) {
            addr = gethostbyname( hostString )
        }
        if addr == nil {
            dynamoLog( "Could not resolve \(hostname) - "+String( UTF8String: hstrerror(h_errno) )! )
            return nil
        }
    }

    if sockaddrTmp == nil {
        let sockaddrPtr = UnsafeMutablePointer<sockaddr>(malloc(sizeof(sockaddr.self)))
        switch addr.memory.h_addrtype {

        case AF_INET:
            let addr0 = UnsafePointer<in_addr>(addr.memory.h_addr_list.memory)
            var ip4addr = sockaddr_in(sin_len: UInt8(sizeof(sockaddr_in)),
                sin_family: sa_family_t(addr.memory.h_addrtype),
                sin_port: htons( port ), sin_addr: addr0.memory,
                sin_zero: (Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0)))
            sockaddrPtr.memory = sockaddr_cast(&ip4addr).memory

        case AF_INET6: // TODO... completely untested
            let addr0 = UnsafePointer<in6_addr>(addr.memory.h_addr_list.memory)
            var ip6addr = sockaddr_in6(sin6_len: UInt8(sizeof(sockaddr_in6)),
                sin6_family: sa_family_t(addr.memory.h_addrtype),
                sin6_port: htons( port ), sin6_flowinfo: 0, sin6_addr: addr0.memory,
                sin6_scope_id: 0)
            sockaddrPtr.memory = sockaddr_cast(&ip6addr).memory

        default:
            dynamoLog( "Unknown address family: \(addr.memory.h_addrtype)" )
            return nil
        }

        hostAddressCache[hostname] = sockaddrPtr
        sockaddrTmp = sockaddrPtr.memory
    }
    else {
        sockaddr_in_cast( &(sockaddrTmp!) ).memory.sin_port = htons( port )
    }
    
    return sockaddrTmp
}

extension NSData {

    /**
        Swizzled/overridden by NSData+deflate.m
     */
    func deflate() -> NSData? {
        return nil
    }

}

//
//  Connection.swift
//  Dynamo
//
//  Created by John Holdsworth on 22/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Connection.swift#13 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

#if os(Linux)
import Glibc
#endif

let dummyBase = NSURL( string: "http://nohost" )!

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

public extension String {
    public func toInt() -> Int? {
        return Int(self)
    }
}

/**
    Class representing a request from a client web browser. This is the request part
    of DynamoHTTPConnection though in practice they are the same instance.
*/

public class DynamoHTTPRequest: _NSObject_ {

    let clientSocket: Int32

    /** reeust method received frmo browser */
    public var method = "GET"

    /** path to document requests */
    public var path = "/"

    /** HTTP version from browser */
    public var version = "HTTP/1.1"

    /** request parsed as NSURL */
    public var url = dummyBase

    /** HTTP request headers received */
    public var requestHeaders = [String:String]()

    /** status to be returned in response */
    public var status = 200

    // response ivars need to be here...
    private var responseHeaders = ""
    private var sentResponseHeaders = false

    /** "deflate" respose when possible - less bandwidth but slow */
    public var compressResponse = false

    /** whether Content-Length has been supplied */
    var knowsResponseLength = false

    // read buffering
    let readBuffer = NSMutableData()
    var readTotal = 0
    var label = ""

    /** initialise connection to browser with socket */
    public init?( clientSocket: Int32 ) {

        self.clientSocket = clientSocket

        super.init()

        if clientSocket >= 0 {
            #if !os(Linux)
            var yes: u_int = 1, yeslen = socklen_t(sizeof(yes.dynamicType))
            if setsockopt( clientSocket, SOL_SOCKET, SO_NOSIGPIPE, &yes, yeslen ) < 0 {
                dynamoStrerror( "Could not set SO_NOSIGPIPE" )
                return nil
            }
            #endif
        }
    }

    /** initialise connection to reote host/port specified in URL */
    public convenience init?( url: NSURL ) {
        if let host = url.host {
            let port = UInt16(url.port?.intValue ?? 80)

            if let addr = addressForHost( host, port: port ) {
                var addr = addr
                #if os(Linux)
                let addrLen = socklen_t(sizeof(sockaddr))
                #else
                let addrLen = socklen_t(addr.sa_len)
                #endif

                let remoteSocket = socket( Int32(addr.sa_family), sockType, 0 )
                if remoteSocket < 0 {
                    dynamoStrerror( "Could not obtain remote socket" )
                }
                else if connect( remoteSocket, &addr, addrLen ) < 0 {
                    dynamoStrerror( "Could not connect to: \(host):\(port)" )
                }
                else {
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
                return String.fromCString( inet_ntoa( sockaddr_in_cast(&addr).memory.sin_addr ) )!
            }
        }

        return "address unknown"
    }

    /** raw read from browser/remote connection */
    func _read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        return recv( clientSocket, buffer, count, 0 )
    }

    /** read the requested number of bytes */
    public func read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        var pos = min( readBuffer.length, count )
        if pos != 0 {
            memcpy( buffer, readBuffer.bytes, pos )
            readBuffer.replaceBytesInRange( NSMakeRange( 0, pos ), withBytes: nil, length: 0 )
        }
        while pos < count {
            let bytesRead = _read( buffer+pos, count: count-pos )
            if bytesRead <= 0 {
                break
            }
            pos += bytesRead
        }
        return pos
    }

    var buffer = [Int8](count: 8192, repeatedValue: 0), newlineChar = Int32(10)

    func readLine() -> String? {
        while true {
            let endOfLine = UnsafeMutablePointer<Int8>( memchr( readBuffer.bytes, newlineChar, readBuffer.length ) )
            if endOfLine != nil {
                endOfLine[0] = 0
                #if os(Linux)
                if endOfLine[-1] == 13 {
                    endOfLine[-1] = 0
                }
                #endif

                let line = String.fromCString( UnsafePointer<Int8>(readBuffer.bytes) )?
                    .stringByTrimmingCharactersInSet( NSCharacterSet.whitespaceAndNewlineCharacterSet() )
                readBuffer.replaceBytesInRange( NSMakeRange( 0, UnsafePointer<Void>(endOfLine)+1-readBuffer.bytes ), withBytes:nil, length:0 )
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
                        requestHeaders[line.substringToIndex( divider )] = line.substringFromIndex( divider.advancedBy( 2 ) )
                    }
                    else {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /** add a HTTP header value to the response */
    public func addResponseHeader( name: String, value: String ) {
        responseHeaders += "\(name): \(value)\r\n"
    }

    /** getter(request)/setter(response) for content mime type */
    public var contentType: String {
        get {
            return requestHeaders["Content-Type"] ?? requestHeaders["Content-type"] ?? "text/plain"
        }
        set {
            addResponseHeader( "Content-Type", value: newValue )
        }
    }

    /** getter(rquest)/setter(response) for content length */
    public var contentLength: Int? {
        get {
            return (requestHeaders["Content-Length"] ?? requestHeaders["Content-length"])?.toInt()
        }
        set {
            addResponseHeader( "Content-Length", value: String( newValue ?? 0 ) )
            knowsResponseLength = true
        }
    }

    /** POST data as String */
    public func postString() -> String? {
        if let postLength = contentLength {
            var bytes = [Int8]( count: postLength + 1, repeatedValue: 0 )
            if read( &bytes, count: postLength ) != postLength {
                dynamoLog( "Could not read \(contentLength) bytes post data from client " )
            }
            return String.fromCString( bytes )
        }
        return nil
    }

    /** POST data as NSData */
    public func postData() -> NSData? {
        if let postLength = contentLength, data = NSMutableData( length: postLength )
                where read( UnsafeMutablePointer<Void>(data.bytes), count: postLength ) == postLength {
            return data
        }
        return nil
    }

#if !os(Linux)
    /** POST data as JSON object */
    public func postJSON() -> AnyObject? {
        if let data = postData() {
            do {
                return try NSJSONSerialization.JSONObjectWithData( data, options: [] )
            } catch let error as NSError {
                dynamoLog( "JSON parse error:: \(error)" )
            }
        }
        return nil
    }
#endif

}

/**
    Class representing a connection to a client web browser. One is created each time a browser
    connects to read the standard HTTP headers ready to present to each of the swiftlets of the server.
*/

public class DynamoHTTPConnection: DynamoHTTPRequest {

    /** raw write to browser/remote connection */
    func _write( buffer: UnsafePointer<Void>, count: Int ) -> Int {
        return send( clientSocket, buffer, count, 0 )
    }

    /** write the requested number of bytes */
    public func write( buffer: UnsafePointer<Void>, count: Int ) -> Int {
        var pos = 0
        while pos < count {
            let bytesWritten = _write( buffer+pos, count: count-pos )
            if bytesWritten <= 0 {
                break
            }
            pos += bytesWritten
        }
        return pos
    }

    /** flush any buffered print() output to browser */
    public func flush() {
        // writes not buffered currently
    }
    
    /** have browser set cookie for this session/domain/path */
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

            addResponseHeader( "Set-Cookie", value: value )
        }
        else {
            dynamoLog( "Cookies must be set before the first HTML content is sent" )
        }
    }

    private func sendResponseHeaders() {
        if responseHeaders == "" {
            contentType = dynamoHtmlMimeType
        }

        addResponseHeader( "Date", value: webDateFormatter.stringFromDate( NSDate() ) )
        addResponseHeader( "Server", value: "Dynamo" )

        let statusText = dynamoStatusText[status] ?? "Unknown Status"
        rawPrint( "\(version) \(status) \(statusText)\r\n\(responseHeaders)\r\n" )
        sentResponseHeaders = true
    }

    /** print a sring directly to browser */
    public func rawPrint( output: String ) {
        output.withCString { (bytes) in
            write( bytes, count: Int(strlen(bytes)) )
        }
    }

    /** print a string, sending HTTP headers if not already sent */
    public func print( output: String ) {
        if !sentResponseHeaders {
            sendResponseHeaders()
        }
        rawPrint( output )
    }

    /** enum base response */
    public func sendResponse( resp: DynamoResponse ) -> DynamoProcessed {
        status = 200

        switch resp {
        case .OK( let html ):
            response( html )
        case .JSON( let json ):
            responseJSON( json )
        case .Data( let data ):
            responseData( data )
        case .Status( let theStatus, let text ):
            status = theStatus
            response( text )
        }

        return .ProcessedAndReusable
    }

    /** set response as a whole from a String */
    public func response( output: String ) {
        output.withCString { (bytes) in
            #if os(Linux)
                responseData( NSData( bytes: UnsafeMutablePointer<Void>(bytes),
                    length: Int(strlen( bytes )) ) )
            #else
                responseData( NSData( bytesNoCopy: UnsafeMutablePointer<Void>(bytes),
                    length: Int(strlen( bytes )), freeWhenDone: false ) )
            #endif
        }
    }

    /** set response as a whole from JSON object */
    public func responseJSON( object: AnyObject ) {
        if NSJSONSerialization.isValidJSONObject( object ) {
            do {
                let json = try NSJSONSerialization.dataWithJSONObject( object,
                        options: NSJSONWritingOptions.PrettyPrinted )
                contentType = dynamoMimeTypeMapping["json"] ?? "application/json"
                responseData( json )
                return
            } catch let error as NSError {
                dynamoLog( "Could not encode: \(object) \(error)" )
            }
        }
    }

    /** set response as a whole from NSData */
    public func responseData( data: NSData ) {
        var dout = data
#if os(OSX)
        if compressResponse && requestHeaders["Accept-Encoding"] == "gzip, deflate" {
            if let deflated = dout.deflate() {
                dout = deflated
                addResponseHeader( "Content-Encoding", value: "deflate" )
            }
        }
#endif
        contentLength = dout.length
        sendResponseHeaders()
        if write( dout.bytes, count: dout.length ) != dout.length {
            dynamoLog( "Could not write \(dout.length) bytes to client " )
        }
    }

    // for DynamoSelector used by proxies
    var hasBytesAvailable: Bool {
        return false
    }

    func receive( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int? {
        return _read( buffer, count: count )
    }

    func forward( buffer: UnsafePointer<Void>, count: Int ) -> Int? {
        return _write( buffer, count: count )
    }

    deinit {
        flush()
        close( clientSocket )
    }

}

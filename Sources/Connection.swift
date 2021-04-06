//
//  Connection.swift
//  Dynamo
//
//  Created by John Holdsworth on 22/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Connection.swift#19 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

#if os(Linux)
import Glibc
#endif

let dummyBase = URL( string: "http://nohost" )!

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

var webDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    return formatter
}()

public extension String {
    func toInt() -> Int? {
        return Int(self)
    }
}

/**
    Class representing a request from a client web browser. This is the request part
    of DynamoHTTPConnection though in practice they are the same instance.
*/

open class DynamoHTTPRequest: _NSObject_ {

    let clientSocket: Int32
    let readFP: UnsafeMutablePointer<FILE>
    let writeFP: UnsafeMutablePointer<FILE>

    /** reeust method received frmo browser */
    open var method = "GET"

    /** path to document requests */
    open var path = "/"

    /** HTTP version from browser */
    open var version = "HTTP/1.1"

    /** request parsed as NSURL */
    open var url = dummyBase

    /** HTTP request headers received */
    open var requestHeaders = [String:String]()

    /** status to be returned in response */
    open var status = 200

    // response ivars need to be here...
    fileprivate var responseHeaders = ""
    fileprivate var sentResponseHeaders = false

    /** "deflate" respose when possible - less bandwidth but slow */
    open var compressResponse = false

    /** whether Content-Length has been supplied */
    var knowsResponseLength = false

    // read buffering
    var readBuffer = Data()
    var readTotal = 0
    var label = ""

    public init( clientSocket: Int32,
                  readFP: UnsafeMutablePointer<FILE>,
                  writeFP: UnsafeMutablePointer<FILE>) {
        self.clientSocket = clientSocket
        self.readFP  = readFP
        self.writeFP = writeFP
        super.init()
    }

    /** initialise connection to browser with socket */
    @objc public convenience init?( clientSocket: Int32 ) {
        guard let readFP = fdopen(clientSocket, "r"),
            let writeFP = fdopen(clientSocket, "w") else {
                return nil
        }

        self.init(clientSocket: clientSocket,
                  readFP: readFP, writeFP: writeFP)

        if clientSocket >= 0 {
            #if !os(Linux)
            var yes: u_int = 1, yeslen = socklen_t(MemoryLayout<u_int>.size)
            if setsockopt( clientSocket, SOL_SOCKET, SO_NOSIGPIPE, &yes, yeslen ) < 0 {
                dynamoStrerror( "Could not set SO_NOSIGPIPE" )
                return nil
            }
            #endif
        }
    }

    /** initialise connection to reote host/port specified in URL */
    public convenience init?( url: URL ) {
        if let host = url.host {
            let port = UInt16(url.port ?? 80)

            if let addr = addressForHost( host, port: port ) {
                var addr = addr
                #if os(Linux)
                let addrLen = socklen_t(MemoryLayout<sockaddr>.size)
                #else
                let addrLen = socklen_t(addr.sa_len)
                #endif

                let remoteSocket = socket( Int32(addr.sa_family), sockType, 0 )
                if remoteSocket < 0 {
                    dynamoStrerror( "Could not obtain remote socket" )
                }
                else if connect( remoteSocket, &addr, addrLen ) < 0 {
                    dynamoStrerror( "Could not connect to: \(host):\(port) (\(String( cString: inet_ntoa(sockaddr_in_cast(&addr).pointee.sin_addr))))" )
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
    open var remoteAddr: String {
        var addr = sockaddr()
        var addrLen = socklen_t(MemoryLayout<sockaddr>.size)

        if getpeername( clientSocket, &addr, &addrLen ) == 0 {
            if addr.sa_family == sa_family_t(AF_INET) {
                return String( cString: inet_ntoa( sockaddr_in_cast(&addr).pointee.sin_addr ) )
            }
        }

        return "address unknown"
    }

    /** raw read from browser/remote connection */
    func _read( buffer: UnsafeMutableRawPointer, count: Int ) -> Int {
        return recv( clientSocket, buffer, count, 0 )
    }

    /** read the requested number of bytes */
    open func read( buffer: UnsafeMutableRawPointer, count: Int ) -> Int {
        return fread(buffer, 1, count, readFP)
    }

    func readLine() -> String? {
        var buffer = [Int8](repeating: 0, count: 8192)
        if fgets(&buffer, Int32(buffer.count), readFP) != nil {
            let len = strlen(buffer)
            buffer[len-1] = 0
            if buffer[len-2] == UInt8(ascii: "\r") {
                buffer[len-2] = 0
            }
            return String(cString: buffer)
        }
        return nil
    }
    
    /** read/parse standard HTTP headers from browser */
    func readHeaders() -> Bool {

        if let request = readLine() {

            let components = request.components( separatedBy: " " )
            if components.count == 3 {

                method = components[0]
                path = components[1]
                version = components[2]

                url = URL( string: path, relativeTo: dummyBase ) ?? dummyBase
                requestHeaders = [String: String]()
                responseHeaders = ""
                sentResponseHeaders = false
                knowsResponseLength = false
                compressResponse = false
                status = 200

                while let line = readLine() {
                    if let divider = line.range( of: ": " )?.lowerBound {
                        requestHeaders[line.substring( to: divider )] = line.substring( from: line.index(divider, offsetBy: 2) )
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
    open func addResponseHeader( name: String, value: String ) {
        responseHeaders += "\(name): \(value)\r\n"
    }

    /** getter(request)/setter(response) for content mime type */
    open var contentType: String {
        get {
            return requestHeaders["Content-Type"] ?? requestHeaders["Content-type"] ?? "text/plain"
        }
        set {
            addResponseHeader( name: "Content-Type", value: newValue )
        }
    }

    /** getter(rquest)/setter(response) for content length */
    open var contentLength: Int? {
        get {
            return (requestHeaders["Content-Length"] ?? requestHeaders["Content-length"])?.toInt()
        }
        set {
            addResponseHeader( name: "Content-Length", value: String( newValue ?? 0 ) )
            knowsResponseLength = true
        }
    }

    /** POST data as String */
    open func postString() -> String? {
        if let postLength = contentLength {
            var bytes = [Int8]( repeating: 0, count: postLength + 1 )
            if read( buffer: &bytes, count: postLength ) != postLength {
                dynamoLog( "Could not read \(String(describing: contentLength)) bytes post data from client " )
            }
            return String( cString: bytes )
        }
        return nil
    }

    /** POST data as NSData */
    open func postData() -> Data? {
        if let postLength = contentLength {
            let data = Data( capacity: postLength )
            return data.withUnsafeBytes({
                (bytes: UnsafePointer<Int8>) -> Data? in
                if read( buffer: UnsafeMutableRawPointer(mutating: bytes), count: postLength ) == postLength {
                    return data
                }
                return nil
            })
        }
        return nil
    }

#if !os(Linux)
    /** POST data as JSON object */
    open func postJSON() -> AnyObject? {
        if let data = postData() {
            do {
                return try JSONSerialization.jsonObject( with: data, options: [] ) as AnyObject
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

open class DynamoHTTPConnection: DynamoHTTPRequest {

    /** raw write to browser/remote connection */
    func _write( buffer: UnsafeRawPointer, count: Int ) -> Int {
        return send( clientSocket, buffer, count, 0 )
    }

    /** write the requested number of bytes */
    @discardableResult
    open func write( buffer: UnsafeRawPointer, count: Int ) -> Int {
        return fwrite(buffer, 1, count, writeFP)
    }

    /** flush any buffered print() output to browser */
    open func flush() {
        // writes not buffered currently
        fflush(writeFP)
    }
    
    /** have browser set cookie for this session/domain/path */
    open func setCookie( name: String, value: String, domain: String? = nil, path: String? = nil, expires: Int? = nil ) {

        if !sentResponseHeaders {
            var value = "\(name)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"

            if domain != nil {
                value += "; Domain="+domain!
            }
            if path != nil {
                value += "; Path="+path!
            }
            if expires != nil {
                let cookieDateFormatter = DateFormatter()
                cookieDateFormatter.dateFormat = "EEE, dd-MMM-yyyy HH:mm:ss zzz"
                let expires = Date().addingTimeInterval( TimeInterval(expires!) )
                value += "; Expires=" + cookieDateFormatter.string( from: expires )
            }

            addResponseHeader( name: "Set-Cookie", value: value )
        }
        else {
            dynamoLog( "Cookies must be set before the first HTML content is sent" )
        }
    }

    fileprivate func sendResponseHeaders() {
        if responseHeaders == "" {
            contentType = dynamoHtmlMimeType
        }

        addResponseHeader( name: "Date", value: webDateFormatter.string( from: Date() ) )
        addResponseHeader( name: "Server", value: "Dynamo" )

        let statusText = dynamoStatusText[status] ?? "Unknown Status"
        rawPrint( "\(version) \(status) \(statusText)\r\n\(responseHeaders)\r\n" )
        sentResponseHeaders = true
    }

    /** print a sring directly to browser */
    open func rawPrint( _ output: String ) {
        output.withCString { (bytes) in
            _ = write( buffer: bytes, count: Int(strlen(bytes)) )
        }
    }

    /** print a string, sending HTTP headers if not already sent */
    open func print( _ output: String ) {
        if !sentResponseHeaders {
            sendResponseHeaders()
        }
        rawPrint( output )
    }

    /** enum base response */
    @discardableResult
    open func sendResponse( resp: DynamoResponse ) -> DynamoProcessed {
        status = 200

        switch resp {
        case .ok( let html ):
            response( text: html )
        case .json( let json ):
            response( json: json )
        case .data( let data ):
            response( data: data )
        case .status( let theStatus, let text ):
            status = theStatus
            response( text: text )
        }

        return .processedAndReusable
    }

    /** set response as a whole from a String */
    open func response( text: String ) {
        text.withCString { (bytes) in
            response( data: Data( bytesNoCopy: UnsafeMutablePointer(mutating: bytes),
                                  count: Int(strlen( bytes )), deallocator: .none ) )
        }
    }

    /** set response as a whole from JSON object */
    open func response( json: AnyObject ) {
        if JSONSerialization.isValidJSONObject( json ) {
            do {
                let json = try JSONSerialization.data( withJSONObject: json,
                        options: JSONSerialization.WritingOptions.prettyPrinted )
                contentType = dynamoMimeTypeMapping["json"] ?? "application/json"
                response( data: json )
                return
            } catch let error as NSError {
                dynamoLog( "Could not encode: \(json) \(error)" )
            }
        }
    }

    /** set response as a whole from NSData */
    open func response( data: Data ) {
        var dout = data
#if os(OSX)
        if compressResponse && requestHeaders["Accept-Encoding"] == "gzip, deflate" {
            if let deflated = dout.deflate() {
                dout = deflated
                addResponseHeader( name: "Content-Encoding", value: "deflate" )
            }
        }
#endif
        contentLength = dout.count
        sendResponseHeaders()
        dout.withUnsafeBytes {
            (bytes: UnsafePointer<Int8>) -> Void in
            if write( buffer: bytes, count: dout.count ) != dout.count {
                dynamoLog( "Could not write \(dout.count) bytes to client " )
            }
        }
    }

    // for DynamoSelector used by proxies
    var hasBytesAvailable: Bool {
        return false
    }

    func receive( buffer: UnsafeMutableRawPointer, count: Int ) -> Int? {
        return _read( buffer: buffer, count: count )
    }

    func forward( buffer: UnsafeRawPointer, count: Int ) -> Int? {
        return _write( buffer: buffer, count: count )
    }

    deinit {
//        Swift.print("deinit \(self)")
        flush()
        fclose(writeFP)
        fclose(readFP)
        close(clientSocket)
    }
}

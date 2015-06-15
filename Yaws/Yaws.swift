//
//  Yaws.swift
//  Yaws
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Yaws/Yaws/Yaws.swift#45 $
//
//  Repo: https://github.com/johnno1962/Yaws
//

import Foundation

// MARK: Example web application

public class YawsExampleAppProcessor : YawsHTMLAppProcessor {

    override public func processRequest( out: YawsHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        out.print( html( nil ) + head( title( "Table Example" ) +
            style( "body, table { font: 10pt Arial" ) ) + body( nil ) )

        if parameters["width"] == nil {
            out.print( h3( "Quick table creation example" ) )
            out.print(
                form( ["method":"GET"],
                    table(
                        tr( td( "Width: " ) + td( input( ["type":"textfield", "name":"width"] ) ) ) +
                        tr( td( "Height: " ) + td( input( ["type":"textfield", "name":"height"] ) ) ) +
                        tr( td( ["colspan":"2"], input( ["type": "submit"] )) )
                    )
                )
            )
        }
        else if out.method == "GET" {
            let width = parameters["width"], height = parameters["height"]
            out.print( "Table width: \(width!), height: \(height!)" + br() )
            out.print( h3( "Enter table values" ) + form( ["method": "POST"], nil ) + table( nil ) )

            if let width = width?.toInt(), height = height?.toInt() {
                for y in 0..<height {
                    out.print( tr( nil ) )
                    for x in 0..<width {
                        out.print( td( input( ["type":"textfield", "name":"x\(x)y\(y)", "size":"5"] ) ) )
                    }
                    out.print( _tr() )
                }
            }

            out.print( _table()+p()+input( ["type": "submit"] )+_form() )
        }
        else {
            out.print( h3( "Your table:" ) + table( ["border":"1"], nil ) )

            if let width = parameters["width"]?.toInt(), height = parameters["height"]?.toInt() {
                for y in 0..<height {
                    out.print( tr( nil ) )
                    for x in 0..<width {
                        out.print( td( parameters["x\(x)y\(y)"]! ) )
                    }
                    out.print( _tr() )
                }
            }

            out.print( _table() )
        }

        out.print( p() + backButton() )
    }
    
}

// MARK: Private functions

private let yawsSSLQueue = dispatch_queue_create( "YawsSSLThread", DISPATCH_QUEUE_CONCURRENT )
private let yawsQueue = dispatch_queue_create( "YawsThread", DISPATCH_QUEUE_CONCURRENT )
private let htons = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16 : { $0 }
private let ntohs = htons
private let INADDR_ANY = in_addr_t(0)

private func sockaddr_cast(p: UnsafeMutablePointer<sockaddr_in>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

private func sockaddr_cast6(p: UnsafeMutablePointer<sockaddr_in6>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

private func setupSocket( socket: Int32 ) {
    var yes: u_int = 1, yeslen = socklen_t(sizeof(yes.dynamicType))
    if setsockopt( socket, SOL_SOCKET, SO_NOSIGPIPE, &yes, yeslen ) < 0 {
        Strerror( "Could not set SO_NOSIGPIPE" )
    }
    if setsockopt( socket, IPPROTO_TCP, TCP_NODELAY, &yes, yeslen ) < 0 {
        Strerror( "Could not set TCP_NODELAY" )
    }
}

private func yawsTrace<T>( msg: T ) {
    println( msg )
}

private func yawsLog<T>( msg: T ) {
    println( "YawsWebServer: \(msg)" )
}

private func Strerror( msg: String ) {
    yawsLog( msg+" - "+String( UTF8String: strerror(errno) )! )
}

// MARK: Basic http: Web server

@objc public enum YawsProcessed : Int {
    case
        NotProcessed, // does not recogise the request
        Processed, // has processed the request
        ProcessedAndReusable // "" and connection may be reused
}

public class YawsWebServer : NSObject, NSStreamDelegate {

    private let serverSocket: Int32
    public var serverPort: UInt16 = 0

    public convenience init?( portNumber: UInt16, processors: [YawsProcessor], localhostOnly: Bool = false ) {

        self.init( portNumber, localhostOnly: localhostOnly )

        if serverPort != 0 {
            runConnectionHandler( {
                (clientSocket: Int32) in

                let yawsClient = YawsHTTPConnection( clientSocket: clientSocket )

                while yawsClient.readHeaders() {
                    var processed = false

                    for processor in processors {

                        switch processor.process( yawsClient ) {
                        case .NotProcessed:
                            continue
                        case .Processed:
                            return
                        case .ProcessedAndReusable:
                            yawsClient.flush()
                            processed = true
                            break
                        }

                        break
                    }

                    if !processed {
                        yawsClient.status = 500
                        yawsClient.print( "Invalid request: \(yawsClient.method) \(yawsClient.uri) \(yawsClient.httpVersion)" )
                        return
                    }
                }

            } )
        }
        else {
            return nil
        }
    }

    private init( _ portNumber: UInt16, localhostOnly: Bool ) {

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
            }
        }

        super.init()
    }

    private func runConnectionHandler( connectionHandler: (Int32) -> Void ) {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            while self.serverSocket >= 0 {

                let clientSocket = accept( self.serverSocket, nil, nil )

                if clientSocket >= 0 {
                    dispatch_async( yawsQueue, {
                        setupSocket( clientSocket )
                        connectionHandler( clientSocket )
                    } )
                }
            }
        } )
    }

}

// MARK: SSL https: Web Server

public class YawsSSLWebServer : YawsWebServer, NSStreamDelegate {

    private var relayMap = [NSStream:YawsSSLRelay]()

    public init?( portNumber: UInt16, pocessors: [YawsProcessor], certs: [AnyObject]? ) {

        var nonSSLPortOnLocalhost = portNumber-1

        // port number 0 uses any available port
        if let surrogateServer = YawsWebServer( portNumber: 0, processors: pocessors, localhostOnly: true ) {
            nonSSLPortOnLocalhost = surrogateServer.serverPort
            yawsLog( "Surrogate server on port \(nonSSLPortOnLocalhost)" )
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

                    let relay = YawsSSLRelay( clientSocket, localSocket, server: self, certs: certs )

                    dispatch_async( yawsSSLQueue, {
                        var buffer = [UInt8](count: 8192, repeatedValue: 0)
                        while true {
                            let bytesRead = recv( localSocket, &buffer, buffer.count, 0 )
                            if bytesRead <= 0 {
                                self.close( relay.outputStream )
                                return
                            }
                            else {
                                var ptr = 0
                                while ptr < bytesRead {
                                    let remaining = UnsafePointer<UInt8>(buffer)+ptr
                                    let bytesWritten = relay.outputStream.write( remaining, maxLength: bytesRead-ptr )
                                    if bytesWritten <= 0 {
                                        yawsLog( "Short write on relay" )
                                        self.close( relay.outputStream )
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
                    yawsLog( "Short write to surrogate" )
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
            relay.closer()
        }
    }
}

private class YawsSSLRelay {

    let clientSocket: Int32
    let localSocket: Int32
    let inputStream: NSInputStream
    let outputStream: NSOutputStream

    init( _ clientSocket: Int32, _ localSocket: Int32, server: YawsSSLWebServer, certs: [AnyObject]? ) {

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

    func closer() {
        outputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream.close()
        inputStream.close()
        close( clientSocket )
        close( localSocket )
    }

}

// MARK: HTTP request parser

private let dummyBase = NSURL( string: "http://nohost" )!
private var yawsRelayThreads = 0
public var yawsStatusText = [
    200: "OK",
    304: "Redirect",
    404: "File not found",
    500: "Server error"
]

@objc public class YawsHTTPConnection {

    private let readFILE: UnsafeMutablePointer<FILE>, writeFILE: UnsafeMutablePointer<FILE>
    public let clientSocket: Int32

    public var method = "GET", uri = "/", httpVersion = "HTTP/1.1"
    public var url = dummyBase
    public var status = 200

    var requestHeaders = [String: String]()
    var responseHeaders = ""
    var sentHeaders = false

    init( clientSocket: Int32 ) {
        self.clientSocket = clientSocket
        readFILE = fdopen( clientSocket, "r" )
        writeFILE = fdopen( clientSocket, "w" )
    }

    convenience init?( url: NSURL ) {
        let host = (url.host! as NSString)
        let addr = gethostbyname( host.UTF8String )
        let sockadddr: UnsafeMutablePointer<sockaddr>

        if addr != nil {
            let port = UInt16(url.port?.intValue ?? 80)
            let addrList = addr.memory.h_addr_list
            switch addr.memory.h_addrtype {
            case AF_INET:
                let addr0 = UnsafePointer<in_addr>(addrList.memory)
                var ip4addr = sockaddr_in(sin_len: UInt8(sizeof(sockaddr_in)),
                    sin_family: sa_family_t(addr.memory.h_addrtype),
                    sin_port: htons( port ), sin_addr: addr0.memory,
                    sin_zero: (Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0)))
                sockadddr = sockaddr_cast(&ip4addr)
            case AF_INET6: // TODO... completely untested
                let addr0 = UnsafePointer<in6_addr>(addrList.memory)
                var ip6addr = sockaddr_in6(sin6_len: UInt8(sizeof(sockaddr_in6)),
                    sin6_family: sa_family_t(addr.memory.h_addrtype),
                    sin6_port: htons( port ), sin6_flowinfo: 0, sin6_addr: addr0.memory,
                    sin6_scope_id: 0)
                sockadddr = sockaddr_cast6(&ip6addr)
            default:
                yawsLog( "Unknown address family: \(addr.memory.h_addrtype)" )
                self.init( clientSocket: 0 )
                return nil
            }

            let remoteSocket = socket( Int32(sockadddr.memory.sa_family), SOCK_STREAM, 0 )
            if remoteSocket < 0 {
                Strerror( "Could not obtain socket" )
            }
            else if connect( remoteSocket, sockadddr, socklen_t(sockadddr.memory.sa_len) ) < 0 {
                Strerror( "Could not connect to: \(host):\(port)" )
            }
            else {
                setupSocket( remoteSocket )
                self.init( clientSocket: remoteSocket )
                return
            }
        }
        else {
            yawsLog( "Could not resolve host: \(host)" )
        }

        self.init( clientSocket: 0 )
        return nil
    }

    func read( buffer: UnsafeMutablePointer<Void>, count: Int ) -> Int {
        return fread( buffer, 1, count, readFILE )
    }

    func write( buffer: UnsafePointer<Void>, count: Int ) -> Int {
        return fwrite( buffer, 1, count, writeFILE )
    }

    func readHeaders() -> Bool {
        if let request = readLine() {
            yawsTrace(request)

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
                yawsTrace( line )
                let nameValue = split( line, maxSplit: 1, allowEmptySlices: true, isSeparator: { $0 == ":" } )
                if nameValue.count < 2 {
                    return true
                }
                else {
                    requestHeaders[nameValue[0]] = (nameValue[1] as NSString).substringFromIndex(1)
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

    private let cr = Int8(("\r" as NSString).characterAtIndex(0)), nl = Int8(("\n" as NSString).characterAtIndex(0))

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

    func contentLength() -> Int? {
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
            yawsLog( "Cookies must be set before the first HTML is sent" )
        }
    }

    private final func writeHeaders() {
        if responseHeaders == "" {
            addHeader( "Content-Type", value: yawsHtmlMimeType )
        }

        let statusText = yawsStatusText[status] ?? "Unknown Status"
        rawPrint( "\(httpVersion) \(status) \(statusText)\r\n\(responseHeaders)\r\n" )
        sentHeaders = true
    }
    
    public func rawPrint( output: String ) {
        let bytes = (output as NSString).UTF8String
        write( bytes, count: Int(strlen(bytes)) )
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
        fflush( writeFILE )
    }

    private func relay( label: String, to: YawsHTTPConnection, _ logger: (String) -> () ) {
        yawsRelayThreads++
        dispatch_async( yawsQueue, {
            var buffer = [Int8](count: 8192, repeatedValue: 0)

            while true {
                let bytesRead = recv( self.clientSocket, &buffer, buffer.count, 0 )
                if bytesRead <= 0 ||
                    send( Int32(to.clientSocket), &buffer, bytesRead, 0 ) != bytesRead {
                        break
                }
            }

            yawsRelayThreads--
            close( self.clientSocket )
            close( to.clientSocket )
        } )
    }

    deinit {
        fclose( writeFILE )
        fclose( readFILE )
        close( clientSocket )
    }

}

// MARK: PROCESSORS

public class YawsProcessor: NSObject {

    @objc func process( yawsClient: YawsHTTPConnection ) -> YawsProcessed {
        fatalError( "YawsProcessor: Abstract method process() called" )
    }

}

// MARK: Proxy Processors

public class YawsSSLProxyProcessor : YawsProxyProcessor {

    override func process( yawsClient: YawsHTTPConnection ) -> YawsProcessed {
        if yawsClient.method != "CONNECT" {
            return .NotProcessed
        }

        if let urlForDestination = NSURL( string: "https://\(yawsClient.uri)" ),
            remoteConnection = YawsHTTPConnection( url: urlForDestination ) {
                yawsClient.rawPrint( "HTTP/1.0 200 Connection established\r\nProxy-agent: Yaws/1.0\r\n\r\n" )
                yawsClient.flush()
                remoteConnection.relay( "<- \(yawsClient.uri)", to: yawsClient, logger )
                yawsClient.relay( "-> \(yawsClient.uri)", to: remoteConnection, logger )
        }

        return .Processed
    }
    
}

public class YawsProxyProcessor : YawsProcessor {

    var logger: (String) -> ()

    public init( logger: (String) -> () = yawsTrace ) {
        self.logger = logger
    }
    
    override func process( yawsClient: YawsHTTPConnection ) -> YawsProcessed {

        if yawsClient.url.host == dummyBase.host {
            return .NotProcessed
        }

        if let host = yawsClient.url.host, remoteConnection = YawsHTTPConnection( url: yawsClient.url ) {

            var remotePath = yawsClient.url.path ?? "/"
            if let query = yawsClient.url.query {
                remotePath += "?"+query
            }

            remoteConnection.rawPrint( "\(yawsClient.method) \(remotePath) \(yawsClient.httpVersion)\r\n" )
            for (name, value) in yawsClient.requestHeaders {
                remoteConnection.rawPrint( "\(name): \(value)\r\n" )
            }
            remoteConnection.rawPrint( "\r\n" )
            remoteConnection.flush()

            remoteConnection.relay( "<- \(host)", to: yawsClient, logger )
            yawsClient.relay( "-> \(host)", to: remoteConnection, logger )
        }

        return .Processed
    }
    
}

// MARK: Processors for dynamic content

public class YawsApplicationProcessor : YawsProcessor {

    let pathPrefix: String

    public init( pathPrefix: String ) {
        self.pathPrefix = pathPrefix
    }

    override func process( yawsClient: YawsHTTPConnection ) -> YawsProcessed {
        if let pathInfo = yawsClient.url.path {
            if pathInfo.hasPrefix( pathPrefix ) {
                var parameters = [String:String]()

                if yawsClient.method == "POST" {
                    if let postData = yawsClient.readPost() {
                        addParameters( &parameters, from: postData )
                    }
                }

                if let queryString = yawsClient.url.query {
                    addParameters( &parameters, from: queryString )
                }

                var cookies = [String:String]()
                if let cookieHeader = yawsClient.requestHeaders["Cookie"] {
                    addParameters( &cookies, from: cookieHeader, delimeter: "; " )
                }

                processRequest( yawsClient, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
                return .Processed
            }
        }

        return .NotProcessed
    }

    private func addParameters(  inout parameters: [String:String], from queryString: String, delimeter: String = "&" ) {
        for nameValue in queryString.componentsSeparatedByString( delimeter ) {
            let nameValue = split( nameValue, maxSplit: 2, allowEmptySlices: true, isSeparator: { $0 == "=" } )
            parameters[nameValue[0]] = nameValue.count > 1 ? nameValue[1].stringByRemovingPercentEncoding! : ""
        }
    }
    
    @objc public func processRequest( out: YawsHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        fatalError( "YawsApplicationProcessor.processRequest(): Subclass responsibility" )
    }

}

private func htmlEscape( attrValue: String ) -> String {
    return attrValue
        .stringByReplacingOccurrencesOfString( "&", withString: "&amp;" )
        .stringByReplacingOccurrencesOfString( "'", withString: "&apos;" )
        .stringByReplacingOccurrencesOfString( "<", withString: "&lt;" )
        .stringByReplacingOccurrencesOfString( ">", withString: "&gt;" )
}

// MARK: HTML Generator

public class YawsHTMLAppProcessor : YawsApplicationProcessor {

    public func tag( name: String, attributes: [String: String]?, content: String? ) -> String {
        var html = "<"+name

        if attributes != nil {
            for (name, value) in attributes! {
                html += " \(name)"
                if value != NSNull() {
                    html += "='\(htmlEscape(value))'"
                }
            }
        }

        if let content = content {
            if content == "" {
                html += "/>"
            } else {
                html += ">\(content)</\(name)>"
            }
        } else {
            html += ">"
        }

        return html
    }

    public func backButton() -> String {
        return button( ["onclick":"history.back();"], "Back" )
    }

    public func _DOCTYPE( _ content: String? = "" ) -> String {
        return tag( "!DOCTYPE", attributes: nil, content: content )
    }
    public func _DOCTYPE( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "!DOCTYPE", attributes: attributes, content: content )
    }

    public func a( _ content: String? = "" ) -> String {
        return tag( "a", attributes: nil, content: content )
    }
    public func a( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "a", attributes: attributes, content: content )
    }
    public func _a() -> String {
        return "</a>"
    }
    public func abbr( _ content: String? = "" ) -> String {
        return tag( "abbr", attributes: nil, content: content )
    }
    public func abbr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "abbr", attributes: attributes, content: content )
    }
    public func _abbr() -> String {
        return "</abbr>"
    }
    public func acronym( _ content: String? = "" ) -> String {
        return tag( "acronym", attributes: nil, content: content )
    }
    public func acronym( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "acronym", attributes: attributes, content: content )
    }
    public func _acronym() -> String {
        return "</acronym>"
    }
    public func address( _ content: String? = "" ) -> String {
        return tag( "address", attributes: nil, content: content )
    }
    public func address( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "address", attributes: attributes, content: content )
    }
    public func _address() -> String {
        return "</address>"
    }
    public func applet( _ content: String? = "" ) -> String {
        return tag( "applet", attributes: nil, content: content )
    }
    public func applet( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "applet", attributes: attributes, content: content )
    }
    public func _applet() -> String {
        return "</applet>"
    }
    public func area( _ content: String? = "" ) -> String {
        return tag( "area", attributes: nil, content: content )
    }
    public func area( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "area", attributes: attributes, content: content )
    }
    public func _area() -> String {
        return "</area>"
    }
    public func article( _ content: String? = "" ) -> String {
        return tag( "article", attributes: nil, content: content )
    }
    public func article( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "article", attributes: attributes, content: content )
    }
    public func _article() -> String {
        return "</article>"
    }
    public func aside( _ content: String? = "" ) -> String {
        return tag( "aside", attributes: nil, content: content )
    }
    public func aside( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "aside", attributes: attributes, content: content )
    }
    public func _aside() -> String {
        return "</aside>"
    }
    public func audio( _ content: String? = "" ) -> String {
        return tag( "audio", attributes: nil, content: content )
    }
    public func audio( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "audio", attributes: attributes, content: content )
    }
    public func _audio() -> String {
        return "</audio>"
    }
    public func b( _ content: String? = "" ) -> String {
        return tag( "b", attributes: nil, content: content )
    }
    public func b( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "b", attributes: attributes, content: content )
    }
    public func _b() -> String {
        return "</b>"
    }
    public func base( _ content: String? = "" ) -> String {
        return tag( "base", attributes: nil, content: content )
    }
    public func base( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "base", attributes: attributes, content: content )
    }
    public func _base() -> String {
        return "</base>"
    }
    public func basefont( _ content: String? = "" ) -> String {
        return tag( "basefont", attributes: nil, content: content )
    }
    public func basefont( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "basefont", attributes: attributes, content: content )
    }
    public func _basefont() -> String {
        return "</basefont>"
    }
    public func bdi( _ content: String? = "" ) -> String {
        return tag( "bdi", attributes: nil, content: content )
    }
    public func bdi( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "bdi", attributes: attributes, content: content )
    }
    public func _bdi() -> String {
        return "</bdi>"
    }
    public func bdo( _ content: String? = "" ) -> String {
        return tag( "bdo", attributes: nil, content: content )
    }
    public func bdo( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "bdo", attributes: attributes, content: content )
    }
    public func _bdo() -> String {
        return "</bdo>"
    }
    public func big( _ content: String? = "" ) -> String {
        return tag( "big", attributes: nil, content: content )
    }
    public func big( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "big", attributes: attributes, content: content )
    }
    public func _big() -> String {
        return "</big>"
    }
    public func blockquote( _ content: String? = "" ) -> String {
        return tag( "blockquote", attributes: nil, content: content )
    }
    public func blockquote( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "blockquote", attributes: attributes, content: content )
    }
    public func _blockquote() -> String {
        return "</blockquote>"
    }
    public func body( _ content: String? = "" ) -> String {
        return tag( "body", attributes: nil, content: content )
    }
    public func body( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "body", attributes: attributes, content: content )
    }
    public func _body() -> String {
        return "</body>"
    }
    public func br( _ content: String? = "" ) -> String {
        return tag( "br", attributes: nil, content: content )
    }
    public func br( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "br", attributes: attributes, content: content )
    }
    public func _br() -> String {
        return "</br>"
    }
    public func button( _ content: String? = "" ) -> String {
        return tag( "button", attributes: nil, content: content )
    }
    public func button( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "button", attributes: attributes, content: content )
    }
    public func _button() -> String {
        return "</button>"
    }
    public func canvas( _ content: String? = "" ) -> String {
        return tag( "canvas", attributes: nil, content: content )
    }
    public func canvas( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "canvas", attributes: attributes, content: content )
    }
    public func _canvas() -> String {
        return "</canvas>"
    }
    public func caption( _ content: String? = "" ) -> String {
        return tag( "caption", attributes: nil, content: content )
    }
    public func caption( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "caption", attributes: attributes, content: content )
    }
    public func _caption() -> String {
        return "</caption>"
    }
    public func center( _ content: String? = "" ) -> String {
        return tag( "center", attributes: nil, content: content )
    }
    public func center( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "center", attributes: attributes, content: content )
    }
    public func _center() -> String {
        return "</center>"
    }
    public func cite( _ content: String? = "" ) -> String {
        return tag( "cite", attributes: nil, content: content )
    }
    public func cite( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "cite", attributes: attributes, content: content )
    }
    public func _cite() -> String {
        return "</cite>"
    }
    public func code( _ content: String? = "" ) -> String {
        return tag( "code", attributes: nil, content: content )
    }
    public func code( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "code", attributes: attributes, content: content )
    }
    public func _code() -> String {
        return "</code>"
    }
    public func col( _ content: String? = "" ) -> String {
        return tag( "col", attributes: nil, content: content )
    }
    public func col( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "col", attributes: attributes, content: content )
    }
    public func _col() -> String {
        return "</col>"
    }
    public func colgroup( _ content: String? = "" ) -> String {
        return tag( "colgroup", attributes: nil, content: content )
    }
    public func colgroup( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "colgroup", attributes: attributes, content: content )
    }
    public func _colgroup() -> String {
        return "</colgroup>"
    }
    public func datalist( _ content: String? = "" ) -> String {
        return tag( "datalist", attributes: nil, content: content )
    }
    public func datalist( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "datalist", attributes: attributes, content: content )
    }
    public func _datalist() -> String {
        return "</datalist>"
    }
    public func dd( _ content: String? = "" ) -> String {
        return tag( "dd", attributes: nil, content: content )
    }
    public func dd( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dd", attributes: attributes, content: content )
    }
    public func _dd() -> String {
        return "</dd>"
    }
    public func del( _ content: String? = "" ) -> String {
        return tag( "del", attributes: nil, content: content )
    }
    public func del( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "del", attributes: attributes, content: content )
    }
    public func _del() -> String {
        return "</del>"
    }
    public func details( _ content: String? = "" ) -> String {
        return tag( "details", attributes: nil, content: content )
    }
    public func details( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "details", attributes: attributes, content: content )
    }
    public func _details() -> String {
        return "</details>"
    }
    public func dfn( _ content: String? = "" ) -> String {
        return tag( "dfn", attributes: nil, content: content )
    }
    public func dfn( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dfn", attributes: attributes, content: content )
    }
    public func _dfn() -> String {
        return "</dfn>"
    }
    public func dialog( _ content: String? = "" ) -> String {
        return tag( "dialog", attributes: nil, content: content )
    }
    public func dialog( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dialog", attributes: attributes, content: content )
    }
    public func _dialog() -> String {
        return "</dialog>"
    }
    public func dir( _ content: String? = "" ) -> String {
        return tag( "dir", attributes: nil, content: content )
    }
    public func dir( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dir", attributes: attributes, content: content )
    }
    public func _dir() -> String {
        return "</dir>"
    }
    public func div( _ content: String? = "" ) -> String {
        return tag( "div", attributes: nil, content: content )
    }
    public func div( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "div", attributes: attributes, content: content )
    }
    public func _div() -> String {
        return "</div>"
    }
    public func dl( _ content: String? = "" ) -> String {
        return tag( "dl", attributes: nil, content: content )
    }
    public func dl( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dl", attributes: attributes, content: content )
    }
    public func _dl() -> String {
        return "</dl>"
    }
    public func dt( _ content: String? = "" ) -> String {
        return tag( "dt", attributes: nil, content: content )
    }
    public func dt( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dt", attributes: attributes, content: content )
    }
    public func _dt() -> String {
        return "</dt>"
    }
    public func em( _ content: String? = "" ) -> String {
        return tag( "em", attributes: nil, content: content )
    }
    public func em( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "em", attributes: attributes, content: content )
    }
    public func _em() -> String {
        return "</em>"
    }
    public func embed( _ content: String? = "" ) -> String {
        return tag( "embed", attributes: nil, content: content )
    }
    public func embed( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "embed", attributes: attributes, content: content )
    }
    public func _embed() -> String {
        return "</embed>"
    }
    public func fieldset( _ content: String? = "" ) -> String {
        return tag( "fieldset", attributes: nil, content: content )
    }
    public func fieldset( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "fieldset", attributes: attributes, content: content )
    }
    public func _fieldset() -> String {
        return "</fieldset>"
    }
    public func figcaption( _ content: String? = "" ) -> String {
        return tag( "figcaption", attributes: nil, content: content )
    }
    public func figcaption( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "figcaption", attributes: attributes, content: content )
    }
    public func _figcaption() -> String {
        return "</figcaption>"
    }
    public func figure( _ content: String? = "" ) -> String {
        return tag( "figure", attributes: nil, content: content )
    }
    public func figure( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "figure", attributes: attributes, content: content )
    }
    public func _figure() -> String {
        return "</figure>"
    }
    public func font( _ content: String? = "" ) -> String {
        return tag( "font", attributes: nil, content: content )
    }
    public func font( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "font", attributes: attributes, content: content )
    }
    public func _font() -> String {
        return "</font>"
    }
    public func footer( _ content: String? = "" ) -> String {
        return tag( "footer", attributes: nil, content: content )
    }
    public func footer( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "footer", attributes: attributes, content: content )
    }
    public func _footer() -> String {
        return "</footer>"
    }
    public func form( _ content: String? = "" ) -> String {
        return tag( "form", attributes: nil, content: content )
    }
    public func form( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "form", attributes: attributes, content: content )
    }
    public func _form() -> String {
        return "</form>"
    }
    public func frame( _ content: String? = "" ) -> String {
        return tag( "frame", attributes: nil, content: content )
    }
    public func frame( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "frame", attributes: attributes, content: content )
    }
    public func _frame() -> String {
        return "</frame>"
    }
    public func frameset( _ content: String? = "" ) -> String {
        return tag( "frameset", attributes: nil, content: content )
    }
    public func frameset( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "frameset", attributes: attributes, content: content )
    }
    public func _frameset() -> String {
        return "</frameset>"
    }
    public func h1( _ content: String? = "" ) -> String {
        return tag( "h1", attributes: nil, content: content )
    }
    public func h1( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h1", attributes: attributes, content: content )
    }
    public func _h1() -> String {
        return "</h1>"
    }
    public func h2( _ content: String? = "" ) -> String {
        return tag( "h2", attributes: nil, content: content )
    }
    public func h2( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h2", attributes: attributes, content: content )
    }
    public func _h2() -> String {
        return "</h2>"
    }
    public func h3( _ content: String? = "" ) -> String {
        return tag( "h3", attributes: nil, content: content )
    }
    public func h3( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h3", attributes: attributes, content: content )
    }
    public func _h3() -> String {
        return "</h3>"
    }
    public func h4( _ content: String? = "" ) -> String {
        return tag( "h4", attributes: nil, content: content )
    }
    public func h4( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h4", attributes: attributes, content: content )
    }
    public func _h4() -> String {
        return "</h4>"
    }
    public func h5( _ content: String? = "" ) -> String {
        return tag( "h5", attributes: nil, content: content )
    }
    public func h5( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h5", attributes: attributes, content: content )
    }
    public func _h5() -> String {
        return "</h5>"
    }
    public func h6( _ content: String? = "" ) -> String {
        return tag( "h6", attributes: nil, content: content )
    }
    public func h6( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h6", attributes: attributes, content: content )
    }
    public func _h6() -> String {
        return "</h6>"
    }
    public func head( _ content: String? = "" ) -> String {
        return tag( "head", attributes: nil, content: content )
    }
    public func head( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "head", attributes: attributes, content: content )
    }
    public func _head() -> String {
        return "</head>"
    }
    public func header( _ content: String? = "" ) -> String {
        return tag( "header", attributes: nil, content: content )
    }
    public func header( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "header", attributes: attributes, content: content )
    }
    public func _header() -> String {
        return "</header>"
    }
    public func hr( _ content: String? = "" ) -> String {
        return tag( "hr", attributes: nil, content: content )
    }
    public func hr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "hr", attributes: attributes, content: content )
    }
    public func _hr() -> String {
        return "</hr>"
    }
    public func html( _ content: String? = "" ) -> String {
        return tag( "html", attributes: nil, content: content )
    }
    public func html( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "html", attributes: attributes, content: content )
    }
    public func _html() -> String {
        return "</html>"
    }
    public func i( _ content: String? = "" ) -> String {
        return tag( "i", attributes: nil, content: content )
    }
    public func i( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "i", attributes: attributes, content: content )
    }
    public func _i() -> String {
        return "</i>"
    }
    public func iframe( _ content: String? = "" ) -> String {
        return tag( "iframe", attributes: nil, content: content )
    }
    public func iframe( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "iframe", attributes: attributes, content: content )
    }
    public func _iframe() -> String {
        return "</iframe>"
    }
    public func img( _ content: String? = "" ) -> String {
        return tag( "img", attributes: nil, content: content )
    }
    public func img( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "img", attributes: attributes, content: content )
    }
    public func _img() -> String {
        return "</img>"
    }
    public func input( _ content: String? = "" ) -> String {
        return tag( "input", attributes: nil, content: content )
    }
    public func input( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "input", attributes: attributes, content: content )
    }
    public func _input() -> String {
        return "</input>"
    }
    public func ins( _ content: String? = "" ) -> String {
        return tag( "ins", attributes: nil, content: content )
    }
    public func ins( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ins", attributes: attributes, content: content )
    }
    public func _ins() -> String {
        return "</ins>"
    }
    public func kbd( _ content: String? = "" ) -> String {
        return tag( "kbd", attributes: nil, content: content )
    }
    public func kbd( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "kbd", attributes: attributes, content: content )
    }
    public func _kbd() -> String {
        return "</kbd>"
    }
    public func keygen( _ content: String? = "" ) -> String {
        return tag( "keygen", attributes: nil, content: content )
    }
    public func keygen( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "keygen", attributes: attributes, content: content )
    }
    public func _keygen() -> String {
        return "</keygen>"
    }
    public func label( _ content: String? = "" ) -> String {
        return tag( "label", attributes: nil, content: content )
    }
    public func label( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "label", attributes: attributes, content: content )
    }
    public func _label() -> String {
        return "</label>"
    }
    public func legend( _ content: String? = "" ) -> String {
        return tag( "legend", attributes: nil, content: content )
    }
    public func legend( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "legend", attributes: attributes, content: content )
    }
    public func _legend() -> String {
        return "</legend>"
    }
    public func li( _ content: String? = "" ) -> String {
        return tag( "li", attributes: nil, content: content )
    }
    public func li( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "li", attributes: attributes, content: content )
    }
    public func _li() -> String {
        return "</li>"
    }
    public func link( _ content: String? = "" ) -> String {
        return tag( "link", attributes: nil, content: content )
    }
    public func link( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "link", attributes: attributes, content: content )
    }
    public func _link() -> String {
        return "</link>"
    }
    public func main( _ content: String? = "" ) -> String {
        return tag( "main", attributes: nil, content: content )
    }
    public func main( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "main", attributes: attributes, content: content )
    }
    public func _main() -> String {
        return "</main>"
    }
    public func map( _ content: String? = "" ) -> String {
        return tag( "map", attributes: nil, content: content )
    }
    public func map( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "map", attributes: attributes, content: content )
    }
    public func _map() -> String {
        return "</map>"
    }
    public func mark( _ content: String? = "" ) -> String {
        return tag( "mark", attributes: nil, content: content )
    }
    public func mark( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "mark", attributes: attributes, content: content )
    }
    public func _mark() -> String {
        return "</mark>"
    }
    public func menu( _ content: String? = "" ) -> String {
        return tag( "menu", attributes: nil, content: content )
    }
    public func menu( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "menu", attributes: attributes, content: content )
    }
    public func _menu() -> String {
        return "</menu>"
    }
    public func menuitem( _ content: String? = "" ) -> String {
        return tag( "menuitem", attributes: nil, content: content )
    }
    public func menuitem( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "menuitem", attributes: attributes, content: content )
    }
    public func _menuitem() -> String {
        return "</menuitem>"
    }
    public func meta( _ content: String? = "" ) -> String {
        return tag( "meta", attributes: nil, content: content )
    }
    public func meta( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "meta", attributes: attributes, content: content )
    }
    public func _meta() -> String {
        return "</meta>"
    }
    public func meter( _ content: String? = "" ) -> String {
        return tag( "meter", attributes: nil, content: content )
    }
    public func meter( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "meter", attributes: attributes, content: content )
    }
    public func _meter() -> String {
        return "</meter>"
    }
    public func nav( _ content: String? = "" ) -> String {
        return tag( "nav", attributes: nil, content: content )
    }
    public func nav( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "nav", attributes: attributes, content: content )
    }
    public func _nav() -> String {
        return "</nav>"
    }
    public func noframes( _ content: String? = "" ) -> String {
        return tag( "noframes", attributes: nil, content: content )
    }
    public func noframes( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "noframes", attributes: attributes, content: content )
    }
    public func _noframes() -> String {
        return "</noframes>"
    }
    public func noscript( _ content: String? = "" ) -> String {
        return tag( "noscript", attributes: nil, content: content )
    }
    public func noscript( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "noscript", attributes: attributes, content: content )
    }
    public func _noscript() -> String {
        return "</noscript>"
    }
    public func object( _ content: String? = "" ) -> String {
        return tag( "object", attributes: nil, content: content )
    }
    public func object( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "object", attributes: attributes, content: content )
    }
    public func _object() -> String {
        return "</object>"
    }
    public func ol( _ content: String? = "" ) -> String {
        return tag( "ol", attributes: nil, content: content )
    }
    public func ol( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ol", attributes: attributes, content: content )
    }
    public func _ol() -> String {
        return "</ol>"
    }
    public func optgroup( _ content: String? = "" ) -> String {
        return tag( "optgroup", attributes: nil, content: content )
    }
    public func optgroup( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "optgroup", attributes: attributes, content: content )
    }
    public func _optgroup() -> String {
        return "</optgroup>"
    }
    public func option( _ content: String? = "" ) -> String {
        return tag( "option", attributes: nil, content: content )
    }
    public func option( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "option", attributes: attributes, content: content )
    }
    public func _option() -> String {
        return "</option>"
    }
    public func output( _ content: String? = "" ) -> String {
        return tag( "output", attributes: nil, content: content )
    }
    public func output( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "output", attributes: attributes, content: content )
    }
    public func _output() -> String {
        return "</output>"
    }
    public func p( _ content: String? = "" ) -> String {
        return tag( "p", attributes: nil, content: content )
    }
    public func p( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "p", attributes: attributes, content: content )
    }
    public func _p() -> String {
        return "</p>"
    }
    public func param( _ content: String? = "" ) -> String {
        return tag( "param", attributes: nil, content: content )
    }
    public func param( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "param", attributes: attributes, content: content )
    }
    public func _param() -> String {
        return "</param>"
    }
    public func pre( _ content: String? = "" ) -> String {
        return tag( "pre", attributes: nil, content: content )
    }
    public func pre( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "pre", attributes: attributes, content: content )
    }
    public func _pre() -> String {
        return "</pre>"
    }
    public func progress( _ content: String? = "" ) -> String {
        return tag( "progress", attributes: nil, content: content )
    }
    public func progress( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "progress", attributes: attributes, content: content )
    }
    public func _progress() -> String {
        return "</progress>"
    }
    public func q( _ content: String? = "" ) -> String {
        return tag( "q", attributes: nil, content: content )
    }
    public func q( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "q", attributes: attributes, content: content )
    }
    public func _q() -> String {
        return "</q>"
    }
    public func rp( _ content: String? = "" ) -> String {
        return tag( "rp", attributes: nil, content: content )
    }
    public func rp( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "rp", attributes: attributes, content: content )
    }
    public func _rp() -> String {
        return "</rp>"
    }
    public func rt( _ content: String? = "" ) -> String {
        return tag( "rt", attributes: nil, content: content )
    }
    public func rt( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "rt", attributes: attributes, content: content )
    }
    public func _rt() -> String {
        return "</rt>"
    }
    public func ruby( _ content: String? = "" ) -> String {
        return tag( "ruby", attributes: nil, content: content )
    }
    public func ruby( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ruby", attributes: attributes, content: content )
    }
    public func _ruby() -> String {
        return "</ruby>"
    }
    public func s( _ content: String? = "" ) -> String {
        return tag( "s", attributes: nil, content: content )
    }
    public func s( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "s", attributes: attributes, content: content )
    }
    public func _s() -> String {
        return "</s>"
    }
    public func samp( _ content: String? = "" ) -> String {
        return tag( "samp", attributes: nil, content: content )
    }
    public func samp( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "samp", attributes: attributes, content: content )
    }
    public func _samp() -> String {
        return "</samp>"
    }
    public func script( _ content: String? = "" ) -> String {
        return tag( "script", attributes: nil, content: content )
    }
    public func script( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "script", attributes: attributes, content: content )
    }
    public func _script() -> String {
        return "</script>"
    }
    public func section( _ content: String? = "" ) -> String {
        return tag( "section", attributes: nil, content: content )
    }
    public func section( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "section", attributes: attributes, content: content )
    }
    public func _section() -> String {
        return "</section>"
    }
    public func select( _ content: String? = "" ) -> String {
        return tag( "select", attributes: nil, content: content )
    }
    public func select( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "select", attributes: attributes, content: content )
    }
    public func _select() -> String {
        return "</select>"
    }
    public func small( _ content: String? = "" ) -> String {
        return tag( "small", attributes: nil, content: content )
    }
    public func small( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "small", attributes: attributes, content: content )
    }
    public func _small() -> String {
        return "</small>"
    }
    public func source( _ content: String? = "" ) -> String {
        return tag( "source", attributes: nil, content: content )
    }
    public func source( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "source", attributes: attributes, content: content )
    }
    public func _source() -> String {
        return "</source>"
    }
    public func span( _ content: String? = "" ) -> String {
        return tag( "span", attributes: nil, content: content )
    }
    public func span( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "span", attributes: attributes, content: content )
    }
    public func _span() -> String {
        return "</span>"
    }
    public func strike( _ content: String? = "" ) -> String {
        return tag( "strike", attributes: nil, content: content )
    }
    public func strike( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "strike", attributes: attributes, content: content )
    }
    public func _strike() -> String {
        return "</strike>"
    }
    public func strong( _ content: String? = "" ) -> String {
        return tag( "strong", attributes: nil, content: content )
    }
    public func strong( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "strong", attributes: attributes, content: content )
    }
    public func _strong() -> String {
        return "</strong>"
    }
    public func style( _ content: String? = "" ) -> String {
        return tag( "style", attributes: nil, content: content )
    }
    public func style( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "style", attributes: attributes, content: content )
    }
    public func _style() -> String {
        return "</style>"
    }
    public func sub( _ content: String? = "" ) -> String {
        return tag( "sub", attributes: nil, content: content )
    }
    public func sub( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "sub", attributes: attributes, content: content )
    }
    public func _sub() -> String {
        return "</sub>"
    }
    public func summary( _ content: String? = "" ) -> String {
        return tag( "summary", attributes: nil, content: content )
    }
    public func summary( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "summary", attributes: attributes, content: content )
    }
    public func _summary() -> String {
        return "</summary>"
    }
    public func sup( _ content: String? = "" ) -> String {
        return tag( "sup", attributes: nil, content: content )
    }
    public func sup( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "sup", attributes: attributes, content: content )
    }
    public func _sup() -> String {
        return "</sup>"
    }
    public func table( _ content: String? = "" ) -> String {
        return tag( "table", attributes: nil, content: content )
    }
    public func table( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "table", attributes: attributes, content: content )
    }
    public func _table() -> String {
        return "</table>"
    }
    public func tbody( _ content: String? = "" ) -> String {
        return tag( "tbody", attributes: nil, content: content )
    }
    public func tbody( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tbody", attributes: attributes, content: content )
    }
    public func _tbody() -> String {
        return "</tbody>"
    }
    public func td( _ content: String? = "" ) -> String {
        return tag( "td", attributes: nil, content: content )
    }
    public func td( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "td", attributes: attributes, content: content )
    }
    public func _td() -> String {
        return "</td>"
    }
    public func textarea( _ content: String? = "" ) -> String {
        return tag( "textarea", attributes: nil, content: content )
    }
    public func textarea( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "textarea", attributes: attributes, content: content )
    }
    public func _textarea() -> String {
        return "</textarea>"
    }
    public func tfoot( _ content: String? = "" ) -> String {
        return tag( "tfoot", attributes: nil, content: content )
    }
    public func tfoot( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tfoot", attributes: attributes, content: content )
    }
    public func _tfoot() -> String {
        return "</tfoot>"
    }
    public func th( _ content: String? = "" ) -> String {
        return tag( "th", attributes: nil, content: content )
    }
    public func th( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "th", attributes: attributes, content: content )
    }
    public func _th() -> String {
        return "</th>"
    }
    public func thead( _ content: String? = "" ) -> String {
        return tag( "thead", attributes: nil, content: content )
    }
    public func thead( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "thead", attributes: attributes, content: content )
    }
    public func _thead() -> String {
        return "</thead>"
    }
    public func time( _ content: String? = "" ) -> String {
        return tag( "time", attributes: nil, content: content )
    }
    public func time( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "time", attributes: attributes, content: content )
    }
    public func _time() -> String {
        return "</time>"
    }
    public func title( _ content: String? = "" ) -> String {
        return tag( "title", attributes: nil, content: content )
    }
    public func title( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "title", attributes: attributes, content: content )
    }
    public func _title() -> String {
        return "</title>"
    }
    public func tr( _ content: String? = "" ) -> String {
        return tag( "tr", attributes: nil, content: content )
    }
    public func tr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tr", attributes: attributes, content: content )
    }
    public func _tr() -> String {
        return "</tr>"
    }
    public func track( _ content: String? = "" ) -> String {
        return tag( "track", attributes: nil, content: content )
    }
    public func track( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "track", attributes: attributes, content: content )
    }
    public func _track() -> String {
        return "</track>"
    }
    public func tt( _ content: String? = "" ) -> String {
        return tag( "tt", attributes: nil, content: content )
    }
    public func tt( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tt", attributes: attributes, content: content )
    }
    public func _tt() -> String {
        return "</tt>"
    }
    public func u( _ content: String? = "" ) -> String {
        return tag( "u", attributes: nil, content: content )
    }
    public func u( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "u", attributes: attributes, content: content )
    }
    public func _u() -> String {
        return "</u>"
    }
    public func ul( _ content: String? = "" ) -> String {
        return tag( "ul", attributes: nil, content: content )
    }
    public func ul( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ul", attributes: attributes, content: content )
    }
    public func _ul() -> String {
        return "</ul>"
    }
    public func video( _ content: String? = "" ) -> String {
        return tag( "video", attributes: nil, content: content )
    }
    public func video( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "video", attributes: attributes, content: content )
    }
    public func _video() -> String {
        return "</video>"
    }
    public func wbr( _ content: String? = "" ) -> String {
        return tag( "wbr", attributes: nil, content: content )
    }
    public func wbr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "wbr", attributes: attributes, content: content )
    }
    public func _wbr() -> String {
        return "</wbr>"
    }

}

// MARK: Session based applicatoins

public class YawsSessionProcessor : YawsApplicationProcessor {

    let appClass: YawsSessionBasedApplcation.Type
    var sessions = [String:YawsSessionBasedApplcation]()

    public init( pathPrefix: String, appClass: YawsSessionBasedApplcation.Type ) {
        self.appClass = appClass
        super.init( pathPrefix: pathPrefix )
    }

    public override func processRequest( out: YawsHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

        let sessionCookieName = "YAWS_SESSION"
        var sessionKey = cookies[sessionCookieName]
        if sessionKey == nil || sessions[sessionKey!] == nil {
            sessionKey = NSUUID().UUIDString
            sessions[sessionKey!] = appClass()
            out.addHeader( "Content-Type", value: yawsHtmlMimeType )
            out.setCookie( sessionCookieName, value: sessionKey!, path: pathPrefix )
        }

        sessions[sessionKey!]?.processRequest( out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
    }
}

public class YawsSessionBasedApplcation : YawsHTMLAppProcessor {

    required public init() {
        super.init( pathPrefix: "N/A" )
    }

    public override func processRequest( out: YawsHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {
        yawsLog( "YawsSessionBsedApplcation.processRequest(): Subclass responsibility" )
    }

}

// MARK: Document Processors

public var yawsHtmlMimeType = "text/html; charset=utf-8"
public var yawsMimeTypeMapping = [
    "ico": "image/x-icon",
    "jpeg":"image/jpeg",
    "jpe": "image/jpeg",
    "jpg": "image/jpeg",
    "tiff":"image/tiff",
    "tif": "image/tiff",
    "gif": "image/gif",
    "png": "image/png",
    "bmp": "image/bmp",
    "css": "text/css",
    "htm": yawsHtmlMimeType,
    "html":yawsHtmlMimeType,
    "java":"text/plain",
    "psp": "text/plain",
    "doc": "application/msword",
    "xls": "application/vnd.ms-excel",
    "ppt": "application/vnd.ms-powerpoint",
    "pps": "application/vnd.ms-powerpoint",
    "js":  "application/x-javascript",
    "jse": "application/x-javascript",
    "reg": "application/octet-stream",
    "eps": "application/postscript",
    "ps":  "application/postscript",
    "gz":  "application/x-gzip",
    "hta": "application/hta",
    "jar": "application/zip",
    "zip": "application/zip",
    "pdf": "application/pdf",
    "qt":  "video/quicktime",
    "mov": "video/quicktime",
    "avi": "video/x-msvideo",
    "wav": "audio/x-wav",
    "snd": "audio/basic",
    "mid": "audio/basic",
    "au":  "audio/basic",
    "mpeg":"video/mpeg",
    "mpe": "video/mpeg",
    "mpg": "video/mpeg",
]

public class YawsDocumentProcessor : YawsProcessor {

    let fileManager = NSFileManager.defaultManager()
    let webDateFormatter = NSDateFormatter()
    let documentRoot: String

    convenience override init() {
        let appResources = NSBundle.mainBundle().resourcePath!
        self.init( documentRoot: appResources )
    }

    public init( documentRoot: String ) {
        self.documentRoot = documentRoot
        webDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    }

    func webDate( date: NSDate ) -> String {
        return webDateFormatter.stringFromDate( date )
    }

    override func process( yawsClient: YawsHTTPConnection ) -> YawsProcessed {
        if yawsClient.method != "GET" {
            return .NotProcessed
        }

        var fullPath = documentRoot.stringByAppendingPathComponent( yawsClient.url.path! )
        if fileManager.contentsOfDirectoryAtPath( fullPath, error: nil ) != nil {
            fullPath = fullPath.stringByAppendingPathComponent( "index.html" )
        }

        let fileExt = fullPath.pathExtension
        let mimeType = yawsMimeTypeMapping[fileExt] ?? yawsHtmlMimeType

        yawsClient.addHeader( "Date", value: webDate( NSDate() ) )
        yawsClient.addHeader( "Content-Type", value: mimeType )

        let zippedPath = fullPath+".gz"
        if fileManager.fileExistsAtPath( zippedPath ) {
            yawsClient.addHeader( "Content-Encoding", value: "gzip" )
            fullPath = zippedPath
        }

        var lastModified = fileManager.attributesOfItemAtPath( fullPath,
            error: nil )?[NSFileModificationDate] as? NSDate

        if let since = yawsClient.requestHeaders["If-Modified-Since"] {
            if lastModified != nil && webDate( lastModified! ) == since {
                yawsClient.status = 304
                yawsClient.addHeader( "Content-Length", value: "0" ) // ???
                yawsClient.print( "" )
                return .ProcessedAndReusable
            }
        }

        if let data = NSData( contentsOfFile: fullPath ) {
            yawsClient.status = 200
            yawsClient.addHeader( "Content-Length", value: "\(data.length)" )
            yawsClient.addHeader( "Last-Modified", value: "\(webDate( lastModified! ))" )
            yawsClient.write( data )
            return .ProcessedAndReusable
        }
        else {
            yawsClient.status = 404
            yawsClient.print( "<b>File not found:</b> \(fullPath)" )
            yawsLog( "404 File not Found: \(fullPath)" )
            return .Processed
        }
    }

}

public class MultiHostProcessor : YawsDocumentProcessor {

    let serverHost: String

    public init( host: String, documentRoot: String ) {
        serverHost = host
        super.init( documentRoot: documentRoot )
    }

    override func process( yawsClient: YawsHTTPConnection ) -> YawsProcessed {

        if let host = yawsClient.requestHeaders["Host"] {
            if host == serverHost {
                return super.process( yawsClient )
            }
        }

        return .NotProcessed
    }
}

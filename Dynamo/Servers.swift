//
//  Servers.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Servers.swift#9 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: Private functions

private let DynamoQueue = dispatch_queue_create( "DynamoThread", DISPATCH_QUEUE_CONCURRENT )

let htons = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16 : { $0 }
let ntohs = htons
let INADDR_ANY = in_addr_t(0)

func sockaddr_cast(p: UnsafeMutablePointer<sockaddr_in>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

func sockaddr_cast6(p: UnsafeMutablePointer<sockaddr_in6>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

func sockaddr_cast_in(p: UnsafeMutablePointer<sockaddr>) -> UnsafeMutablePointer<sockaddr_in> {
    return UnsafeMutablePointer<sockaddr_in>(p)
}

func setupSocket( socket: Int32 ) {
    var yes: u_int = 1, yeslen = socklen_t(sizeof(yes.dynamicType))
    if setsockopt( socket, SOL_SOCKET, SO_NOSIGPIPE, &yes, yeslen ) < 0 {
        Strerror( "Could not set SO_NOSIGPIPE" )
    }
    if setsockopt( socket, IPPROTO_TCP, TCP_NODELAY, &yes, yeslen ) < 0 {
        Strerror( "Could not set TCP_NODELAY" )
    }
}

public func dynamoTrace<T>( msg: T ) {
    println( msg )
}

func dynamoLog<T>( msg: T ) {
    println( "DynamoWebServer: \(msg)" )
}

func Strerror( msg: String ) {
    dynamoLog( msg+" - "+String( UTF8String: strerror(errno) )! )
}

/**
 Result returned by a processor to indicate whether it has handled the request. If a "Content-Length"
 header has been provided the connection can be reused in the HTTP/1.1 protocol and the connection
 will be recyled.
 */

@objc public enum DynamoProcessed : Int {
    case
        NotProcessed, // does not recogise the request
        Processed, // has processed the request
        ProcessedAndReusable // "" and connection may be reused
}

/*
 Basic protocol that processors must implement to pick up and process requests from a client.
 */

@objc public protocol DynamoProcessor {

    @objc func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed    
}

// MARK: Basic http: Web server

/**
 Basic http protocol web server running on the specified port. Requests are presented to each of a set
 of proessors provided in a connecton thread until one is encountered that can process the request.
 */

public class DynamoWebServer : NSObject, NSStreamDelegate {

    private let serverSocket: Int32
    public var serverPort: UInt16 = 0

    public convenience init?( portNumber: UInt16, processors: [DynamoProcessor], localhostOnly: Bool = false ) {

        self.init( portNumber, localhostOnly: localhostOnly )

        if serverPort != 0 {
            runConnectionHandler( {
                (clientSocket: Int32) in

                if let httpClient = DynamoHTTPConnection( clientSocket: clientSocket ) {

                    while httpClient.readHeaders() {
                        var processed = false

                        for processor in processors {

                            switch processor.process( httpClient ) {
                            case .NotProcessed:
                                continue
                            case .Processed:
                                return
                            case .ProcessedAndReusable:
                                httpClient.flush()
                                processed = true
                                break
                            }

                            break
                        }

                        if !processed {
                            httpClient.status = 400
                            httpClient.print( "Invalid request: \(httpClient.method) \(httpClient.uri) \(httpClient.httpVersion)" )
                            return
                        }
                    }
                }
            } )
        }
        else {
            return nil
        }
    }

    init( _ portNumber: UInt16, localhostOnly: Bool ) {

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

    func runConnectionHandler( connectionHandler: (Int32) -> Void ) {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            while self.serverSocket >= 0 {

                let clientSocket = accept( self.serverSocket, nil, nil )

                if clientSocket >= 0 {
                    dispatch_async( DynamoQueue, {
                        setupSocket( clientSocket )
                        connectionHandler( clientSocket )
                    } )
                }
            }
        } )
    }

}

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
@objc public class DynamoHTTPConnection {

    private let readFILE: UnsafeMutablePointer<FILE>, writeFILE: UnsafeMutablePointer<FILE>
    let clientSocket: Int32

    public var method = "GET", uri = "/", httpVersion = "HTTP/1.1"
    public var url = dummyBase
    public var status = 200

    var requestHeaders = [String:String]()
    var responseHeaders = ""
    var sentHeaders = false

    init?( clientSocket: Int32 ) {
        self.clientSocket = clientSocket
        readFILE = fdopen( clientSocket, "r" )
        writeFILE = fdopen( clientSocket, "w" )
        if (readFILE == nil || writeFILE == nil) && clientSocket >= 0 {
            Strerror( "FILE open error on fd #\(clientSocket)" )
            return nil;
        }
    }

    convenience init?( url: NSURL ) {
        let host = (url.host! as NSString)
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
            dynamoLog( "Cookies must be set before the first HTML is sent" )
        }
    }

    private final func writeHeaders() {
        if responseHeaders == "" {
            addHeader( "Content-Type", value: dynamoHtmlMimeType )
        }

        let statusText = dynamoStatusText[status] ?? "Unknown Status"
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

    func relay( label: String, to: DynamoHTTPConnection, _ logger: ((String) -> ())? ) {
        dynamoRelayThreads++
        dispatch_async( DynamoQueue, {
            var buffer = [Int8](count: 32*1024, repeatedValue: 0)
            var writeError = false

            while !writeError {
                let bytesRead = recv( self.clientSocket, &buffer, buffer.count, 0 )
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

// MARK: Cached gethostbyname()

private var hostAddressCache = [NSString:UnsafeMutablePointer<sockaddr>]()

/**
 Caching version of gethostbyname returning a sockaddr to use in a connect() call
 */
public func addressForHost( hostname: NSString, port: UInt16 ) -> sockaddr? {
    var addr: UnsafeMutablePointer<hostent> = nil
    var sockaddrTmp = hostAddressCache[hostname]?.memory
    if sockaddrTmp == nil {
        addr = gethostbyname( hostname.UTF8String )
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

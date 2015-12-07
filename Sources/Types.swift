//
//  Types.swift
//  Dynamo
//
//  Created by John Holdsworth on 07/12/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//

import Foundation

/**
    Linux can not inherit from NSObject for some reason and OSX/iOS must so...
 */

#if os(Linux)
public class _NSObject_ {
    init() {
    }
}
#else
public class _NSObject_ : NSObject {
}
#endif

/**
    Result returned by a swiftlet to indicate whether it has handled the request. If a "Content-Length"
    header has been provided the connection can be reused in the HTTP/1.1 protocol and the connection
    will be kept open and recycled.
 */

@objc public enum DynamoProcessed: Int {
    case
    NotProcessed, // does not recogise the request
    Processed, // has processed the request
    ProcessedAndReusable // "" and connection may be reused
}

/**
Basic protocol that switlets implement to pick up and process requests from a client.
*/

#if os(Linux)
public protocol DynamoSwiftlet {

    /**
        each request is presented ot each swiftlet until one indicates it has processed the request
     */
    func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed
}
#else
@objc public protocol DynamoSwiftlet {

    /**
        each request is presented ot each swiftlet until one indicates it has processed the request
     */
    func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed
}
#endif

/**
    Once a swiftlet has decided it can handle a request the headers are interpreted to extract parameters
    and cookies and any POST parameters. The web application then implements this protocol.
 */

public protocol DynamoBrowserSwiftlet: DynamoSwiftlet {

    /**
        A request can be further parsed to extract parameters, method "POST" data and cookies before processing
     */

    func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] )

}

// MARK: util definitions/functions

let INADDR_ANY = in_addr_t(0)

func htons( port: UInt16 ) -> UInt16 {
    return (port << 8) + (port >> 8)
}
let ntohs = htons

func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
}

func sockaddr_in_cast(p: UnsafeMutablePointer<sockaddr>) -> UnsafeMutablePointer<sockaddr_in> {
    return UnsafeMutablePointer<sockaddr_in>(p)
}

/** default tracer for frequent messages */
public func dynamoTrace<T>( msg: T ) {
    print( msg )
}

/** logger for server errors */
func dynamoLog<T>( msg: T ) {
#if os(Linux)
    print( "DynamoWebServer: \(msg)" )
#else
    NSLog( "DynamoWebServer: %@", "\(msg)" )
#endif
}

/** logger for low level errors */
func dynamoStrerror( msg: String ) {
#if os(Linux)
    dynamoLog( "\(msg)" )
#else
    dynamoLog( "\(msg) - \( String.fromCString( strerror(errno) )! )" )
#endif
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
        hostname.withCString { (hostString) in
            addr = gethostbyname( hostString )
        }
        if addr == nil {
            #if os(Linux)
                dynamoLog( "Could not resolve \(hostname)" )
            #else
                dynamoLog( "Could not resolve \(hostname) - "+String.fromCString( hstrerror(h_errno) )! )
            #endif
            return nil
        }
    }

    if sockaddrTmp == nil {
        let sockaddrPtr = UnsafeMutablePointer<sockaddr>(malloc(sizeof(sockaddr.self)))
        switch addr.memory.h_addrtype {

        case AF_INET:
            let addr0 = UnsafePointer<in_addr>(addr.memory.h_addr_list.memory)
            #if os(Linux)
                var ip4addr = sockaddr_in(
                    sin_family: sa_family_t(addr.memory.h_addrtype),
                    sin_port: htons( port ), sin_addr: addr0.memory,
                    sin_zero: (UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0)))
            #else
                var ip4addr = sockaddr_in(sin_len: UInt8(sizeof(sockaddr_in)),
                    sin_family: sa_family_t(addr.memory.h_addrtype),
                    sin_port: htons( port ), sin_addr: addr0.memory,
                    sin_zero: (Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0),Int8(0)))
            #endif
            sockaddrPtr.memory = sockaddr_cast(&ip4addr).memory

        case AF_INET6: // TODO... completely untested
            let addr0 = UnsafePointer<in6_addr>(addr.memory.h_addr_list.memory)
            #if os(Linux)
                var ip6addr = sockaddr_in6(
                    sin6_family: sa_family_t(addr.memory.h_addrtype),
                    sin6_port: in_port_t(htons( port )), sin6_flowinfo: 0, sin6_addr: addr0.memory,
                    sin6_scope_id: 0)
            #else
                var ip6addr = sockaddr_in6(sin6_len: UInt8(sizeof(sockaddr_in6)),
                    sin6_family: sa_family_t(addr.memory.h_addrtype),
                    sin6_port: htons( port ), sin6_flowinfo: 0, sin6_addr: addr0.memory,
                    sin6_scope_id: 0)
            #endif
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

public extension NSData {
    
    /**
     Overridden by NSData+deflate.m
     */
    func deflate() -> NSData? {
        return nil
    }
    
}
//
//  Lunix.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Linux.swift#4 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

// Hastily put together NSString/libdispatch substitutes

import Foundation


#if os(Linux)
import Glibc
//import Dispatch

let DISPATCH_QUEUE_CONCURRENT = 0, DISPATCH_QUEUE_PRIORITY_HIGH = 0

func dispatch_get_global_queue( type: Int, _ flags: Int ) -> Int {
    return type
}

func dispatch_queue_create( name: String, _ type: Int ) -> Int {
    return type
}

func dispatch_async( queue: Int, _ block: () -> () ) {
    block()
}

let NSUTF8StringEncoding = 0

private let O = "0".ord, A = "A".ord, percent = "%".ord

private func unhex( char: Int8 ) -> Int8 {
    return char < A ? char - O : char - A + 10
}

extension String {

    var ord: Int8 {
        return Int8(utf8.first!)
    }

    var stringByRemovingPercentEncoding: String? {
        var arr = [Int8]( count: 100000, repeatedValue: 0 )
        var out = UnsafeMutablePointer<Int8>( arr )

        self.withCString { (bytes) in
            var bytes = UnsafeMutablePointer<Int8>(bytes)

            while out < &arr + arr.count {
                let start = strchr( bytes, Int32(percent) ) - UnsafeMutablePointer<Int8>( bytes )
                if start < 0 {
                    strcat( out, bytes )
                    break
                }

                bytes[start] = 0
                strcat( out, bytes )
                bytes += start + 3
                out += start + 1
                out[-1] = (unhex( bytes[-2] ) << 4) + unhex( bytes[-1] )
            }
        }

        return String.fromCString( arr )
    }

    func stringByAddingPercentEscapesUsingEncoding( encoding: Int ) -> String? {
        return self
    }

    func stringByTrimmingCharactersInSet( cset: NSCharacterSet ) -> String {
        return self
    }
    
    func componentsSeparatedByString( sep: String ) -> [String] {
        var out = [String]()

        self.withCString { (bytes) in
            sep.withCString { (sbytes) in
                var bytes = UnsafeMutablePointer<Int8>( bytes )

                while true {
                    let start = strstr( bytes, sbytes ) - UnsafeMutablePointer<Int8>( bytes )
                    if start < 0 {
                        out.append( String.fromCString( bytes )! )
                        break
                    }
                    bytes[start] = 0
                    out.append( String.fromCString( bytes )! )
                    bytes = bytes + start + Int(strlen( sbytes ))
                }
            }
        }

        return out
    }

    func stringByReplacingOccurrencesOfString( str1: String, withString str2: String ) -> String {
        return self.componentsSeparatedByString( str1 ).joinWithSeparator( str2 )
    }

    func rangeOfString( str: String ) -> Range<Int>? {
        var start = -1
        self.withCString { (bytes) in
            str.withCString { (sbytes) in
                start = strstr( bytes, sbytes ) - UnsafeMutablePointer<Int8>( bytes )
            }
        }
        return start < 0 ? nil : start..<start+str.utf8.count
    }

    func substringToIndex( index: Int ) -> String {
        var out = self
        self.withCString { (bytes) in
            let bytes = UnsafeMutablePointer<Int8>(bytes)
            bytes[index] = 0
            out = String.fromCString( bytes )!
        }
        return out
    }
    
    func substringFromIndex( index: Int ) -> String {
        var out = self
        self.withCString { (bytes) in
            out = String.fromCString( bytes+index )!
        }
        return out
    }
    
}

// Linux can't inherit from NSObject
public class _NSObject_ {
}
#else
public class _NSObject_ : NSObject {
}
#endif

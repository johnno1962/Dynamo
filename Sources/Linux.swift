//
//  Lunix.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Linux.swift#1 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

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

extension String {

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
        //???return split( self, maxSplit: 100000, isSeparator: { $0 == sep } )
    }

    func rangeOfString( str: String ) -> Range<Int>? {
        var start = -1
        self.withCString { (bytes) in
            str.withCString { (sbytes) in
                start = strstr( bytes, sbytes ) - UnsafeMutablePointer<Int8>( bytes )
            }
        }
        if start < 0 {
            return nil
        }
        return start..<start+str.utf8.count
    }

    func stringByReplacingOccurrencesOfString( str1: String, withString str2: String ) -> String {
        let arr = [Int8]( count: 100000, repeatedValue: 0 )
        let out = UnsafeMutablePointer<Int8>( arr )

        self.withCString { (bytes) in
            var bytes = bytes
            str1.withCString { (bytes1) in
                str2.withCString { (bytes2) in

                    while true {
                        let start = strstr( bytes, bytes1 ) - UnsafeMutablePointer<Int8>( bytes )
                        if start < 0 {
                            strcat( out, bytes )
                            break
                        }
                        strcat( out, bytes )
                        strcat( out, bytes2 )
                        bytes = bytes + start + Int(strlen( bytes1 )) + Int(strlen( bytes2 ))
                    }
                }
            }
        }
        
        //print( self ) print( String.fromCString( out )! )
        return String.fromCString( out )!
    }
    
    var stringByRemovingPercentEncoding: String? {
        return self
    }
    
    func stringByAddingPercentEscapesUsingEncoding( encoding: Int ) -> String? {
        return self
    }
    
    func stringByTrimmingCharactersInSet( cset: NSCharacterSet ) -> String {
        return self
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

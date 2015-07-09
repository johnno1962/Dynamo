#!/usr/bin/env python

#  compiler.py
#  Dynamo
#
#  Created by John Holdsworth on 18/06/2015.
#  Copyright (c) 2015 John Holdsworth. All rights reserved.


import os
import re

productName = os.getenv( "PRODUCT_NAME" )

imports = ""
props = ""
code = {}
match = 0

file = open( productName+".shtml", "r" )
stml = file.read()

def replacer(m):
    global imports, props, match, code
    out = "";
    content = m.group(2)
    if m.group(1) == '@':
        imports += content
    elif m.group(1) == '!':
        props += content
    elif m.group(1) == '=':
        out = "__%d__" % match
        code[out] = "\"\nresponse += %s\nresponse += \"" % content
        match = match + 1
    else:
        out = "__%d__" % match
        code[out] = "\"\n%s\nresponse += \"" % content
        match = match + 1
    return out;

stml = re.sub( r"<%(@|!|=|)(.*?)%>\n?", replacer, stml, 0, re.DOTALL )
stml = re.sub( r"(\"|\\(?!\())", r"\\\1", stml )
stml = re.sub( r"\r", r"\\r", stml )
stml = re.sub( r"\n", r"\\n", stml )

for key in code:
    stml = re.sub( key, code[key], stml )

file = open( productName+".swift", "w" )
file.write( '''
// compiled from %s.shtml

import Foundation
#if os(OSX)
import Dynamo
#endif

%s

@objc (%sProcessor)
public class %sProcessor: DynamoSessionBasedApplication {

%s

    override public func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        var response = ""

        response += "%s"
        
        out.response( response )
    }

}

''' % (productName, imports, productName, productName, props, stml) )

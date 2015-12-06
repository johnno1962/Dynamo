//
//  Example.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/07/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Example.swift#1 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: Example web application

/**
    Example web application or "swiftlet" testing form sbumission.
 */

public class ExampleAppSwiftlet: HTMLApplicationSwiftlet {

    /**
        This is the entry point for most application swiftlets after browser parameters have been parsed.
     */

    override public func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        out.print( html( nil ) + head( title( "Table Example" ) +
            style( "body, table { font: 10pt Arial" ) ) + body( nil ) )

        if parameters["width"] == nil {
            out.print( h3( "Quick table creation example" ) )
            out.print(
                form( ["method":"GET"],
                    table(
                        tr( td( "Title: " ) + td( input( ["type":"textfield", "name":"title"] ) ) ) +
                        tr( td( "Width: " ) + td( input( ["type":"textfield", "name":"width"] ) ) ) +
                        tr( td( "Height: " ) + td( input( ["type":"textfield", "name":"height"] ) ) ) +
                        tr( td( ["colspan":"2"], input( ["type": "submit", "value": "Generate"] )) )
                    )
                )
            )
        }
        else if out.method == "GET" {
            if let title = parameters["title"] {
                out.print( h2( title ) )
            }

            out.print( h3( "Enter table values" ) + form( ["method": "POST"], nil ) + table( nil ) )

            if let width = parameters["width"]?.toInt(), height = parameters["height"]?.toInt() {
                for y in 0..<height {
                    out.print( tr( nil ) )
                    for x in 0..<width {
                        out.print( td( input( ["type":"textfield", "name":"x\(x)y\(y)", "size":"5"] ) ) )
                    }
                    out.print( _tr() )
                }
            }

            out.print( _table()+p()+input( ["type": "submit", "value": "Complete"] )+_form() )
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

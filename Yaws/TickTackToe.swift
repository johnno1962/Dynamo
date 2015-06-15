//
//  TickTackToe.swift
//  Yaws
//
//  Created by John Holdsworth on 13/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

import Foundation

private class TickTackGameEngine {

    var board = [["white", "white", "white"], ["white", "white", "white"], ["white", "white", "white"]]

    func winner() -> String? {
        var won: String?

        let middle = board[1][1]
        if board[1][0] == middle && middle == board[1][2] ||
            board[0][1] == middle && middle == board[2][1] ||
            board[0][0] == middle && middle == board[2][2] ||
            board[0][2] == middle && middle == board[2][0] {
                if middle != "white" {
                    won = middle
                }
        }
        if board[0][0] == board[0][1] && board[0][1] == board[0][2] ||
            board[0][0] == board[1][0] && board[1][0] == board[2][0] {
                if board[0][0] != "white" {
                    won = board[0][0]
                }
        }
        if board[0][2] == board[1][2] && board[1][2] == board[2][2] ||
            board[2][0] == board[2][1] && board[2][1] == board[2][2] {
                if board[2][2] != "white" {
                    won = board[2][2]
                }
        }

        return won
    }

}

public class TickTackToe: YawsHTMLAppProcessor {

    private var engine = TickTackGameEngine()

    public init() {
        super.init( pathPrefix: "/ticktacktoe" )
    }

    override public func processRequest( out: YawsHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        var cookies = cookies

        let webDateFormatter = NSDateFormatter()
        webDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        out.addHeader( "Date", value: webDateFormatter.stringFromDate( NSDate() ) )

        // reset board and keep scores
        if let whoWon = parameters["reset"] {
            engine = TickTackGameEngine()
            if whoWon != "draw" {
                let newCount = cookies[whoWon] ?? "0"
                let newValue = "\(newCount.toInt()!+1)"
                out.setCookie( whoWon, value: newValue, expires: 60 )
                cookies[whoWon] = newValue
            }
        }

        let scores = ", ".join( cookies.keys.map( { "\($0) wins: \(cookies[$0]!)" } ) )

        out.print( html( nil ) + head( title( "Table Example" ) +
            style( "body, table { font: 10pt Arial; } " +
                    "table { border: 4px outset; } " +
                    "td { border: 4px inset; }" ) ) + body( nil ) +
            h3( "Tick Tack Toe "+scores ) )

        // make move
        var player = parameters["player"] ?? "green"

        if let x = parameters["x"]?.toInt(), y = parameters["y"]?.toInt() {
            engine.board[y][x] = player
        }

        // print board
        let nextPlayer = player == "green" ? "red" : "green"
        var played = 0

        out.print( center( nil ) + table( nil ) )

        for y in 0..<3 {
            out.print( tr( nil ) )
            for x in 0..<3 {
                var attrs = ["bgcolor":engine.board[y][x], "width":"100", "height":"100"]
                if engine.board[y][x] != "white" {
                    played++
                } else {
                    attrs["onclick"] = "document.location.replace( '\(pathInfo)?player=\(nextPlayer)&x=\(x)&y=\(y)' );"
                }
                out.print( td( attrs, "&nbsp;" ) )
            }
            out.print( _tr() )
        }

        out.print( _table() )

        // check for winner
        var won = engine.winner()

        if won != nil {
            out.print( script( "alert( '\(player) wins' ); document.location.href = '/ticktacktoe?reset=\(won!)';" ) )
        }
        else if played == 9 {
            out.print( script( "alert( 'It\\'s a draw!' ); document.location.href = '/ticktacktoe?reset=draw';" ) )
        }

        out.print( backButton() )
    }

}

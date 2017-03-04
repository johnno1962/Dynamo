//
//  Generated.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Generated.swift#2 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: HTML Generator

private func htmlEscape( attrValue: String ) -> String {
    return attrValue
        .stringByReplacingOccurrencesOfString( "&", withString: "&amp;" )
        .stringByReplacingOccurrencesOfString( "'", withString: "&apos;" )
        .stringByReplacingOccurrencesOfString( "<", withString: "&lt;" )
        .stringByReplacingOccurrencesOfString( ">", withString: "&gt;" )
}

/**
    Generated class to ease creation of text for common HTML tags. tr( td( "text" ) )
    is converted into "<tr><td>text</td></tr>". By convention if the contents are nil
    the tag is not closed. A optional set of attributes acn be passed as a dictionary:
    a( ["href"="htp://google.com"], "link text" ) becomes "<a href='http//google.com'>link text</a>".
 */

public class HTMLApplicationSwiftlet: ApplicationSwiftlet {

    /**
        Opens and closes and HTHL tag with the specidied content. If the content is null the tag is only opened.
     */

    public final func tag( name: String, attributes: [String: String]?, _ content: String? ) -> String {
        var html = "<"+name

        if attributes != nil {
            for (name, value) in attributes! {
                html += " \(name)"
                #if os(Linux)
                    html += "='\(htmlEscape(value))'"
                #else
                    if value != NSNull() {
                        html += "='\(htmlEscape(value))'"
                    }
                #endif
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

    public final func backButton() -> String {
        return button( ["onclick":"history.back();"], "Back" )
    }

    public final func _DOCTYPE( content: String? = "" ) -> String {
        return tag( "!DOCTYPE", attributes: nil, content )
    }
    public final func _DOCTYPE( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "!DOCTYPE", attributes: attributes, content )
    }

    public final func a( content: String? = "" ) -> String {
        return tag( "a", attributes: nil, content )
    }
    public final func a( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "a", attributes: attributes, content )
    }
    public final func _a() -> String {
        return "</a>"
    }
    public final func abbr( content: String? = "" ) -> String {
        return tag( "abbr", attributes: nil, content )
    }
    public final func abbr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "abbr", attributes: attributes, content )
    }
    public final func _abbr() -> String {
        return "</abbr>"
    }
    public final func acronym( content: String? = "" ) -> String {
        return tag( "acronym", attributes: nil, content )
    }
    public final func acronym( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "acronym", attributes: attributes, content )
    }
    public final func _acronym() -> String {
        return "</acronym>"
    }
    public final func address( content: String? = "" ) -> String {
        return tag( "address", attributes: nil, content )
    }
    public final func address( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "address", attributes: attributes, content )
    }
    public final func _address() -> String {
        return "</address>"
    }
    public final func applet( content: String? = "" ) -> String {
        return tag( "applet", attributes: nil, content )
    }
    public final func applet( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "applet", attributes: attributes, content )
    }
    public final func _applet() -> String {
        return "</applet>"
    }
    public final func area( content: String? = "" ) -> String {
        return tag( "area", attributes: nil, content )
    }
    public final func area( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "area", attributes: attributes, content )
    }
    public final func _area() -> String {
        return "</area>"
    }
    public final func article( content: String? = "" ) -> String {
        return tag( "article", attributes: nil, content )
    }
    public final func article( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "article", attributes: attributes, content )
    }
    public final func _article() -> String {
        return "</article>"
    }
    public final func aside( content: String? = "" ) -> String {
        return tag( "aside", attributes: nil, content )
    }
    public final func aside( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "aside", attributes: attributes, content )
    }
    public final func _aside() -> String {
        return "</aside>"
    }
    public final func audio( content: String? = "" ) -> String {
        return tag( "audio", attributes: nil, content )
    }
    public final func audio( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "audio", attributes: attributes, content )
    }
    public final func _audio() -> String {
        return "</audio>"
    }
    public final func b( content: String? = "" ) -> String {
        return tag( "b", attributes: nil, content )
    }
    public final func b( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "b", attributes: attributes, content )
    }
    public final func _b() -> String {
        return "</b>"
    }
    public final func base( content: String? = "" ) -> String {
        return tag( "base", attributes: nil, content )
    }
    public final func base( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "base", attributes: attributes, content )
    }
    public final func _base() -> String {
        return "</base>"
    }
    public final func basefont( content: String? = "" ) -> String {
        return tag( "basefont", attributes: nil, content )
    }
    public final func basefont( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "basefont", attributes: attributes, content )
    }
    public final func _basefont() -> String {
        return "</basefont>"
    }
    public final func bdi( content: String? = "" ) -> String {
        return tag( "bdi", attributes: nil, content )
    }
    public final func bdi( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "bdi", attributes: attributes, content )
    }
    public final func _bdi() -> String {
        return "</bdi>"
    }
    public final func bdo( content: String? = "" ) -> String {
        return tag( "bdo", attributes: nil, content )
    }
    public final func bdo( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "bdo", attributes: attributes, content )
    }
    public final func _bdo() -> String {
        return "</bdo>"
    }
    public final func big( content: String? = "" ) -> String {
        return tag( "big", attributes: nil, content )
    }
    public final func big( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "big", attributes: attributes, content )
    }
    public final func _big() -> String {
        return "</big>"
    }
    public final func blockquote( content: String? = "" ) -> String {
        return tag( "blockquote", attributes: nil, content )
    }
    public final func blockquote( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "blockquote", attributes: attributes, content )
    }
    public final func _blockquote() -> String {
        return "</blockquote>"
    }
    public final func body( content: String? = "" ) -> String {
        return tag( "body", attributes: nil, content )
    }
    public final func body( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "body", attributes: attributes, content )
    }
    public final func _body() -> String {
        return "</body>"
    }
    public final func br( content: String? = "" ) -> String {
        return tag( "br", attributes: nil, content )
    }
    public final func br( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "br", attributes: attributes, content )
    }
    public final func _br() -> String {
        return "</br>"
    }
    public final func button( content: String? = "" ) -> String {
        return tag( "button", attributes: nil, content )
    }
    public final func button( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "button", attributes: attributes, content )
    }
    public final func _button() -> String {
        return "</button>"
    }
    public final func canvas( content: String? = "" ) -> String {
        return tag( "canvas", attributes: nil, content )
    }
    public final func canvas( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "canvas", attributes: attributes, content )
    }
    public final func _canvas() -> String {
        return "</canvas>"
    }
    public final func caption( content: String? = "" ) -> String {
        return tag( "caption", attributes: nil, content )
    }
    public final func caption( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "caption", attributes: attributes, content )
    }
    public final func _caption() -> String {
        return "</caption>"
    }
    public final func center( content: String? = "" ) -> String {
        return tag( "center", attributes: nil, content )
    }
    public final func center( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "center", attributes: attributes, content )
    }
    public final func _center() -> String {
        return "</center>"
    }
    public final func cite( content: String? = "" ) -> String {
        return tag( "cite", attributes: nil, content )
    }
    public final func cite( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "cite", attributes: attributes, content )
    }
    public final func _cite() -> String {
        return "</cite>"
    }
    public final func code( content: String? = "" ) -> String {
        return tag( "code", attributes: nil, content )
    }
    public final func code( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "code", attributes: attributes, content )
    }
    public final func _code() -> String {
        return "</code>"
    }
    public final func col( content: String? = "" ) -> String {
        return tag( "col", attributes: nil, content )
    }
    public final func col( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "col", attributes: attributes, content )
    }
    public final func _col() -> String {
        return "</col>"
    }
    public final func colgroup( content: String? = "" ) -> String {
        return tag( "colgroup", attributes: nil, content )
    }
    public final func colgroup( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "colgroup", attributes: attributes, content )
    }
    public final func _colgroup() -> String {
        return "</colgroup>"
    }
    public final func datalist( content: String? = "" ) -> String {
        return tag( "datalist", attributes: nil, content )
    }
    public final func datalist( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "datalist", attributes: attributes, content )
    }
    public final func _datalist() -> String {
        return "</datalist>"
    }
    public final func dd( content: String? = "" ) -> String {
        return tag( "dd", attributes: nil, content )
    }
    public final func dd( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dd", attributes: attributes, content )
    }
    public final func _dd() -> String {
        return "</dd>"
    }
    public final func del( content: String? = "" ) -> String {
        return tag( "del", attributes: nil, content )
    }
    public final func del( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "del", attributes: attributes, content )
    }
    public final func _del() -> String {
        return "</del>"
    }
    public final func details( content: String? = "" ) -> String {
        return tag( "details", attributes: nil, content )
    }
    public final func details( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "details", attributes: attributes, content )
    }
    public final func _details() -> String {
        return "</details>"
    }
    public final func dfn( content: String? = "" ) -> String {
        return tag( "dfn", attributes: nil, content )
    }
    public final func dfn( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dfn", attributes: attributes, content )
    }
    public final func _dfn() -> String {
        return "</dfn>"
    }
    public final func dialog( content: String? = "" ) -> String {
        return tag( "dialog", attributes: nil, content )
    }
    public final func dialog( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dialog", attributes: attributes, content )
    }
    public final func _dialog() -> String {
        return "</dialog>"
    }
    public final func dir( content: String? = "" ) -> String {
        return tag( "dir", attributes: nil, content )
    }
    public final func dir( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dir", attributes: attributes, content )
    }
    public final func _dir() -> String {
        return "</dir>"
    }
    public final func div( content: String? = "" ) -> String {
        return tag( "div", attributes: nil, content )
    }
    public final func div( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "div", attributes: attributes, content )
    }
    public final func _div() -> String {
        return "</div>"
    }
    public final func dl( content: String? = "" ) -> String {
        return tag( "dl", attributes: nil, content )
    }
    public final func dl( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dl", attributes: attributes, content )
    }
    public final func _dl() -> String {
        return "</dl>"
    }
    public final func dt( content: String? = "" ) -> String {
        return tag( "dt", attributes: nil, content )
    }
    public final func dt( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dt", attributes: attributes, content )
    }
    public final func _dt() -> String {
        return "</dt>"
    }
    public final func em( content: String? = "" ) -> String {
        return tag( "em", attributes: nil, content )
    }
    public final func em( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "em", attributes: attributes, content )
    }
    public final func _em() -> String {
        return "</em>"
    }
    public final func embed( content: String? = "" ) -> String {
        return tag( "embed", attributes: nil, content )
    }
    public final func embed( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "embed", attributes: attributes, content )
    }
    public final func _embed() -> String {
        return "</embed>"
    }
    public final func fieldset( content: String? = "" ) -> String {
        return tag( "fieldset", attributes: nil, content )
    }
    public final func fieldset( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "fieldset", attributes: attributes, content )
    }
    public final func _fieldset() -> String {
        return "</fieldset>"
    }
    public final func figcaption( content: String? = "" ) -> String {
        return tag( "figcaption", attributes: nil, content )
    }
    public final func figcaption( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "figcaption", attributes: attributes, content )
    }
    public final func _figcaption() -> String {
        return "</figcaption>"
    }
    public final func figure( content: String? = "" ) -> String {
        return tag( "figure", attributes: nil, content )
    }
    public final func figure( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "figure", attributes: attributes, content )
    }
    public final func _figure() -> String {
        return "</figure>"
    }
    public final func font( content: String? = "" ) -> String {
        return tag( "font", attributes: nil, content )
    }
    public final func font( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "font", attributes: attributes, content )
    }
    public final func _font() -> String {
        return "</font>"
    }
    public final func footer( content: String? = "" ) -> String {
        return tag( "footer", attributes: nil, content )
    }
    public final func footer( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "footer", attributes: attributes, content )
    }
    public final func _footer() -> String {
        return "</footer>"
    }
    public final func form( content: String? = "" ) -> String {
        return tag( "form", attributes: nil, content )
    }
    public final func form( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "form", attributes: attributes, content )
    }
    public final func _form() -> String {
        return "</form>"
    }
    public final func frame( content: String? = "" ) -> String {
        return tag( "frame", attributes: nil, content )
    }
    public final func frame( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "frame", attributes: attributes, content )
    }
    public final func _frame() -> String {
        return "</frame>"
    }
    public final func frameset( content: String? = "" ) -> String {
        return tag( "frameset", attributes: nil, content )
    }
    public final func frameset( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "frameset", attributes: attributes, content )
    }
    public final func _frameset() -> String {
        return "</frameset>"
    }
    public final func h1( content: String? = "" ) -> String {
        return tag( "h1", attributes: nil, content )
    }
    public final func h1( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h1", attributes: attributes, content )
    }
    public final func _h1() -> String {
        return "</h1>"
    }
    public final func h2( content: String? = "" ) -> String {
        return tag( "h2", attributes: nil, content )
    }
    public final func h2( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h2", attributes: attributes, content )
    }
    public final func _h2() -> String {
        return "</h2>"
    }
    public final func h3( content: String? = "" ) -> String {
        return tag( "h3", attributes: nil, content )
    }
    public final func h3( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h3", attributes: attributes, content )
    }
    public final func _h3() -> String {
        return "</h3>"
    }
    public final func h4( content: String? = "" ) -> String {
        return tag( "h4", attributes: nil, content )
    }
    public final func h4( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h4", attributes: attributes, content )
    }
    public final func _h4() -> String {
        return "</h4>"
    }
    public final func h5( content: String? = "" ) -> String {
        return tag( "h5", attributes: nil, content )
    }
    public final func h5( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h5", attributes: attributes, content )
    }
    public final func _h5() -> String {
        return "</h5>"
    }
    public final func h6( content: String? = "" ) -> String {
        return tag( "h6", attributes: nil, content )
    }
    public final func h6( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h6", attributes: attributes, content )
    }
    public final func _h6() -> String {
        return "</h6>"
    }
    public final func head( content: String? = "" ) -> String {
        return tag( "head", attributes: nil, content )
    }
    public final func head( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "head", attributes: attributes, content )
    }
    public final func _head() -> String {
        return "</head>"
    }
    public final func header( content: String? = "" ) -> String {
        return tag( "header", attributes: nil, content )
    }
    public final func header( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "header", attributes: attributes, content )
    }
    public final func _header() -> String {
        return "</header>"
    }
    public final func hr( content: String? = "" ) -> String {
        return tag( "hr", attributes: nil, content )
    }
    public final func hr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "hr", attributes: attributes, content )
    }
    public final func _hr() -> String {
        return "</hr>"
    }
    public final func html( content: String? = "" ) -> String {
        return tag( "html", attributes: nil, content )
    }
    public final func html( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "html", attributes: attributes, content )
    }
    public final func _html() -> String {
        return "</html>"
    }
    public final func i( content: String? = "" ) -> String {
        return tag( "i", attributes: nil, content )
    }
    public final func i( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "i", attributes: attributes, content )
    }
    public final func _i() -> String {
        return "</i>"
    }
    public final func iframe( content: String? = "" ) -> String {
        return tag( "iframe", attributes: nil, content )
    }
    public final func iframe( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "iframe", attributes: attributes, content )
    }
    public final func _iframe() -> String {
        return "</iframe>"
    }
    public final func img( content: String? = "" ) -> String {
        return tag( "img", attributes: nil, content )
    }
    public final func img( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "img", attributes: attributes, content )
    }
    public final func _img() -> String {
        return "</img>"
    }
    public final func input( content: String? = "" ) -> String {
        return tag( "input", attributes: nil, content )
    }
    public final func input( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "input", attributes: attributes, content )
    }
    public final func _input() -> String {
        return "</input>"
    }
    public final func ins( content: String? = "" ) -> String {
        return tag( "ins", attributes: nil, content )
    }
    public final func ins( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ins", attributes: attributes, content )
    }
    public final func _ins() -> String {
        return "</ins>"
    }
    public final func kbd( content: String? = "" ) -> String {
        return tag( "kbd", attributes: nil, content )
    }
    public final func kbd( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "kbd", attributes: attributes, content )
    }
    public final func _kbd() -> String {
        return "</kbd>"
    }
    public final func keygen( content: String? = "" ) -> String {
        return tag( "keygen", attributes: nil, content )
    }
    public final func keygen( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "keygen", attributes: attributes, content )
    }
    public final func _keygen() -> String {
        return "</keygen>"
    }
    public final func label( content: String? = "" ) -> String {
        return tag( "label", attributes: nil, content )
    }
    public final func label( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "label", attributes: attributes, content )
    }
    public final func _label() -> String {
        return "</label>"
    }
    public final func legend( content: String? = "" ) -> String {
        return tag( "legend", attributes: nil, content )
    }
    public final func legend( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "legend", attributes: attributes, content )
    }
    public final func _legend() -> String {
        return "</legend>"
    }
    public final func li( content: String? = "" ) -> String {
        return tag( "li", attributes: nil, content )
    }
    public final func li( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "li", attributes: attributes, content )
    }
    public final func _li() -> String {
        return "</li>"
    }
    public final func link( content: String? = "" ) -> String {
        return tag( "link", attributes: nil, content )
    }
    public final func link( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "link", attributes: attributes, content )
    }
    public final func _link() -> String {
        return "</link>"
    }
    public final func main( content: String? = "" ) -> String {
        return tag( "main", attributes: nil, content )
    }
    public final func main( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "main", attributes: attributes, content )
    }
    public final func _main() -> String {
        return "</main>"
    }
    public final func map( content: String? = "" ) -> String {
        return tag( "map", attributes: nil, content )
    }
    public final func map( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "map", attributes: attributes, content )
    }
    public final func _map() -> String {
        return "</map>"
    }
    public final func mark( content: String? = "" ) -> String {
        return tag( "mark", attributes: nil, content )
    }
    public final func mark( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "mark", attributes: attributes, content )
    }
    public final func _mark() -> String {
        return "</mark>"
    }
    public final func menu( content: String? = "" ) -> String {
        return tag( "menu", attributes: nil, content )
    }
    public final func menu( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "menu", attributes: attributes, content )
    }
    public final func _menu() -> String {
        return "</menu>"
    }
    public final func menuitem( content: String? = "" ) -> String {
        return tag( "menuitem", attributes: nil, content )
    }
    public final func menuitem( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "menuitem", attributes: attributes, content )
    }
    public final func _menuitem() -> String {
        return "</menuitem>"
    }
    public final func meta( content: String? = "" ) -> String {
        return tag( "meta", attributes: nil, content )
    }
    public final func meta( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "meta", attributes: attributes, content )
    }
    public final func _meta() -> String {
        return "</meta>"
    }
    public final func meter( content: String? = "" ) -> String {
        return tag( "meter", attributes: nil, content )
    }
    public final func meter( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "meter", attributes: attributes, content )
    }
    public final func _meter() -> String {
        return "</meter>"
    }
    public final func nav( content: String? = "" ) -> String {
        return tag( "nav", attributes: nil, content )
    }
    public final func nav( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "nav", attributes: attributes, content )
    }
    public final func _nav() -> String {
        return "</nav>"
    }
    public final func noframes( content: String? = "" ) -> String {
        return tag( "noframes", attributes: nil, content )
    }
    public final func noframes( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "noframes", attributes: attributes, content )
    }
    public final func _noframes() -> String {
        return "</noframes>"
    }
    public final func noscript( content: String? = "" ) -> String {
        return tag( "noscript", attributes: nil, content )
    }
    public final func noscript( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "noscript", attributes: attributes, content )
    }
    public final func _noscript() -> String {
        return "</noscript>"
    }
    public final func object( content: String? = "" ) -> String {
        return tag( "object", attributes: nil, content )
    }
    public final func object( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "object", attributes: attributes, content )
    }
    public final func _object() -> String {
        return "</object>"
    }
    public final func ol( content: String? = "" ) -> String {
        return tag( "ol", attributes: nil, content )
    }
    public final func ol( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ol", attributes: attributes, content )
    }
    public final func _ol() -> String {
        return "</ol>"
    }
    public final func optgroup( content: String? = "" ) -> String {
        return tag( "optgroup", attributes: nil, content )
    }
    public final func optgroup( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "optgroup", attributes: attributes, content )
    }
    public final func _optgroup() -> String {
        return "</optgroup>"
    }
    public final func option( content: String? = "" ) -> String {
        return tag( "option", attributes: nil, content )
    }
    public final func option( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "option", attributes: attributes, content )
    }
    public final func _option() -> String {
        return "</option>"
    }
    public final func output( content: String? = "" ) -> String {
        return tag( "output", attributes: nil, content )
    }
    public final func output( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "output", attributes: attributes, content )
    }
    public final func _output() -> String {
        return "</output>"
    }
    public final func p( content: String? = "" ) -> String {
        return tag( "p", attributes: nil, content )
    }
    public final func p( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "p", attributes: attributes, content )
    }
    public final func _p() -> String {
        return "</p>"
    }
    public final func param( content: String? = "" ) -> String {
        return tag( "param", attributes: nil, content )
    }
    public final func param( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "param", attributes: attributes, content )
    }
    public final func _param() -> String {
        return "</param>"
    }
    public final func pre( content: String? = "" ) -> String {
        return tag( "pre", attributes: nil, content )
    }
    public final func pre( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "pre", attributes: attributes, content )
    }
    public final func _pre() -> String {
        return "</pre>"
    }
    public final func progress( content: String? = "" ) -> String {
        return tag( "progress", attributes: nil, content )
    }
    public final func progress( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "progress", attributes: attributes, content )
    }
    public final func _progress() -> String {
        return "</progress>"
    }
    public final func q( content: String? = "" ) -> String {
        return tag( "q", attributes: nil, content )
    }
    public final func q( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "q", attributes: attributes, content )
    }
    public final func _q() -> String {
        return "</q>"
    }
    public final func rp( content: String? = "" ) -> String {
        return tag( "rp", attributes: nil, content )
    }
    public final func rp( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "rp", attributes: attributes, content )
    }
    public final func _rp() -> String {
        return "</rp>"
    }
    public final func rt( content: String? = "" ) -> String {
        return tag( "rt", attributes: nil, content )
    }
    public final func rt( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "rt", attributes: attributes, content )
    }
    public final func _rt() -> String {
        return "</rt>"
    }
    public final func ruby( content: String? = "" ) -> String {
        return tag( "ruby", attributes: nil, content )
    }
    public final func ruby( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ruby", attributes: attributes, content )
    }
    public final func _ruby() -> String {
        return "</ruby>"
    }
    public final func s( content: String? = "" ) -> String {
        return tag( "s", attributes: nil, content )
    }
    public final func s( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "s", attributes: attributes, content )
    }
    public final func _s() -> String {
        return "</s>"
    }
    public final func samp( content: String? = "" ) -> String {
        return tag( "samp", attributes: nil, content )
    }
    public final func samp( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "samp", attributes: attributes, content )
    }
    public final func _samp() -> String {
        return "</samp>"
    }
    public final func script( content: String? = "" ) -> String {
        return tag( "script", attributes: nil, content )
    }
    public final func script( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "script", attributes: attributes, content )
    }
    public final func _script() -> String {
        return "</script>"
    }
    public final func section( content: String? = "" ) -> String {
        return tag( "section", attributes: nil, content )
    }
    public final func section( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "section", attributes: attributes, content )
    }
    public final func _section() -> String {
        return "</section>"
    }
    public final func Select( content: String? = "" ) -> String {
        return tag( "select", attributes: nil, content )
    }
    public final func select( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "select", attributes: attributes, content )
    }
    public final func _select() -> String {
        return "</select>"
    }
    public final func small( content: String? = "" ) -> String {
        return tag( "small", attributes: nil, content )
    }
    public final func small( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "small", attributes: attributes, content )
    }
    public final func _small() -> String {
        return "</small>"
    }
    public final func source( content: String? = "" ) -> String {
        return tag( "source", attributes: nil, content )
    }
    public final func source( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "source", attributes: attributes, content )
    }
    public final func _source() -> String {
        return "</source>"
    }
    public final func span( content: String? = "" ) -> String {
        return tag( "span", attributes: nil, content )
    }
    public final func span( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "span", attributes: attributes, content )
    }
    public final func _span() -> String {
        return "</span>"
    }
    public final func strike( content: String? = "" ) -> String {
        return tag( "strike", attributes: nil, content )
    }
    public final func strike( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "strike", attributes: attributes, content )
    }
    public final func _strike() -> String {
        return "</strike>"
    }
    public final func strong( content: String? = "" ) -> String {
        return tag( "strong", attributes: nil, content )
    }
    public final func strong( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "strong", attributes: attributes, content )
    }
    public final func _strong() -> String {
        return "</strong>"
    }
    public final func style( content: String? = "" ) -> String {
        return tag( "style", attributes: nil, content )
    }
    public final func style( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "style", attributes: attributes, content )
    }
    public final func _style() -> String {
        return "</style>"
    }
    public final func sub( content: String? = "" ) -> String {
        return tag( "sub", attributes: nil, content )
    }
    public final func sub( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "sub", attributes: attributes, content )
    }
    public final func _sub() -> String {
        return "</sub>"
    }
    public final func summary( content: String? = "" ) -> String {
        return tag( "summary", attributes: nil, content )
    }
    public final func summary( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "summary", attributes: attributes, content )
    }
    public final func _summary() -> String {
        return "</summary>"
    }
    public final func sup( content: String? = "" ) -> String {
        return tag( "sup", attributes: nil, content )
    }
    public final func sup( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "sup", attributes: attributes, content )
    }
    public final func _sup() -> String {
        return "</sup>"
    }
    public final func table( content: String? = "" ) -> String {
        return tag( "table", attributes: nil, content )
    }
    public final func table( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "table", attributes: attributes, content )
    }
    public final func _table() -> String {
        return "</table>"
    }
    public final func tbody( content: String? = "" ) -> String {
        return tag( "tbody", attributes: nil, content )
    }
    public final func tbody( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tbody", attributes: attributes, content )
    }
    public final func _tbody() -> String {
        return "</tbody>"
    }
    public final func td( content: String? = "" ) -> String {
        return tag( "td", attributes: nil, content )
    }
    public final func td( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "td", attributes: attributes, content )
    }
    public final func _td() -> String {
        return "</td>"
    }
    public final func textarea( content: String? = "" ) -> String {
        return tag( "textarea", attributes: nil, content )
    }
    public final func textarea( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "textarea", attributes: attributes, content )
    }
    public final func _textarea() -> String {
        return "</textarea>"
    }
    public final func tfoot( content: String? = "" ) -> String {
        return tag( "tfoot", attributes: nil, content )
    }
    public final func tfoot( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tfoot", attributes: attributes, content )
    }
    public final func _tfoot() -> String {
        return "</tfoot>"
    }
    public final func th( content: String? = "" ) -> String {
        return tag( "th", attributes: nil, content )
    }
    public final func th( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "th", attributes: attributes, content )
    }
    public final func _th() -> String {
        return "</th>"
    }
    public final func thead( content: String? = "" ) -> String {
        return tag( "thead", attributes: nil, content )
    }
    public final func thead( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "thead", attributes: attributes, content )
    }
    public final func _thead() -> String {
        return "</thead>"
    }
    public final func time( content: String? = "" ) -> String {
        return tag( "time", attributes: nil, content )
    }
    public final func time( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "time", attributes: attributes, content )
    }
    public final func _time() -> String {
        return "</time>"
    }
    public final func title( content: String? = "" ) -> String {
        return tag( "title", attributes: nil, content )
    }
    public final func title( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "title", attributes: attributes, content )
    }
    public final func _title() -> String {
        return "</title>"
    }
    public final func tr( content: String? = "" ) -> String {
        return tag( "tr", attributes: nil, content )
    }
    public final func tr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tr", attributes: attributes, content )
    }
    public final func _tr() -> String {
        return "</tr>"
    }
    public final func track( content: String? = "" ) -> String {
        return tag( "track", attributes: nil, content )
    }
    public final func track( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "track", attributes: attributes, content )
    }
    public final func _track() -> String {
        return "</track>"
    }
    public final func tt( content: String? = "" ) -> String {
        return tag( "tt", attributes: nil, content )
    }
    public final func tt( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tt", attributes: attributes, content )
    }
    public final func _tt() -> String {
        return "</tt>"
    }
    public final func u( content: String? = "" ) -> String {
        return tag( "u", attributes: nil, content )
    }
    public final func u( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "u", attributes: attributes, content )
    }
    public final func _u() -> String {
        return "</u>"
    }
    public final func ul( content: String? = "" ) -> String {
        return tag( "ul", attributes: nil, content )
    }
    public final func ul( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ul", attributes: attributes, content )
    }
    public final func _ul() -> String {
        return "</ul>"
    }
    public final func video( content: String? = "" ) -> String {
        return tag( "video", attributes: nil, content )
    }
    public final func video( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "video", attributes: attributes, content )
    }
    public final func _video() -> String {
        return "</video>"
    }
    public final func wbr( content: String? = "" ) -> String {
        return tag( "wbr", attributes: nil, content )
    }
    public final func wbr( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "wbr", attributes: attributes, content )
    }
    public final func _wbr() -> String {
        return "</wbr>"
    }

}

//
//  Generated.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Generated.swift#3 $
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

public class DynamoHTMLAppProcessor : DynamoApplicationProcessor {

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

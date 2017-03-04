//
//  Generated.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Generated.swift#3 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: HTML Generator

private func htmlEscape( _ attrValue: String ) -> String {
    return attrValue
        .replacingOccurrences( of: "&", with: "&amp;" )
        .replacingOccurrences( of: "'", with: "&apos;" )
        .replacingOccurrences( of: "<", with: "&lt;" )
        .replacingOccurrences( of: ">", with: "&gt;" )
}

/**
    Generated class to ease creation of text for common HTML tags. tr( td( "text" ) )
    is converted into "<tr><td>text</td></tr>". By convention if the contents are nil
    the tag is not closed. A optional set of attributes acn be passed as a dictionary:
    a( ["href"="htp://google.com"], "link text" ) becomes "<a href='http//google.com'>link text</a>".
 */

open class HTMLApplicationSwiftlet: ApplicationSwiftlet {

    /**
        Opens and closes and HTHL tag with the specidied content. If the content is null the tag is only opened.
     */

    public final func tag( _ name: String, attributes: [String: String]?, _ content: String? ) -> String {
        var html = "<"+name

        if attributes != nil {
            for (name, value) in attributes! {
                html += " \(name)"
                #if os(Linux)
                    html += "='\(htmlEscape(value))'"
                #else
                    if value != "NSNull()" {
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

    public final func _DOCTYPE( _ content: String? = "" ) -> String {
        return tag( "!DOCTYPE", attributes: nil, content )
    }
    public final func _DOCTYPE( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "!DOCTYPE", attributes: attributes, content )
    }

    public final func a( _ content: String? = "" ) -> String {
        return tag( "a", attributes: nil, content )
    }
    public final func a( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "a", attributes: attributes, content )
    }
    public final func _a() -> String {
        return "</a>"
    }
    public final func abbr( _ content: String? = "" ) -> String {
        return tag( "abbr", attributes: nil, content )
    }
    public final func abbr( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "abbr", attributes: attributes, content )
    }
    public final func _abbr() -> String {
        return "</abbr>"
    }
    public final func acronym( _ content: String? = "" ) -> String {
        return tag( "acronym", attributes: nil, content )
    }
    public final func acronym( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "acronym", attributes: attributes, content )
    }
    public final func _acronym() -> String {
        return "</acronym>"
    }
    public final func address( _ content: String? = "" ) -> String {
        return tag( "address", attributes: nil, content )
    }
    public final func address( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "address", attributes: attributes, content )
    }
    public final func _address() -> String {
        return "</address>"
    }
    public final func applet( _ content: String? = "" ) -> String {
        return tag( "applet", attributes: nil, content )
    }
    public final func applet( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "applet", attributes: attributes, content )
    }
    public final func _applet() -> String {
        return "</applet>"
    }
    public final func area( _ content: String? = "" ) -> String {
        return tag( "area", attributes: nil, content )
    }
    public final func area( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "area", attributes: attributes, content )
    }
    public final func _area() -> String {
        return "</area>"
    }
    public final func article( _ content: String? = "" ) -> String {
        return tag( "article", attributes: nil, content )
    }
    public final func article( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "article", attributes: attributes, content )
    }
    public final func _article() -> String {
        return "</article>"
    }
    public final func aside( _ content: String? = "" ) -> String {
        return tag( "aside", attributes: nil, content )
    }
    public final func aside( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "aside", attributes: attributes, content )
    }
    public final func _aside() -> String {
        return "</aside>"
    }
    public final func audio( _ content: String? = "" ) -> String {
        return tag( "audio", attributes: nil, content )
    }
    public final func audio( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "audio", attributes: attributes, content )
    }
    public final func _audio() -> String {
        return "</audio>"
    }
    public final func b( _ content: String? = "" ) -> String {
        return tag( "b", attributes: nil, content )
    }
    public final func b( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "b", attributes: attributes, content )
    }
    public final func _b() -> String {
        return "</b>"
    }
    public final func base( _ content: String? = "" ) -> String {
        return tag( "base", attributes: nil, content )
    }
    public final func base( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "base", attributes: attributes, content )
    }
    public final func _base() -> String {
        return "</base>"
    }
    public final func basefont( _ content: String? = "" ) -> String {
        return tag( "basefont", attributes: nil, content )
    }
    public final func basefont( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "basefont", attributes: attributes, content )
    }
    public final func _basefont() -> String {
        return "</basefont>"
    }
    public final func bdi( _ content: String? = "" ) -> String {
        return tag( "bdi", attributes: nil, content )
    }
    public final func bdi( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "bdi", attributes: attributes, content )
    }
    public final func _bdi() -> String {
        return "</bdi>"
    }
    public final func bdo( _ content: String? = "" ) -> String {
        return tag( "bdo", attributes: nil, content )
    }
    public final func bdo( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "bdo", attributes: attributes, content )
    }
    public final func _bdo() -> String {
        return "</bdo>"
    }
    public final func big( _ content: String? = "" ) -> String {
        return tag( "big", attributes: nil, content )
    }
    public final func big( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "big", attributes: attributes, content )
    }
    public final func _big() -> String {
        return "</big>"
    }
    public final func blockquote( _ content: String? = "" ) -> String {
        return tag( "blockquote", attributes: nil, content )
    }
    public final func blockquote( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "blockquote", attributes: attributes, content )
    }
    public final func _blockquote() -> String {
        return "</blockquote>"
    }
    public final func body( _ content: String? = "" ) -> String {
        return tag( "body", attributes: nil, content )
    }
    public final func body( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "body", attributes: attributes, content )
    }
    public final func _body() -> String {
        return "</body>"
    }
    public final func br( _ content: String? = "" ) -> String {
        return tag( "br", attributes: nil, content )
    }
    public final func br( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "br", attributes: attributes, content )
    }
    public final func _br() -> String {
        return "</br>"
    }
    public final func button( _ content: String? = "" ) -> String {
        return tag( "button", attributes: nil, content )
    }
    public final func button( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "button", attributes: attributes, content )
    }
    public final func _button() -> String {
        return "</button>"
    }
    public final func canvas( _ content: String? = "" ) -> String {
        return tag( "canvas", attributes: nil, content )
    }
    public final func canvas( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "canvas", attributes: attributes, content )
    }
    public final func _canvas() -> String {
        return "</canvas>"
    }
    public final func caption( _ content: String? = "" ) -> String {
        return tag( "caption", attributes: nil, content )
    }
    public final func caption( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "caption", attributes: attributes, content )
    }
    public final func _caption() -> String {
        return "</caption>"
    }
    public final func center( _ content: String? = "" ) -> String {
        return tag( "center", attributes: nil, content )
    }
    public final func center( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "center", attributes: attributes, content )
    }
    public final func _center() -> String {
        return "</center>"
    }
    public final func cite( _ content: String? = "" ) -> String {
        return tag( "cite", attributes: nil, content )
    }
    public final func cite( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "cite", attributes: attributes, content )
    }
    public final func _cite() -> String {
        return "</cite>"
    }
    public final func code( _ content: String? = "" ) -> String {
        return tag( "code", attributes: nil, content )
    }
    public final func code( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "code", attributes: attributes, content )
    }
    public final func _code() -> String {
        return "</code>"
    }
    public final func col( _ content: String? = "" ) -> String {
        return tag( "col", attributes: nil, content )
    }
    public final func col( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "col", attributes: attributes, content )
    }
    public final func _col() -> String {
        return "</col>"
    }
    public final func colgroup( _ content: String? = "" ) -> String {
        return tag( "colgroup", attributes: nil, content )
    }
    public final func colgroup( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "colgroup", attributes: attributes, content )
    }
    public final func _colgroup() -> String {
        return "</colgroup>"
    }
    public final func datalist( _ content: String? = "" ) -> String {
        return tag( "datalist", attributes: nil, content )
    }
    public final func datalist( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "datalist", attributes: attributes, content )
    }
    public final func _datalist() -> String {
        return "</datalist>"
    }
    public final func dd( _ content: String? = "" ) -> String {
        return tag( "dd", attributes: nil, content )
    }
    public final func dd( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dd", attributes: attributes, content )
    }
    public final func _dd() -> String {
        return "</dd>"
    }
    public final func del( _ content: String? = "" ) -> String {
        return tag( "del", attributes: nil, content )
    }
    public final func del( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "del", attributes: attributes, content )
    }
    public final func _del() -> String {
        return "</del>"
    }
    public final func details( _ content: String? = "" ) -> String {
        return tag( "details", attributes: nil, content )
    }
    public final func details( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "details", attributes: attributes, content )
    }
    public final func _details() -> String {
        return "</details>"
    }
    public final func dfn( _ content: String? = "" ) -> String {
        return tag( "dfn", attributes: nil, content )
    }
    public final func dfn( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dfn", attributes: attributes, content )
    }
    public final func _dfn() -> String {
        return "</dfn>"
    }
    public final func dialog( _ content: String? = "" ) -> String {
        return tag( "dialog", attributes: nil, content )
    }
    public final func dialog( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dialog", attributes: attributes, content )
    }
    public final func _dialog() -> String {
        return "</dialog>"
    }
    public final func dir( _ content: String? = "" ) -> String {
        return tag( "dir", attributes: nil, content )
    }
    public final func dir( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dir", attributes: attributes, content )
    }
    public final func _dir() -> String {
        return "</dir>"
    }
    public final func div( _ content: String? = "" ) -> String {
        return tag( "div", attributes: nil, content )
    }
    public final func div( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "div", attributes: attributes, content )
    }
    public final func _div() -> String {
        return "</div>"
    }
    public final func dl( _ content: String? = "" ) -> String {
        return tag( "dl", attributes: nil, content )
    }
    public final func dl( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dl", attributes: attributes, content )
    }
    public final func _dl() -> String {
        return "</dl>"
    }
    public final func dt( _ content: String? = "" ) -> String {
        return tag( "dt", attributes: nil, content )
    }
    public final func dt( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "dt", attributes: attributes, content )
    }
    public final func _dt() -> String {
        return "</dt>"
    }
    public final func em( _ content: String? = "" ) -> String {
        return tag( "em", attributes: nil, content )
    }
    public final func em( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "em", attributes: attributes, content )
    }
    public final func _em() -> String {
        return "</em>"
    }
    public final func embed( _ content: String? = "" ) -> String {
        return tag( "embed", attributes: nil, content )
    }
    public final func embed( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "embed", attributes: attributes, content )
    }
    public final func _embed() -> String {
        return "</embed>"
    }
    public final func fieldset( _ content: String? = "" ) -> String {
        return tag( "fieldset", attributes: nil, content )
    }
    public final func fieldset( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "fieldset", attributes: attributes, content )
    }
    public final func _fieldset() -> String {
        return "</fieldset>"
    }
    public final func figcaption( _ content: String? = "" ) -> String {
        return tag( "figcaption", attributes: nil, content )
    }
    public final func figcaption( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "figcaption", attributes: attributes, content )
    }
    public final func _figcaption() -> String {
        return "</figcaption>"
    }
    public final func figure( _ content: String? = "" ) -> String {
        return tag( "figure", attributes: nil, content )
    }
    public final func figure( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "figure", attributes: attributes, content )
    }
    public final func _figure() -> String {
        return "</figure>"
    }
    public final func font( _ content: String? = "" ) -> String {
        return tag( "font", attributes: nil, content )
    }
    public final func font( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "font", attributes: attributes, content )
    }
    public final func _font() -> String {
        return "</font>"
    }
    public final func footer( _ content: String? = "" ) -> String {
        return tag( "footer", attributes: nil, content )
    }
    public final func footer( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "footer", attributes: attributes, content )
    }
    public final func _footer() -> String {
        return "</footer>"
    }
    public final func form( _ content: String? = "" ) -> String {
        return tag( "form", attributes: nil, content )
    }
    public final func form( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "form", attributes: attributes, content )
    }
    public final func _form() -> String {
        return "</form>"
    }
    public final func frame( _ content: String? = "" ) -> String {
        return tag( "frame", attributes: nil, content )
    }
    public final func frame( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "frame", attributes: attributes, content )
    }
    public final func _frame() -> String {
        return "</frame>"
    }
    public final func frameset( _ content: String? = "" ) -> String {
        return tag( "frameset", attributes: nil, content )
    }
    public final func frameset( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "frameset", attributes: attributes, content )
    }
    public final func _frameset() -> String {
        return "</frameset>"
    }
    public final func h1( _ content: String? = "" ) -> String {
        return tag( "h1", attributes: nil, content )
    }
    public final func h1( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h1", attributes: attributes, content )
    }
    public final func _h1() -> String {
        return "</h1>"
    }
    public final func h2( _ content: String? = "" ) -> String {
        return tag( "h2", attributes: nil, content )
    }
    public final func h2( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h2", attributes: attributes, content )
    }
    public final func _h2() -> String {
        return "</h2>"
    }
    public final func h3( _ content: String? = "" ) -> String {
        return tag( "h3", attributes: nil, content )
    }
    public final func h3( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h3", attributes: attributes, content )
    }
    public final func _h3() -> String {
        return "</h3>"
    }
    public final func h4( _ content: String? = "" ) -> String {
        return tag( "h4", attributes: nil, content )
    }
    public final func h4( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h4", attributes: attributes, content )
    }
    public final func _h4() -> String {
        return "</h4>"
    }
    public final func h5( _ content: String? = "" ) -> String {
        return tag( "h5", attributes: nil, content )
    }
    public final func h5( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h5", attributes: attributes, content )
    }
    public final func _h5() -> String {
        return "</h5>"
    }
    public final func h6( _ content: String? = "" ) -> String {
        return tag( "h6", attributes: nil, content )
    }
    public final func h6( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "h6", attributes: attributes, content )
    }
    public final func _h6() -> String {
        return "</h6>"
    }
    public final func head( _ content: String? = "" ) -> String {
        return tag( "head", attributes: nil, content )
    }
    public final func head( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "head", attributes: attributes, content )
    }
    public final func _head() -> String {
        return "</head>"
    }
    public final func header( _ content: String? = "" ) -> String {
        return tag( "header", attributes: nil, content )
    }
    public final func header( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "header", attributes: attributes, content )
    }
    public final func _header() -> String {
        return "</header>"
    }
    public final func hr( _ content: String? = "" ) -> String {
        return tag( "hr", attributes: nil, content )
    }
    public final func hr( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "hr", attributes: attributes, content )
    }
    public final func _hr() -> String {
        return "</hr>"
    }
    public final func html( _ content: String? = "" ) -> String {
        return tag( "html", attributes: nil, content )
    }
    public final func html( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "html", attributes: attributes, content )
    }
    public final func _html() -> String {
        return "</html>"
    }
    public final func i( _ content: String? = "" ) -> String {
        return tag( "i", attributes: nil, content )
    }
    public final func i( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "i", attributes: attributes, content )
    }
    public final func _i() -> String {
        return "</i>"
    }
    public final func iframe( _ content: String? = "" ) -> String {
        return tag( "iframe", attributes: nil, content )
    }
    public final func iframe( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "iframe", attributes: attributes, content )
    }
    public final func _iframe() -> String {
        return "</iframe>"
    }
    public final func img( _ content: String? = "" ) -> String {
        return tag( "img", attributes: nil, content )
    }
    public final func img( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "img", attributes: attributes, content )
    }
    public final func _img() -> String {
        return "</img>"
    }
    public final func input( _ content: String? = "" ) -> String {
        return tag( "input", attributes: nil, content )
    }
    public final func input( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "input", attributes: attributes, content )
    }
    public final func _input() -> String {
        return "</input>"
    }
    public final func ins( _ content: String? = "" ) -> String {
        return tag( "ins", attributes: nil, content )
    }
    public final func ins( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ins", attributes: attributes, content )
    }
    public final func _ins() -> String {
        return "</ins>"
    }
    public final func kbd( _ content: String? = "" ) -> String {
        return tag( "kbd", attributes: nil, content )
    }
    public final func kbd( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "kbd", attributes: attributes, content )
    }
    public final func _kbd() -> String {
        return "</kbd>"
    }
    public final func keygen( _ content: String? = "" ) -> String {
        return tag( "keygen", attributes: nil, content )
    }
    public final func keygen( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "keygen", attributes: attributes, content )
    }
    public final func _keygen() -> String {
        return "</keygen>"
    }
    public final func label( _ content: String? = "" ) -> String {
        return tag( "label", attributes: nil, content )
    }
    public final func label( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "label", attributes: attributes, content )
    }
    public final func _label() -> String {
        return "</label>"
    }
    public final func legend( _ content: String? = "" ) -> String {
        return tag( "legend", attributes: nil, content )
    }
    public final func legend( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "legend", attributes: attributes, content )
    }
    public final func _legend() -> String {
        return "</legend>"
    }
    public final func li( _ content: String? = "" ) -> String {
        return tag( "li", attributes: nil, content )
    }
    public final func li( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "li", attributes: attributes, content )
    }
    public final func _li() -> String {
        return "</li>"
    }
    public final func link( _ content: String? = "" ) -> String {
        return tag( "link", attributes: nil, content )
    }
    public final func link( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "link", attributes: attributes, content )
    }
    public final func _link() -> String {
        return "</link>"
    }
    public final func main( _ content: String? = "" ) -> String {
        return tag( "main", attributes: nil, content )
    }
    public final func main( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "main", attributes: attributes, content )
    }
    public final func _main() -> String {
        return "</main>"
    }
    public final func map( _ content: String? = "" ) -> String {
        return tag( "map", attributes: nil, content )
    }
    public final func map( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "map", attributes: attributes, content )
    }
    public final func _map() -> String {
        return "</map>"
    }
    public final func mark( _ content: String? = "" ) -> String {
        return tag( "mark", attributes: nil, content )
    }
    public final func mark( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "mark", attributes: attributes, content )
    }
    public final func _mark() -> String {
        return "</mark>"
    }
    public final func menu( _ content: String? = "" ) -> String {
        return tag( "menu", attributes: nil, content )
    }
    public final func menu( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "menu", attributes: attributes, content )
    }
    public final func _menu() -> String {
        return "</menu>"
    }
    public final func menuitem( _ content: String? = "" ) -> String {
        return tag( "menuitem", attributes: nil, content )
    }
    public final func menuitem( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "menuitem", attributes: attributes, content )
    }
    public final func _menuitem() -> String {
        return "</menuitem>"
    }
    public final func meta( _ content: String? = "" ) -> String {
        return tag( "meta", attributes: nil, content )
    }
    public final func meta( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "meta", attributes: attributes, content )
    }
    public final func _meta() -> String {
        return "</meta>"
    }
    public final func meter( _ content: String? = "" ) -> String {
        return tag( "meter", attributes: nil, content )
    }
    public final func meter( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "meter", attributes: attributes, content )
    }
    public final func _meter() -> String {
        return "</meter>"
    }
    public final func nav( _ content: String? = "" ) -> String {
        return tag( "nav", attributes: nil, content )
    }
    public final func nav( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "nav", attributes: attributes, content )
    }
    public final func _nav() -> String {
        return "</nav>"
    }
    public final func noframes( _ content: String? = "" ) -> String {
        return tag( "noframes", attributes: nil, content )
    }
    public final func noframes( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "noframes", attributes: attributes, content )
    }
    public final func _noframes() -> String {
        return "</noframes>"
    }
    public final func noscript( _ content: String? = "" ) -> String {
        return tag( "noscript", attributes: nil, content )
    }
    public final func noscript( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "noscript", attributes: attributes, content )
    }
    public final func _noscript() -> String {
        return "</noscript>"
    }
    public final func object( _ content: String? = "" ) -> String {
        return tag( "object", attributes: nil, content )
    }
    public final func object( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "object", attributes: attributes, content )
    }
    public final func _object() -> String {
        return "</object>"
    }
    public final func ol( _ content: String? = "" ) -> String {
        return tag( "ol", attributes: nil, content )
    }
    public final func ol( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ol", attributes: attributes, content )
    }
    public final func _ol() -> String {
        return "</ol>"
    }
    public final func optgroup( _ content: String? = "" ) -> String {
        return tag( "optgroup", attributes: nil, content )
    }
    public final func optgroup( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "optgroup", attributes: attributes, content )
    }
    public final func _optgroup() -> String {
        return "</optgroup>"
    }
    public final func option( _ content: String? = "" ) -> String {
        return tag( "option", attributes: nil, content )
    }
    public final func option( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "option", attributes: attributes, content )
    }
    public final func _option() -> String {
        return "</option>"
    }
    public final func output( _ content: String? = "" ) -> String {
        return tag( "output", attributes: nil, content )
    }
    public final func output( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "output", attributes: attributes, content )
    }
    public final func _output() -> String {
        return "</output>"
    }
    public final func p( _ content: String? = "" ) -> String {
        return tag( "p", attributes: nil, content )
    }
    public final func p( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "p", attributes: attributes, content )
    }
    public final func _p() -> String {
        return "</p>"
    }
    public final func param( _ content: String? = "" ) -> String {
        return tag( "param", attributes: nil, content )
    }
    public final func param( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "param", attributes: attributes, content )
    }
    public final func _param() -> String {
        return "</param>"
    }
    public final func pre( _ content: String? = "" ) -> String {
        return tag( "pre", attributes: nil, content )
    }
    public final func pre( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "pre", attributes: attributes, content )
    }
    public final func _pre() -> String {
        return "</pre>"
    }
    public final func progress( _ content: String? = "" ) -> String {
        return tag( "progress", attributes: nil, content )
    }
    public final func progress( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "progress", attributes: attributes, content )
    }
    public final func _progress() -> String {
        return "</progress>"
    }
    public final func q( _ content: String? = "" ) -> String {
        return tag( "q", attributes: nil, content )
    }
    public final func q( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "q", attributes: attributes, content )
    }
    public final func _q() -> String {
        return "</q>"
    }
    public final func rp( _ content: String? = "" ) -> String {
        return tag( "rp", attributes: nil, content )
    }
    public final func rp( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "rp", attributes: attributes, content )
    }
    public final func _rp() -> String {
        return "</rp>"
    }
    public final func rt( _ content: String? = "" ) -> String {
        return tag( "rt", attributes: nil, content )
    }
    public final func rt( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "rt", attributes: attributes, content )
    }
    public final func _rt() -> String {
        return "</rt>"
    }
    public final func ruby( _ content: String? = "" ) -> String {
        return tag( "ruby", attributes: nil, content )
    }
    public final func ruby( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ruby", attributes: attributes, content )
    }
    public final func _ruby() -> String {
        return "</ruby>"
    }
    public final func s( _ content: String? = "" ) -> String {
        return tag( "s", attributes: nil, content )
    }
    public final func s( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "s", attributes: attributes, content )
    }
    public final func _s() -> String {
        return "</s>"
    }
    public final func samp( _ content: String? = "" ) -> String {
        return tag( "samp", attributes: nil, content )
    }
    public final func samp( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "samp", attributes: attributes, content )
    }
    public final func _samp() -> String {
        return "</samp>"
    }
    public final func script( _ content: String? = "" ) -> String {
        return tag( "script", attributes: nil, content )
    }
    public final func script( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "script", attributes: attributes, content )
    }
    public final func _script() -> String {
        return "</script>"
    }
    public final func section( _ content: String? = "" ) -> String {
        return tag( "section", attributes: nil, content )
    }
    public final func section( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "section", attributes: attributes, content )
    }
    public final func _section() -> String {
        return "</section>"
    }
    public final func Select( _ content: String? = "" ) -> String {
        return tag( "select", attributes: nil, content )
    }
    public final func select( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "select", attributes: attributes, content )
    }
    public final func _select() -> String {
        return "</select>"
    }
    public final func small( _ content: String? = "" ) -> String {
        return tag( "small", attributes: nil, content )
    }
    public final func small( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "small", attributes: attributes, content )
    }
    public final func _small() -> String {
        return "</small>"
    }
    public final func source( _ content: String? = "" ) -> String {
        return tag( "source", attributes: nil, content )
    }
    public final func source( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "source", attributes: attributes, content )
    }
    public final func _source() -> String {
        return "</source>"
    }
    public final func span( _ content: String? = "" ) -> String {
        return tag( "span", attributes: nil, content )
    }
    public final func span( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "span", attributes: attributes, content )
    }
    public final func _span() -> String {
        return "</span>"
    }
    public final func strike( _ content: String? = "" ) -> String {
        return tag( "strike", attributes: nil, content )
    }
    public final func strike( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "strike", attributes: attributes, content )
    }
    public final func _strike() -> String {
        return "</strike>"
    }
    public final func strong( _ content: String? = "" ) -> String {
        return tag( "strong", attributes: nil, content )
    }
    public final func strong( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "strong", attributes: attributes, content )
    }
    public final func _strong() -> String {
        return "</strong>"
    }
    public final func style( _ content: String? = "" ) -> String {
        return tag( "style", attributes: nil, content )
    }
    public final func style( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "style", attributes: attributes, content )
    }
    public final func _style() -> String {
        return "</style>"
    }
    public final func sub( _ content: String? = "" ) -> String {
        return tag( "sub", attributes: nil, content )
    }
    public final func sub( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "sub", attributes: attributes, content )
    }
    public final func _sub() -> String {
        return "</sub>"
    }
    public final func summary( _ content: String? = "" ) -> String {
        return tag( "summary", attributes: nil, content )
    }
    public final func summary( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "summary", attributes: attributes, content )
    }
    public final func _summary() -> String {
        return "</summary>"
    }
    public final func sup( _ content: String? = "" ) -> String {
        return tag( "sup", attributes: nil, content )
    }
    public final func sup( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "sup", attributes: attributes, content )
    }
    public final func _sup() -> String {
        return "</sup>"
    }
    public final func table( _ content: String? = "" ) -> String {
        return tag( "table", attributes: nil, content )
    }
    public final func table( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "table", attributes: attributes, content )
    }
    public final func _table() -> String {
        return "</table>"
    }
    public final func tbody( _ content: String? = "" ) -> String {
        return tag( "tbody", attributes: nil, content )
    }
    public final func tbody( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tbody", attributes: attributes, content )
    }
    public final func _tbody() -> String {
        return "</tbody>"
    }
    public final func td( _ content: String? = "" ) -> String {
        return tag( "td", attributes: nil, content )
    }
    public final func td( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "td", attributes: attributes, content )
    }
    public final func _td() -> String {
        return "</td>"
    }
    public final func textarea( _ content: String? = "" ) -> String {
        return tag( "textarea", attributes: nil, content )
    }
    public final func textarea( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "textarea", attributes: attributes, content )
    }
    public final func _textarea() -> String {
        return "</textarea>"
    }
    public final func tfoot( _ content: String? = "" ) -> String {
        return tag( "tfoot", attributes: nil, content )
    }
    public final func tfoot( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tfoot", attributes: attributes, content )
    }
    public final func _tfoot() -> String {
        return "</tfoot>"
    }
    public final func th( _ content: String? = "" ) -> String {
        return tag( "th", attributes: nil, content )
    }
    public final func th( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "th", attributes: attributes, content )
    }
    public final func _th() -> String {
        return "</th>"
    }
    public final func thead( _ content: String? = "" ) -> String {
        return tag( "thead", attributes: nil, content )
    }
    public final func thead( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "thead", attributes: attributes, content )
    }
    public final func _thead() -> String {
        return "</thead>"
    }
    public final func time( _ content: String? = "" ) -> String {
        return tag( "time", attributes: nil, content )
    }
    public final func time( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "time", attributes: attributes, content )
    }
    public final func _time() -> String {
        return "</time>"
    }
    public final func title( _ content: String? = "" ) -> String {
        return tag( "title", attributes: nil, content )
    }
    public final func title( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "title", attributes: attributes, content )
    }
    public final func _title() -> String {
        return "</title>"
    }
    public final func tr( _ content: String? = "" ) -> String {
        return tag( "tr", attributes: nil, content )
    }
    public final func tr( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tr", attributes: attributes, content )
    }
    public final func _tr() -> String {
        return "</tr>"
    }
    public final func track( _ content: String? = "" ) -> String {
        return tag( "track", attributes: nil, content )
    }
    public final func track( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "track", attributes: attributes, content )
    }
    public final func _track() -> String {
        return "</track>"
    }
    public final func tt( _ content: String? = "" ) -> String {
        return tag( "tt", attributes: nil, content )
    }
    public final func tt( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "tt", attributes: attributes, content )
    }
    public final func _tt() -> String {
        return "</tt>"
    }
    public final func u( _ content: String? = "" ) -> String {
        return tag( "u", attributes: nil, content )
    }
    public final func u( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "u", attributes: attributes, content )
    }
    public final func _u() -> String {
        return "</u>"
    }
    public final func ul( _ content: String? = "" ) -> String {
        return tag( "ul", attributes: nil, content )
    }
    public final func ul( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "ul", attributes: attributes, content )
    }
    public final func _ul() -> String {
        return "</ul>"
    }
    public final func video( _ content: String? = "" ) -> String {
        return tag( "video", attributes: nil, content )
    }
    public final func video( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "video", attributes: attributes, content )
    }
    public final func _video() -> String {
        return "</video>"
    }
    public final func wbr( _ content: String? = "" ) -> String {
        return tag( "wbr", attributes: nil, content )
    }
    public final func wbr( _ attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "wbr", attributes: attributes, content )
    }
    public final func _wbr() -> String {
        return "</wbr>"
    }

}

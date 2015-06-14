#!/usr/bin/perl
use strict;

#  gentags.pl
#  Yaws
#
#  Created by John Holdsworth on 13/06/2015.
#  Copyright (c) 2015 John Holdsworth. All rights reserved.

while ( my ($tag) = <DATA> =~ /([!\w]+)/ ) {
    print <<SWIFT;
    public func $tag( _ content: String? = "" ) -> String {
        return tag( "$tag", attributes: nil, content: content )
    }
    public func $tag( attributes: [String: String], _ content: String? = "" ) -> String {
        return tag( "$tag", attributes: attributes, content: content )
    }
    public func _$tag() -> String {
        return "</$tag>"
    }
SWIFT
}

__DATA__
<a>
<abbr>
<acronym>
<address>
<applet>
<area>
<article>
<aside>
<audio>
<b>
<base>
<basefont>
<bdi>
<bdo>
<big>
<blockquote>
<body>
<br>
<button>
<canvas>
<caption>
<center>
<cite>
<code>
<col>
<colgroup>
<datalist>
<dd>
<del>
<details>
<dfn>
<dialog>
<dir>
<div>
<dl>
<dt>
<em>
<embed>
<fieldset>
<figcaption>
<figure>
<font>
<footer>
<form>
<frame>
<frameset>
<h1>
<h2>
<h3>
<h4>
<h5>
<h6>
<head>
<header>
<hr>
<html>
<i>
<iframe>
<img>
<input>
<ins>
<kbd>
<keygen>
<label>
<legend>
<li>
<link>
<main>
<map>
<mark>
<menu>
<menuitem>
<meta>
<meter>
<nav>
<noframes>
<noscript>
<object>
<ol>
<optgroup>
<option>
<output>
<p>
<param>
<pre>
<progress>
<q>
<rp>
<rt>
<ruby>
<s>
<samp>
<script>
<section>
<select>
<small>
<source>
<span>
<strike>
<strong>
<style>
<sub>
<summary>
<sup>
<table>
<tbody>
<td>
<textarea>
<tfoot>
<th>
<thead>
<time>
<title>
<tr>
<track>
<tt>
<u>
<ul>
<video>
<wbr>

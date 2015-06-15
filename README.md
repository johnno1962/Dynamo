## Yaws - Yet another Swift Web Server

Yaws is a minimal, 100% Swift, single file implementation of a Web server supporting SSL
that can also be used from Objective-C. It can serve static or dynamic content and
when used from the command line and includes "processors" for acting as a http and https
proxy on your local host for debugging and tracing.

Incorporating the YawsWebServer in your web server or application is simple. The initialiser
takes a port number and a list of "processors" (applications or document processors)
that will each be presented the incoming requests in the order specified and have the
option of processing them. The basic code pattern for initialisation in your app delegate is:

```Swift
    let serverPort: UInt16 = 8080
    YawsWebServer( portNumber: serverPort, processors: [
        YawsExampleAppProcessor( pathPrefix: "/example" ),
        TickTackToe(),
        YawsSSLProxyProcessor(),
        YawsProxyProcessor(),
        YawsDocumentProcessor( documentRoot: NSBundle.mainBundle().resourcePath! ),
    ] )

    webView.mainFrame.loadRequest( NSURLRequest( URL: NSURL( string: "http://localhost:\(serverPort)" )! ) )
```

See AppDelegate.swift in the example project for further details. 
A processor runs in it's own thread and is an instance of subclass 
of "YawsProcessor" that has the following signature:

```Swift
    @objc public enum YawsProcessed : Int {
    case
        NotProcessed, // does not recognise the request
        Processed, // has processed the request
        ProcessedAndReusable // "" and connection may be reused
    }

    public class YawsProcessor: NSObject {

        @objc func process( yawsClient: YawsHTTPConnection ) -> YawsProcessed {
            fatalError( "YawsProcessor: Abstract method process() called" )
        }

    }
```

Other than this, once a YawsProcessor has recognised a request it can process it
in any manner it pleases accessing the client through the YawsHTTPConnection class.
It returns .ProcessedAndReusable if the connection can be reused (as can be done
with HTTP/1.1) This requires a "Content-Length" HTTP header value to have been set.

A user written subclass of one particular subclass of YawsProcessor, "YawsApplicationProcessor"
receives the  query string, POST data and any Cookies preprocessed and is used for dynamic content.
Application processors must provide a "pathPrefix" that will be matched against the
first part of the URL to distinguish them from each other and the default document
serving processor. After parsing the request processing is handed over to the user
written implementation of the following function.

```Swift
    @objc public func processRequest( out: YawsHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        fatalError( "Application Subclass responsibility" )
    }
```

Note: while the "YawsHTTPConnection" object representing the request is transient,
the processor instance is persistent for the life of the server and must implement sessions
or state as it chooses.

A further subclass of YawsApplicationProcessor, "YawsHTMLAppProcessor" provides
functions to generate balanced HTML tags easily using functions. for example:

```Swift
    out.print( html( nil ) + head( title( "Table Example" ) +
        style( "body, table { font: 10pt Arial" ) ) + body( nil ) )

    if parameters["width"] == nil {
        out.print( h3( "Quick table creation example" ) )
        out.print(
            form( ["method":"GET"],
                table(
                    tr( td( "Width: " ) + td( input( ["type":"textfield", "name":"width"] ) ) ) +
                    tr( td( "Height: " ) + td( input( ["type":"textfield", "name":"height"] ) ) ) +
                    tr( td( ["colspan":"2"], input( ["type": "submit"] )) )
                )
            )
        )
    }
```

In these tag functions an optional dictionary of attributes for the tag can be supplied 
and a contents of nil specifies not to close the tag.

A final processor, the "YawsDocumentProcessor" generally takes the end of the chain
serving documents from a document root (which can be your app’s resource directory.)
A subclass of this, the "MultiHostProcessor" can be used to implement multiple
sites on one server using the "Host:" http request header. In this case it's
up to any dynamic content to make sure it runs on the right host.

### Design

YawsWebServer has been implemented using BSD sockets rather than Apple's CFSocket as I wasn't convinced 
it was any less low level and I didn't want to tangle with the main run loop. This also simplifies the
parsing of the HTTP headers as they come in using the venerable "fgets". If you don't share this vision
the classes YawsWebServer and YawsHTTPConnection where all this code is concentrated can be re-implemented
without affecting the basic architecture of the server or affecting any of the "processor" code.

One thing CFSocket/NSStreams does give however is support for an SSL server so a way had to be found
to turn the "push" of CFSockets to the "pull" of the Yaws code. The solution was to run a separate
CFSocket based SSL server as a proxy relaying decrypted data to a "surrogate" Yaws server on localhost
satisfying both architectures. The code to generate the required certificates in DDKeychain.[nm] was taken from
robbiehanson's [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer) under the following license:

    Software License Agreement (BSD License)

    Copyright (c) 2011, Deusty, LLC
    All rights reserved.

    Redistribution and use of this software in source and binary forms,
    with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above
    copyright notice, this list of conditions and the
    following disclaimer.

    * Neither the name of Deusty nor the names of its
    contributors may be used to endorse or promote products
    derived from this software without specific prior
    written permission of Deusty, LLC.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

YawsHTMLAppProcessor borrows it's design from the original Perl CGI module the grand-daddy of all dynamic web
content. This is my third and by far the cleanest Web server I've implemented in various languages 
and combines the experience but thankfully none of the code from the "PSP" and "jhttpd" servers.

Dynamic content can be coded entirely in Swift and one interesting use case is that it
can be used inside an iOS or OS X app. This allows you to write a "lag free" portable web 
interface connecting to the embedded server on the local device rather than a remote server. 
This is shown in the two examples included in the release.

![Icon](http://injectionforxcode.johnholdsworth.com/yaws2.png)

As ever, announcements of major commits to the repo will be made on twitter 
[@Injection4Xcode](https://twitter.com/#!/@Injection4Xcode).

Enjoy!

### MIT License

Copyright (C) 2015 John Holdsworth

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


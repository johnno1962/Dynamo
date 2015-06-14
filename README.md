## Yaws - Yet another Swift Web Server

Yaws is a minimal (?? 1750 lines??) single file implementation of a Web server written
Swift that can also be used from Objective-C. It can serve static or dynamic content
and includes "processors" for proxying http and https requests on your local host for 
debugging.

Dynamic content can be coded entirely in Swift and can be used inside an OSX or iOS app
to provide a portable web interface connecting to the embedded server on the local device
rather than a remote server as shown in the two examples included in the release.

Incorporating the YawsWebServer in your application is simple. The initialiser
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

A processor runs in it's own thread and is am instance of subclass of "YawsProcessor" that returns one of three values:

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
in any manner it chooses returning .ProcessedAndReusable if the connection can be
reused (as can be done with HTTP/1.1)

A user written subclass of one particular subclass of YawsProcessor, "YawsApplicationProcessor"
receives the  queryString and any Cookies preprocessed is used for dynamic content.
Application processors must provide a "pathPrefix" that will be matched against the
first part of the URL to distinguish them from each other and the default document
serving processor. After parsing the request processing is handed over to the user
written implementation of the following function.

```Swift
    @objc public func processRequest( out: YawsHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        fatalError( "Application Subclass responsibility" )
    }
```

Note: that while the "YawsHTTPConnection" representing the request is transient,
the proceseor is persistent for the life of the server and can implement sessions
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

As ever, announcements of major commits to the repo will be made on twitter 
[@Injection4Xcode](https://twitter.com/#!/@Injection4Xcode). Enjoy!

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



# Dynamo - Dynamic Swift Web Server

Dynamo is a high performance, minimal, Swift implementation of a  Web server supporting SSL that 
can also be used in Objective-C applications. Dynamic content can be provided in what you could
call "swiftlets" which are dynamically loadable bundles in your document root. These bundles
hot-swap when modified using method Swizzling so the server does not have to be restarted.

To see dynamic loading in action, run the DynamoApp target and browse to http://localhost:8080
and select either the Simple Game TickTackToe or the Number Guesser example. Modify the
souces in their bundle projects and build the project. The changes should take effect without
having to restart the server or affecting the object's state.

Testing with [JMeter](http://jmeter.apache.org/) as shown Dynamo can serve 12,000 requests per minute
and 6,000 requests per minute for an SSL server. For further information about the classes and protools
that make up Dynamo please consult the jazzy docs [here](http://johnholdsworth.com/dynamo/docs/).

Incorporating the DynamoWebServer in your web server or application is simple. The initialiser
takes a port number and a list of "swiftlets" (applications or document swiftlets)
that will each be presented the incoming requests in the order specified and have the
option of processing them. The basic code pattern for initialisation in your app delegate is:

```Swift
    // create non-SSL server/proxy on 8080
    let serverPort: UInt16 = 8080
    DynamoWebServer( portNumber: serverPort, swiftlets: [
        DynamoLoggingSwiftlet( logger: dynamoTrace ),
        exampleTableGeneratorApp,
        tickTackToeGame,
        DynamoSSLProxySwiftlet( logger: logger ),
        DynamoProxySwiftlet( logger: logger ),
        DynamoSwiftServerPagesSwiftlet( documentRoot: documentRoot ),
        DynamoDocumentSwiftlet( documentRoot: documentRoot )
    ] )

    webView.mainFrame.loadRequest( NSURLRequest( URL: NSURL( string: "http://localhost:\(serverPort)" )! ) )
```

Bring it into your project with a Podfile something like:

```
    use_frameworks!

    target "<project>" do

        pod 'Dynamo', :git => 'https://github.com/johnno1962/Dynamo.git'

    end
```

See OSX/AppDelegate.swift or iOS/AppDelegate.m in the example project for
further details.  A swiftlet runs in it's own thread and 
implements the "DynamoSwiftlet" protocol that has the following signature:

```Swift
    @objc public enum DynamoProcessed : Int {
    case
        NotProcessed, // does not recognise the request
        Processed, // has processed the request
        ProcessedAndReusable // "" and connection may be reused
    }

    @objc public protocol DynamoSwiftlet {

        @objc func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed    
    }
```

A subclass of DynamoApplicationSwiftlet, "DynamoHTMLAppSwiftlet" provides
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

### Design

DynamoWebServer has been implemented using BSD sockets rather than Apple's CFSocket for simplicity and speed.
This should also help in any eventual port to Linux. One thing CFSocket/NSStreams does provide however is support
for an SSL connection so a way had to be found to turn the "push" of CFSockets to the "pull" of the Dynamo code.
The solution was to run a separate CFSocket based SSL server as a proxy relaying decrypted data to a "surrogate" 
Dynamo server on localhost thus satisfying both architectures. The code to generate the required certificates in
DDKeychain.[nm], slightly modified from robbiehanson's [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer)
under the following license:

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

Dynamic content can be coded entirely in Swift and perhaps the most interesting use case is that
it can be used inside an iOS or OS X app. This allows you to write a "lag free" portable web 
interface connecting to the embedded server on the local device rather than a remote server. 
This is shown in the two examples included in the release.

![Icon](http://johnholdsworth.com/dynamo/dynamo2.png)

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


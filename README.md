
# Dynamo - Dynamic Swift Web Server

Starting this project the intention was to code the simplest possible Web Server entirely
in Swift. Unfortunately I got a bit carried away adding features such as proxying and dynamic
reloading of server code. Dynamo now also works on Linux, see [DynamoLinux](https://github.com/johnno1962/DynamoLinux).

So.. while Dynamo can be used in an iOS application as is demonstrated in this project, the focus
has turned to the server side to set up a simple framework inside which it is possible to experiment
with SSL, Proxies and what you could call "Swift Server Pages" which are loadable bundles of code
placed in the document hierarchy.

The Dynamo server core is based on "Swiftlets", instances implementing the `DynamoSwiftlet` protocol.
These are presented with incoming HTTP requests from the browser and can choose to process it in any
manner it chooses. The developer passes in an array of swiftlet instances combining the features 
and applications desired on server startup.

```Swift
    @objc public protocol DynamoSwiftlet {

        @objc func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed    
    }

    @objc public enum DynamoProcessed : Int {
        case
            NotProcessed, // does not recognise the request
            Processed, // has processed the request
            ProcessedAndReusable // "" and connection may be reused in HTTP/1.1
    }
```

For further information about the classes and protools that make up Dynamo please consult the jazzy docs
[here](http://johnholdsworth.com/dynamo/docs/). The Swiftlets included in the framework are as follows:

### DocumentSwiftlet

The default swiftlet to serve documents from ~/Sites/host:port or the applications resources directory for iOS.

### ProxySwiftlet, SSLProxySwiftlet

Dynamo can act as a proxy server logging what can be a surprising about of traffic from your browser.
To use the proxy, run `OSX` target and set your proxy to localhost:8080.

### ApplicationSwiftlet, SessionSwiftlet

`ApplicationSwiftlet` is the abstract superclass of all "application" swiftlets parsing browser GET and POST
parameters and any Cookies. `SessionSwiftlet` adds the ability to have an application Swiftlet
created separately for each unique web user using Cookies.

### BundleSwiftlet, ServerPagesSwiftlet

`BundleSwiftlet`, loads a swiftlet from a bundle with extension ".ssp" in an OSX application's resources.
A simple python script can generate the Swift source for the bundle from a ".shtml" mixing HTML and Swift
language. The `ServerPagesSwiftlet` takes this a step further where the bundle is loaded from the
document root for the sever when used from the command line. If the bundle is updated for new functionality,
provided it contains the "AutoLoader.m" stub the new code will be "swizzled" into operation.

### ExampleAppSwiftlet, TickTackToe, NumberGuesser

The `ExampleAppSwiftlet` is used in the tests for checking character encoding in GET and POST
form submission. `TickTackToe` is an example .ssp application in a bundle target. `NumberGuesser` is 
implemented as a .shtml template compiled into swift code by the Utilities/sspcompiler.py script.
Changes made to these Swiftlets will take effect when you reload the page after a project build.

### DynamoWebServer, DynamoSSLWebServer severs.

Consult OSX/AppDelegate.swift or iOS/AppDelegate.m of the OSX and iOS targets for how to create
instances of these classes. 

```Swift
    // create shared swiftlet for server applications
    let exampleTableGenerator = ExampleAppSwiftlet( pathPrefix: "/example" )
    let tickTackToeGame = BundleSwiftlet( pathPrefix: "/ticktacktoe", bundleName: "TickTackToe" )!

    let logger = {
        (msg: String) in
        println( msg )
    }

    // create non-SSL server/proxy on 8080
    DynamoWebServer( portNumber: serverPort, swiftlets: [
        LoggingSwiftlet( logger: dynamoTrace ),
        exampleTableGenerator,
        tickTackToeGame,
        SSLProxySwiftlet( logger: logger ),
        ProxySwiftlet( logger: logger ),
        ServerPagesSwiftlet( documentRoot: documentRoot ),
        DocumentSwiftlet( documentRoot: documentRoot )
    ] )
```

Creating the instance is sufficient for the server to start and run in it's own threads.
There is an additional "Daemon" target creating a command line version of the sever which should
be run from inside the DynamoApp.app's resources so it can find the Dynamo framework.

The Dynamo framework has a .podspec file so it can be brought into your project with the following:

```
    use_frameworks!

    target "<project>" do

        pod 'Dynamo', :git => 'https://github.com/johnno1962/Dynamo.git'

    end
```

Running an SSL server requires set of certificates which can be generated using code slightly modified
from robbiehanson's [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer) under a
BSD license contained in the Utilities/DDKeyChain.[hm] source.

## Performance

Testing with [JMeter](http://jmeter.apache.org/) has shown Dynamo is capable of serving:

40,000 requests per minute for a static file in the documents directory (25 threads)

40,000 requests per minute for the NumberGuesser which reuses connections (see below)

18,000 requests per minute for TickTckToe which does not reuse connections (see below)

Reusing connections is important for large numbers of requests from the same client. This is
achieved by using a single DynamoHTTPConnection.response( html ) method call rather than
individual calls to method DynamoHTTPConnection.print( html ).

As ever, announcements of major commits to the repo will be made on twitter 
[@Injection4Xcode](https://twitter.com/#!/@Injection4Xcode).

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


//
//  AppDelegate.swift
//  DynamoApp
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

import Cocoa
import Dynamo
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var webView: WebView!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        let serverPort: UInt16 = 8080, sslServerPort: UInt16 = 9090
        let documentRoot = "\(NSHomeDirectory())/Sites"

        // create shared processors for server applications
        let exampleTableGeneratorApp = DynamoExampleAppProcessor( pathPrefix: "/example" )
        let tickTackToeGame = DynamoReloadingProcessor( pathPrefix: "/ticktacktoe", bundleName: "TickTackToe" )

        let logger = {
            (msg: String) in
            println( msg )
        }

        // create non-SSL server/proxy on 8080
        DynamoWebServer( portNumber: serverPort, processors: [
            DynamoLoggingProcessor( logger: dynamoTrace ),
            exampleTableGeneratorApp,
            tickTackToeGame,
            DynamoSSLProxyProcessor( logger: logger ),
            DynamoProxyProcessor( logger: logger ),
            DynamoSwiftServerPagesProcessor( documentRoot: documentRoot ),
            DynamoDocumentProcessor( documentRoot: documentRoot )
        ] )

        let keyChainName = "DynamoSSL"
        var certs = DDKeychain.SSLIdentityAndCertificates( keyChainName )
        if certs.count == 0 {
            DDKeychain.createNewIdentity( keyChainName )
            certs = DDKeychain.SSLIdentityAndCertificates( keyChainName )
        }

        // create SSL server on port 9090
        DynamoSSLWebServer( portNumber: sslServerPort, pocessors: [
            DynamoLoggingProcessor( logger: { println( $0 ) } ),
            exampleTableGeneratorApp,
            tickTackToeGame,
            DynamoSwiftServerPagesProcessor( documentRoot: documentRoot ),
            DynamoDocumentProcessor( documentRoot: documentRoot )
        ], certs: certs )

        webView.mainFrame.loadRequest( NSURLRequest( URL: NSURL( string: "http://localhost:\(serverPort)" )! ) )
    }

    override func webView( aWebView: WebView, didReceiveTitle aTitle: String, forFrame frame: WebFrame ) {
        window.title = aTitle
    }

    override func webView( sender: WebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WebFrame ) {
        let alert = NSAlert()
        alert.messageText = "JavaScript message from page"
        alert.informativeText = message
        alert.runModal()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}


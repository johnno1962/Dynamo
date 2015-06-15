//
//  AppDelegate.swift
//  Yaws
//
//  Created by John Holdsworth on 11/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var webView: WebView!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        let serverPort: UInt16 = 8080, sslServerPort: UInt16 = 9090

        // create shared processors for server applications
        let exampleTableGeneratorApp = YawsExampleAppProcessor( pathPrefix: "/example" )
        let tickTackToeGame = YawsSessionProcessor( pathPrefix: "/ticktacktoe", appClass: TickTackToe.self )

        // create non-SSL server/proxy on 8080
        YawsWebServer( portNumber: serverPort, processors: [
            exampleTableGeneratorApp,
            tickTackToeGame,
            YawsSSLProxyProcessor(),
            YawsProxyProcessor(),
            YawsDocumentProcessor( documentRoot: NSBundle.mainBundle().resourcePath! ),
        ] )

        var certs = DDKeychain.SSLIdentityAndCertificates()
        if certs.count == 0 {
            DDKeychain.createNewIdentity()
            certs = DDKeychain.SSLIdentityAndCertificates()
        }

        // create SSL server on port 9090
        YawsSSLWebServer( portNumber: sslServerPort, pocessors: [
            exampleTableGeneratorApp,
            tickTackToeGame,
            YawsDocumentProcessor( documentRoot: NSBundle.mainBundle().resourcePath! ),
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

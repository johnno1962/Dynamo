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
        let serverPort: UInt16 = 8080
        YawsWebServer( portNumber: serverPort, processors: [
            YawsExampleAppProcessor( pathPrefix: "/example" ),
            TickTackToe(),
            YawsSSLProxyProcessor(),
            YawsProxyProcessor(),
            YawsDocumentProcessor( documentRoot: NSBundle.mainBundle().resourcePath! ),
        ] )

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

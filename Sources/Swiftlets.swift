//
//  WebApps.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Swiftlets.swift#13 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation
import Dispatch

// MARK: Swiftlets for dynamic content

/**
    Base application swiftlet testing to see if the URL path matches against a prefix to decide if it should
    process it. Handles parsing of HTTP headers to present to web application code.
 */

open class ApplicationSwiftlet: _NSObject_, DynamoBrowserSwiftlet {

    let pathPrefix: String

    /**
        Basic Application Swiftlets are identified by a prefix to their URL's path
     */

    @objc public init( pathPrefix: String ) {
        self.pathPrefix = pathPrefix
    }

    open func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        let pathInfo = httpClient.url.path
        if pathInfo.hasPrefix( pathPrefix ) {
            let endIndex = pathInfo.range( of: pathPrefix )!.upperBound
            return process( httpClient: httpClient, pathInfo: pathInfo.substring( to: endIndex ) )
        }

        return .notProcessed
    }

    /**
        Filters by path prefix to determine if this Swiftlet is to be used and parses browser
        query string, any post data and cookeis arriving from the browser.
     */

    open func process( httpClient: DynamoHTTPConnection, pathInfo: String ) -> DynamoProcessed {

        var cookies = [String:String]()
        if let cookieHeader = httpClient.requestHeaders["Cookie"] {
            addParameters( &cookies, from: cookieHeader, delimeter: "; " )
        }

        var parameters = [String:String]()
        if let queryString = httpClient.url.query {
            addParameters( &parameters, from: queryString )
        }

        if httpClient.method == "POST" {
            if httpClient.contentType == "application/json" {
#if !os(Linux)
                if let json = httpClient.postJSON() {
                    processJSON( out: httpClient,
                        pathInfo: pathInfo,
                        parameters: parameters,
                        cookies: cookies,
                        json: json )
                }
#endif
                return httpClient.knowsResponseLength ? .processedAndReusable : .processed
            }

            if httpClient.contentType == "application/x-www-form-urlencoded" {
                if let postString = httpClient.postString() {
                    addParameters( &parameters, from: postString )
                }
                else {
                    dynamoLog( "POST data not available" )
                }
            }
        }

        processRequest( out: httpClient, pathInfo: pathInfo, parameters: parameters, cookies: cookies )

        return httpClient.knowsResponseLength ? .processedAndReusable : .processed
    }

    fileprivate func addParameters(  _ parameters: inout [String:String], from queryString: String, delimeter: String = "&" ) {
        for nameValue in queryString.components( separatedBy: delimeter ) {
            if let divider = nameValue.range( of: "=" )?.lowerBound {
                let value = nameValue.substring( from: nameValue.index(divider, offsetBy: 1) )
                if let value = value
                        .replacingOccurrences( of: "+", with: " " )
                        .removingPercentEncoding {
                    parameters[nameValue.substring( to: divider )] = value
                }
            }
            else {
                parameters[nameValue] = ""
            }
        }
    }

    /**
        An application Swiftlet implements this method to performs it's processing printing to the browser
        or setting a "response" as whole which will allow the connection to be reused.
     */	   

    open func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        dynamoLog( "DynamoApplicationSwiftlet.processRequest(): Subclass responsibility" )
    }

    /**
        Sepcial treatment of JSON Post
     */

    open func processJSON( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String], json: AnyObject ) {
        processRequest( out: out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
    }

}

// MARK: Session based applications

/**
 Default session expiry time in seconds
 */

public var dynanmoDefaultSessionExpiry: TimeInterval = 15*60
private var sessionExpiryCheckInterval: TimeInterval = 60

/**
    Swiftlet that creates now instancews of the application class per user session.
    Sessions are identified by a UUID in a "DynamoSession" Coookie.
 */

open class SessionSwiftlet: ApplicationSwiftlet {

    var appClass: SessionApplication.Type
    var sessions = [String:ApplicationSwiftlet]()

    fileprivate var sessionLock = NSLock()
    fileprivate let cookieName: String

    /**
        Makea bindling between a pat pah prefix and a class the will be instantieted to process a session of requests
     */

    @objc public init( pathPrefix: String, appClass: SessionApplication.Type, cookieName: String = "DynamoSession" ) {
        self.appClass = appClass
        self.cookieName = cookieName
        super.init( pathPrefix: pathPrefix )
        cleanupSessions()
    }

    fileprivate func cleanupSessions() {
        for (key, session) in sessions {
            if let session = session as? SessionApplication, session.expiry < Date().timeIntervalSinceReferenceDate {
                    sessionLock.lock()
                    sessions.removeValue( forKey: key )
                    sessionLock.unlock()
            }
        }

        let delayTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(sessionExpiryCheckInterval*1000.0))
        DispatchQueue.global(qos: .background).asyncAfter( deadline: delayTime, execute: cleanupSessions )
    }
    /**
        Create a new instance of the application class to process the request if request and have it process it.
     */

    open override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

    	sessionLock.lock()
        var sessionKey = cookies[cookieName]
        if sessionKey == nil || sessions[sessionKey!] == nil {
            sessionKey = UUID().uuidString
            sessions[sessionKey!] = appClass.init( manager: self, sessionKey: sessionKey! )
            out.setCookie( name: cookieName, value: sessionKey!, path: pathPrefix )
            out.contentType = dynamoHtmlMimeType
        }
        sessionLock.unlock()

        if let sessionApp = sessions[sessionKey!] {
            sessionApp.processRequest( out: out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
        }
        else {
            dynamoLog( "Missing app for session \(String(describing: sessionKey))" )
        }
    }

}

/**
    Class to be subclassed for the application code when writing session based applications
 */

open class SessionApplication: HTMLApplicationSwiftlet {

    let sessionKey: String
    let manager: SessionSwiftlet
    var expiry: TimeInterval

    /**
        Clear out the current session for the next request
     */

    open func clearSession() {
        manager.sessions.removeValue( forKey: sessionKey )
    }

    /**
        Create new instance of applicatoin swiftlet on damand for session based processing
     */

    required public init( manager: SessionSwiftlet, sessionKey: String ) {
        self.manager = manager
        self.sessionKey = sessionKey
        self.expiry = Date().timeIntervalSinceReferenceDate + dynanmoDefaultSessionExpiry
        super.init( pathPrefix: "N/A" )
    }

    /**
        Overridden by applpication code toprocess request.
     */

    open override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {
        dynamoLog( "DynamoSessionApplication.processRequest(): Subclass responsibility" )
    }

}

// MARK: Bundle based, reloading swiftlets

/**
    This Swiftlet is session based and also loads it's application code from a code bundle with a ".ssp" extension.
    If the module includes the Utilities/AutoLoader.m code it will reload and swizzle it'a new implementation when
    the bundle is rebuilt/re-deployed for hot-swapping in the code. Existing instances/sessions receive the new code
    but retain their state. This does not work for changes to the layout or number of properties in the class.
*/

open class BundleSwiftlet: SessionSwiftlet {

    let bundleName: String
    let bundlePath: String
    let binaryPath: String
    var loaded: TimeInterval
    let fileManager = FileManager.default
    var loadNumber = 0

    /**
        A convenience initialiser for ".ssp" bundles that are in the projects resources
     */

    public convenience init?( pathPrefix: String, bundleName: String ) {
        let bundlePath = Bundle.main.path( forResource: bundleName, ofType: "ssp" )!
        self.init( pathPrefix: pathPrefix, bundleName: bundleName, bundlePath: bundlePath )
    }

    /**
        Initialises and performs an initial load of bundle specified.
        Bundle must contain a class with the @objc name "\(bundleNme)Swiftlet".
     */

    @objc public init?( pathPrefix: String, bundleName: String, bundlePath: String ) {

        self.bundleName = bundleName
        self.bundlePath = bundlePath
        self.binaryPath = "\(bundlePath)/Contents/MacOS/\(bundleName)"
        self.loaded = Date().timeIntervalSinceReferenceDate

        if let bundle = Bundle( path: bundlePath ), bundle.load() {
            if let appClass = bundle.classNamed( "\(bundleName)Swiftlet" ) as? SessionApplication.Type {
                super.init( pathPrefix: pathPrefix, appClass: appClass )
                return
            }
            else {
                dynamoLog( "Could not locate class with @objc name \(bundleName)Swiftlet in \(bundlePath)")
            }
        }

        dynamoLog( "Could not find/load swiftlet for bundle \(bundlePath)" )
        super.init( pathPrefix: pathPrefix, appClass: SessionApplication.self )
        return nil
    }

    /**
        When it comes to process a bundle swiftlet,  the modificatoin timme of the binsry
        is checked and if the bundle has been changed will reload the bundle by copying
        it to a new unique path in /tmp.
     */

    open override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

        if let attrs = try? fileManager.attributesOfItem( atPath: binaryPath),
            let lastModified = (attrs[FileAttributeKey.modificationDate] as? Date)?.timeIntervalSinceReferenceDate, lastModified > loaded {
            let nextPath = "/tmp/\(bundleName)V\(loadNumber).ssp"
            loadNumber += 1

            do {
                try fileManager.removeItem( atPath: nextPath )
            } catch _ {
            }

            do {
                try fileManager.copyItem( atPath: bundlePath, toPath: nextPath )

                if let bundle = Bundle( path: nextPath ) {
                    if bundle.load() {
                        // AutoLoader.m Swizzles new implementation
                        self.loaded = lastModified
                    }
                    else {
                        dynamoLog( "Could not reload bundle \(nextPath)" )
                    }
                }
            } catch let error as NSError {
                dynamoLog( "Could not copy bundle to \(nextPath) \(error)" )
            }
        }

        super.processRequest( out: out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
    }

}

// MARK: Reloading swiftlet based in bundle inside documentRoot

/**
    A specialisation of a bundle reloading, session based swiftlet where the bundle is loaded
    from the web document directory. As before it reloads and hot-swaps in the new code if the
    bundle is updated.
*/

#if !os(Linux)

open class ServerPagesSwiftlet: ApplicationSwiftlet {

    let documentRoot: String
    var reloaders = [String:BundleSwiftlet]()
    let fileManager = FileManager.default

    /**
        Document root indicates where the ".ssp" bundles are to be found
     */

    @objc public init( documentRoot: String ) {
        self.documentRoot = documentRoot
        super.init( pathPrefix: "/**.ssp" )
    }

    /**
        Parses url to see if there is a path to a .ssp bundle in the document root.
        If present it will lbe loaded as a reloadable bnudle to process the request.
     */

    override open func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        let path = httpClient.path

        if let sspMatch = path.range( of: ".ssp" )?.upperBound, let host = httpClient.requestHeaders["Host"] {
            let sspPath = path.substring( to: sspMatch )

            if sspPath != path && fileManager.fileExists( atPath: "\(documentRoot)/\(host)\(path)") {
                return .notProcessed
            }

            let sspFullPath = "\(documentRoot)/\(host)\(sspPath)"
            let reloader = reloaders[sspPath]

            if reloader == nil && fileManager.fileExists( atPath: sspFullPath ) {
                if let nameStart = sspPath.range( of: "/",
                                                options: NSString.CompareOptions.backwards )?.upperBound {
                    let nameEnd = sspPath.index(sspPath.endIndex, offsetBy: -4)
                    let bundleName = sspPath.substring( with: (nameStart ..< nameEnd) )
                    if let reloader = BundleSwiftlet( pathPrefix: sspPath,
                                    bundleName: bundleName, bundlePath: sspFullPath ) {
                        reloaders[sspPath] = reloader
                    }
                }
                else {
                    dynamoLog( "Unable to parse .ssp path: \(sspPath)" )
                    return .notProcessed
                }
            }

            if let reloader = reloaders[sspPath] {
                return reloader.present( httpClient: httpClient )
            }
            else {
                dynamoLog( "Missing .ssp bundle for path \(path)" )
            }
        }

        return .notProcessed
    }
}

#endif

//
//  WebApps.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/Swiftlets.swift#8 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation
import CoreData

// MARK: Swiftlets for dynamic content

/**
    Once a swiftlet has decided it can handle a request the headers are interpreted to extract parameters
    and cookies and any POST parameters. The web application then implements this protocol.
 */

@objc public protocol DynamoBrowserSwiftlet: DynamoSwiftlet {

    /**
        A request can be further parsed to extract parameters, method "POST" data and cookies before processing
     */

    @objc func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] )

}

/**
    Base application swiftlet testing to see if the URL path matches against a prefix to decide if it should
    process it. Handles parsing of HTTP headers to present to web application code.
 */

public class DynamoApplicationSwiftlet : NSObject, DynamoBrowserSwiftlet {

    let pathPrefix: String

    /**
        Basic Application Swiftlets are identified by a prefix to their URL's path
     */

    public init( pathPrefix: String ) {
        self.pathPrefix = pathPrefix
    }

    /**
        Filters by path prefix to determine if this Swiftlet is to be used and parses browser
        query string, any post data and cookeis arriving from the browser.
     */

    public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        if let pathInfo = httpClient.url.path {

            if pathInfo.hasPrefix( pathPrefix ) {
                var parameters = [String:String]()

                if let queryString = httpClient.url.query {
                    addParameters( &parameters, from: queryString )
                }

                if httpClient.method == "POST" && httpClient.contentType == "application/x-www-form-urlencoded" {
                    if let postData = httpClient.postString() {
                        addParameters( &parameters, from: postData )
                    }
                    else {
                        dynamoLog( "POST data not available" )
                    }
                }

                var cookies = [String:String]()
                if let cookieHeader = httpClient.requestHeaders["Cookie"] {
                    addParameters( &cookies, from: cookieHeader, delimeter: "; " )
                }

                processRequest( httpClient, pathInfo: pathInfo, parameters: parameters, cookies: cookies )

                return httpClient.knowsResponseLength ? .ProcessedAndReusable : .Processed
            }
        }

        return .NotProcessed
    }

    private func addParameters(  inout parameters: [String:String], from queryString: String, delimeter: String = "&" ) {
        for nameValue in queryString.componentsSeparatedByString( delimeter ) {
            if let divider = nameValue.rangeOfString( "=" )?.startIndex {
                let value = nameValue.substringFromIndex( advance( divider, 1 ) )
                if let value = value
                    .stringByReplacingOccurrencesOfString( "+", withString: " " )
                    .stringByRemovingPercentEncoding {
                        parameters[nameValue.substringToIndex( divider )] = value
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

    public func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        fatalError( "DynamoApplicationSwiftlet.processRequest(): Subclass responsibility" )
    }

}

// MARK: Logging Swiftlet

/**
    Null swiftlet to log each request as it is presented to the processing chain.
 */

public class DynamoLoggingSwiftlet : NSObject, DynamoSwiftlet {

    let logger: (String) -> Void

    /** default initialiser for logging Swiftlet */
    public init( logger: ((String) -> Void) = dynamoTrace ) {
        self.logger = logger
    }

    /** log current request */
    public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        logger( "\(httpClient.method) \(httpClient.path) \(httpClient.version) - \(httpClient.remoteAddr)" )
        return .NotProcessed
    }

}

// MARK: Session based applications

/**
 Default session expiry time in seconds
 */

public var dynanmoDefaultSessionExpiry: NSTimeInterval = 15*60
private var sessionExpiryCheckInterval: NSTimeInterval = 60

/**
    Swiftlet that creates now instancews of the application class per user session.
    Sessions are identified by a UUID in a "DynamoSession" Coookie.
 */

public class DynamoSessionSwiftlet : DynamoApplicationSwiftlet {

    var appClass: DynamoSessionApplication.Type
    var sessions = [String:DynamoApplicationSwiftlet]()
    private var lastCheck = NSDate().timeIntervalSinceReferenceDate
    private var sessionLock = OS_SPINLOCK_INIT
    private let cookieName: String

    /**
        Makea bindling between a pat pah prefix and a class the will be instantieted to process a session of requests
     */

    public init( pathPrefix: String, appClass: DynamoSessionApplication.Type, cookieName: String = "DynamoSession" ) {
        self.appClass = appClass
        self.cookieName = cookieName
        super.init( pathPrefix: pathPrefix )
    }

    /**
        Create a new instance of the application class to process the request if request and have it process it.
     */

    public override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

        let now = NSDate.timeIntervalSinceReferenceDate()
        if lastCheck + sessionExpiryCheckInterval < now {
            lastCheck = now
            for (key, session) in sessions {
                if let session = session as? DynamoSessionApplication {
                    if session.expiry < NSDate.timeIntervalSinceReferenceDate() {
                        OSSpinLockLock( &sessionLock )
                        sessions.removeValueForKey( key )
                        OSSpinLockUnlock( &sessionLock )
                    }
                }
            }
        }

        OSSpinLockLock( &sessionLock )
        var sessionKey = cookies[cookieName]
        if sessionKey == nil || sessions[sessionKey!] == nil {
            sessionKey = NSUUID().UUIDString
            sessions[sessionKey!] = appClass( manager: self, sessionKey: sessionKey! )
            out.setCookie( cookieName, value: sessionKey!, path: pathPrefix )
            out.contentType = dynamoHtmlMimeType
        }
        OSSpinLockUnlock( &sessionLock )

        if let sessionApp = sessions[sessionKey!] {
            sessionApp.processRequest( out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
        }
        else {
            dynamoLog( "Missing app for session \(sessionKey)" )
        }
    }

}

/**
    Class to be subclassed for the application code when writing session based applications
 */

public class DynamoSessionApplication : DynamoHTMLAppSwiftlet {

    let sessionKey: String
    let manager: DynamoSessionSwiftlet
    var expiry: NSTimeInterval

    /**
        Clear out the current session for the next request
     */

    public func clearSession() {
        manager.sessions.removeValueForKey( sessionKey )
    }

    /**
        Create new instance of applicatoin swiftlet on damand for session based processing
     */

    required public init( manager: DynamoSessionSwiftlet, sessionKey: String ) {
        self.manager = manager
        self.sessionKey = sessionKey
        self.expiry = NSDate.timeIntervalSinceReferenceDate() + dynanmoDefaultSessionExpiry
        super.init( pathPrefix: "N/A" )
    }

    /**
        Overridden by applpication code toprocess request.
     */

    public override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {
        dynamoLog( "DynamoSessionBsedApplcation.processRequest(): Subclass responsibility" )
    }

}

// MARK: Bundle based, reloading swiftlets

/**
    This Swiftlet is session based and also loads it's application code from a code bundle with a ".ssp" extension.
    If the module includes the Utilities/AutoLoader.m code it will reload and swizzle it'a new implementation when
    the bundle is rebuilt/re-deployed for hot-swapping in the code. Existing instances/sessions receive the new code
    but retain their state. This does not work for changes to the layout or number of properties in the class.
*/

public class DynamoBundleSwiftlet : DynamoSessionSwiftlet {

    let bundleName: String
    let bundlePath: String
    let binaryPath: String
    var loaded: NSTimeInterval
    let fileManager = NSFileManager.defaultManager()
    var loadNumber = 0

    /**
        A convenience initialiser for ".ssp" bundles that are in the projects resources
     */

    public convenience init?( pathPrefix: String, bundleName: String ) {
        let bundlePath = NSBundle.mainBundle().pathForResource( bundleName, ofType: "ssp" )!
        self.init( pathPrefix: pathPrefix, bundleName: bundleName, bundlePath: bundlePath )
    }

    /**
        Initialises and performs an initial load of bundle specified.
        Bundle must contain a class with the @objc name "\(bundleNme)Swiftlet".
     */

    public init?( pathPrefix: String, bundleName: String, bundlePath: String ) {

        self.bundleName = bundleName
        self.bundlePath = bundlePath
        self.binaryPath = "\(bundlePath)/Contents/MacOS/\(bundleName)"
        self.loaded = NSDate().timeIntervalSinceReferenceDate

        if let bundle = NSBundle( path: bundlePath ) {
            if bundle.load() {
                if let appClass = bundle.classNamed( "\(bundleName)Swiftlet" ) as? DynamoSessionApplication.Type {
                    super.init( pathPrefix: pathPrefix, appClass: appClass )
                    return
                }
            }
        }

        dynamoLog( "Could not find/load swiftlet for bundle \(bundlePath)" )
        super.init( pathPrefix: pathPrefix, appClass: DynamoSessionApplication.self )
        return nil
    }

    /**
        When it comes to process a bundle swiftlet,  the modificatoin timme of the binsry
        is checked and if the bundle has been changed will reload the bundle by copying
        it to a new unique path in /tmp.
     */

    public override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

        if let attrs = fileManager.attributesOfItemAtPath( binaryPath, error: nil ),
            lastModified = (attrs[NSFileModificationDate] as? NSDate)?.timeIntervalSinceReferenceDate {
            if lastModified > loaded {
                let nextPath = "/tmp/\(bundleName)V\(loadNumber++).ssp"

                if fileManager.removeItemAtPath( nextPath, error: nil ) &&
                    fileManager.copyItemAtPath( bundlePath, toPath: nextPath, error: nil ) {

                    if let bundle = NSBundle( path: nextPath ) {
                        if bundle.load() {
                            // AutoLoader.m Swizzles new implementation
                            self.loaded = lastModified
                        }
                        else {
                            dynamoLog( "Could not reload bundle \(nextPath)" )
                        }
                    }
                }
                else {
                    dynamoLog( "Could not copy bundle to \(nextPath)" )
                }
            }
        }

        super.processRequest( out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
    }

}

// MARK: Reloading swiftlet based in bundle inside documentRoot

/**
    A specialisation of a bundle reloading, session based swiftlet where the bundle is loaded
    from the web document directory. As before it reloads and hot-swaps in the new code if the
    bundle is updated.
*/

public class DynamoServerPagesSwiftlet : DynamoApplicationSwiftlet {

    let documentRoot: String
    var reloaders = [String:DynamoBundleSwiftlet]()
    let fileManager = NSFileManager.defaultManager()

    /**
        Document root indicates where the ".ssp" bundles are to be found
     */

    public init( documentRoot: String ) {
        self.documentRoot = documentRoot
        super.init( pathPrefix: "/**.ssp" )
    }

    /**
        Parses url to see if there is a path to a .ssp bundle in the document root.
        If present it will lbe loaded as a reloadable bnudle to process the request.
     */

    override public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        if let host = httpClient.requestHeaders["Host"] {
            let path = httpClient.path

            if let sspMatch = path.rangeOfString( ".ssp" )?.endIndex {
                let sspPath = path.substringToIndex( sspMatch )

                if sspPath != path && fileManager.fileExistsAtPath( "\(documentRoot)/\(host)\(path)") {
                    return .NotProcessed
                }

                let sspFullPath = "\(documentRoot)/\(host)\(sspPath)"
                var reloader = reloaders[sspPath]

                if reloader == nil && fileManager.fileExistsAtPath( sspFullPath ) {
                    if let nameStart = sspPath.rangeOfString( "/",
                                                    options: NSStringCompareOptions.BackwardsSearch )?.endIndex {
                        let bundleName = sspPath.substringWithRange( Range( start: nameStart, end: advance( sspPath.endIndex, -4 ) ) )
                        if let reloader = DynamoBundleSwiftlet( pathPrefix: sspPath,
                                        bundleName: bundleName, bundlePath: sspFullPath ) {
                            reloaders[sspPath] = reloader
                        }
                    }
                    else {
                        dynamoLog( "Unable to parse .ssp path: \(sspPath)" )
                        return .NotProcessed
                    }
                }

                if let reloader = reloaders[sspPath] {
                    return reloader.process( httpClient )
                }
                else {
                    dynamoLog( "Missing .ssp bundle for path \(path)" )
                }
            }
        }
        
        return .NotProcessed
    }
}

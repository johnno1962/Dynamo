//
//  WebApps.swift
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

import Foundation
import CoreData

// MARK: Example web application

/**
 Example web application or "swiftlet" testing form sbumission.
 */

public class DynamoExampleAppProcessor : DynamoHTMLAppProcessor {

    override public func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
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
        else if out.method == "GET" {
            let width = parameters["width"], height = parameters["height"]
            out.print( "Table width: \(width!), height: \(height!)" + br() )
            out.print( h3( "Enter table values" ) + form( ["method": "POST"], nil ) + table( nil ) )

            if let width = width?.toInt(), height = height?.toInt() {
                for y in 0..<height {
                    out.print( tr( nil ) )
                    for x in 0..<width {
                        out.print( td( input( ["type":"textfield", "name":"x\(x)y\(y)", "size":"5"] ) ) )
                    }
                    out.print( _tr() )
                }
            }

            out.print( _table()+p()+input( ["type": "submit"] )+_form() )
        }
        else {
            out.print( h3( "Your table:" ) + table( ["border":"1"], nil ) )

            if let width = parameters["width"]?.toInt(), height = parameters["height"]?.toInt() {
                for y in 0..<height {
                    out.print( tr( nil ) )
                    for x in 0..<width {
                        out.print( td( parameters["x\(x)y\(y)"]! ) )
                    }
                    out.print( _tr() )
                }
            }

            out.print( _table() )
        }
        
        out.print( p() + backButton() )
    }
    
}

// MARK: Processors for dynamic content

/**
 Once a processor has decided it can handle a request the headers are interpreted to extract parameters and cookies
 and any POST parameters. The web application then implements this protocol.
 */

@objc public protocol DynamoApplicationProtoccol: DynamoProcessor {

    @objc func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] )

}

/**
 Original application processor testing to see if the URL path matches against a prefix to decide if it should
 process it. Handles parsing of HTTP headers to present to web application code.
 */

public class DynamoApplicationProcessor : NSObject, DynamoApplicationProtoccol {

    let pathPrefix: String

    public init( pathPrefix: String ) {
        self.pathPrefix = pathPrefix
    }

    @objc public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        if let pathInfo = httpClient.url.path {
            if pathInfo.hasPrefix( pathPrefix ) {
                var parameters = [String:String]()

                if httpClient.method == "POST" {
                    if let postData = httpClient.readPost() {
                        addParameters( &parameters, from: postData )
                    }
                }

                if let queryString = httpClient.url.query {
                    addParameters( &parameters, from: queryString )
                }

                var cookies = [String:String]()
                if let cookieHeader = httpClient.requestHeaders["Cookie"] {
                    addParameters( &cookies, from: cookieHeader, delimeter: "; " )
                }

                processRequest( httpClient, pathInfo: pathInfo, parameters: parameters, cookies: cookies )

                return .Processed
            }
        }

        return .NotProcessed
    }

    private func addParameters(  inout parameters: [String:String], from queryString: String, delimeter: String = "&" ) {
        for nameValue in queryString.componentsSeparatedByString( delimeter ) {
            let nameValue = split( nameValue, maxSplit: 2, allowEmptySlices: true, isSeparator: { $0 == "=" } )
            parameters[nameValue[0]] = nameValue.count > 1 ? nameValue[1].stringByRemovingPercentEncoding! : ""
        }
    }

    @objc public func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        fatalError( "DynamoApplicationProcessor.processRequest(): Subclass responsibility" )
    }

}

// MARK: Logging Processor

/**
 Null processor to log each request as it is presented to the processing chain.
 */

public class DynamoLoggingProcessor : NSObject, DynamoProcessor {

    let logger: (String) -> Void

    public init( logger: (String) -> Void ) {
        self.logger = logger
    }

    @objc public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        logger( "\(httpClient.method) \(httpClient.uri) \(httpClient.httpVersion) - \(httpClient.remoteAddr())" )
        return .NotProcessed
    }

}

// MARK: Session based applications

/**
 Default session expiry time in seconds
 */

public var dynanmoDefaultSessionExpiry = NSTimeInterval( 15*60 )

/**
 Processor that creates now instancews of the application class per user session.
 Sessions are identified by a UUID in a "DynamoSession" Coookie.
 */

public class DynamoSessionProcessor : DynamoApplicationProcessor {

    var appClass: DynamoSessionBasedApplication.Type
    var sessions = [String:DynamoApplicationProtoccol]()

    public init( pathPrefix: String, appClass: DynamoSessionBasedApplication.Type ) {
        self.appClass = appClass
        super.init( pathPrefix: pathPrefix )
    }

    public override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

        for (key, session) in sessions {
            if let session = session as? DynamoSessionBasedApplication {
                if session.expiry < NSDate.timeIntervalSinceReferenceDate() {
                    sessions.removeValueForKey( key )
                }
            }
        }

        let sessionCookieName = "DynamoSession"
        var sessionKey = cookies[sessionCookieName]
        if sessionKey == nil || sessions[sessionKey!] == nil {
            sessionKey = NSUUID().UUIDString
            sessions[sessionKey!] = appClass( manager: self, sessionKey: sessionKey! ) as DynamoApplicationProtoccol
            out.addHeader( "Content-Type", value: dynamoHtmlMimeType )
            out.setCookie( sessionCookieName, value: sessionKey!, path: pathPrefix )
        }

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

public class DynamoSessionBasedApplication : DynamoHTMLAppProcessor {

    let sessionKey: String
    let manager: DynamoSessionProcessor
    var expiry: NSTimeInterval

    public func clearSession() {
        manager.sessions.removeValueForKey( sessionKey )
    }

    required public init( manager: DynamoSessionProcessor, sessionKey: String ) {
        self.manager = manager
        self.sessionKey = sessionKey
        self.expiry = NSDate.timeIntervalSinceReferenceDate() + dynanmoDefaultSessionExpiry
        super.init( pathPrefix: "N/A" )
    }

    public override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {
        dynamoLog( "DynamoSessionBsedApplcation.processRequest(): Subclass responsibility" )
    }

}

// MARK: Bundle based, reloading processors

/**
 This processor is sessoin based and also loads it's application code from a code bundle with a ".ssp" extension.
 If the module includes the Utilities/AutoLoader.m code it will reload and swizzle it'a new implementation when
 the bundle is rebuilt/re-deployed for hot-swapping in the code. Existing instances/sessions receive the new code
 but retain their state. This does not work for changes to the layout or number of properties in the class.
 */

public class DynamoReloadingProcessor : DynamoSessionProcessor {

    var bundleName: String
    var loaded: NSTimeInterval
    let bundlePath: String
    let binaryPath: String
    let fileManager = NSFileManager.defaultManager()
    let mainBundle = NSBundle.mainBundle()
    var loadNumber = 0

    public convenience init( pathPrefix: String, bundleName: String ) {
        let bundlePath = NSBundle.mainBundle().pathForResource( bundleName, ofType: "ssp" )!
        self.init( pathPrefix: pathPrefix, bundleName: bundleName, bundlePath: bundlePath )
    }

    public init( pathPrefix: String, bundleName: String, bundlePath: String ) {
        self.bundlePath = bundlePath
        let bundle = NSBundle( path: bundlePath )!
        bundle.load()
        self.bundleName = bundleName
        self.loaded = NSDate().timeIntervalSinceReferenceDate
        self.binaryPath = "\(bundlePath)/Contents/MacOS/\(bundleName)"
        let appClass = bundle.classNamed( "\(bundleName)Processor" ) as! DynamoSessionBasedApplication.Type
        super.init( pathPrefix: pathPrefix, appClass: appClass )
    }

    public override func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String : String], cookies: [String : String] ) {

        if let attrs = fileManager.attributesOfItemAtPath( binaryPath, error: nil ),
            lastModified = (attrs[NSFileModificationDate] as? NSDate)?.timeIntervalSinceReferenceDate {
            if lastModified > loaded {
                let nextPath = "/tmp/\(bundleName)V\(loadNumber++).ssp"

                fileManager.removeItemAtPath( nextPath, error: nil )
                fileManager.copyItemAtPath( bundlePath, toPath: nextPath, error: nil )

                if let bundle = NSBundle( path: nextPath ) {
                    bundle.load() // AutoLoader.m Swizzles new implementation
                    self.loaded = lastModified
                }
                else {
                    dynamoLog( "Could not load bundle \(nextPath)" )
                }
            }
        }

        super.processRequest(out, pathInfo: pathInfo, parameters: parameters, cookies: cookies )
    }

}

// MARK: Reloading processor based in bundle inside documentRoot

/**
 A specialisation of a bundle reloading, session based processor where the bundle is loaded
 from the web document directory. As before it reloads and hot-swaps in the new code if the
 bundle is updated.
 */

public class DynamoSwiftServerPagesProcessor : DynamoApplicationProcessor {

    let documentRoot: String
    var reloaders = [String:DynamoReloadingProcessor]()
    let sspRegexp = NSRegularExpression(pattern: "^(.*/(\\w+)\\.ssp)(.*)", options: nil, error: nil )!
    let fileManager = NSFileManager.defaultManager()

    public init( documentRoot: String ) {
        self.documentRoot = documentRoot
        super.init( pathPrefix: "/**.ssp" )
    }

    override public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        let path = httpClient.uri as NSString, range = NSMakeRange( 0, path.length )

        if let host = httpClient.requestHeaders["Host"] {

            if let sspMatch = sspRegexp.firstMatchInString( httpClient.uri, options: nil, range: range ) {
                let sspPath = path.substringWithRange( sspMatch.rangeAtIndex(1) )

                if sspPath != path && fileManager.fileExistsAtPath( "\(documentRoot)/\(host)\(path)") {
                    return .NotProcessed
                }

                let sspFullPath = "\(documentRoot)/\(host)\(sspPath)"
                var reloader = reloaders[sspPath]

                if reloader == nil && fileManager.fileExistsAtPath( sspFullPath ) {
                    let bundleName = path.substringWithRange( sspMatch.rangeAtIndex(2) )
                    reloaders[sspPath] = DynamoReloadingProcessor( pathPrefix: sspPath,
                        bundleName: bundleName, bundlePath: sspFullPath )
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

// MARK: Default document Processor

/**
 Default document mime type/charset
 */

public var dynamoHtmlMimeType = "text/html; charset=utf-8"

/**
 Supported mime types by document extension.
 */

public var dynamoMimeTypeMapping = [
    "ico": "image/x-icon",
    "jpeg":"image/jpeg",
    "jpe": "image/jpeg",
    "jpg": "image/jpeg",
    "tiff":"image/tiff",
    "tif": "image/tiff",
    "gif": "image/gif",
    "png": "image/png",
    "bmp": "image/bmp",
    "css": "text/css",
    "htm": dynamoHtmlMimeType,
    "html":dynamoHtmlMimeType,
    "java":"text/plain",
    "json":"application/json",
    "doc": "application/msword",
    "xls": "application/vnd.ms-excel",
    "ppt": "application/vnd.ms-powerpoint",
    "pps": "application/vnd.ms-powerpoint",
    "js":  "application/x-javascript",
    "jse": "application/x-javascript",
    "reg": "application/octet-stream",
    "eps": "application/postscript",
    "ps":  "application/postscript",
    "gz":  "application/x-gzip",
    "hta": "application/hta",
    "jar": "application/zip",
    "zip": "application/zip",
    "pdf": "application/pdf",
    "qt":  "video/quicktime",
    "mov": "video/quicktime",
    "avi": "video/x-msvideo",
    "wav": "audio/x-wav",
    "snd": "audio/basic",
    "mid": "audio/basic",
    "au":  "audio/basic",
    "mpeg":"video/mpeg",
    "mpe": "video/mpeg",
    "mpg": "video/mpeg",
]

/**
 Default processor, generally last in the processor chain to serve static documents of the file system.
 This is either from the app resources driectory for iOS apps or ~/Sites/hostname:port/... on OSX.
 */

public class DynamoDocumentProcessor : NSObject, DynamoProcessor {

    let fileManager = NSFileManager.defaultManager()
    let webDateFormatter = NSDateFormatter()
    let documentRoot: String

    convenience override init() {
        let appResources = NSBundle.mainBundle().resourcePath!
        self.init( documentRoot: appResources )
    }

    public init( documentRoot: String ) {
        self.documentRoot = documentRoot
        webDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    }

    func webDate( date: NSDate ) -> String {
        return webDateFormatter.stringFromDate( date )
    }

    @objc public func process( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        if httpClient.method != "GET" {
            return .NotProcessed
        }

        let hostHeader = httpClient.requestHeaders["Host"] ?? "localhost"
        var fullPath = "\(documentRoot)/\(hostHeader)\(httpClient.uri)"
        if fileManager.contentsOfDirectoryAtPath( fullPath, error: nil ) != nil {
            fullPath = fullPath.stringByAppendingPathComponent( "index.html" )
        }

        let fileExt = fullPath.pathExtension
        let mimeType = dynamoMimeTypeMapping[fileExt] ?? dynamoHtmlMimeType

        httpClient.addHeader( "Date", value: webDate( NSDate() ) )
        httpClient.addHeader( "Content-Type", value: mimeType )

        let zippedPath = fullPath+".gz"
        if fileManager.fileExistsAtPath( zippedPath ) {
            httpClient.addHeader( "Content-Encoding", value: "gzip" )
            fullPath = zippedPath
        }

        var lastModified = fileManager.attributesOfItemAtPath( fullPath,
            error: nil )?[NSFileModificationDate] as? NSDate

        if let since = httpClient.requestHeaders["If-Modified-Since"] {
            if lastModified != nil && webDate( lastModified! ) == since {
                httpClient.status = 304
                httpClient.addHeader( "Content-Length", value: "0" ) // ???
                httpClient.print( "" )
                return .ProcessedAndReusable
            }
        }

        if let data = NSData( contentsOfFile: fullPath ) {
            httpClient.status = 200
            httpClient.addHeader( "Content-Length", value: "\(data.length)" )
            httpClient.addHeader( "Last-Modified", value: "\(webDate( lastModified! ))" )
            httpClient.write( data )
            return .ProcessedAndReusable
        }
        else {
            httpClient.status = 404
            httpClient.print( "<b>File not found:</b> \(fullPath)" )
            dynamoLog( "404 File not Found: \(fullPath)" )
            return .Processed
        }
    }

}

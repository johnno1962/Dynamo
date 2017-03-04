//
//  Document.swift
//  Dynamo
//
//  Created by John Holdsworth on 11/07/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Sources/Document.swift#9 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

import Foundation

// MARK: Logging Swiftlet

/**
    Null swiftlet to log each request as it is presented to the processing chain.
*/

open class LoggingSwiftlet: _NSObject_, DynamoSwiftlet {

    let logger: (String) -> Void

    /** default initialiser for logging Swiftlet */
    public init( logger: @escaping ((String) -> Void) = dynamoTrace ) {
        self.logger = logger
    }

    /** log current request */
    open func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {
        logger( "\(httpClient.method) \(httpClient.path) \(httpClient.version) - \(httpClient.remoteAddr)" )
        return .notProcessed
    }
    
}

// MARK: Default document Swiftlet

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
    Default swiftlet, generally last in the swiftlet chain to serve static documents from the file system.
    This is either from the app resources directory for iOS apps or ~/Sites/hostname:port/... on OSX.
*/

open class DocumentSwiftlet: _NSObject_, DynamoSwiftlet {

    let fileManager = FileManager.default
    let documentRoot: String
    let report404: Bool

    /**
        Convenience initialiser taking document root from the resources directory/localhost:port
    */

    public convenience override init() {
        self.init( documentRoot: Bundle.main.resourcePath! )
    }

    /**
        Initialiser pecifying documentRoot an whether this is the last Swiftlet and it should report 404
        if a document is not found.
    */

    public init( documentRoot: String, report404: Bool = true ) {
        self.documentRoot = documentRoot
        self.report404 = report404
    }

    fileprivate func webDate( date: Date ) -> String {
        return webDateFormatter.string( from: date )
    }

    /**
        Look for static documents in directory named affter host(:port) used in url
    */

    open func present( httpClient: DynamoHTTPConnection ) -> DynamoProcessed {

        if httpClient.method == "GET" {

            let siteHost = httpClient.requestHeaders["Host"] ?? "localhost"
            var fullPath = "\(documentRoot)/\(siteHost)"+(httpClient.url.path == "" ? "/" : httpClient.url.path)

            var isDir: ObjCBool = false
            #if os(Linux)
            if fileManager.fileExists( atPath: fullPath, isDirectory: &isDir ) && isDir {
                fullPath = URL( fileURLWithPath: fullPath ).appendingPathComponent( "index.html" ).path
            }
            #else
            if fileManager.fileExists( atPath: fullPath, isDirectory: &isDir ) && isDir.boolValue {
                fullPath = URL( fileURLWithPath: fullPath ).appendingPathComponent( "index.html" ).path
            }
            #endif

            let ext = URL( fileURLWithPath: fullPath ).pathExtension
            httpClient.contentType = (ext != "" ? dynamoMimeTypeMapping[ext] : nil) ?? dynamoHtmlMimeType

            let zippedPath = fullPath+".gz"
            if fileManager.fileExists( atPath: zippedPath ) {
                httpClient.addResponseHeader( name: "Content-Encoding", value: "gzip" )
                fullPath = zippedPath
            }

            if let attrs = try? fileManager.attributesOfItem( atPath: fullPath ),
                        let lastModifiedDate = attrs[FileAttributeKey.modificationDate] as? Date {

                let lastModified = webDate( date: lastModifiedDate )
                httpClient.addResponseHeader( name: "Last-Modified", value: lastModified )

                if let since = httpClient.requestHeaders["If-Modified-Since"], since == lastModified {
                    return httpClient.sendResponse( resp: .status( status: 304, text: "" ) )
                }

                if let data = try? Data( contentsOf: URL(fileURLWithPath: fullPath) ) {
                    return httpClient.sendResponse( resp: .data( data: data ) )
                }
            }

            if report404 {
                dynamoLog( "404 File not Found: \(fullPath)" )
                return httpClient.sendResponse( resp: .status( status: 404, text: "<b>File not found:</b> \(fullPath)<p>" +
                    "<button onclick='history.back();'>Back</button>" ) )
            }
        }

        return .notProcessed
    }

}

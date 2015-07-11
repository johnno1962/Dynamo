//
//  DynamoAppTests.swift
//  DynamoAppTests
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

import Cocoa
import XCTest
import DynamoApp

class DynamoAppTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFormSubmission() {
        // This is an example of a functional test case.
        let problematicString = "Hello Test £ + & % ? 今日は"
        let reference = problematicString.stringByReplacingOccurrencesOfString( "&", withString: "&amp;" )

        evalJavaScript( "document.location = 'http://localhost:8080/example'" )

        NSRunLoop.mainRunLoop().runUntilDate( NSDate( timeIntervalSinceNow: 0.5 ) )

        evalJavaScript( "document.forms[0].title.value = '\(problematicString)'" )
        evalJavaScript( "document.forms[0].width.value = 10" )
        evalJavaScript( "document.forms[0].height.value = 10" )
        evalJavaScript( "document.forms[0].submit()" )

        NSRunLoop.mainRunLoop().runUntilDate( NSDate( timeIntervalSinceNow: 0.5 ) )

        let bodyContains: String -> Bool = {
            (reference) in
            if let html = evalJavaScript( "document.body.outerHTML" ) {
                return html.rangeOfString( reference ) != nil
            }
            return false
        }

        XCTAssert( bodyContains( "<h2>\(reference)</h2>" ), "GET method submission" )

        evalJavaScript( "document.forms[0].x5y5.value = '\(problematicString)'" )
        evalJavaScript( "document.forms[0].submit()" )

        NSRunLoop.mainRunLoop().runUntilDate( NSDate( timeIntervalSinceNow: 0.5 ) )

        XCTAssert( bodyContains( "<td>\(reference)</td>" ), "POST method submission" )
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}

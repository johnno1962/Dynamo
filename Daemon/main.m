//
//  main.m
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDKeychain.h"

@import Dynamo;

int main( int argc, char *argv[] ) {
    unsigned short serverPort = 8080;
    NSString *documentRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Sites"];
    NSString *keyChainName;

    switch ( argc ) {
    default:
        keyChainName = [[NSString alloc] initWithUTF8String:argv[3]];
    case 3:
        documentRoot = [[NSString alloc] initWithUTF8String:argv[2]];
    case 2:
        serverPort = atoi( argv[1] );
    case 1:
        break;
    }

    NSMutableArray *processors = [NSMutableArray new];
    [processors addObject:[[DynamoLoggingProcessor alloc] initWithLogger:^( NSString *request) {
        NSLog( @"%@", request );
    }]];
    [processors addObject:[[DynamoSwiftServerPagesProcessor alloc] initWithDocumentRoot:documentRoot]];
    [processors addObject:[[DynamoDocumentProcessor alloc] initWithDocumentRoot:documentRoot report404:TRUE]];

    if ( keyChainName ) {
        NSArray *certs = [DDKeychain SSLIdentityAndCertificates:keyChainName]; // could be generalised for key name
        (void)[[DynamoSSLWebServer alloc] initWithPortNumber:serverPort pocessors:processors certs:certs];
    }
    else {
        [processors insertObject:[[DynamoSSLProxyProcessor alloc] initWithLogger:nil] atIndex:1];
        [processors insertObject:[[DynamoProxyProcessor alloc] initWithLogger:nil] atIndex:2];
        (void)[[DynamoWebServer alloc] initWithPortNumber:serverPort processors:processors localhostOnly:NO];
    }

    [[NSRunLoop mainRunLoop] run];
}
//
//  main.m
//  Dynamo
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDKeychain.h"
#import <pwd.h>

@import Dynamo;

int main( int argc, char *argv[] ) {
    unsigned short serverPort = 8080;
    NSString *documentRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Sites"];
    NSString *keyChainName;
    const char *runAs;

    switch ( argc ) {
    default:
        runAs = argv[4];
    case 4:
        keyChainName = [[NSString alloc] initWithUTF8String:argv[3]];
    case 3:
        documentRoot = [[NSString alloc] initWithUTF8String:argv[2]];
    case 2:
        serverPort = atoi( argv[1] );
    case 1:
        break;
    }

    NSMutableArray *swiftlets = [NSMutableArray new];
    [swiftlets addObject:[[DynamoLoggingSwiftlet alloc] initWithLogger:^( NSString *request) {
        NSLog( @"%@", request );
    }]];
    [swiftlets addObject:[[DynamoServerPagesSwiftlet alloc] initWithDocumentRoot:documentRoot]];
    [swiftlets addObject:[[DynamoDocumentSwiftlet alloc] initWithDocumentRoot:documentRoot report404:TRUE]];

    if ( keyChainName ) {
        NSArray *certs = [DDKeychain SSLIdentityAndCertificates:keyChainName];
        (void)[[DynamoSSLWebServer alloc] initWithPortNumber:serverPort swiftlets:swiftlets certs:certs surrogate:nil];
    }
    else {
        [swiftlets insertObject:[[DynamoSSLProxySwiftlet alloc] initWithLogger:nil] atIndex:1];
        [swiftlets insertObject:[[DynamoProxySwiftlet alloc] initWithLogger:nil] atIndex:2];
        (void)[[DynamoWebServer alloc] initWithPortNumber:serverPort swiftlets:swiftlets localhostOnly:NO];
    }

    if ( runAs ) {
        struct passwd *pwd = getpwnam( runAs );
        if ( pwd )
            setuid( pwd->pw_uid );
        else {
            NSLog( @"Could not locate username %s for setuid()", runAs );
            exit(1);
        }
    }

    [[NSRunLoop mainRunLoop] run];
}
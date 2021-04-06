//
//  NSData+deflate.m
//  Dynamo
//
//  Created by John Holdsworth on 11/07/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Deflate/NSData+deflate.m#1 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

@import Foundation;
#import <zlib.h>

@implementation NSData(deflate)

- (NSData *)deflate {
    uLong sourceLen = self.length;
    uLong destLen = compressBound( sourceLen );
    Bytef *dest = malloc( destLen );

    if ( compress( dest, &destLen, self.bytes, sourceLen ) != Z_OK ) {
        NSLog( @"DynamoWebServer: Compression error %d -> %d", (int)sourceLen, (int)destLen );
        free( dest );
        return nil;
    }

    return [NSData dataWithBytesNoCopy:dest length:destLen];
}

@end

//
//  NSData+deflate.m
//  Dynamo
//
//  Created by John Holdsworth on 11/07/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Dynamo/Dynamo/NSData+deflate.m#8 $
//
//  Repo: https://github.com/johnno1962/Dynamo
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <zlib.h>

@interface NSData(deflate)
- (NSData *)deflate;
@end

@implementation NSData(delflate2)

+ (void)load {
    // replace Swift placeholder with this implementation (no bridging headers in frameworks)
    method_exchangeImplementations(class_getInstanceMethod( self, @selector(deflate) ),
                                   class_getInstanceMethod( self, @selector(deflate2) ));
}

- (NSData *)deflate2 {
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

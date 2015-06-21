#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

@interface DDKeychain : NSObject
{
	
}

+ (NSString *)passwordForHTTPServer;
+ (BOOL)setPasswordForHTTPServer:(NSString *)password;

+ (void)createNewIdentity:(NSString *)keyChainName;
+ (NSArray *)SSLIdentityAndCertificates:(NSString *)keyChainName;

+ (NSString *)applicationTemporaryDirectory;
+ (NSString *)stringForSecExternalFormat:(SecExternalFormat)extFormat;
+ (NSString *)stringForSecExternalItemType:(SecExternalItemType)itemType;
+ (NSString *)stringForSecKeychainAttrType:(SecKeychainAttrType)attrType;

@end

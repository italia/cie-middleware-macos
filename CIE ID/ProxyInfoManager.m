//
//  ProxyInfoManager.m
//  CIE ID
//

//  Copyright © 2021 IPZS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProxyInfoManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "AES.h"
@interface ProxyInfoManager()

@property (strong, nonatomic) NSData* iv;
@property (strong, nonatomic) NSData* key;

@end

@implementation ProxyInfoManager

-(id)init
{
    self.key = [self sha256:[self getSystemUUID]];
    self.iv = [@"9/\\~V).A,lY&=t2b" dataUsingEncoding:NSUTF8StringEncoding];
    
    return self;
}

-(NSString *)getEncryptedCredentials: (NSString*)credentials
{
    NSError *error;
    return [AES encrypt:credentials withKey:self.key withIV:self.iv error:&error];
}

-(NSString *)getDecryptedCredentials: (NSString*)encryptedCredentials
{
    NSError *error;
    return [AES decrypt:encryptedCredentials withKey:self.key withIV:self.iv error:&error];
}

- (NSString *)getSystemUUID {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    if (!platformExpert)
        return nil;

    CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
    IOObjectRelease(platformExpert);
    if (!serialNumberAsCFString)
        return nil;

    return (__bridge_transfer NSString *)(serialNumberAsCFString);
    
}

-(NSData*) sha256:(NSString *)clear{
    const char *s=[clear cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *keyData=[NSData dataWithBytes:s length:strlen(s)];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH + 1]={0};
    CC_SHA256(keyData.bytes, (CC_LONG) keyData.length, digest);
    NSData *out=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    return out;
}

@end

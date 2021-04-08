//
//  AES.h
//  cie-pkcs11
//
//  Copyright © 2021 IPZS. All rights reserved.
//

#ifndef AES_h
#define AES_h

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface AES : NSObject

+ (NSString *)encrypt:(NSString *)plainText withKey: (NSData*)key withIV: (NSData*)iv error:(NSError **)error;
+ (NSString *)decrypt:(NSString *)plainText withKey: (NSData*)key withIV: (NSData*)iv error:(NSError **)error;

@end

#endif /* AES_h */

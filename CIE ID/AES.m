//
//  AES.m
//  CIE ID
//
//  Copyright © 2021 IPZS. All rights reserved.
//

#import "AES.h"

@implementation AES

+ (NSString *)encrypt:(NSString *)plainText withKey: (NSData*)key withIV: (NSData*)iv error:(NSError **)error {
    NSMutableData *result =  [AES doAES:[plainText dataUsingEncoding:NSUTF8StringEncoding] context: kCCEncrypt key:key iv:iv error:error];
    return [result base64EncodedStringWithOptions:0];
}


+ (NSString *)decrypt:(NSString *)encryptedBase64String withKey: (NSData*)key withIV: (NSData*)iv error:(NSError **)error {
    NSData *dataToDecrypt = [[NSData alloc] initWithBase64EncodedString:encryptedBase64String options:0];
    NSMutableData *result = [AES doAES:dataToDecrypt context: kCCDecrypt key:key iv:iv error:error];
    return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];

}

+ (NSMutableData *)doAES:(NSData *)dataIn context:(CCOperation)kCCEncrypt_or_kCCDecrypt key: (NSData*) key iv:(NSData*)iv error:(NSError **)error {
        CCCryptorStatus ccStatus   = kCCSuccess;
        size_t          cryptBytes = 0;
        NSMutableData  *dataOut    = [NSMutableData dataWithLength:dataIn.length + kCCBlockSizeAES128];

        ccStatus = CCCrypt( kCCEncrypt_or_kCCDecrypt,
                           kCCAlgorithmAES,
                           kCCOptionPKCS7Padding,
                           key.bytes,
                           key.length,
                           (iv)?nil:iv.bytes,
                           dataIn.bytes,
                           dataIn.length,
                           dataOut.mutableBytes,
                           dataOut.length,
                           &cryptBytes);

        if (ccStatus == kCCSuccess) {
            dataOut.length = cryptBytes;
        }
        else {
            if (error) {
                *error = [NSError errorWithDomain:@"kEncryptionError"
                                             code:ccStatus
                                         userInfo:nil];
            }
            
            dataOut = nil;
        }

        return dataOut;
}

@end

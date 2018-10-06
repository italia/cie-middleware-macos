//
//  TokenSession.m
//  CIEToken
//
//  Created by ugo chirico on 06/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "Token.h"

@implementation TokenSession

- (TKTokenAuthOperation *)tokenSession:(TKTokenSession *)session beginAuthForOperation:(TKTokenOperation)operation constraint:(TKTokenOperationConstraint)constraint error:(NSError **)error {
    // Insert code here to create an instance of TKTokenAuthOperation based on the specified operation and constraint.
    // Note that the constraint was previously established when populating keychainContents during token initialization.
    return [TKTokenSmartCardPINAuthOperation new];
}

- (BOOL)tokenSession:(TKTokenSession *)session supportsOperation:(TKTokenOperation)operation usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm {
    // Indicate whether the given key supports the specified operation and algorithm.
    return YES;
}

- (NSData *)tokenSession:(TKTokenSession *)session signData:(NSData *)dataToSign usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm error:(NSError **)error {
    NSData *signature;

    // Insert code here to sign data using the specified key and algorithm.
    signature = nil;

    if (!signature) {
        if (error) {
            // If the operation failed for some reason, fill in an appropriate error like TKErrorCodeObjectNotFound, TKErrorCodeCorruptedData, etc.
            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:@{NSLocalizedDescriptionKey: @"Authentication required!"}];
        }
    }

    return signature;
}

- (NSData *)tokenSession:(TKTokenSession *)session decryptData:(NSData *)ciphertext usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm error:(NSError **)error {
    NSData *plaintext;

    // Insert code here to decrypt the ciphertext using the specified key and algorithm.
    plaintext = nil;

    if (!plaintext) {
        if (error) {
            // If the operation failed for some reason, fill in an appropriate error like TKErrorCodeObjectNotFound, TKErrorCodeCorruptedData, etc.
            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:@{NSLocalizedDescriptionKey: @"Authentication required!"}];
        }
    }

    return plaintext;
}

- (NSData *)tokenSession:(TKTokenSession *)session performKeyExchangeWithPublicKey:(NSData *)otherPartyPublicKeyData usingKey:(TKTokenObjectID)objectID algorithm:(TKTokenKeyAlgorithm *)algorithm parameters:(TKTokenKeyExchangeParameters *)parameters error:(NSError **)error {
    NSData *secret;

    // Insert code here to perform Diffie-Hellman style key exchange.
    secret = nil;

    if (!secret) {
        if (error) {
            // If the operation failed for some reason, fill in an appropriate error like TKErrorCodeObjectNotFound, TKErrorCodeCorruptedData, etc.
            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:@{NSLocalizedDescriptionKey: @"Authentication required!"}];
        }
    }

    return secret;
}

@end

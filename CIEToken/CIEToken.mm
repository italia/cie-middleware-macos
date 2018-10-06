//
//  Token.m
//  CIEToken
//
//  Created by ugo chirico on 06/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "CIEToken.h"


@implementation CIEToken

- (instancetype)initWithSmartCard:(TKSmartCard *)smartCard AID:(NSData *)AID tokenDriver:(CIETokenDriver *)tokenDriver error:(NSError **)error {
    NSString *instanceID = @"CIEToken_id"; // Fill in a unique persistent identifier of the token instance.
    
    if (self = [super initWithSmartCard:smartCard AID:AID instanceID:instanceID tokenDriver:tokenDriver]) {
        NSMutableArray<TKTokenKeychainItem *> *items = [NSMutableArray array];
        
        // TOTO Insert code here to enumerate token objects and populate keychainContents with instances of TKTokenKeychainCertificate, TKTokenKeychainKey, etc.
        
        
        
        [self.keychainContents fillWithItems:items];
    }
    return self;
}

- (TKTokenSession *)token:(TKToken *)token createSessionWithError:(NSError **)error {
    return [[CIETokenSession alloc] initWithToken:self];
}

@end

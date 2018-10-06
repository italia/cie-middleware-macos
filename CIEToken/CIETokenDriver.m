//
//  TokenDriver.m
//  CIEToken
//
//  Created by ugo chirico on 06/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "Token.h"

@implementation TokenDriver

- (TKSmartCardToken *)tokenDriver:(TKSmartCardTokenDriver *)driver createTokenForSmartCard:(TKSmartCard *)smartCard AID:(NSData *)AID error:(NSError **)error {
    return [[Token alloc] initWithSmartCard:smartCard AID:AID tokenDriver:self error:error];
}

@end

//
//  Token.h
//  CIEToken
//
//  Created by ugo chirico on 06/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <CryptoTokenKit/CryptoTokenKit.h>

// directive for PKCS#11
#include "../cie-pkcs11/PKCS11/cryptoki.h"
#include <dlfcn.h>

static const TKTokenOperationConstraint CIEConstraintPIN = @"PIN";
static const TKTokenOperationConstraint CIEConstraintPINAlways = @"PINAlways";

bool findObject(CK_SESSION_HANDLE hSession, CK_ATTRIBUTE_PTR pAttributes, CK_ULONG ulCount, CK_OBJECT_HANDLE_PTR pObjects, CK_ULONG_PTR pulObjCount);

@interface CIETokenKeychainKey : TKTokenKeychainKey

- (instancetype)initWithCertificate:(SecCertificateRef)certificateRef objectID:(TKTokenObjectID)objectID certificateID:(TKTokenObjectID)certificateID alwaysAuthenticate:(BOOL)alwaysAuthenticate NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCertificate:(nullable SecCertificateRef)certificateRef objectID:(TKTokenObjectID)objectID NS_UNAVAILABLE;

@property (readonly) TKTokenObjectID certificateID;
@property (readonly) BOOL alwaysAuthenticate;
@property (readonly) UInt8 keyID;
@property (readonly) UInt8 algID;

@end

@interface CIETokenDriver : TKSmartCardTokenDriver<TKSmartCardTokenDriverDelegate>

@end

@interface CIETokenSession : TKSmartCardTokenSession<TKTokenSessionDelegate>

typedef NS_ENUM(NSInteger, PIVAuthState) {
    CIEAuthStateUnauthorized = 0,
    CIEAuthStateFreshlyAuthorized = 1,
    CIEAuthStateAuthorizedButAlreadyUsed = 2,
};

@property PIVAuthState authState;

@end

@interface CIEAuthOperation : TKTokenSmartCardPINAuthOperation

- (instancetype)initWithSession:(CIETokenSession *)session;
@property (readonly) CIETokenSession *session;

@end

@interface CIEToken : TKSmartCardToken<TKTokenDelegate>

@property CK_SESSION_HANDLE hSession;

- (instancetype)initWithSmartCard:(TKSmartCard *)smartCard AID:(NSData *)AID tokenDriver:(CIETokenDriver *)tokenDriver error:(NSError **)error;

@end

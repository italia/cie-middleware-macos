//
//  TokenSession.m
//  CIEToken
//
//  Created by ugo chirico on 06/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "CIEToken.h"

extern CK_FUNCTION_LIST_PTR g_pFuncList;

//bool findObject(CK_SESSION_HANDLE hSession, CK_ATTRIBUTE_PTR pAttributes, CK_ULONG ulCount, CK_OBJECT_HANDLE_PTR pObjects, CK_ULONG_PTR pulObjCount);

@implementation CIEAuthOperation

- (instancetype)initWithSession:(CIETokenSession *)session {
    if (self = [super init]) {
        _session = session;
        
        self.smartCard = session.smartCard;
        self.APDUTemplate = nil;
        //self.PINFormat = [[TKSmartCardPINFormat alloc] init];
        //self.PINFormat.PINBitOffset = 5 * 8;
    }
    
    return self;
}

// Remove this as soon as PIVAuthOperation implements automatic PIN submission according to APDUTemplate.
- (BOOL)finishWithError:(NSError * _Nullable __autoreleasing *)error
{
    char szPIN[5];
    
    [[self.PIN dataUsingEncoding:NSUTF8StringEncoding] getBytes:szPIN length:5];
    
    CK_RV rv = g_pFuncList->C_Login(((CIEToken*)_session.token).hSession, CKU_USER, (CK_CHAR_PTR)szPIN, strlen(szPIN));
    if (rv != CKR_OK)
    {
        if (error != nil) {
            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationFailed userInfo:nil];
        }
        return false;
    }
    
//
//    // Format PIN as UTF-8, right padded with 0xff to 8 bytes.
//    NSMutableData *PINData = [NSMutableData dataWithLength:8];
//    memset(PINData.mutableBytes, 0xff, PINData.length);
//
//
//    [[self.PIN dataUsingEncoding:NSUTF8StringEncoding] getBytes:PINData.mutableBytes length:PINData.length];
//
    self.session.authState = CIEAuthStateFreshlyAuthorized;
    
    // Mark card session sensitive, because we entered PIN into it and no session should access it in this state.
    self.session.smartCard.sensitive = YES;
    
    // Remember in card context that the card is authenticated.
    self.session.smartCard.context = @(YES);
    
    // Mark PIVTokenSession as freshly authorized.
//    self.session.authState = CIEAuthStateFreshlyAuthorized;
    return YES;
}

@end

@implementation CIETokenSession


- (TKTokenAuthOperation *)tokenSession:(TKTokenSession *)session beginAuthForOperation:(TKTokenOperation)operation constraint:(TKTokenOperationConstraint)constraint error:(NSError **)error {
    // Insert code here to create an instance of TKTokenAuthOperation based on the specified operation and constraint.
    // Note that the constraint was previously established when populating keychainContents during token initialization.
    return [[CIEAuthOperation alloc] initWithSession:self];
//    return [TKTokenSmartCardPINAuthOperation new];
}

- (BOOL)tokenSession:(TKTokenSession *)session supportsOperation:(TKTokenOperation)operation usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm {
    
    CIETokenKeychainKey *keyItem = (CIETokenKeychainKey *)[self.token.keychainContents keyForObjectID:keyObjectID error:nil];
    if (keyItem == nil) {
        return NO;
    }
    
    CK_MECHANISM_TYPE mechanism;
    return algorithmToMechanism(algorithm, &mechanism);
    
}

- (NSData *)tokenSession:(TKTokenSession *)session signData:(NSData *)dataToSign usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm error:(NSError **)error
{

    if(self.authState != CIEAuthStateFreshlyAuthorized)
    {
        if (error != nil) {
            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:nil];
        }
        return nil;
    }
    
    CK_OBJECT_HANDLE hObjectPriKey = 0;
    CK_ULONG ulCount = 1;
    CK_OBJECT_CLASS ckClassPri     = CKO_PRIVATE_KEY;
    
    CK_ATTRIBUTE template_cko_keyPri[] = {
        {CKA_CLASS, &ckClassPri, sizeof(ckClassPri)},
    };
    
    
    if(!findObject(((CIEToken*)self.token).hSession, template_cko_keyPri, 1, &hObjectPriKey, &ulCount))
    {
//        std::cout << "  -> Operazione fallita" << std::endl;
        return nil;
    }
    
    if(ulCount < 1)
    {
//        std::cout << "  -> Oggetto chiave privata non trovato" << std::endl;
        return nil;
    }
    
    CK_MECHANISM_TYPE mechanism;
    if(!algorithmToMechanism(algorithm, &mechanism))
    {
        return nil;
    }
    
    CK_MECHANISM pMechanism[] = {mechanism, NULL_PTR, 0};
    
    CK_ULONG outputLen = 256;
    
    
    CK_RV rv = g_pFuncList->C_SignInit(((CIEToken*)self.token).hSession, pMechanism, hObjectPriKey);
    if (rv != CKR_OK)
    {
        return nil;
    }
    
    rv = g_pFuncList->C_Sign(((CIEToken*)self.token).hSession, (CK_BYTE*)dataToSign.bytes, dataToSign.length, NULL, &outputLen);
    if (rv != CKR_OK)
    {
//        error(rv);
        return nil;
    }
    
    CK_BYTE* pOutput = (CK_BYTE*)malloc(outputLen);
    
    rv = g_pFuncList->C_Sign(((CIEToken*)self.token).hSession, (CK_BYTE*)dataToSign.bytes, dataToSign.length, pOutput, &outputLen);
    if (rv != CKR_OK)
    {
        free(pOutput);
//        error(rv);
        return nil;
    }
    
    NSData* signature = [NSData dataWithBytes:pOutput length:outputLen];
    
    free(pOutput);
    
//    // Insert code here to sign data using the specified key and algorithm.
//    signature = nil;
//
//    if (!signature) {
//        if (error) {
//            // If the operation failed for some reason, fill in an appropriate error like TKErrorCodeObjectNotFound, TKErrorCodeCorruptedData, etc.
//            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
//            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:@{NSLocalizedDescriptionKey: @"Authentication required!"}];
//        }
//    }

    return signature;
}

- (NSData *)tokenSession:(TKTokenSession *)session decryptData:(NSData *)ciphertext usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm error:(NSError **)error {
    
    CK_OBJECT_HANDLE hObjectPriKey = 0;
    CK_ULONG ulCount = 1;
    CK_OBJECT_CLASS ckClassPri     = CKO_PRIVATE_KEY;
    
    CK_ATTRIBUTE template_cko_keyPri[] = {
        {CKA_CLASS, &ckClassPri, sizeof(ckClassPri)},
    };
    
    if(!findObject(((CIEToken*)self.token).hSession, template_cko_keyPri, 1, &hObjectPriKey, &ulCount))
    {
        //        std::cout << "  -> Operazione fallita" << std::endl;
        return nil;
    }
    
    if(ulCount < 1)
    {
        //        std::cout << "  -> Oggetto chiave privata non trovato" << std::endl;
        return nil;
    }
    
    CK_MECHANISM_TYPE mechanism;
    if(!algorithmToMechanism(algorithm, &mechanism))
    {
        return nil;
    }
    
    CK_MECHANISM pMechanism[] = {mechanism, NULL_PTR, 0};
    
    CK_ULONG outputLen = 256;
    
    CK_RV rv = g_pFuncList->C_DecryptInit(((CIEToken*)self.token).hSession, pMechanism, hObjectPriKey);
    if (rv != CKR_OK)
    {
        return nil;
    }
    
    rv = g_pFuncList->C_Decrypt(((CIEToken*)self.token).hSession, (CK_BYTE*)ciphertext.bytes, ciphertext.length, NULL, &outputLen);
    if (rv != CKR_OK)
    {
        //        error(rv);
        return nil;
    }
    
    CK_BYTE* pOutput = (CK_BYTE*)malloc(outputLen);
    
    rv = g_pFuncList->C_Decrypt(((CIEToken*)self.token).hSession, (CK_BYTE*)ciphertext.bytes, ciphertext.length, pOutput, &outputLen);
    if (rv != CKR_OK)
    {
        free(pOutput);
        //        error(rv);
        return nil;
    }
    
    NSData* plaintext = [NSData dataWithBytes:pOutput length:outputLen];
    
    free(pOutput);
    
    
//    NSData *plaintext;
//
//    // Insert code here to decrypt the ciphertext using the specified key and algorithm.
//    plaintext = nil;
//
//    if (!plaintext) {
//        if (error) {
//            // If the operation failed for some reason, fill in an appropriate error like TKErrorCodeObjectNotFound, TKErrorCodeCorruptedData, etc.
//            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
//            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:@{NSLocalizedDescriptionKey: @"Authentication required!"}];
//        }
//    }

    return plaintext;
}

- (NSData *)tokenSession:(TKTokenSession *)session performKeyExchangeWithPublicKey:(NSData *)otherPartyPublicKeyData usingKey:(TKTokenObjectID)objectID algorithm:(TKTokenKeyAlgorithm *)algorithm parameters:(TKTokenKeyExchangeParameters *)parameters error:(NSError **)error {
    NSData *secret = nil;
//
//    // Insert code here to perform Diffie-Hellman style key exchange.
//    secret = nil;
//
//    if (!secret) {
//        if (error) {
//            // If the operation failed for some reason, fill in an appropriate error like TKErrorCodeObjectNotFound, TKErrorCodeCorruptedData, etc.
//            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
//            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:@{NSLocalizedDescriptionKey: @"Authentication required!"}];
//        }
//    }

    return secret;
}

static bool algorithmToMechanism(TKTokenKeyAlgorithm * algorithm, CK_MECHANISM_TYPE* mechanismType)
{
    if ([algorithm isAlgorithm:kSecKeyAlgorithmRSAEncryptionRaw]
        || [algorithm isAlgorithm:kSecKeyAlgorithmRSASignatureRaw])
    {
        *mechanismType =  CKM_RSA_X_509;
        return true;
    }
    if ([algorithm isAlgorithm:kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA1])
    {
        *mechanismType = CKM_SHA1_RSA_PKCS;
        return true;
    }
    if ([algorithm isAlgorithm:kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA256])
    {
        *mechanismType = CKM_SHA256_RSA_PKCS;
        return true;
    }
    
//    if ([algorithm isAlgorithm:kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA384])
//        return CKM_SHA384_RSA_PKCS;
//    if ([algorithm isAlgorithm:kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA512])
//        return CKM_SHA512_RSA_PKCS;
//    
    return false;
}

@end

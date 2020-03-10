//
//  TokenSession.m
//  CIEToken
//
//  Created by ugo chirico on 06/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "CIEToken.h"

extern CK_FUNCTION_LIST_PTR g_pFuncList;
CK_SESSION_HANDLE openSession(CK_SLOT_ID slotid);
void closeSession(CK_SESSION_HANDLE hSession);

//bool findObject(CK_SESSION_HANDLE hSession, CK_ATTRIBUTE_PTR pAttributes, CK_ULONG ulCount, CK_OBJECT_HANDLE_PTR pObjects, CK_ULONG_PTR pulObjCount);

@implementation CIEAuthOperation

- (instancetype)initWithSession:(CIETokenSession *)session {
    if (self = [super init]) {
        _session = session;
        
        self.smartCard = session.smartCard;
        self.APDUTemplate = nil;
        self.PIN = nil;
        self.PINByteOffset = 0;
        
        
    }
    
    return self;
}

- (BOOL)finishWithError:(NSError * _Nullable __autoreleasing *)error
{
    char szPIN[5];
 
    if (*error != nil) {
        *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationFailed userInfo:nil];
        return false;
    }
    
    memset(szPIN, 0, 5);
    
    [[self.PIN dataUsingEncoding:NSUTF8StringEncoding] getBytes:szPIN length:4];
    
    CK_RV rv = g_pFuncList->C_Login(((CIETokenSession*)_session).hSession, CKU_USER, (CK_CHAR_PTR)szPIN, 4);
    if (rv != CKR_OK && rv != CKR_USER_ALREADY_LOGGED_IN)
    {
        if (error != nil) {
            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationFailed userInfo:nil];
        }
        return false;
    }
    
    ((CIEToken*)_session.token).loginRequired = false;
    
    self.session.authState = CIEAuthStateFreshlyAuthorized;
    
    // Mark card session sensitive, because we entered PIN into it and no session should access it in this state.
    self.session.smartCard.sensitive = YES;
    
    // Remember in card context that the card is authenticated.
    self.session.smartCard.context = @(YES);
    
    return YES;
}

@end

@implementation CIETokenSession


- (TKTokenAuthOperation *)tokenSession:(TKTokenSession *)session beginAuthForOperation:(TKTokenOperation)operation constraint:(TKTokenOperationConstraint)constraint error:(NSError **)error {
    return [[CIEAuthOperation alloc] initWithSession:self];
}

- (BOOL)tokenSession:(TKTokenSession *)session supportsOperation:(TKTokenOperation)operation usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm {
    
    CIETokenKeychainKey *keyItem = (CIETokenKeychainKey *)[self.token.keychainContents keyForObjectID:keyObjectID error:nil];
    if (keyItem == nil) {
        return NO;
    }
    switch (operation) {
        case TKTokenOperationSignData:
            if (keyItem.canSign) {
                if ([keyItem.keyType isEqual:(id)kSecAttrKeyTypeRSA]) {
                    
                    return [algorithm isAlgorithm:kSecKeyAlgorithmRSASignatureRaw] &&
                    [algorithm supportsAlgorithm:kSecKeyAlgorithmRSASignatureDigestPKCS1v15Raw];
                }
            }
            break;
            
        case TKTokenOperationDecryptData:
            break;
            
        case TKTokenOperationPerformKeyExchange:
            break;
        
        default:
            break;
    }


    return NO;
}

- (NSData *)tokenSession:(TKTokenSession *)session signData:(NSData *)dataToSign usingKey:(TKTokenObjectID)keyObjectID algorithm:(TKTokenKeyAlgorithm *)algorithm error:(NSError **)error
{
    if(self.authState != CIEAuthStateFreshlyAuthorized && ((CIEToken*)self.token).loginRequired)
    {
        if (error != nil) {
            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:nil];
        }
        
        // non va chiamata la close session perchè dopo il return con error TKErrorCodeAuthenticationNeeded
        // verà chiamata la C_Login
        
        return nil;
    }
    
    CK_OBJECT_HANDLE hObjectPriKey = 0;
    CK_ULONG ulCount = 1;
    CK_OBJECT_CLASS ckClassPri = CKO_PRIVATE_KEY;
    
    CK_ATTRIBUTE template_cko_keyPri[] = {
        {CKA_CLASS, &ckClassPri, sizeof(ckClassPri)},
    };
    
    if(!findObject(self.hSession, template_cko_keyPri, 1, &hObjectPriKey, &ulCount))
    {
        return nil;
    }
    
    if(ulCount < 1)
    {
        return nil;
    }
    
    CK_MECHANISM_TYPE mechanism = CKM_RSA_PKCS;
    
    CK_MECHANISM pMechanism[] = {mechanism, NULL_PTR, 0};
    
    CK_ULONG outputLen = 256;
    
//    NSString* hex = dataToSign.hexString;
    
    CK_RV rv = g_pFuncList->C_SignInit(self.hSession, pMechanism, hObjectPriKey);
    if (rv != CKR_OK)
    {
        return nil;
    }
    
    unsigned long offset = [self removePaddingBT1:dataToSign];
    
    CK_BYTE* data = ((CK_BYTE*)dataToSign.bytes) + offset;
    unsigned long len = dataToSign.length - offset;
    
    rv = g_pFuncList->C_Sign(self.hSession, data, len, NULL, &outputLen);
    if (rv != CKR_OK)
    {
//        error(rv);
        return nil;
    }
    
    CK_BYTE* pOutput = (CK_BYTE*)malloc(outputLen);
    
    rv = g_pFuncList->C_Sign(self.hSession, data, len, pOutput, &outputLen);
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
    
    return nil;
    
//    CK_OBJECT_HANDLE hObjectPriKey = 0;
//    CK_ULONG ulCount = 1;
//    CK_OBJECT_CLASS ckClassPri     = CKO_PRIVATE_KEY;
//
//    CK_ATTRIBUTE template_cko_keyPri[] = {
//        {CKA_CLASS, &ckClassPri, sizeof(ckClassPri)},
//    };
//
//    if(!findObject(((CIEToken*)self.token).hSession, template_cko_keyPri, 1, &hObjectPriKey, &ulCount))
//    {
//        //        std::cout << "  -> Operazione fallita" << std::endl;
//        return nil;
//    }
//
//    if(ulCount < 1)
//    {
//        //        std::cout << "  -> Oggetto chiave privata non trovato" << std::endl;
//        return nil;
//    }
//
//    CK_MECHANISM_TYPE mechanism;
//    if(!algorithmToMechanism(algorithm, &mechanism))
//    {
//        return nil;
//    }
//
//    CK_MECHANISM pMechanism[] = {mechanism, NULL_PTR, 0};
//
//    CK_ULONG outputLen = 256;
//
//    CK_RV rv = g_pFuncList->C_DecryptInit(((CIEToken*)self.token).hSession, pMechanism, hObjectPriKey);
//    if (rv != CKR_OK)
//    {
//        return nil;
//    }
//
//    rv = g_pFuncList->C_Decrypt(((CIEToken*)self.token).hSession, (CK_BYTE*)ciphertext.bytes, ciphertext.length, NULL, &outputLen);
//    if (rv != CKR_OK)
//    {
//        //        error(rv);
//        return nil;
//    }
//
//    CK_BYTE* pOutput = (CK_BYTE*)malloc(outputLen);
//
//    rv = g_pFuncList->C_Decrypt(((CIEToken*)self.token).hSession, (CK_BYTE*)ciphertext.bytes, ciphertext.length, pOutput, &outputLen);
//    if (rv != CKR_OK)
//    {
//        free(pOutput);
//        //        error(rv);
//        return nil;
//    }
//
//    NSData* plaintext = [NSData dataWithBytes:pOutput length:outputLen];
//
//    free(pOutput);
//
//
////    NSData *plaintext;
////
////    // Insert code here to decrypt the ciphertext using the specified key and algorithm.
////    plaintext = nil;
////
////    if (!plaintext) {
////        if (error) {
////            // If the operation failed for some reason, fill in an appropriate error like TKErrorCodeObjectNotFound, TKErrorCodeCorruptedData, etc.
////            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
////            *error = [NSError errorWithDomain:TKErrorDomain code:TKErrorCodeAuthenticationNeeded userInfo:@{NSLocalizedDescriptionKey: @"Authentication required!"}];
////        }
////    }
//
//    return plaintext;
}

- (NSData *)tokenSession:(TKTokenSession *)session performKeyExchangeWithPublicKey:(NSData *)otherPartyPublicKeyData usingKey:(TKTokenObjectID)objectID algorithm:(TKTokenKeyAlgorithm *)algorithm parameters:(TKTokenKeyExchangeParameters *)parameters error:(NSError **)error {
    return nil;
}

- (unsigned long) removePaddingBT1:(NSData*) paddedData
{
    CK_BYTE* data = (CK_BYTE*)paddedData.bytes;
    
    if (data[0]!=0)
        return -1;
    if (data[1]!=1)
        return -2;
    for (unsigned long i = 2; i<paddedData.length; i++)
    {
        if (data[i]==0) {
            return i+1;
        }
        if (data[i] != 0xff)
            return -3;
    }
    return -4;
}

@end

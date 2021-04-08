//
//  ProxyInfoManager.h
//  cie-pkcs11
//
//

#ifndef ProxyInfoManager_h
#define ProxyInfoManager_h

@interface ProxyInfoManager : NSObject

-(id)init;
-(NSString *)getEncryptedCredentials: (NSString*)credentials;
-(NSString *)getDecryptedCredentials: (NSString*)encryptedCredentials;
@end
#endif /* ProxyInfoManager_h */

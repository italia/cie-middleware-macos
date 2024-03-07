//
//  PreferencesManager.h
//  cie-pkcs11
//
//  Created by Antonio Ciccarelli on 12/02/24.
//  Copyright © 2024 IPZS. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef PreferencesManager_h
#define PreferencesManager_h

@interface PreferencesManager : NSObject

-(id) init;
+(instancetype) sharedInstance;
-(NSString *) getConfigKeyValue : (NSString *) configOptionName;
-(void) setConfigKeyValue: (NSString *) configOptionName : (NSString *) optionValue;

@end
#endif /* PreferencesController_h */

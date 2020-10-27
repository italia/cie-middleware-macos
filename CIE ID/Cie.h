//
//  Cie.h
//  CIE ID
//
//  Created by Pierluigi De Gregorio on 21/09/2020.
//  Copyright © 2020 IPZS. All rights reserved.
//

#ifndef Cie_h
#define Cie_h

#import <Foundation/Foundation.h>

@interface Cie : NSObject <NSCoding>

-(id)init: (NSString*) name serial:(NSString*) serialNumner pan:(NSString *) pan;

-(NSString*) getName;
-(NSString*) getSerialNumber;
-(NSString*) getPan;

@end

#endif /* Cie_h */

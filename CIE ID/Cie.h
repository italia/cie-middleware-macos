//
//  Cie.h
//  CIE ID
//


#ifndef Cie_h
#define Cie_h

#import <Foundation/Foundation.h>

@interface Cie : NSObject <NSCoding>

-(id)init: (NSString*) name serial:(NSString*) serialNumner pan:(NSString *) pan;

-(NSString*) getName;
-(NSString*) getSerialNumber;
-(NSString*) getPan;
-(BOOL)getCustomSign;
-(void)customSignSet: (BOOL)setValue;
@end

#endif /* Cie_h */

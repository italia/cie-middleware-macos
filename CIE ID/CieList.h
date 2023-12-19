//
//  CieList.h
//  Dictionary_Class_Example
//

//

#ifndef CieList_h
#define CieList_h

#import <Foundation/Foundation.h>
#import "Cie.h"


@interface CieList : NSObject



-(id) init;
//-(id) init:(NSDictionary*)dictionary;
-(id) init:(NSData *) data;

-(void)addCie:(NSString*) pan owner:(Cie*) cie;

-(void)removeCie:(NSString*) pan;

-(void)removeAllCie;

-(NSDictionary*)getDictionary;
-(NSData *)getData;

#endif /* CieList_h */

@end

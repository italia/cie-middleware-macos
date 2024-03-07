//
//  Cie.m
//  CIE ID
//


#import "Cie.h"

@interface Cie()

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* serialNumber;
@property (strong, nonatomic) NSString* pan;
@property BOOL customSign;

@end

@implementation Cie

-(id)init: (NSString*) name serial:(NSString*) serialNumber pan:(NSString *) pan
{
    self.serialNumber = serialNumber;
    self.name = name;
    self.pan = pan;
    self.customSign = false;
    return self;
}

-(NSString*) getName
{
    return self.name;
}
-(NSString*) getSerialNumber
{
    return self.serialNumber;
}

-(NSString*) getPan
{
    return self.pan;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.serialNumber forKey:@"serialNumber"];
    [coder encodeObject:self.pan forKey:@"pan"];
    [coder encodeBool:self.customSign forKey:@"customSign"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self.name = [coder decodeObjectForKey:@"name"];
    self.serialNumber = [coder decodeObjectForKey:@"serialNumber"];
    self.pan = [coder decodeObjectForKey:@"pan"];
    
    if([coder containsValueForKey:@"customSign"])
    {
        self.customSign = [coder decodeBoolForKey:@"customSign"];
    }else
    {
        self.customSign = false;
    }
    
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"name = %@; serial = %@", _name, _serialNumber];
}


-(BOOL) getCustomSign
{
    return self.customSign;
}

-(void)customSignSet: (BOOL)setValue
{
    self.customSign = setValue;
}

@end

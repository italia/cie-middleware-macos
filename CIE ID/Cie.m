//
//  Cie.m
//  CIE ID
//
//  Created by Pierluigi De Gregorio on 21/09/2020.
//  Copyright © 2020 IPZS. All rights reserved.
//

#import "Cie.h"

@interface Cie()

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* serialNumber;
@property (strong, nonatomic) NSString* pan;

@end

@implementation Cie

-(id)init: (NSString*) name serial:(NSString*) serialNumner pan:(NSString *) pan
{
    self.serialNumber = serialNumner;
    self.name = name;
    self.pan = pan;
    
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
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self.name = [coder decodeObjectForKey:@"name"];
    self.serialNumber = [coder decodeObjectForKey:@"serialNumber"];
    self.pan = [coder decodeObjectForKey:@"pan"];
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"name = %@; serial = %@", _name, _serialNumber];
}

@end

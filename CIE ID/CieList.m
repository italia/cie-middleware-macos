//
//  CieList.m
//  Dictionary_Class_Example
//
//  Created by Pierluigi De Gregorio on 21/09/2020.
//  Copyright © 2020 Pierluigi De Gregorio. All rights reserved.
//

#import "CieList.h"

@interface CieList()

@property (strong, nonatomic) NSMutableDictionary *dictionary;

@end

@implementation CieList


- (id)init
{
    self.dictionary = [[NSMutableDictionary alloc] init];
    
    return self;
}

//-(id) init:(NSDictionary*)dictionary
//{
//    //self.dictionary = [[NSMutableDictionary alloc ]initWithDictionary:dictionary];
//    self.dictionary = [[NSMutableDictionary alloc]initWithDictionary:dictionary];
//    NSLog(@"Dictionary after initialization: %@", [self.dictionary description]);
//    return self;
//}


-(id) init:(NSData *) data {
    NSDictionary *retrievedDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.dictionary = [[NSMutableDictionary alloc] initWithDictionary:retrievedDictionary];
    return self;
}

-(void)addCie:(NSString*) pan owner:(Cie*) cie
{
    [self.dictionary setObject:cie forKey:pan];
    
    NSLog(@"Dictionary after add: %@", [self.dictionary description]);
}

-(void)removeCie:(NSString*) pan
{
    [self.dictionary removeObjectForKey:pan];
    NSLog(@"Dictionary after remove: %@", [self.dictionary description]);
}

-(void)removeAllCie
{
    [self.dictionary removeAllObjects];
    NSLog(@"Dictionary after remove all objects: %@", [self.dictionary description]);
    
}

-(NSDictionary*)getDictionary
{
    return [[NSDictionary alloc ] initWithDictionary:self.dictionary];
}

- (NSData *) getData
{
    return [NSKeyedArchiver archivedDataWithRootObject:self.dictionary];
}

@end

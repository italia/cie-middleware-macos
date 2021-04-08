//
//  ChangeView.m
//  CIE ID
//
//

#import <Foundation/Foundation.h>
#import "ChangeView.h"

@interface ChangeView()


@end

@implementation ChangeView


+ (ChangeView *)getInstance {
    static ChangeView *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


-(id)init
{
    
    return self;
}

-(NSView*)getView: (viewIndex) viewIndex
{
    return [self.viewArray objectAtIndex:viewIndex];
}

-(void) showSubView: (viewIndex) viewIndex
{
    
    for(int i = 0; i<self.viewArray.count; i++)
    {
        NSView* hV = [self.viewArray objectAtIndex:i];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (viewIndex == i) {
                hV.hidden = NO;
            }
            else {
                hV.hidden = YES;
            }
        });

    }
    
    
}


@end

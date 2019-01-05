//
//  CIEMessageView.m
//  CIEIDBar
//
//  Created by ugo chirico on 05/01/2019.
//  Copyright © 2019 IPZS. All rights reserved.
//

#import "CIEMessageView.h"

@implementation CIEMessageView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void) updateWithMessage: (NSString* ) message
{
    _messageLabel.stringValue = message;
}

@end

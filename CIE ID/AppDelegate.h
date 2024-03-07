//
//  AppDelegate.h
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessageViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, CIEPopoverProtocol>
@property(nonatomic) BOOL closeAppFromStatusBar;
@property NSWindow* window;

@end


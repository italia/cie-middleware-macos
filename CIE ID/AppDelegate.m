//
//  AppDelegate.m
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier: NSBundle.mainBundle.bundleIdentifier].count > 1)
    {
        [NSApplication.sharedApplication terminate:self];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end

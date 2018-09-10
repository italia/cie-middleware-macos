//
//  AbilitaCIE.cpp
//  cie-pkcs11
//
//  Created by ugo chirico on 02/09/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#include <stdio.h>
#include "AbilitaCIE.h"
#include <Foundation/Foundation.h>

void showUI()
{
    NSTask *task = [[NSTask alloc] init];
    //            [task setLaunchPath:@"/Applications/iCal.app/Contents/MacOS/iCal"];
    [task setLaunchPath:@"AbilitaCIE"];
    [task launch];
        
//    NSRect frame = NSMakeRect(0, 0, 200, 200);
//    window  = [[NSWindow alloc] initWithContentRect:frame
//                                          styleMask:NSBorderlessWindowMask
//                                            backing:NSBackingStoreBuffered
//                                              defer:NO];
//    [window setBackgroundColor:[NSColor blueColor]];
//    [window makeKeyAndOrderFront:NSApp];
//
//    AbilitaCIEViewController* viewController = [[AbilitaCIEViewController alloc] initWithNibName:@"AbilitaCIEViewController" bundle:nil];
//    [window setContentViewController:viewController];
}

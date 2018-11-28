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

#include <AppKit/AppKit.h>

void showUI(const char* szPAN)
{
//    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
//    NSURL* url = [NSURL fileURLWithPath:@"/usr/bin/AbilitaCIE.app" isDirectory:NO];
//    [ws launchApplicationAtURL:url
//                       options:NSWorkspaceLaunchWithoutActivation
//                 configuration:@{}
//                         error:nil];
//
//
    NSTask *task = [[NSTask alloc] init];
//    task.launchPath = @"/usr/bin/open";
//    task.arguments = @[@"-a", @"/usr/local/bin/AbilitaCIE.app"];//, [NSString stringWithUTF8String:szPAN]];

    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", @"/Applications/AbilitaCIE.app"];//, [NSString stringWithUTF8String:szPAN]];

    [task launch];
    
    
//    NSTask *task = [[NSTask alloc] init];
//    [task setLaunchPath:@"open -a AbilitaCIE.app"];
//    [task launch];
}

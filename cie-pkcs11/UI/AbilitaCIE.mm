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
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", @"/Applications/CIE ID.app"];//, [NSString stringWithUTF8String:szPAN]];

    [task launch];
}

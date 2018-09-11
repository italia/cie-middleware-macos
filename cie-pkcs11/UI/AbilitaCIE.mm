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
    [task setLaunchPath:@"AbilitaCIE"];
    [task launch];
}

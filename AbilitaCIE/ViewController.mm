//
//  ViewController.m
//  AbilitaCIE
//
//  Created by ugo chirico on 02/09/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "ViewController.h"

// directive for PKCS#11
#include "../cie-pkcs11/PKCS11/cryptoki.h"

#include <memory.h>
#include <time.h>
#include <dlfcn.h>
#include "../cie-pkcs11/CSP/AbilitaCIE.h"

typedef CK_RV (*C_GETFUNCTIONLIST)(CK_FUNCTION_LIST_PTR_PTR ppFunctionList);
CK_FUNCTION_LIST_PTR g_pFuncList;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

CK_RV progressCallback(const int progress,
                      const char* szMessage)
{
    NSLog(@"%d %s", progress, szMessage);
    return 0;
}

- (IBAction)onAbilita:(id)sender
{
    //NSString* dir = [[NSBundle mainBundle] bundleURL].absoluteString;
    
    const char* szCryptoki = "libcie-pkcs11.dylib";
    
    void* hModule = dlopen(szCryptoki, RTLD_LAZY);
    if(!hModule)
    {
        exit(1);
    }
    
    C_GETFUNCTIONLIST pfnGetFunctionList=(C_GETFUNCTIONLIST)dlsym(hModule, "C_GetFunctionList");
    if(!pfnGetFunctionList)
    {
        dlclose(hModule);
        exit(1);
    }
    
//    CK_RV rv = pfnGetFunctionList(&g_pFuncList);
//    if(rv != CKR_OK)
//    {
//        dlclose(hModule);
//        exit(1);
//    }
//    
//    CK_C_INITIALIZE_ARGS* pInitArgs = NULL_PTR;
//    rv = g_pFuncList->C_Initialize(pInitArgs);
//    if(rv != CKR_OK)
//    {        
//        return;
//    }
    
    AbilitaCIEfn pfnAbilitaCIE = (AbilitaCIEfn)dlsym(hModule, "AbilitaCIE");
    if(!pfnAbilitaCIE)
    {
        dlclose(hModule);
        exit(1);
    }
    
    NSString* pin = _textFieldPIN.stringValue;
    
    pfnAbilitaCIE("hjhjh", [pin cStringUsingEncoding:NSUTF8StringEncoding], &progressCallback);
    
    exit(0);
}

@end

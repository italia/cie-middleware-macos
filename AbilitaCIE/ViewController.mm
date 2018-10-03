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

NSTextField* labelProgressPointer;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    _labelProgress.stringValue = @"";
    
    labelProgressPointer = _labelProgress;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


CK_RV progressCallback(const int progress,
                      const char* szMessage)
{
    NSLog(@"%d %s", progress, szMessage);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        labelProgressPointer.stringValue = [NSString stringWithUTF8String:szMessage];
    });
    
    return 0;
}

- (IBAction)onAbilita:(id)sender
{
    NSString* pin = self.textFieldPIN.stringValue;
    
    [((NSControl*)sender) setEnabled:NO];
    
    const char* szCryptoki = "libcie-pkcs11.dylib";
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
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
        
        AbilitaCIEfn pfnAbilitaCIE = (AbilitaCIEfn)dlsym(hModule, "AbilitaCIE");
        if(!pfnAbilitaCIE)
        {
            dlclose(hModule);
            exit(1);
        }
        
        char* szPIN = NULL;
        
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        
        if(args.count > 1)
            szPIN = (char*)[((NSString*)[args objectAtIndex:1]) cStringUsingEncoding:NSUTF8StringEncoding];
        
        int attempts = -1;
        
        
        long ret = pfnAbilitaCIE(szPIN, [pin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallback);

        dispatch_async(dispatch_get_main_queue(), ^{
            
            [((NSControl*)sender) setEnabled:YES];
            
            switch(ret)
            {
                case CKR_TOKEN_NOT_RECOGNIZED:
                    [self showMessage:@"Impossibile trovare la CIE con Numero Identificativo" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"Impossibile trovare la CIE con Numero Identificativo" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PIN digitato è errato. rimangono %d tentativi", attempts] withTitle:@"PIN non corretto" exitAfter:false];
                    
                    break;
                    
                case CKR_PIN_LOCKED:
                    [self showMessage:@"Il PIN è bloccato" withTitle:@"PIN bloccato" exitAfter:false];
                    break;
                
                case CKR_GENERAL_ERROR:
                    [self showMessage:@"Errore inaspettato durante la comunicazione con la smart card" withTitle:@"Errore inaspettato" exitAfter:false];
                    break;
                    
                case CKR_OK:
                    [self showMessage:@"L'abilitazione della CIE è avvennuta con successo" withTitle:@"CIE Abilitata" exitAfter:true];
                    break;
            }
        });
    });
}

- (void) showMessage: (NSString*) message withTitle: (NSString*) title exitAfter: (bool) exitAfter
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Ok"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    
//    alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
//        if (returnCode == NSAlertSecondButtonReturn) {
//            NSLog(@"Delete was cancelled!");
//            return;
//        }
//
//        NSLog(@"This project was deleted!");
//    }];
    
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:&exitAfter];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    /*
     The following options are deprecated in 10.9. Use NSAlertFirstButtonReturn instead
     NSAlertDefaultReturn = 1,
     NSAlertAlternateReturn = 0,
     NSAlertOtherReturn = -1,
     NSAlertErrorReturn = -2
     NSOKButton = 1, // NSModalResponseOK should be used
     NSCancelButton = 0 // NSModalResponseCancel should be used
     */
    
    if(contextInfo)
        exit(0);
}
@end

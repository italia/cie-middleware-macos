//
//  ViewController.m
//  CambioPIN
//
//  Created by ugo chirico on 05/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "ViewController.h"

// directive for PKCS#11
#include "../cie-pkcs11/PKCS11/cryptoki.h"

#include <memory.h>
#include <time.h>
#include <dlfcn.h>
#include "../cie-pkcs11/CSP/PINManager.h"

typedef CK_RV (*C_GETFUNCTIONLIST)(CK_FUNCTION_LIST_PTR_PTR ppFunctionList);
CK_FUNCTION_LIST_PTR g_pFuncList;

@implementation ViewController

NSTextField* labelProgressPointer;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
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

- (IBAction)onChangePIN:(id)sender
{
    NSString* pin = self.textFieldPIN.stringValue;
    NSString* newpin = self.textFieldNewPIN.stringValue;
    NSString* confirmpin = self.textFieldConfirmPIN.stringValue;
    
    if(pin.length != 8 || newpin.length != 8)
    {
        [self showMessage: @"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    if(![newpin isEqualToString:confirmpin])
    {
        [self showMessage: @"I PIN non corrispondono" withTitle:@"PIN non corrispondenti" exitAfter:false];
        return;
    }
    
    if([newpin isEqualToString:pin])
    {
        [self showMessage: @"Il vecchio e nuovo PIN non possono essere uguali" withTitle:@"PIN identici" exitAfter:false];
        return;
    }
    
    unichar c = [pin characterAtIndex:0];
    
    int i = 1;
    for(i = 1; i < pin.length && (c >= '0' && c <= '9'); i++)
    {
        c = [pin characterAtIndex:i];
    }
    
    if(!(c >= '0' && c <= '9'))
    {
        [self showMessage: @"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    
    for(i = 1; i < newpin.length && (c >= '0' && c <= '9'); i++)
    {
        c = [newpin characterAtIndex:i];
    }
    
    if(!(c >= '0' && c <= '9'))
    {
        [self showMessage: @"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    unichar lastchar = c;
        
    for(i = 1; i < newpin.length && c == lastchar; i++)
    {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if(c == lastchar)
    {
        [self showMessage: @"Il nuovo PIN non deve essere composto da cifre uguali" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    lastchar = c - 1;
    
    for(i = 1; i < newpin.length && c == lastchar + 1; i++)
    {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if(c == lastchar + 1)
    {
        [self showMessage: @"Il nuovo PIN non deve essere composto da cifre consecutive" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    lastchar = c + 1;
    
    for(i = 1; i < newpin.length && c == lastchar - 1; i++)
    {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if(c == lastchar - 1)
    {
        [self showMessage: @"Il nuovo PIN non deve essere composto da cifre consecutive" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    [((NSControl*)sender) setEnabled:NO];
    
    const char* szCryptoki = "libcie-pkcs11.dylib";
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
        void* hModule = dlopen(szCryptoki, RTLD_LAZY);
        if(!hModule)
        {
            [self showMessage: @"Middleware non trovato" withTitle:@"Errore inaspettato" exitAfter:true];
            return;
        }
        
        C_GETFUNCTIONLIST pfnGetFunctionList=(C_GETFUNCTIONLIST)dlsym(hModule, "C_GetFunctionList");
        if(!pfnGetFunctionList)
        {
            dlclose(hModule);
            [self showMessage: @"Il middleware non è valido" withTitle:@"Errore inaspettato" exitAfter:true];
            return;
        }
        
        CambioPINfn pfnCambioPIN = (CambioPINfn)dlsym(hModule, "CambioPIN");
        if(!pfnCambioPIN)
        {
            dlclose(hModule);
            [self showMessage: @"Funzione CambioPIN non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:false];
            return;
        }
        
        int attempts = -1;
        
        
        long ret = pfnCambioPIN([pin cStringUsingEncoding:NSUTF8StringEncoding], [newpin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallback);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [((NSControl*)sender) setEnabled:YES];
            
            switch(ret)
            {
                case CKR_TOKEN_NOT_RECOGNIZED:
                    [self showMessage:@"Impossibile trovare la CIE con Numero Identificativo" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"CIE presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PIN digitato è errato. rimangono %d tentativi", attempts] withTitle:@"PIN non corretto" exitAfter:false];
                    break;
                    
                case CKR_PIN_LOCKED:
                    [self showMessage:@"Il PIN è bloccato" withTitle:@"PIN bloccato" exitAfter:false];
                    break;
                    
                case CKR_GENERAL_ERROR:
                    [self showMessage:@"Errore inaspettato durante la comunicazione con la CIE" withTitle:@"Errore inaspettato" exitAfter:false];
                    break;
                    
                case CKR_OK:
                    [self showMessage:@"Il PIN è stato modificato con successo" withTitle:@"Operazione completata" exitAfter:false];
                    break;
            }
        });
    });
}

- (IBAction)onCancel:(id)sender
{
    exit(0);
}

- (void) showMessage: (NSString*) message withTitle: (NSString*) title exitAfter: (bool) exitAfter
{
    __block bool exit = exitAfter;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Ok"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:&exit];
    });
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool *)contextInfo
{
    if(*contextInfo)
        exit(0);
}

@end

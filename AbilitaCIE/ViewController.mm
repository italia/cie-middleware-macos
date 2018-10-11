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

void* hModule;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    _labelProgress.stringValue = @"";
    
    labelProgressPointer = _labelProgress;
}

- (void) viewDidAppear
{
    [super viewDidAppear];
    
    const char* szCryptoki = "libcie-pkcs11.dylib";
    
    hModule = dlopen(szCryptoki, RTLD_LAZY);
    if(!hModule)
    {
        [self showMessage: @"Middleware non trovato" withTitle:@"Errore inaspettato" exitAfter:true];
        exit(1);
    }
    
    if([self checkEnabled])
    {
        NSAlert* confirmAlert = [NSAlert alertWithMessageText: @"CIE già abilitata"
                                                defaultButton:@"No"
                                              alternateButton:@"Si"
                                                  otherButton:nil
                                    informativeTextWithFormat:@"La CIE sul lettore è già abilitata. Vuoi disabilitarla?"];
        
        if([confirmAlert runModal] == NSAlertDefaultReturn)
        {
            exit(1);
        }
        else
        {
            DisabilitaCIEfn pfnDisabilitaCIE = (VerificaCIEAbilitatafn)dlsym(hModule, "DisabilitaCIE");
            if(!pfnDisabilitaCIE)
            {
                dlclose(hModule);
                [self showMessage: @"Funzione DisabilitaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:true];
                return;
            }
            
            CK_RV rv = pfnDisabilitaCIE();
            
            switch (rv) {
                case CKR_OK:
                    [self showMessage:@"CIE disabilitata con successo" withTitle:@"CIE disabilitata" exitAfter:NO];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"CIE non presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                default:
                    [self showMessage:@"Impossibile disabilitare la CIE" withTitle:@"CIE non disabilitata" exitAfter:NO];
                    break;
            }
        }
    }
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

- (bool) checkEnabled
{
    // check se abilitata ossia se cache presente
    VerificaCIEAbilitatafn pfnVerificaCIE = (VerificaCIEAbilitatafn)dlsym(hModule, "VerificaCIEAbilitata");
    if(!pfnVerificaCIE)
    {
        dlclose(hModule);
        [self showMessage: @"Funzione VerificaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
        return false;
    }
    
    CK_RV rv = pfnVerificaCIE();
    
    switch (rv) {
        case CKR_OK:
            return false;
            break;
        
        case CKR_CANCEL:
            return true;
            break;
            
        case CKR_TOKEN_NOT_PRESENT:
            [self showMessage:@"CIE non presente sul lettore" withTitle:@"Verifica CIE" exitAfter:false];
            break;
            
        default:
            [self showMessage:@"Errore nella verifica della CIE" withTitle:@"Verifica CIE" exitAfter:false];
            break;
    }
    
    return false;
}
           
- (IBAction)onAbilita:(id)sender
{
    NSString* pin = self.textFieldPIN.stringValue;
    
    [((NSControl*)sender) setEnabled:NO];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
        AbilitaCIEfn pfnAbilitaCIE = (AbilitaCIEfn)dlsym(hModule, "AbilitaCIE");
        if(!pfnAbilitaCIE)
        {
            dlclose(hModule);
            [self showMessage: @"Funzione AbilitaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
            return;
        }
        
        char* szPAN = NULL;
        
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        
        if(args.count > 1)
            szPAN = (char*)[((NSString*)[args objectAtIndex:1]) cStringUsingEncoding:NSUTF8StringEncoding];
        
        int attempts = -1;
        
        
        long ret = pfnAbilitaCIE(szPAN, [pin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallback);

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
                    [self showMessage:@"L'abilitazione della CIE è avvennuta con successo" withTitle:@"CIE Abilitata" exitAfter:NO];
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

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo
{
    if(*contextInfo)
        exit(0);
}
@end

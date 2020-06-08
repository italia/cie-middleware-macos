//
//  MainViewController.m
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "MainViewController.h"

// directive for PKCS#11
#include "../cie-pkcs11/PKCS11/cryptoki.h"
#import "PINNoticeViewController.h"

#include <memory.h>
#include <time.h>
#include <dlfcn.h>


#include "../cie-pkcs11/CSP/AbilitaCIE.h"
#include "../cie-pkcs11/CSP/PINManager.h"

using namespace std;

typedef CK_RV (*C_GETFUNCTIONLIST)(CK_FUNCTION_LIST_PTR_PTR ppFunctionList);
CK_FUNCTION_LIST_PTR g_pFuncList;


@implementation MainViewController

NSTextField* labelProgressPointer;
NSProgressIndicator* progressIndicatorPointer;

NSTextField* labelProgressPointerCambioPIN;
NSProgressIndicator* progressIndicatorPointerCambioPIN;

NSTextField* labelProgressPointerSbloccoPIN;
NSProgressIndicator* progressIndicatorPointerSbloccoPIN;

string sPAN;
string sName;
string sEfSeriale;

void* hModule;

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    const char* szCryptoki = "libcie-pkcs11.dylib";
    
    hModule = dlopen(szCryptoki, RTLD_LAZY);
    if(!hModule)
    {
        [self showMessage: @"Middleware non trovato" withTitle:@"Errore inaspettato" exitAfter:true];
        exit(1);
    }
    
    _labelProgress.stringValue = @"";
    
    labelProgressPointer = _labelProgress;
    progressIndicatorPointer = _progressIndicator;
    
    labelProgressPointerCambioPIN = _labelProgressCambioPIN;
    progressIndicatorPointerCambioPIN = _progressIndicatorCambioPIN;
    
    labelProgressPointerSbloccoPIN = _labelProgressSbloccoPIN;
    progressIndicatorPointerSbloccoPIN = _progressIndicatorSbloccoPIN;
}

- (void) viewDidAppear
{
    [super viewDidAppear];
    
    self.view.window.delegate = self;

    [self showHomeFirstPage];
    
    
    if(![NSUserDefaults.standardUserDefaults objectForKey:@"dontShowIntro"])
    {
        NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        NSViewController* viewController = [storyboard instantiateControllerWithIdentifier:@"IntroViewController"];
        
        [self presentViewControllerAsModalWindow:viewController];
    }
}

- (BOOL) windowShouldClose: (NSObject*) sender
{
    [NSApplication.sharedApplication terminate:self];
    
    return YES;
}

// delete key detection
- (BOOL)control:(NSTextField *)textField textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if (commandSelector == @selector(deleteBackward:)){
        //NSLog(@"Backspace!!");
        
        if(textField.tag > 1)
        {
            NSTextField* textField1;
            if(textField.stringValue.length == 0)
            {
                textField1 = [self.view viewWithTag:textField.tag - 1];
            }
            else
            {
                textField1 = textField;
            }
            
            textField1.stringValue = @"";
            [textField1 selectText:nil];
        }
    }
    else if (commandSelector == @selector(insertNewline:)){
        //NSLog(@"newline!!");
        if(textField.tag == 8)
            [self abbina:textField];
    }
        
    return NO;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    
    if(textField.tag > 0)
    {
        if(textField.tag < 8)
        {
            NSTextField* textField1 = [self.view viewWithTag:textField.tag + 1];
            textField1.stringValue = @"";
            [textField1 selectText:nil];
        }
        else
        {
            textField.stringValue = [textField.stringValue substringToIndex:1];
        }
    }
}

CK_RV progressCallback(const int progress,
                       const char* szMessage)
{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        labelProgressPointer.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointer.doubleValue = progress;
    });
    
    return 0;
}

CK_RV progressCallbackCambioPIN(const int progress,
                       const char* szMessage)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        labelProgressPointerCambioPIN.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointerCambioPIN.doubleValue = progress;
    });
    
    return 0;
}


CK_RV progressCallbackSbloccoPIN(const int progress,
                       const char* szMessage)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        labelProgressPointerSbloccoPIN.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointerSbloccoPIN.doubleValue = progress;
    });
    
    return 0;
}

CK_RV completedCallback(string& PAN,
                        string& name,
                        string& ef_seriale)
{
    
    NSLog(@"CompletedCallback %s %s %s", PAN.c_str(), name.c_str(), ef_seriale.c_str());
    
    
    sPAN = PAN;
    sName = name;
    sEfSeriale = ef_seriale;
    
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
    
    NSString* pan = [NSUserDefaults.standardUserDefaults objectForKey:@"PAN"];
    if(pan)
    {
        CK_RV rv = pfnVerificaCIE([pan cStringUsingEncoding:NSUTF8StringEncoding]);
        
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
    }
    
    return false;
}

- (IBAction)onDisabilita:(id)sender
{
    [self askRemove:@"Vuoi rimuovere la CIE attualmente abbinata?" withTitle:@"Rimozione CIE"];
}

- (void) disabilita
{
    NSString* pan = [NSUserDefaults.standardUserDefaults objectForKey:@"serialnumber"];
    
    // check se abilitata ossia se cache presente
    VerificaCIEAbilitatafn pfnVerificaCIE = (VerificaCIEAbilitatafn)dlsym(hModule, "VerificaCIEAbilitata");
    if(!pfnVerificaCIE)
    {
        dlclose(hModule);
        [self showMessage: @"Funzione VerificaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
        return;
    }
    
    CK_RV rv = pfnVerificaCIE([pan cStringUsingEncoding:NSUTF8StringEncoding]);
    
    switch (rv) {
        case CKR_OK:
            [self showMessage:@"CIE non abilitata" withTitle:@"Verifica CIE" exitAfter:false];
            return;
            break;
            
        case CKR_CANCEL:
            break;
            
        case CKR_TOKEN_NOT_PRESENT:
            [self showMessage:@"CIE non presente sul lettore" withTitle:@"Verifica CIE" exitAfter:false];
            break;
            
        default:
            [self showMessage:@"Errore nella verifica della CIE" withTitle:@"Verifica CIE" exitAfter:false];
            return;
            break;
    }
    
    DisabilitaCIEfn pfnDisabilitaCIE = (VerificaCIEAbilitatafn)dlsym(hModule, "DisabilitaCIE");
    if(!pfnDisabilitaCIE)
    {
        dlclose(hModule);
        [self showMessage: @"Funzione DisabilitaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:true];
        return;
    }
    
    rv = pfnDisabilitaCIE([pan cStringUsingEncoding:NSUTF8StringEncoding]);
    
    switch (rv) {
        case CKR_OK:
            [self showMessage:@"CIE disabilitata con successo" withTitle:@"CIE disabilitata" exitAfter:NO];
            self.labelSerialNumber.stringValue = @"";
            self.labelCardHolder.stringValue = @"";
            
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"serialnumber"];
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"cardholder"];
            
            if( [NSUserDefaults.standardUserDefaults objectForKey:@"efSeriale"])
                [NSUserDefaults.standardUserDefaults removeObjectForKey:@"efSeriale"];
            
            [NSUserDefaults.standardUserDefaults synchronize];
            
            [self showHomeFirstPage];
            break;
            
        case CKR_TOKEN_NOT_PRESENT:
            [self showMessage:@"CIE non presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
            break;
            
        default:
            [self showMessage:@"Impossibile disabilitare la CIE" withTitle:@"CIE non disabilitata" exitAfter:NO];
            break;
    }
}

- (IBAction)home:(id)sender
{
    [self showHomeFirstPage];
}

- (IBAction)cambioPIN:(id)sender
{
    [self showCambioPINPage];
}

- (IBAction)sbloccaCarta:(id)sender
{
    [self showSbloccoPage];
}

- (IBAction)tutorial:(id)sender
{
    [self showTutorialPage];
}

- (IBAction)aiuto:(id)sender
{
    [self showHelpPage];
}

- (IBAction)informazioni:(id)sender
{
    [self showInfoPage];
}

- (IBAction)abbina:(id)sender
{
    NSString* pin = @"";
    
    for(int i = 1; i < 9; i++)
    {
        NSTextField* txtField = [self.view viewWithTag:i];
        
        pin = [pin stringByAppendingString:txtField.stringValue];
    }
    
    if(pin.length != 8)
    {
        [self showMessage: @"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        [self showHomeFirstPage];
        return;
    }
    
    unichar c = [pin characterAtIndex:0];
    
    int i = 1;
    for(i = 1; i < pin.length && (c >= '0' && c <= '9'); i++)
    {
        c = [pin characterAtIndex:i];
    }
    
    if(i < pin.length || !(c >= '0' && c <= '9'))
    {
        [self showMessage: @"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
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
        {
            NSString* arg = ((NSString*)[args objectAtIndex:1]);
            if(![arg hasPrefix:@"-NS"]) // for running in debug from xcode
                szPAN = (char*)[arg cStringUsingEncoding:NSUTF8StringEncoding];
        }
        
        int attempts = -1;
        
        [self showHomeSecondPage];
        
        long ret = pfnAbilitaCIE(szPAN, [pin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallback, &completedCallback);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [((NSControl*)sender) setEnabled:YES];
            
            switch(ret)
            {
                case CKR_TOKEN_NOT_RECOGNIZED:
                    if(szPAN)
                        [self showMessage:[NSString stringWithFormat:@"CIE con numero identificativo %s non presente sul lettore", szPAN] withTitle:@"Abilitazione CIE" exitAfter:false];
                    else
                        [self showMessage:@"CIE non presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
                    
                    [self showHomeFirstPage];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"CIE non presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
                    [self showHomeFirstPage];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PIN digitato è errato. rimangono %d tentativi", attempts] withTitle:@"PIN non corretto" exitAfter:false];
                    
                    [self showHomeFirstPage];
                    
                    break;
                    
                case CKR_PIN_LOCKED:
                    [self showMessage:@"Munisciti del codice PUK e utilizza la funzione di sblocco carta per abilitarla" withTitle:@"Carta bloccata" exitAfter:false];
                    [self showHomeFirstPage];
                    break;
                    
                case CKR_GENERAL_ERROR:
                    [self showMessage:@"Errore inaspettato durante la comunicazione con la smart card" withTitle:@"Errore inaspettato" exitAfter:false];
                    [self showHomeFirstPage];
                    break;
                    
                case CKR_OK:
                    [self showMessage:@"L'abilitazione della CIE è avvennuta con successo. Allontanare la card dal lettore" withTitle:@"CIE Abilitata" exitAfter:NO];
                    
                    self.labelSerialNumber.stringValue = [NSString stringWithUTF8String:sEfSeriale.c_str()];
                    self.labelCardHolder.stringValue = [NSString stringWithUTF8String:sName.c_str()];
                    
                    NSString *PAN =
                    [[NSString alloc] initWithCString:sPAN.c_str()
                                      encoding:NSMacOSRomanStringEncoding];
                    
                    //[NSUserDefaults.standardUserDefaults setObject:PAN forKey:@"PAN"];
                    
                    [NSUserDefaults.standardUserDefaults setObject:self.labelSerialNumber.stringValue forKey:@"efSeriale"];
                    [NSUserDefaults.standardUserDefaults setObject:PAN forKey:@"serialnumber"];
                    [NSUserDefaults.standardUserDefaults setObject:self.labelCardHolder.stringValue forKey:@"cardholder"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                    
                    
                    [self showHomeThirdPage];
                    
                    break;
            }
        });
    });
}

- (IBAction)sblocca:(id)sender
{
    NSString* puk = self.textFieldPUK.stringValue;
    NSString* newpin = self.textFieldNewPINSblocco.stringValue;
    NSString* confirmpin = self.textFieldConfirmPINSbloco.stringValue;
    
    if(puk.length != 8)
    {
        [self showMessage: @"Il PUK deve essere composto da 8 numeri" withTitle:@"PUK non corretto" exitAfter:false];
        return;
    }
    
    if(newpin.length != 8)
    {
        [self showMessage: @"Il nuovo PIN deve essere composto da 8 numeri" withTitle:@"Nuovo PIN non corretto" exitAfter:false];
        return;
    }
    
    unichar c = [puk characterAtIndex:0];
    
    int i = 1;
    for(i = 1; i < puk.length && (c >= '0' && c <= '9'); i++)
    {
        c = [puk characterAtIndex:i];
    }
    
    if(!(c >= '0' && c <= '9'))
    {
        [self showMessage: @"Il PUK deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    
    for(i = 1; i < newpin.length && (c >= '0' && c <= '9'); i++)
    {
        c = [newpin characterAtIndex:i];
    }
    
    if(!(c >= '0' && c <= '9'))
    {
        [self showMessage: @"Il nuovo PIN deve essere composto da 8 numeri" withTitle:@"Nuovo PIN non corretto" exitAfter:false];
        return;
    }
    
    if(![newpin isEqualToString:confirmpin])
    {
        [self showMessage: @"I PIN non corrispondono" withTitle:@"PIN non corrispondenti" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    unichar lastchar = c;
    
    i = 1;
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
    
    self.progressIndicatorSbloccoPIN.hidden = NO;
    self.labelProgressSbloccoPIN.hidden = NO;

    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
        SbloccoPINfn pfnSbloccoPIN = (SbloccoPINfn)dlsym(hModule, "SbloccoPIN");
        if(!pfnSbloccoPIN)
        {
            dlclose(hModule);
            [self showMessage: @"Funzione SbloccoPIN non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:false];
            return;
        }
        
        int attempts = -1;
        
        long ret = pfnSbloccoPIN([puk cStringUsingEncoding:NSUTF8StringEncoding], [newpin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallbackSbloccoPIN);
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            self.progressIndicatorSbloccoPIN.hidden = YES;
            self.labelProgressSbloccoPIN.hidden = YES;

            
            [((NSControl*)sender) setEnabled:YES];
            
            switch(ret)
            {
                case CKR_TOKEN_NOT_RECOGNIZED:
                    [self showMessage:@"La smart card inserita non è una CIE" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"Nessuna CIE trovata" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PUK digitato è errato. rimangono %d tentativi", attempts] withTitle:@"PIN non corretto" exitAfter:false];
                    break;
                    
                case CKR_PIN_LOCKED:
                    [self showMessage:@"La carta utilizzata è bloccata in modo irreversibile, è necessaria la sostituzione" withTitle:@"Carta bloccata" exitAfter:false];
                    break;
                    
                case CKR_GENERAL_ERROR:
                    [self showMessage:@"Errore inaspettato durante la comunicazione con la CIE" withTitle:@"Errore inaspettato" exitAfter:false];
                    break;
                    
                case CKR_OK:
                    [self showSbloccoOKPage];
//                    [self showMessage:@"Il PIN è stato sbloccato con successo" withTitle:@"Operazione completata" exitAfter:false];
                    self.textFieldPUK.stringValue = @"";
                    self.textFieldNewPINSblocco.stringValue = @"";
                    self.textFieldConfirmPINSbloco.stringValue = @"";
                    
                    NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
                    NSViewController* viewController = [storyboard instantiateControllerWithIdentifier:@"PINNoticeViewController"];
                    
                    [self presentViewControllerAsModalWindow:viewController];
                    
                    break;
            }
        });
    });
}



- (IBAction)concludi:(id)sender
{
    [self showHomeFourthPage];
}

- (IBAction)cambiaPIN:(id)sender
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
        [self showMessage: @"" withTitle:@"PIN non corrispondenti" exitAfter:false];
        return;
    }
    
    if([newpin isEqualToString:pin])
    {
        [self showMessage: @"Il vecchio e nuovo PIN non possoo essere uguali" withTitle:@"PIN identici" exitAfter:false];
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
    
    self.progressIndicatorCambioPIN.hidden = NO;
    self.labelProgressCambioPIN.hidden = NO;

    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
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
        
        
        long ret = pfnCambioPIN([pin cStringUsingEncoding:NSUTF8StringEncoding], [newpin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallbackCambioPIN);
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            self.progressIndicatorCambioPIN.hidden = YES;
            self.labelProgressCambioPIN.hidden = YES;
            
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
                    [self showMessage:@"Munisciti del codice PUK e utilizza la funzione di sblocco carta per abilitarla" withTitle:@"Carta bloccata" exitAfter:false];
                                        
                    break;
                    
                case CKR_GENERAL_ERROR:
                    [self showMessage:@"Errore inaspettato durante la comunicazione con la CIE" withTitle:@"Errore inaspettato" exitAfter:false];
                    break;
                    
                case CKR_OK:
//                    [self showMessage:@"Il PIN è stato modificato con successo" withTitle:@"Operazione completata" exitAfter:false];
                    self.textFieldPIN.stringValue = @"";
                    self.textFieldNewPIN.stringValue = @"";
                    self.textFieldConfirmPIN.stringValue = @"";
                    
                    [self showCambioPINOKPage];
                    
                    NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
                    NSViewController* viewController = [storyboard instantiateControllerWithIdentifier:@"PINNoticeViewController"];
                    
                    [self presentViewControllerAsModalWindow:viewController];
                    
                    break;
            }
        });
    });
}


- (void) askRiabbina: (NSString*) message withTitle: (NSString*) title
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"SI"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSAlertStyleInformational];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(askRiabbinaDidEnd:returnCode:contextInfo:) contextInfo:nil];
    });
}


- (void)askRiabbinaDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo
{
    if(returnCode == NSAlertFirstButtonReturn)
    {
            self.labelSerialNumber.stringValue = @"";
            self.labelCardHolder.stringValue = @"";
            
            self.homeFirstPageView.hidden = NO;
            self.homeSecondPageView.hidden = YES;
            self.homeThirdPageView.hidden = YES;
            self.homeFourthPageView.hidden = YES;
            self.cambioPINPageView.hidden = YES;
            self.cambioPINOKPageView.hidden = YES;
            self.sbloccoPageView.hidden = YES;
            self.sbloccoOKPageView.hidden = YES;
            self.helpPageView.hidden = YES;
            self.infoPageView.hidden = YES;
            
            for(int i = 1; i < 9; i++)
            {
                NSTextField* txtField = [self.view viewWithTag:i];
                
                txtField.stringValue = @"";
            }
            
            NSTextField* txtField = [self.view viewWithTag:1];
            [txtField selectText:nil];
    }else{
        self.labelSerialNumber.stringValue = @"Per visualizzarlo occorre\nrifare l'abbinamento";
        
        [self.labelSerialNumber sizeToFit];
        self.labelCardHolder.stringValue = [NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"];
        
        [self showHomeFourthPage];
    }
}

- (void) showHomeFirstPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        if((![NSUserDefaults.standardUserDefaults objectForKey:@"efSeriale"]) and [NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"])
        {
            
            self.labelCardHolder.stringValue = [NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"];
            
            
            self.labelSerialNumber.stringValue = @"Per visualizzarlo occorre\nrifare l'abbinamento";
            
            [self askRiabbina:@"E' necessario effettuare un nuovo abbinamento. Procedere?" withTitle:@"Abbinare nuovamente la CIE"];
            
        }else if([NSUserDefaults.standardUserDefaults objectForKey:@"efSeriale"] and [NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"])
        {
            self.labelSerialNumber.stringValue = [NSUserDefaults.standardUserDefaults objectForKey:@"efSeriale"];
            
            self.labelCardHolder.stringValue = [NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"];
            
            [self showHomeFourthPage];
        }
        else
        {
            
            self.labelSerialNumber.stringValue = @"";
            self.labelCardHolder.stringValue = @"";
            
            //    if(self.homeFirstPageView.hidden)
            //    {
            self.homeFirstPageView.hidden = NO;
            self.homeSecondPageView.hidden = YES;
            self.homeThirdPageView.hidden = YES;
            self.homeFourthPageView.hidden = YES;
            self.cambioPINPageView.hidden = YES;
            self.cambioPINOKPageView.hidden = YES;
            self.sbloccoPageView.hidden = YES;
            self.sbloccoOKPageView.hidden = YES;
            self.helpPageView.hidden = YES;
            self.infoPageView.hidden = YES;
            
            for(int i = 1; i < 9; i++)
            {
                NSTextField* txtField = [self.view viewWithTag:i];
                
                txtField.stringValue = @"";
            }
            
            NSTextField* txtField = [self.view viewWithTag:1];
            [txtField selectText:nil];
             
        }
        //    }
    });
}

- (void) showHomeThirdPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = NO;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
    });
}

- (void) showHomeSecondPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = NO;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
    });
}


- (void) showHomeFourthPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = NO;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
    });
}

- (void) showCambioPINPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.progressIndicatorCambioPIN.hidden = YES;
        self.labelProgressCambioPIN.hidden = YES;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = NO;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = YES;
        self.sbloccoOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
    });
}

- (void) showCambioPINOKPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = NO;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
    });
}

- (void) showSbloccoPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.progressIndicatorSbloccoPIN.hidden = YES;
        self.labelProgressSbloccoPIN.hidden = YES;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = NO;
        self.sbloccoOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
    });
}

- (void) showSbloccoOKPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = YES;
        self.sbloccoOKPageView.hidden = NO;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
    });
}

- (void) showHelpPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        
        self.labelHelp.stringValue = @"Aiuto";
        self.assistenzaImageView.hidden = NO;
        self.sbloccoImageView.hidden = NO;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = NO;
        self.infoPageView.hidden = YES;
        
        [self.helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/aiuto.jsp"]]];
    });
}

- (void) showTutorialPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.labelHelp.stringValue = @"Tutorial";
        self.assistenzaImageView.hidden = YES;
        self.sbloccoImageView.hidden = YES;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = NO;
        self.infoPageView.hidden = YES;
        
        [self.helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/tutorial_mac.jsp"]]];
    });
}

- (void) showInfoPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = NO;
        
        [self.infoWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/privacy.jsp"]]];
    });
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

- (void) askRemove: (NSString*) message withTitle: (NSString*) title
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"SI"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSAlertStyleInformational];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(askRemoveDidEnd:returnCode:contextInfo:) contextInfo:nil];
    });
}


- (void)askRemoveDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo
{
    if(returnCode == NSAlertFirstButtonReturn)
        [self disabilita];
}


@end

//
//  MainViewController.m
//  CIE ID
//
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "MainViewController.h"
#import <IOKit/IOKitLib.h>
#import <CommonCrypto/CommonDigest.h>
#import "ProxyInfoManager.h"
#import "CarouselView.h"
#import "PINNoticeViewController.h"
#import "CieList.h"
#import "Cie.h"
#import "ChangeView.h"
#import "CIE_ID-Swift.h"
#import "PreferencesManager.h"
#import "AppDelegate.h"
#import <SSZipArchive/SSZipArchive.h>
#include "../cie-pkcs11/Cryptopp/aes.h"

// directive for PKCS#11
#include "../cie-pkcs11/PKCS11/cryptoki.h"
#include <memory.h>
#include <time.h>
#include <dlfcn.h>
#include "../cie-pkcs11/CSP/AbilitaCIE.h"
#include "../cie-pkcs11/CSP/PINManager.h"
#include "../cie-pkcs11/Sign/CIEVerify.h"
#include "../cie-pkcs11/CSP/FirmaConCIE.h"
#include "../cie-pkcs11/CSP/VerificaConCIE.h"

#define CARD_ALREADY_ENABLED        0x000000F0
#define CARD_PAN_MISMATCH           0x000000F1

using namespace std;

typedef CK_RV (*C_GETFUNCTIONLIST)(CK_FUNCTION_LIST_PTR_PTR ppFunctionList);
CK_FUNCTION_LIST_PTR g_pFuncList;

static NSString * const LogConfigPrefixLib = @"LIB_LOG_LEVEL";
static NSString * const LogConfigPrefixApp = @"APP_LOG_LEVEL";

struct logLevels {
    AppLogLevel logLevelApp;
    AppLogLevel logLevelLib;
};

@interface MainViewController() <CarouselViewDelegate, NSTableViewDataSource, NSTableViewDelegate> {
    Cie *removingCie;
}

@property (weak) IBOutlet NSTextField *lblCades;
@property (weak) IBOutlet NSTextField *lblCadesSub;
@property (weak) IBOutlet NSImageView *pictureCades;
@property (weak) IBOutlet NSTextField *lblPades;
@property (weak) IBOutlet NSTextField *lblPadesSub;
@property (weak) IBOutlet NSImageView *picturePades;
@property (weak) IBOutlet NSTextField *filePathSignOp;
@property (weak) IBOutlet NSButton *cbGraphicSignature;
@property (weak) IBOutlet NSView *viewSignatureSelectOp;
@property (weak) IBOutlet NSView *prevImageView;
@property (weak) IBOutlet NSTextField *lblPathSignaturePreview;
@property (weak) IBOutlet NSTextField *lblPathSignaturePIN;
@property (weak) IBOutlet NSTextField *lblInsertPIN;
@property (weak) IBOutlet NSProgressIndicator *progressSignature;
@property (weak) IBOutlet NSTextField *lblProgressSignature;
@property (weak) IBOutlet NSImageView *imgSignatureOK;
@property (weak) IBOutlet NSView *cvInsertPIN;
@property (weak) IBOutlet NSButton *btnAbortSignature;
@property (weak) IBOutlet NSButton *btnSignatureCompleted;
@property (weak) IBOutlet NSButton *btnSign;
@property (weak) IBOutlet NSButton *btnMenuDigitalSignature;
@property (weak) IBOutlet NSButton *btnMenuVerifySignature;
@property (weak) IBOutlet NSTextField *lblPathOp;
@property (weak) IBOutlet NSButton *btnProceedSignatureOp;
@property (weak) IBOutlet NSImageView *signImageView;
@property (weak) IBOutlet NSTextField *lblDigitalSignatureHeader;
@property (weak) IBOutlet NSTextField *lblDigitalSignatureHeaderSubtitle;
@property (weak) IBOutlet NSView *fileSelectionSignatureBlockView;
@property (weak) IBOutlet NSTextFieldCell *lblCustomizeGraphicSignature;
@property (weak) IBOutlet NSButton *btnCustomizeGraphicSignature;
@property (weak) IBOutlet NSTextField *lblGraphicSignatureCustomizationDesc;
@property (weak) IBOutlet NSTextField *lblCustomized;
@property (weak) IBOutlet NSTableView *tbVerifyInfo;
@property (weak) IBOutlet NSTextField *lblVerifyPath;
@property (weak) IBOutlet NSTextField *lblSignersNumber;
@property (weak) IBOutlet NSImageView *imgUpload;
@property (weak) IBOutlet NSButton *btnGenerateGraphicSignature;
@property (weak) IBOutlet NSTextField *txtProxyAddr;
@property (weak) IBOutlet NSTextField *txtUsername;
@property (weak) IBOutlet NSSecureTextField *txtPassword;
@property (weak) IBOutlet NSTextField *plainPassword;

@property (weak) IBOutlet NSTextField *txtPort;
@property (weak) IBOutlet NSButton *cbShowPsw;
@property (weak) IBOutlet NSButton *btnSaveProxy;
@property (weak) IBOutlet NSButton *btnEditProxy;
@property (weak) IBOutlet NSButton *btnExtractFile;

@property (weak) IBOutlet NSLayoutConstraint *pairButtonWhenAbortVisible;

@property (weak) IBOutlet NSLayoutConstraint *pairButtonWhenAbortInvisible;
@property (weak) IBOutlet NSView *mainCustomView;

@property (nonatomic, strong) NSString *tmpPANCIE;
@property BOOL fullPINSignature;
@property PreferencesManager *prefManager;
@property NSWindow *window;

typedef NS_ENUM(NSUInteger, signOp) {
    NO_OP,
    CADES_SIGNATURE,
    PADES_SIGNATURE,
    VERIFY,
};

@end

@implementation MainViewController

NSTextField* labelProgressPointer;
NSProgressIndicator* progressIndicatorPointer;

NSTextField* labelProgressPointerChangePIN;
NSProgressIndicator* progressIndicatorPointerChangePIN;

NSTextField* labelProgressPointerUnlockPIN;
NSProgressIndicator* progressIndicatorPointerUnlockPIN;

NSProgressIndicator* progressIndicatorSignaturePointer;
NSTextField* lblInsertPinPointer;
NSTextField* lblProgressSignaturePointer;
NSView* cvInsertPinPointer;
NSButton* btnAbortPointer;
NSButton* btnAbortSignaturePointer;
NSButton* btnSignaturePointer;
NSButton* btnSignatureCompletedPointer;
NSImageView* imgSignatureOKPointer;
NSButton* cbGraphicSignaturePointer;

string sPAN;
string sName;
string sEfSeriale;

NSString *filePath;
NSString *path;
NSArray *viewArray;
NSMutableArray <VerifyItem *> *verifyItems;

signOp operation;
PdfPreview *pdfPreview;

CieList *cieList;

void* hModule;

@synthesize logLevelApp;
@synthesize logLevelLib;

AppLogger *logger;

- (void)loadView {
    [super loadView];
    viewArray = [[NSArray alloc] initWithObjects:_homeFirstPageView,
                 _homeSecondPageView,
                 _homeThirdPageView,
                 _homeFourthPageView,
                 _changePINPageView,
                 _changePINOKPageView,
                 _unlockPageView,
                 _unlockOKPageView,
                 _helpPageView,
                 _infoPageView,
                 _selectFilePageView,
                 _selectOperationView,
                 _signOperationView,
                 _signPreView,
                 _signPINView,
                 _customizeGraphicSignatureView,
                 _verifyView,
                 _settingsView,
                 nil];
    ChangeView *cG = [ChangeView getInstance];
    cG.viewArray = viewArray;
    [self showHomeFirstPage];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _prefManager = PreferencesManager.sharedInstance;
    logger = [AppLogger sharedInstanceWithDefaultLogLevel];
    [self LoadLogConfigFromFile];
    [logger info:@"App CIE - logger inizializzato"];
    [logger debug:@"App CIE - debug"];
    [logger error:@"App CIE - error"];
    [logger info:[NSString stringWithFormat:@"[I] Livello di log applicazione: %ld", [self logLevelApp]]];
    [logger info:[NSString stringWithFormat:@"[I] Livello di log libreria: %ld", [self logLevelLib]]];
    [logger info:@"Inizializzo view principale"];
    
    [_viewSignatureSelectOp updateLayer];
    [self addSubviewToMainCustomView:_homeFirstPageView];
    [self addSubviewToMainCustomView:_homeSecondPageView];
    [self addSubviewToMainCustomView:_homeThirdPageView];
    [self addSubviewToMainCustomView:_homeFourthPageView];
    [self addSubviewToMainCustomView:_changePINPageView];
    [self addSubviewToMainCustomView:_changePINOKPageView];
    [self addSubviewToMainCustomView:_unlockPageView];
    [self addSubviewToMainCustomView:_unlockOKPageView];
    [self addSubviewToMainCustomView:_helpPageView];
    [self addSubviewToMainCustomView:_infoPageView];
    [self addSubviewToMainCustomView:_selectFilePageView];
    [self addSubviewToMainCustomView:_selectOperationView];
    [self addSubviewToMainCustomView:_signOperationView];
    [self addSubviewToMainCustomView:_signPreView];
    [self addSubviewToMainCustomView:_signPINView];
    [self addSubviewToMainCustomView:_customizeGraphicSignatureView];
    [self addSubviewToMainCustomView:_verifyView];
    [self addSubviewToMainCustomView:_settingsView];
    [_imgUpload unregisterDraggedTypes];
    operation = NO_OP;
    
    if (([NSUserDefaults.standardUserDefaults objectForKey:@"cieDictionary"])) {
        NSData *cieData = [NSUserDefaults.standardUserDefaults objectForKey:@"cieDictionary"];
        CieList *test = [[CieList alloc] init:cieData];
        NSDictionary *cieDict = [test getDictionary];
        
        if (cieDict.count > 0) {
            [_homeFourthPageView setHidden:NO];
        } else {
            [_homeFirstPageView setHidden:NO];
        }
    } else {
        [_homeFirstPageView setHidden:NO];
    }
    
    [self updateViewConstraints];
    const char* szCryptoki = "libcie-pkcs11.dylib";
    hModule = dlopen(szCryptoki, RTLD_LAZY);
    
    if (!hModule) {
        [self showMessage:@"Middleware non trovato" withTitle:@"Errore inaspettato" exitAfter:true];
        exit(1);
    }
    
    _labelProgress.stringValue = @"";
    labelProgressPointer = _labelProgress;
    progressIndicatorPointer = _progressIndicator;
    labelProgressPointerChangePIN = _labelProgressChangePIN;
    progressIndicatorPointerChangePIN = _progressIndicatorChangePIN;
    labelProgressPointerUnlockPIN = _labelProgressUnlockPIN;
    progressIndicatorPointerUnlockPIN = _progressIndicatorUnlockPIN;
    progressIndicatorSignaturePointer = _progressSignature;
    lblInsertPinPointer =  _lblInsertPIN;
    lblProgressSignaturePointer = _lblProgressSignature;
    cvInsertPinPointer = _cvInsertPIN;
    btnAbortPointer = _btnAbort;
    btnAbortSignaturePointer = _btnAbortSignature;
    btnSignaturePointer = _btnSign;
    btnSignatureCompletedPointer = _btnSignatureCompleted;
    imgSignatureOKPointer = _imgSignatureOK;
    cbGraphicSignaturePointer = _cbGraphicSignature;
    
    self.carouselView.delegate = self;
    [self.tbVerifyInfo registerNib:[[NSNib alloc] initWithNibNamed:@"VerifyCell" bundle:nil]forIdentifier:@"verifyCellID"];
    self.tbVerifyInfo.delegate = self;
    self.tbVerifyInfo.dataSource = self;
}

- (void)addSubviewToMainCustomView:(NSView *)view {
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.mainCustomView addSubview:view];
    [self.mainCustomView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainCustomView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.mainCustomView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainCustomView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.mainCustomView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainCustomView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self.mainCustomView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainCustomView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    self.view.window.delegate = self;
    [self showHomeFirstPage];
    [self updateAbbinaAndAnnullaLayout];
    
    [NSUserDefaults.standardUserDefaults setObject:@"OK" forKey:@"dontShowIntro"];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    if([NSUserDefaults.standardUserDefaults objectForKey:@"dontShowIntro"] &&
       ![[_prefManager getConfigKeyValue:@"SHOW_TUTORIAL"] isEqualToString: @"YES"]) {
        [_prefManager setConfigKeyValue:@"SHOW_TUTORIAL" : @"NO"];
    }
    
    if ([[_prefManager getConfigKeyValue:@"SHOW_TUTORIAL"] isEqualToString: @"YES"] ||
        ![_prefManager getConfigKeyValue:@"SHOW_TUTORIAL"]) {
        NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        NSViewController* viewController = [storyboard instantiateControllerWithIdentifier:@"IntroViewController"];
        [self presentViewControllerAsModalWindow:viewController];
    }
}

- (BOOL)windowShouldClose:(NSObject*)sender {
    
    [NSApplication.sharedApplication terminate:self];
    return YES;
}

// delete key detection
- (BOOL)control:(NSTextField *)textField textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(deleteBackward:)) {
        //NSLog(@"Backspace!!");
        if (textField.tag > 1) {
            NSTextField* textField1;
            
            if (textField.stringValue.length == 0 && textField.tag != 9) {
                textField1 = [self.view viewWithTag:textField.tag - 1];
            } else {
                textField1 = textField;
            }
            
            textField1.stringValue = @"";
            [textField1 selectText:nil];
        }
    } else if (commandSelector == @selector(insertNewline:)) {
        //NSLog(@"newline!!");
        if (textField.tag == 8) {
            [self abbina:textField];
        }
    }
    
    return NO;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    
    if (textField.tag > 0) {
        if (textField.tag < ((self.fullPINSignature) ? 17 : 13)) {
            if (textField.tag == 8 || textField.tag == ((self.fullPINSignature) ? 16 : 12)) {
                textField.stringValue = [textField.stringValue substringToIndex:1];
            } else {
                NSTextField* textField1 = [self.view viewWithTag:textField.tag + 1];
                textField1.stringValue = @"";
                [textField1 selectText:nil];
            }
        } else {
            textField.stringValue = [textField.stringValue substringToIndex:1];
        }
    }
}

CK_RV progressCallback(const int progress,
                       const char* szMessage) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        labelProgressPointer.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointer.doubleValue = progress;
    });
    return 0;
}

CK_RV progressSignatureCallback(const int progress,
                                const char* szMessage) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        progressIndicatorSignaturePointer.doubleValue = progress;
    });
    return 0;
}

CK_RV progressCallbackCambioPIN(const int progress,
                                const char* szMessage) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        labelProgressPointerChangePIN.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointerChangePIN.doubleValue = progress;
    });
    return 0;
}

CK_RV progressCallbackUnlockPIN(const int progress,
                                const char* szMessage) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        labelProgressPointerUnlockPIN.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointerUnlockPIN.doubleValue = progress;
    });
    return 0;
}

CK_RV completedSignatureCallback(int ret) {
    [logger info:@"completedSignatureCallback: - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        if (ret == 0) {
            lblProgressSignaturePointer.stringValue = @"File firmato con successo";
            [logger debug:lblProgressSignaturePointer.stringValue];
            imgSignatureOKPointer.hidden = NO;
            imgSignatureOKPointer.image = [NSImage imageNamed:@"check"];
        } else {
            lblProgressSignaturePointer.stringValue = @"Si è verificato un errore durante la firma";
            [logger debug:lblProgressSignaturePointer.stringValue];
            //TODO impostare immagine errore
            imgSignatureOKPointer.hidden = NO;
            imgSignatureOKPointer.image = [NSImage imageNamed:@"cross"];
        }
        
        progressIndicatorSignaturePointer.hidden = YES;
        btnSignatureCompletedPointer.hidden = NO;
        btnAbortSignaturePointer.hidden = YES;
        btnSignaturePointer.hidden = YES;
        
    });
    return 0;
}

CK_RV completedCallback(string& PAN,
                        string& name,
                        string& ef_seriale) {
    sPAN = PAN;
    sName = name;
    sEfSeriale = ef_seriale;
    return 0;
}

- (bool)checkEnabled {
    [logger info:@"-checkEnabled - Inizia funzione"];
    // check se abilitata ossia se cache presente
    VerificaCIEAbilitatafn pfnVerificaCIE = (VerificaCIEAbilitatafn)dlsym(hModule, "VerificaCIEAbilitata");
    
    if (!pfnVerificaCIE) {
        dlclose(hModule);
        [logger debug:@"Funzione VerificaCIE non trovata nel middleware"];
        [self showMessage:@"Funzione VerificaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
        return false;
    }
    
    NSString* pan = [NSUserDefaults.standardUserDefaults objectForKey:@"PAN"];
    
    if (pan) {
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

- (IBAction)onAggiungiCie:(id)sender {
    [logger info:@"onAggiungiCie: - Inizia funzione"];
    
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:HOME_FIRST_PAGE];
    
    for (int i = 1; i < 9; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        txtField.stringValue = @"";
    }
    
    NSTextField* txtField = [self.view viewWithTag:1];
    [txtField selectText:nil];
}

- (void)disabilita {
    [logger info:@"disabilita - Inizia funzione"];
    
    if(self.tmpPANCIE == nil)
        self.fullPINSignature = NO;
    
    NSString* pan = (self.fullPINSignature) ? self.tmpPANCIE : [removingCie getPan];
    NSString* serialNumber = self.fullPINSignature ? [[[cieList getDictionary] valueForKey: self.tmpPANCIE] getSerialNumber] : [removingCie getSerialNumber];
    removingCie = nil;
    // check se abilitata ossia se cache presente
    VerificaCIEAbilitatafn pfnVerificaCIE = (VerificaCIEAbilitatafn)dlsym(hModule, "VerificaCIEAbilitata");
    
    if (!pfnVerificaCIE) {
        dlclose(hModule);
        [self showMessage:@"Funzione VerificaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
        return;
    }
    
    CK_RV rv = pfnVerificaCIE([pan cStringUsingEncoding:NSUTF8StringEncoding]);
    
    switch (rv) {
        case CKR_OK:
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
    
    if (!pfnDisabilitaCIE) {
        dlclose(hModule);
        [self showMessage:@"Funzione DisabilitaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:true];
        return;
    }
    
    rv = pfnDisabilitaCIE([pan cStringUsingEncoding:NSUTF8StringEncoding]);
    
    switch (rv) {
        case CKR_OK: {
            if(!self.fullPINSignature) {
                [self showMessage:@"CIE disabilitata con successo" withTitle:@"CIE disabilitata" exitAfter:NO];
                [self showHomeFirstPage];
            }
            
            [cieList removeCie:pan];
            [self.carouselView configureWithCards:[[cieList getDictionary] allValues]];
            NSFileManager *manager = [NSFileManager defaultManager];
            [manager removeItemAtPath:[self getSignImagePath:serialNumber] error:NULL];
            [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
            [NSUserDefaults.standardUserDefaults synchronize];
            break;
        }
            
        case CKR_TOKEN_NOT_PRESENT:
            if(!self.fullPINSignature) {
                [self showMessage:@"CIE non presente sul lettore" withTitle:@"Disabilitazione CIE" exitAfter:false];
            }
            break;
            
        default:
            if(!self.fullPINSignature) {
                [self showMessage:@"Impossibile disabilitare la CIE" withTitle:@"CIE non disabilitata" exitAfter:NO];
            }
            break;
    }
}

- (IBAction)runInBackgroundSetting:(NSButton *)sender {
    [logger info:@"runInBackgroundSetting: - Inizia funzione"];
}

- (IBAction)rbLoggingAppAction:(NSButton *)sender {
    [logger info:@"rbLoggingAppAction: - Inizia funzione"];
}

- (IBAction)rbLoggingLibAction:(NSButton *)sender {
    [logger info:@"rbLoggingLibAction: - Inizia funzione"];
}

- (IBAction)home:(id)sender {
    [logger info:@"home: - Inizia funzione"];
    _lblDigitalSignatureHeader.stringValue = @"CIE ID";
    _lblDigitalSignatureHeaderSubtitle.stringValue = @"Carta di Identità Elettronica abbinata correttamente";
    [self showHomeFirstPage];
}

- (IBAction)impostazioni:(id)sender {
    [logger info:@"impostazioni: - Inizia funzione"];
    [self showImpostazioniPage];
}

- (IBAction)firmaElettronica:(id)sender {
    [logger info:@"firmaElettronica: - Inizia funzione"];
    //[self showFirmaPinView];
    [self showFirmaElettronica];
    [self showFirmaPinView];
}

- (IBAction)verificaFirma:(id)sender {
    [logger info:@"verificaFirma: - Inizia funzione"];
    [self showVerificaFirma];
}

- (IBAction)cambioPIN:(id)sender {
    [logger info:@"cambioPIN: - Inizia funzione"];
    [self showChangePINPage];
}

- (IBAction)sbloccaCarta:(id)sender {
    [logger info:@"sbloccaCarta: - Inizia funzione"];
    [self showSbloccoPage];
}

- (IBAction)tutorial:(id)sender {
    [logger info:@"tutorial: - Inizia funzione"];
    [self showTutorialPage];
}

- (IBAction)aiuto:(id)sender {
    [logger info:@"aiuto: - Inizia funzione"];
    [self showHelpPage];
}

- (IBAction)informazioni:(id)sender {
    [logger info:@"informazioni: - Inizia funzione"];
    [self showInfoPage];
}

- (IBAction)annulla:(id)sender {
    [logger info:@"annulla: - Inizia funzione"];
}

- (IBAction)abbina:(id)sender {
    [logger info:@"abbina: - Inizia funzione"];
    NSString* pin = @"";
    
    for (int i = 1; i < 9; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        pin = [pin stringByAppendingString:txtField.stringValue];
    }
    
    if (pin.length != 8) {
        [self showMessage:@"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        [self showHomeFirstPage];
        return;
    }
    
    unichar c = [pin characterAtIndex:0];
    int i = 1;
    
    for (i = 1; i < pin.length && (c >= '0' && c <= '9'); i++) {
        c = [pin characterAtIndex:i];
    }
    
    if (i < pin.length || !(c >= '0' && c <= '9')) {
        [self showMessage:@"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    [self showHomeSecondPage];
    [((NSControl*)sender) setEnabled:NO];
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {
        
        AbilitaCIEfn pfnAbilitaCIE = (AbilitaCIEfn)dlsym(hModule, "AbilitaCIE");
        
        if (!pfnAbilitaCIE) {
            dlclose(hModule);
            [self showMessage:@"Funzione AbilitaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
            return;
        }
        
        char* szPAN = NULL;
        
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        
        if (args.count > 1) {
            NSString* arg = ((NSString*)[args objectAtIndex:1]);
            
            if (![arg hasPrefix:@"-NS"]) { // for running in debug from xcode
                szPAN = (char*)[arg cStringUsingEncoding:NSUTF8StringEncoding];
            }
        }
        
        int attempts = -1;
        
        long ret = pfnAbilitaCIE(szPAN, [pin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallback, &completedCallback);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [((NSControl*)sender) setEnabled:YES];
            
            switch (ret) {
                case CKR_TOKEN_NOT_RECOGNIZED:
                    if (szPAN) {
                        [self showMessage:[NSString stringWithFormat:@"CIE con numero identificativo %s non presente sul lettore", szPAN] withTitle:@"Abilitazione CIE" exitAfter:false];
                    } else {
                        [self showMessage:@"CIE non presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
                    }
                    
                    [self showHomeFirstPage];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"CIE non presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
                    [self showHomeFirstPage];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PIN digitato è errato. Rimangono %d tentativi", attempts] withTitle:@"PIN non corretto" exitAfter:false];
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
                    
                case CARD_ALREADY_ENABLED:
                    [self showMessage:@"CIE già abilitata" withTitle:@"CIE già abilitata" exitAfter:NO];
                    [self showHomeFirstPage];
                    break;
                    
                case CKR_OK:
                    [self showMessage:@"L'abilitazione della CIE è avvenuta con successo. Allontanare la card dal lettore" withTitle:@"CIE Abilitata" exitAfter:NO];
                    NSString *PAN = [[NSString alloc] initWithCString:sPAN.c_str() encoding:NSUTF8StringEncoding];
                    NSString *serialNumber = [[NSString alloc] initWithCString:sEfSeriale.c_str() encoding:NSUTF8StringEncoding];
                    NSString *name = [[NSString alloc] initWithCString:sName.c_str() encoding:NSUTF8StringEncoding];
                    Cie *cie = [[Cie alloc] init:name serial:serialNumber pan:PAN];
                    [cieList addCie:PAN owner:cie];
                    [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                    [self showHomeThirdPage];
                    break;
            }
        });
    });
}

- (IBAction)sblocca:(id)sender {
    [logger info:@"sblocca: - Inizia funzione"];
    NSString* puk = self.textFieldPUK.stringValue;
    NSString* newpin = self.textFieldNewUnlockPIN.stringValue;
    NSString* confirmpin = self.textFieldConfirmUnlockPIN.stringValue;
    
    if (puk.length != 8) {
        [self showMessage:@"Il PUK deve essere composto da 8 numeri" withTitle:@"PUK non corretto" exitAfter:false];
        return;
    }
    
    if (newpin.length != 8) {
        [self showMessage:@"Il nuovo PIN deve essere composto da 8 numeri" withTitle:@"Nuovo PIN non corretto" exitAfter:false];
        return;
    }
    
    unichar c = [puk characterAtIndex:0];
    int i = 1;
    
    for (i = 1; i < puk.length && (c >= '0' && c <= '9'); i++) {
        c = [puk characterAtIndex:i];
    }
    
    if (!(c >= '0' && c <= '9')) {
        [self showMessage:@"Il PUK deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    
    for (i = 1; i < newpin.length && (c >= '0' && c <= '9'); i++) {
        c = [newpin characterAtIndex:i];
    }
    
    if (!(c >= '0' && c <= '9')) {
        [self showMessage:@"Il nuovo PIN deve essere composto da 8 numeri" withTitle:@"Nuovo PIN non corretto" exitAfter:false];
        return;
    }
    
    if (![newpin isEqualToString:confirmpin]) {
        [self showMessage:@"I PIN non corrispondono" withTitle:@"PIN non corrispondenti" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    unichar lastchar = c;
    i = 1;
    
    for (i = 1; i < newpin.length && c == lastchar; i++) {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if (c == lastchar) {
        [self showMessage:@"Il nuovo PIN non deve essere composto da cifre uguali" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    lastchar = c - 1;
    
    for (i = 1; i < newpin.length && c == lastchar + 1; i++) {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if (c == lastchar + 1) {
        [self showMessage:@"Il nuovo PIN non deve essere composto da cifre consecutive" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    lastchar = c + 1;
    
    for (i = 1; i < newpin.length && c == lastchar - 1; i++) {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if (c == lastchar - 1) {
        [self showMessage:@"Il nuovo PIN non deve essere composto da cifre consecutive" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    [((NSControl*)sender) setEnabled:NO];
    self.progressIndicatorUnlockPIN.hidden = NO;
    self.labelProgressUnlockPIN.hidden = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {
        
        SbloccoPINfn pfnSbloccoPIN = (SbloccoPINfn)dlsym(hModule, "SbloccoPIN");
        
        if (!pfnSbloccoPIN) {
            dlclose(hModule);
            [self showMessage:@"Funzione SbloccoPIN non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:false];
            return;
        }
        
        int attempts = -1;
        
        long ret = pfnSbloccoPIN([puk cStringUsingEncoding:NSUTF8StringEncoding], [newpin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallbackUnlockPIN);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.progressIndicatorUnlockPIN.hidden = YES;
            self.labelProgressUnlockPIN.hidden = YES;
            
            [((NSControl*)sender) setEnabled:YES];
            
            switch (ret) {
                case CKR_TOKEN_NOT_RECOGNIZED:
                    [self showMessage:@"La smart card inserita non è una CIE" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"Nessuna CIE trovata" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PUK digitato è errato. Rimangono %d tentativi", attempts] withTitle:@"PIN non corretto" exitAfter:false];
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
                    self.textFieldNewUnlockPIN.stringValue = @"";
                    self.textFieldConfirmUnlockPIN.stringValue = @"";
                    NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
                    NSViewController* viewController = [storyboard instantiateControllerWithIdentifier:@"PINNoticeViewController"];
                    [self presentViewControllerAsModalWindow:viewController];
                    break;
            }
        });
    });
}

- (IBAction)concludi:(id)sender {
    [logger info:@"concludi: - Inizia funzione"];
    [self showHomeFourthPage];
}

- (IBAction)cambiaPIN:(id)sender {
    [logger info:@"cambiaPIN: - Inizia funzione"];
    NSString* pin = self.textFieldPIN.stringValue;
    NSString* newpin = self.textFieldNewPIN.stringValue;
    NSString* confirmpin = self.textFieldConfirmPIN.stringValue;
    
    if (pin.length != 8 || newpin.length != 8) {
        [self showMessage:@"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    if (![newpin isEqualToString:confirmpin]) {
        [self showMessage:@"" withTitle:@"PIN non corrispondenti" exitAfter:false];
        return;
    }
    
    if ([newpin isEqualToString:pin]) {
        [self showMessage:@"Il vecchio e nuovo PIN non possono essere uguali" withTitle:@"PIN identici" exitAfter:false];
        return;
    }
    
    unichar c = [pin characterAtIndex:0];
    int i = 1;
    
    for (i = 1; i < pin.length && (c >= '0' && c <= '9'); i++) {
        c = [pin characterAtIndex:i];
    }
    
    if (!(c >= '0' && c <= '9')) {
        [self showMessage:@"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    
    for (i = 1; i < newpin.length && (c >= '0' && c <= '9'); i++) {
        c = [newpin characterAtIndex:i];
    }
    
    if (!(c >= '0' && c <= '9')) {
        [self showMessage:@"Il PIN deve essere composto da 8 numeri" withTitle:@"PIN non corretto" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    unichar lastchar = c;
    
    for (i = 1; i < newpin.length && c == lastchar; i++) {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if (c == lastchar) {
        [self showMessage:@"Il nuovo PIN non deve essere composto da cifre uguali" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    lastchar = c - 1;
    
    for (i = 1; i < newpin.length && c == lastchar + 1; i++) {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if (c == lastchar + 1) {
        [self showMessage:@"Il nuovo PIN non deve essere composto da cifre consecutive" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    c = [newpin characterAtIndex:0];
    lastchar = c + 1;
    
    for (i = 1; i < newpin.length && c == lastchar - 1; i++) {
        lastchar = c;
        c = [newpin characterAtIndex:i];
    }
    
    if (c == lastchar - 1) {
        [self showMessage:@"Il nuovo PIN non deve essere composto da cifre consecutive" withTitle:@"PIN non valido" exitAfter:false];
        return;
    }
    
    [((NSControl*)sender) setEnabled:NO];
    self.progressIndicatorChangePIN.hidden = NO;
    self.labelProgressChangePIN.hidden = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {
        
        C_GETFUNCTIONLIST pfnGetFunctionList = (C_GETFUNCTIONLIST)dlsym(hModule, "C_GetFunctionList");
        
        if (!pfnGetFunctionList) {
            dlclose(hModule);
            [self showMessage:@"Il middleware non è valido" withTitle:@"Errore inaspettato" exitAfter:true];
            return;
        }
        
        CambioPINfn pfnCambioPIN = (CambioPINfn)dlsym(hModule, "CambioPIN");
        
        if (!pfnCambioPIN) {
            dlclose(hModule);
            [self showMessage:@"Funzione CambioPIN non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:false];
            return;
        }
        
        int attempts = -1;
        
        long ret = pfnCambioPIN([pin cStringUsingEncoding:NSUTF8StringEncoding], [newpin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallbackCambioPIN);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.progressIndicatorChangePIN.hidden = YES;
            self.labelProgressChangePIN.hidden = YES;
            
            [((NSControl*)sender) setEnabled:YES];
            
            switch (ret) {
                case CKR_TOKEN_NOT_RECOGNIZED:
                    [self showMessage:@"Impossibile trovare la CIE con Numero Identificativo" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"CIE presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PIN digitato è errato. Rimangono %d tentativi", attempts] withTitle:@"PIN non corretto" exitAfter:false];
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

- (void)askRiabbina:(NSString*)message withTitle:(NSString*)title {
    [logger info:@"askRiabbina:withTitle: - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"SI"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSAlertStyleInformational];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(askRiabbinaDidEnd:returnCode:contextInfo:) contextInfo:nil];
    });
}

- (void)askRiabbinaDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo {
    [logger info:@"askRiabbinaDidEnd:returnCode:contextInfo: - Inizia funzione"];
    
    if (returnCode == NSAlertFirstButtonReturn) {
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HOME_FIRST_PAGE];
        
        for (int i = 1; i < 9; i++) {
            NSTextField* txtField = [self.view viewWithTag:i];
            txtField.stringValue = @"";
        }
        
        NSTextField* txtField = [self.view viewWithTag:1];
        [txtField selectText:nil];
    } else {
        [self showHomeFourthPage];
    }
}

- (void)showImpostazioniPage {
    [logger info:@"showImpostazioniPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        
        [self disableSettingsFormEditing];
        
        if ([NSUserDefaults.standardUserDefaults objectForKey:@"proxyUrl"] && ![[NSUserDefaults.standardUserDefaults objectForKey:@"proxyUrl"] isEqual:@""]) {
            [logger debug:@"User Defaults credentials"];
            
            if (!([NSUserDefaults.standardUserDefaults objectForKey:@"credentials"]) || ([[NSUserDefaults.standardUserDefaults objectForKey:@"credentials"] isEqual:@""])) {
                _txtUsername.stringValue = @"";
                _txtPassword.stringValue = @"";
            } else {
                NSString* encryptedCredentials = [NSUserDefaults.standardUserDefaults objectForKey:@"credentials"];
                [logger debug:[NSString stringWithFormat:@"Encrypted Credentials: %@", encryptedCredentials]];
                ProxyInfoManager *proxyInfoManager = [[ProxyInfoManager alloc] init];
                NSString* decrypted = [proxyInfoManager getDecryptedCredentials:encryptedCredentials];
                [logger debug:[NSString stringWithFormat:@"Decrypted Credentials: %@", decrypted]];
                
                if ([[decrypted substringToIndex:5] isEqual:@"cred="]) {
                    NSArray *infos = [[decrypted substringFromIndex:5] componentsSeparatedByString:@":"];
                    _txtUsername.stringValue = infos[0];
                    _txtPassword.stringValue = infos[1];
                }
            }
            
            _txtProxyAddr.stringValue = [NSUserDefaults.standardUserDefaults objectForKey:@"proxyUrl"];
            _txtPort.stringValue = [NSUserDefaults.standardUserDefaults objectForKey:@"proxyPort"];
        }
        
        [_rbLoggingAppError setState:NSOffState];
        [_rbLoggingAppInfo setState:NSOffState];
        [_rbLoggingAppDebug setState:NSOffState];
        [_rbLoggingAppNone setState:NSOffState];
        
        [_rbLoggingLibError setState:NSOffState];
        [_rbLoggingLibInfo setState:NSOffState];
        [_rbLoggingLibDebug setState:NSOffState];
        [_rbLoggingLibNone setState:NSOffState];
        
        NSString *runInBackgroundCBValue = [_prefManager getConfigKeyValue:@"RUN_IN_BACKGROUND"];
        if([runInBackgroundCBValue isEqualToString:@"YES"])
            [_cbShouldRunInBackground setState: NSOnState];
        else
            [_cbShouldRunInBackground setState: NSOffState];
        
        NSString *showTutorialCBValue = [_prefManager getConfigKeyValue:@"SHOW_TUTORIAL"];
        if([showTutorialCBValue isEqualToString:@"YES"])
            [_cbShowTutorial setState: NSOnState];
        else
            [_cbShowTutorial setState: NSOffState];
        
        [self LoadLogConfigFromFile];
        
        switch ([self logLevelApp]) {
            case AppLogLevel_DEBUG:
                [_rbLoggingAppDebug setState:NSOnState];
                break;
                
            case AppLogLevel_ERROR:
                [_rbLoggingAppError setState:NSOnState];
                break;
                
            case AppLogLevel_INFO:
                [_rbLoggingAppInfo setState:NSOnState];
                break;
                
            case AppLogLevel_NONE:
            default:
                [_rbLoggingAppNone setState:NSOnState];
        }
        switch ([self logLevelLib]) {
            case AppLogLevel_DEBUG:
                [_rbLoggingLibDebug setState:NSOnState];
                break;
                
            case AppLogLevel_ERROR:
                [_rbLoggingLibError setState:NSOnState];
                break;
                
            case AppLogLevel_INFO:
                [_rbLoggingLibInfo setState:NSOnState];
                break;
                
            case AppLogLevel_NONE:
            default:
                [_rbLoggingLibNone setState:NSOnState];
        }
        
        [[ChangeView getInstance] showSubView:IMPOSTAZIONI];
    });
}

- (void)showFirmaElettronica {
    [logger info:@"showFirmaElettronica - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self updateAbbinaAndAnnullaLayout];
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        _lblCades.textColor = NSColor.grayColor;
        _lblCadesSub.textColor = NSColor.grayColor;
        _lblPades.textColor = NSColor.grayColor;
        _lblPadesSub.textColor = NSColor.grayColor;
        _cbGraphicSignature.state = NSOffState;
        _btnProceedSignatureOp.enabled = NO;
        operation = NO_OP;
        ChangeView *cG = [ChangeView getInstance];
        
        if([cieList getDictionary].count > 0) {
            _lblDigitalSignatureHeader.stringValue = @"Firma Elettronica";
            _lblDigitalSignatureHeaderSubtitle.stringValue = @"Seleziona la CIE da utilizzare";
            [self.carouselView changeButtonViews];
            [_fileSelectionSignatureBlockView setHidden:NO];
            [cG showSubView:HOME_FOURTH_PAGE];
        } else {
            [_fileSelectionSignatureBlockView setHidden:YES];
            [cG showSubView:SELECT_FILE_PAGE];
        }
    });
}

- (void)showVerificaFirma {
    [logger info:@"showVerificaFirma - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self updateAbbinaAndAnnullaLayout];
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        _lblCades.textColor = NSColor.grayColor;
        _lblCadesSub.textColor = NSColor.grayColor;
        _lblPades.textColor = NSColor.grayColor;
        _lblPadesSub.textColor = NSColor.grayColor;
        _cbGraphicSignature.state = NSOffState;
        _btnProceedSignatureOp.enabled = NO;
        operation = VERIFY;
        _lblDigitalSignatureHeader.stringValue = @"Firma Elettronica";
        _lblDigitalSignatureHeaderSubtitle.stringValue = @"Seleziona la CIE da utilizzare";
        [_fileSelectionSignatureBlockView setHidden:YES];
        [[ChangeView getInstance] showSubView:SELECT_FILE_PAGE];
    });
}

- (void)showHomeFirstPage {
    [logger info:@"showHomeFirstPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        [self updateAbbinaAndAnnullaLayout];
        
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        if ((![NSUserDefaults.standardUserDefaults objectForKey:@"cieDictionary"])) {
            cieList = [CieList new];
        } else {
            NSData *cieData = [NSUserDefaults.standardUserDefaults objectForKey:@"cieDictionary"];
            cieList = [[CieList alloc] init:cieData];
            NSDictionary *cieDict = [cieList getDictionary];
            [logger debug:[NSString stringWithFormat:@"Dizionario %@", cieDict]];
        }
        
        if ([NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"]) {
            NSString* name = [NSUserDefaults.standardUserDefaults stringForKey:@"cardholder"];
            NSString* PAN = [NSUserDefaults.standardUserDefaults stringForKey:@"serialnumber"];
            NSString* serialNumber = [NSUserDefaults.standardUserDefaults stringForKey:@"efSeriale"];
            Cie *cie = [[Cie alloc] init:name serial:serialNumber pan:PAN];
            [cieList addCie:PAN owner:cie];
            [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"cardholder"];
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"serialnumber"];
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"efSeriale"];
            [NSUserDefaults.standardUserDefaults synchronize];
        }
        
        [self.carouselView configureWithCards:[[cieList getDictionary] allValues]];
        
        if ([[cieList getDictionary] count] > 0) {
            [self showHomeFourthPage];
        }
        
        else {
            
            ChangeView *cG = [ChangeView getInstance];
            [cG showSubView:HOME_FIRST_PAGE];
            //[_btnFirmaElettronica setEnabled:NO];
            
            for (int i = 1; i < 9; i++) {
                NSTextField* txtField = [self.view viewWithTag:i];
                txtField.stringValue = @"";
            }
            
            NSTextField* txtField = [self.view viewWithTag:1];
            [txtField selectText:nil];
        }
    });
}

- (void)showHomeThirdPage {
    [logger info:@"showHomeThirdPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HOME_THIRD_PAGE];
    });
}

- (void)showHomeSecondPage {
    [logger info:@"showHomeSecondPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = NO;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.changePINPageView.hidden = YES;
        self.changePINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HOME_SECOND_PAGE];
    });
}

- (void)showHomeFourthPage {
    [logger info:@"showHomeFourthPage - Inizia funzione"];
    [self.carouselView configureWithCards:[[cieList getDictionary] allValues]];
    [_btnMenuDigitalSignature setEnabled:YES];
    dispatch_async(dispatch_get_main_queue(), ^ {
        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        [self updateAbbinaAndAnnullaLayout];
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HOME_FOURTH_PAGE];
    });
}

- (void)showChangePINPage {
    [logger info:@"showChangePINPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.progressIndicatorChangePIN.hidden = YES;
        self.labelProgressChangePIN.hidden = YES;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:CAMBIO_PIN_PAGE];
    });
}

- (void)showCambioPINOKPage {
    [logger info:@"showCambioPINOKPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:CAMBIO_PIN_OK_PAGE];
    });
}

- (void)showSbloccoPage {
    [logger info:@"showSbloccoPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.progressIndicatorUnlockPIN.hidden = YES;
        self.labelProgressUnlockPIN.hidden = YES;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:SBLOCCO_PAGE];
    });
}

- (void)showSbloccoOKPage {
    [logger info:@"showSbloccoOKPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:SBLOCCO_OK_PAGE];
        
    });
}

- (void)showHelpPage {
    [logger info:@"showHelpPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.labelHelp.stringValue = @"Aiuto";
        self.helpImageView.hidden = NO;
        self.unlockImageView.hidden = NO;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HELP_PAGE];
        
        [self.helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/aiuto.jsp"]]];
    });
}

- (void)showTutorialPage {
    [logger info:@"showTutorialPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        self.labelHelp.stringValue = @"Tutorial";
        self.helpImageView.hidden = YES;
        self.unlockImageView.hidden = YES;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HELP_PAGE];
        
        [self.helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/tutorial_mac.jsp"]]];
    });
}

- (void)showInfoPage {
    [logger info:@"showInfoPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.digitalSignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verifySignatureButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.changePINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.unlockPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.settingsButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:INFO_PAGE];
        
        [self.infoWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/privacy.jsp"]]];
    });
}

- (void)showMessage:(NSString*)message withTitle:(NSString*)title exitAfter:(bool)exitAfter {
    [logger info:@"showMessage:withTitle:exitAfter: - Inizia funzione"];
    __block bool exit = exitAfter;
    dispatch_async(dispatch_get_main_queue(), ^ {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:&exit];
    });
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo {
    [logger info:@"alertDidEnd:returnCode:contextInfo: - Inizia funzione"];
    
    if (*contextInfo) {
        [logger debug:[NSString stringWithFormat:@"alert did end with status %ld", (long)returnCode]];
    }
}

- (void)askRemoveLogs:(NSString*)message withTitle:(NSString*)title {
    [logger info:@"askRemoveLogs:withTitle: - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Annulla"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        
        [alert setAlertStyle:NSAlertStyleInformational];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(askRemoveLogsDidEnd:returnCode:contextInfo:) contextInfo:nil];
    });
}

- (void)askRemove:(NSString*)message withTitle:(NSString*)title {
    [logger info:@"askRemove:withTitle: - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Annulla"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        
        [alert setAlertStyle:NSAlertStyleInformational];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(askRemoveDidEnd:returnCode:contextInfo:) contextInfo:nil];
    });
}

- (void)askRemoveAll:(NSString*)message withTitle:(NSString*)title {
    [logger info:@"askRemoveAll:withTitle: - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Sì"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        
        [alert setAlertStyle:NSAlertStyleInformational];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(askRemoveAllDidEnd:returnCode:contextInfo:) contextInfo:nil];
    });
}

- (void)askRemoveAllDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo {
    [logger info:@"askRemoveAllDidEnd:returnCode:contextInfo: - Inizia funzione"];
    
    if (returnCode == NSAlertFirstButtonReturn) {
        NSArray *cieArr = [[cieList getDictionary] allValues];
        
        for (Cie * cie in cieArr) {
            removingCie = cie;
            [self disabilita];
        }
    }
}

- (void)askRemoveDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo {
    [logger info:@"askRemoveDidEnd:returnCode:contextInfo: - Inizia funzione"];
    
    if (returnCode == NSAlertFirstButtonReturn) {
        [self disabilita];
    }
}

- (void)askRemoveLogsDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(bool*)contextInfo {
    [logger info:@"askRemoveLogsDidEnd:returnCode:contextInfo: - Inizia funzione"];
    
    if (returnCode == NSAlertFirstButtonReturn) {
        BOOL success = [self deleteLogFiles];
        if (!success) {
            [self showMessage:@"Si è verificato un errore durante la cancellazione dei log. È possibile che alcuni file siano aperti ed in uso da terze parti, per cui non è stato possibile procedere con l'eliminazione." withTitle:@"Attenzione" exitAfter:false];
            [logger error:@"Errore durante l'eliminazione dei log."];
        } else {
            [self showMessage:@"L'eliminazione dei log è avvenuta con successo. Se hai riscontrato un'anomalia nel software che intendi segnalare, puoi impostare il livello di logging su 'Debug', replicare l'operazione, raccogliere i log con l'apposito pulsante e condividerli con lo sviluppatore." withTitle:@"Eliminazione completata" exitAfter:false];
            [logger info:@"Log eliminati con successo."];
        }
    }
}

- (void)updateAbbinaAndAnnullaLayout {
    [logger info:@"updateAbbinaAndAnnullaLayout - Inizia funzione"];
    
    if ( [[cieList getDictionary] count] >= 1) {
        self.btnAbort.hidden = NO;
        self.pairButtonWhenAbortVisible.priority = NSLayoutPriorityDefaultHigh;
        self.pairButtonWhenAbortInvisible.priority = NSLayoutPriorityDefaultLow;
    } else {
        self.btnAbort.hidden = YES;
        self.pairButtonWhenAbortVisible.priority = NSLayoutPriorityDefaultLow;
        self.pairButtonWhenAbortInvisible.priority = NSLayoutPriorityDefaultHigh;
    }
    
    [self updateViewConstraints];
}

- (IBAction)selectDocument:(id)sender {
    [logger info:@"selectDocument: - Inizia funzione"];
    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    
    if ([panel runModal] == NSModalResponseOK) {
        NSArray* selectedFile = [panel URLs];
        NSURL *url = (NSURL *)selectedFile[0];
        path = [url path];
        filePath = path;
        [self chooseSignOrVerifyFileOperation:path];
    }
}

- (void)chooseSignOrVerifyFileOperation:(NSString*)_filePath {
    [logger info:@"chooseSignOrVerifyFileOperation: - Inizia funzione"];
    [logger info:[NSString stringWithFormat:@"%@ was selected", _filePath]];
    ChangeView *cG = [ChangeView getInstance];
    NSView* cV = [cG getView:SELECT_OP_PAGE];
    NSTextField* lblPath = [cV viewWithTag:1];
    lblPath.stringValue = _filePath;
    if (operation == VERIFY) {
        // go to verify
        [self btnVerificaOp:nil];
    } else {
        [self btnFirmaOp:nil];
    }
}

- (IBAction)btnFirmaOp:(id)sender {
    [logger info:@"btnFirmaOp: - Inizia funzione"];
    filePath = _lblPathOp.stringValue;
    _filePathSignOp.stringValue = filePath;
    _btnProceedSignatureOp.enabled = NO;
    _lblCades.textColor = NSColor.grayColor;
    _lblCadesSub.textColor = NSColor.grayColor;
    _lblPades.textColor = NSColor.grayColor;
    _lblPadesSub.textColor = NSColor.grayColor;
    _pictureCades.image = [NSImage imageNamed:@"p7m_gray"];
    _picturePades.image = [NSImage imageNamed:@"pdf_gray"];
    _cbGraphicSignature.enabled = NO;
    _cbGraphicSignature.state = NSOffState;
    NSColor *color = [NSColor grayColor];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_cbGraphicSignature attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_cbGraphicSignature setAttributedTitle:colorTitle];
    operation = NO_OP;
    NSString *filePathNoSpaces = [filePath stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* fileType = [[NSURL URLWithString:filePathNoSpaces] pathExtension];
    
    self.fullPINSignature = [self.carouselView shouldUseFullPINForSignature];
    
    if ([fileType isEqualTo:@"pdf"] && !self.fullPINSignature) {
        [_cbGraphicSignature setEnabled:YES];
        [_cbGraphicSignature setHidden:NO];
    } else {
        [_cbGraphicSignature setEnabled:NO];
        [_cbGraphicSignature setHidden:YES];
    }
    
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:SELECT_FIRMA_OP];
    //_filePathSignOp.stringValue = [filePath stringByReplacingOccurrencesOfString:@"/" withString:@" ▶︎ "];
}

- (IBAction)btnVerificaOp:(id)sender {
    [logger info:@"btnVerificaOp: - Inizia funzione"];
    [logger debug:@"Selected Verifica Operation"];
    filePath = _lblPathOp.stringValue;
    _lblVerifyPath.stringValue = filePath;
    [self verificaConCie:sender inputFilePath:filePath];
}

- (IBAction)btnAbortOp:(id)sender {
    [logger info:@"btnAbortOp: - Inizia funzione"];
    _btnProceedSignatureOp.enabled = NO;
    _lblCades.textColor = NSColor.grayColor;
    _lblCadesSub.textColor = NSColor.grayColor;
    _lblPades.textColor = NSColor.grayColor;
    _lblPadesSub.textColor = NSColor.grayColor;
    operation = NO_OP;
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:SELECT_FILE_PAGE];
}

- (IBAction)CadesClick:(id)sender {
    [logger info:@"CadesClick: - Inizia funzione"];
    _lblCades.textColor = NSColor.blueColor;
    _lblCadesSub.textColor = NSColor.blackColor;
    _lblPades.textColor = NSColor.grayColor;
    _lblPadesSub.textColor = NSColor.grayColor;
    _btnProceedSignatureOp.enabled = YES;
    NSColor *color = [NSColor grayColor];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_cbGraphicSignature attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_cbGraphicSignature setAttributedTitle:colorTitle];
    _pictureCades.image = [NSImage imageNamed:@"p7m"];
    _picturePades.image = [NSImage imageNamed:@"pdf_gray"];
    operation = CADES_SIGNATURE;
    _cbGraphicSignature.state = NSOffState;
    //TODO mettere immagine colorata
}

- (IBAction)PadesClick:(id)sender {
    [logger info:@"PadesClick: - Inizia funzione"];
    NSString *filePathNoSpaces = [filePath stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* fileType = [[NSURL URLWithString:filePathNoSpaces] pathExtension];
    
    if ([fileType isEqualTo:@"pdf"]) {
        _lblCades.textColor = NSColor.grayColor;
        _lblCadesSub.textColor = NSColor.grayColor;
        _lblPades.textColor = NSColor.redColor;
        _lblPadesSub.textColor = NSColor.blackColor;
        NSColor *color = [NSColor blackColor];
        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_cbGraphicSignature attributedTitle]];
        NSRange titleRange = NSMakeRange(0, [colorTitle length]);
        [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
        [_cbGraphicSignature setAttributedTitle:colorTitle];
        _btnProceedSignatureOp.enabled = YES;
        _pictureCades.image = [NSImage imageNamed:@"p7m_gray"];
        _picturePades.image = [NSImage imageNamed:@"pdf"];
        operation = PADES_SIGNATURE;
    }
}
- (IBAction)cbFirmaGraficaClick:(id)sender {
    [logger info:@"cbFirmaGraficaClick: - Inizia funzione"];
    [self PadesClick:0];
}

- (NSString*)getSignImagePath:(NSString*)serial {
    [logger info:@"getSignImagePath:serial - Inizia funzione"];
    NSString * homeDir = NSHomeDirectory();
    NSString* signImgPath = [NSString stringWithFormat:@"%@/%@/%@_default.png", homeDir, @".CIEPKI", serial];
    [logger debug:[NSString stringWithFormat:@"%@", signImgPath]];
    return signImgPath;
}

- (void)drawText:(NSString*)text pathToFile:(NSString*)path {
    [logger info:@"drawText:pathToFile:path - Inizia funzione"];
    NSDictionary *attributes =
    @ { NSFontAttributeName :
        [NSFont fontWithName:@"Allura-Regular" size:60.0],
        NSForegroundColorAttributeName :
        NSColor.blackColor
    };
    NSImage *img = [[NSImage alloc] initWithSize:[text sizeWithAttributes:attributes]];
    [img lockFocus];
    [[NSColor whiteColor] set];
    CGRect rc = NSMakeRect(0, 0, [img size].width, [img size].height);
    NSRectFill(rc);
    [img drawInRect:rc];
    [text drawAtPoint:NSZeroPoint withAttributes:attributes];
    [img unlockFocus];
    NSData *imageData = [img TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:imageProps];
    NSError *error = nil;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    [logger debug:[NSString stringWithFormat:@"Write returned error: %@", [error localizedDescription]]];
}

- (IBAction)btnProceedSignatureOp:(id)sender {
    [logger info:@"btnProceedSignatureOp: - Inizia funzione"];
    
    for (NSView * aSubview in [[self prevImageView] subviews]) {
        [aSubview removeFromSuperview];
    }
    
    [self showFirmaPinView];
    
    ChangeView *cG = [ChangeView getInstance];
    
    if (operation == PADES_SIGNATURE && (_cbGraphicSignature.state == NSOnState)) {
        [logger debug:@"Firma pades con firma grafica"];
        Cie* selectedCie = [self.carouselView getSelectedCard];
        NSString* signImgPath = [self getSignImagePath:[selectedCie getSerialNumber]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:signImgPath]) {
            [self drawText:[selectedCie getName].capitalizedString pathToFile:signImgPath];
        }
        
        pdfPreview = [[PdfPreview alloc] initWithPrImageView:[self prevImageView] pdfPath:filePath signImagePath:signImgPath];
        _lblPathSignaturePreview.stringValue = filePath;
        [cG showSubView:FIRMA_PDF_PREVIEW];
    } else {
        [logger debug:@"Firma senza grafica"];
        _lblPathSignaturePIN.stringValue = filePath;
        [cG showSubView:FIRMA_PIN_PAGE];
    }
}

- (IBAction)btnAnnullaFirmaOp:(id)sender {
    [logger info:@"btnAnnullaFirmaOp: - Inizia funzione"];
    _lblCades.textColor = NSColor.grayColor;
    _lblCadesSub.textColor = NSColor.grayColor;
    _lblPades.textColor = NSColor.grayColor;
    _lblPadesSub.textColor = NSColor.grayColor;
    _btnProceedSignatureOp.enabled = NO;
    _cbGraphicSignature.state = NSOffState;
    operation = NO_OP;
    ChangeView *cG = [ChangeView getInstance];
    [logger debug:@"AnnullaFirmaOp"];
    [cG showSubView:SELECT_OP_PAGE];
}

- (IBAction)pdfPageUp:(id)sender {
    [logger info:@"pdfPageUp: - Inizia funzione"];
    [pdfPreview pageUp];
}

- (IBAction)pdfPageDown:(id)sender {
    [logger info:@"pdfPageDown: - Inizia funzione"];
    [pdfPreview pageDown];
}

- (IBAction)ProseguiFirma:(id)sender {
    [logger info:@"ProseguiFirma: - Inizia funzione"];
    //TODO prendere posizione firma grafica
    _lblPathSignaturePIN.stringValue = filePath;
    [self showFirmaPinView];
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:FIRMA_PIN_PAGE];
}

- (IBAction)annullaFirmaClick:(id)sender {
    [logger info:@"annullaFirmaClick: - Inizia funzione"];
    _lblInsertPIN.hidden = NO;
    _cvInsertPIN.hidden = NO;
    _btnAbort.hidden = NO;
    _btnSignatureCompleted.hidden = YES;
    _progressSignature.hidden = YES;
    _lblProgressSignature.hidden = YES;
    
    for (int i = 9; i < 17; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        txtField.stringValue = @"";
    }
    
    ChangeView *cG = [ChangeView getInstance];
    
    if (_cbGraphicSignature.state == NSOnState) {
        [cG showSubView:FIRMA_PDF_PREVIEW];
    } else {
        [cG showSubView:SELECT_FIRMA_OP];
    }
}

- (IBAction)firmaClick:(id)sender {
    [logger info:@"firmaClick: - Inizia funzione"];
    NSString* pin = @"";
    int pinLength = (self.fullPINSignature) ? 8 : 4;
    NSString* message = ((pinLength == 8) ? @"Inserire le 8 cifre del PIN" : @"Inserire le ultime 4 cifre del PIN");
    
    for (int i = 9; i < 9 + pinLength; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        pin = [pin stringByAppendingString:txtField.stringValue];
    }
    
    if (pin.length != pinLength) {
        [self showMessage:message withTitle:@"PIN non corretto" exitAfter:false];
        [self showFirmaPinView];
        return;
    }
    
    unichar c = [pin characterAtIndex:0];
    int i = 1;
    
    for (i = 1; i < pin.length && (c >= '0' && c <= '9'); i++) {
        c = [pin characterAtIndex:i];
    }
    
    if (i < pin.length || !(c >= '0' && c <= '9')) {
        [self showMessage:[NSString stringWithFormat:@"%@/%@/%@", @"Il PIN deve essere composto da ", ((self.fullPINSignature) ? @"8" : @"4"), @" numeri"] withTitle:@"PIN non corretto" exitAfter:false];
        [self showFirmaPinView];
        return;
    }
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSString* fileName = [filePath lastPathComponent];
    [panel setMessage:@"Scegliere dove salvare il file firmato"]; // Message inside modal window
    [panel setExtensionHidden:NO];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:@"Salva file firmato"];
    [panel setAllowsOtherFileTypes:NO];
    
    if (operation == PADES_SIGNATURE) {
        [panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"pdf", nil]];
        NSString *saveFileName = [NSString stringWithFormat:@"%@%@", [fileName stringByDeletingPathExtension], @"-signed"];
        [panel setNameFieldStringValue:saveFileName];
        [panel beginWithCompletionHandler: ^ (NSInteger result) {
            if (result == NSModalResponseOK) {
                _lblInsertPIN.hidden = YES;
                _cvInsertPIN.hidden = YES;
                _btnSignatureCompleted.hidden = YES;
                _btnSign.enabled = NO;
                _btnAbortSignature.enabled = NO;
                _progressSignature.hidden = NO;
                _lblProgressSignature.hidden = NO;
                NSString *outPath = [[panel URL] path];
                
                if (_cbGraphicSignature.state == NSOnState) {
                    Cie* selectedCie = [self.carouselView getSelectedCard];
                    NSString* signImgPath = [self getSignImagePath:[selectedCie getSerialNumber]];
                    NSArray *array = [pdfPreview getSignImageInfos];
                    [self firmaConCie:sender inputFilePath:filePath outFilePath:outPath signImagePath:signImgPath pin:pin x:[array[0] floatValue] y:[array[1] floatValue] w:[array[2] floatValue] h:[array[3] floatValue] fileType:@"pdf"];
                } else {
                    [self firmaConCie:sender inputFilePath:filePath outFilePath:outPath signImagePath:NULL pin:pin x:0.0 y:0.0 w:0.0 h:0.0 fileType:@"pdf"];
                }
            }
        }];
    } else {
        NSString *saveFileName = [NSString stringWithFormat:@"%@%@%@", [fileName stringByReplacingOccurrencesOfString:@".p7m" withString:@""], @"-signed", @".p7m"];
        [logger debug:[NSString stringWithFormat:@"File out: %@", saveFileName]];
        [panel setNameFieldStringValue:saveFileName];
        //[panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"p7m", nil]];
        [panel beginWithCompletionHandler: ^ (NSInteger result) {
            if (result == NSModalResponseOK) {
                _lblInsertPIN.hidden = YES;
                _cvInsertPIN.hidden = YES;
                _btnSignatureCompleted.hidden = YES;
                _btnSign.enabled = NO;
                _btnAbortSignature.enabled = NO;
                _progressSignature.hidden = NO;
                _lblProgressSignature.hidden = NO;
                NSString *outPath = [[panel URL] path];
                [self firmaConCie:sender inputFilePath:filePath outFilePath:outPath signImagePath:NULL pin:pin x:0.0 y:0.0 w:0.0 h:0.0 fileType:@"p7m"];
            }
        }];
    }
}

- (void) signMWCall:(NSControl*)sender inputFilePath:(NSString*)inPath outFilePath:(NSString*)outPath signImagePath:(NSString*)signImagePath pin:(NSString*)pin x:(float)x y:(float)y w:(float)w h:(float)h fileType:(NSString*)fileType {
    
    firmaConCIEfn pfnFirmaConCie = (firmaConCIEfn)dlsym(hModule, "firmaConCIE");
    
    if (!pfnFirmaConCie) {
        dlclose(hModule);
        [self showMessage:@"Funzione firmaConCie non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
        return;
    }
    
    int pageNumber = [pdfPreview getSelectedPage];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {
        NSString *pan = (self.fullPINSignature ? self.tmpPANCIE : [[self.carouselView getSelectedCard] getPan]);
        
        long ret = pfnFirmaConCie([inPath UTF8String], [fileType UTF8String], [pin UTF8String], [pan UTF8String], pageNumber, x, y, w, h, [signImagePath UTF8String], [outPath UTF8String], &progressSignatureCallback, &completedSignatureCallback);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [((NSControl*)sender) setEnabled:YES];
            
            if(self.fullPINSignature) {
                [self disabilita];
                self.fullPINSignature = NO;
                self.tmpPANCIE = nil;
            }
            
            switch (ret) {
                    
                case CKR_TOKEN_NOT_RECOGNIZED:
                    [self showMessage:@"CIE non presente sul lettore" withTitle:@"Firma con CIE" exitAfter:false];
                    [self showFirmaPinView];
                    break;
                    
                case CKR_TOKEN_NOT_PRESENT:
                    [self showMessage:@"CIE non presente sul lettore" withTitle:@"Firma con CIE"  exitAfter:false];
                    [self showFirmaPinView];
                    break;
                    
                case CKR_PIN_INCORRECT:
                    [self showMessage:[NSString stringWithFormat:@"Il PIN digitato è errato"] withTitle:@"PIN non corretto" exitAfter:false];
                    [self showFirmaPinView];
                    break;
                    
                case CKR_PIN_LOCKED:
                    [self showMessage:@"Munisciti del codice PUK e utilizza la funzione di sblocco carta per abilitarla" withTitle:@"Carta bloccata" exitAfter:false];
                    [self showFirmaPinView];
                    break;
                    
                case CKR_GENERAL_ERROR:
                    [self showMessage:@"Errore inaspettato durante la comunicazione con la smart card" withTitle:@"Errore inaspettato" exitAfter:false];
                    [self showFirmaPinView];
                    
                case CARD_PAN_MISMATCH:
                    [self showMessage:@"CIE selezionata diversa da quella presente sul lettore" withTitle:@"CIE non corrispondente" exitAfter:false];
                    [self showFirmaPinView];
                    break;
            }
        });
    });
}

- (void)firmaConCie:(NSControl*)sender inputFilePath:(NSString*)inPath outFilePath:(NSString*)outPath signImagePath:(NSString*)signImagePath pin:(NSString*)pin x:(float)x y:(float)y w:(float)w h:(float)h fileType:(NSString*)fileType {
    [logger info:@"firmaConCie:inputFilePath:outFilePath:signImagePath:pin:x:y:w:h:fileType: - Inizia funzione"];
    
    [sender setEnabled:NO];
    
    if(self.fullPINSignature) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^ {
            AbilitaCIEfn pfnAbilitaCIE = (AbilitaCIEfn)dlsym(hModule, "AbilitaCIE");
            
            if (!pfnAbilitaCIE) {
                dlclose(hModule);
                [self showMessage:@"Funzione AbilitaCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
                return;
            }
            
            char* szPAN = NULL;
            
            int attempts = -1;
            
            long ret = pfnAbilitaCIE(szPAN, [pin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallback, &completedCallback);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [((NSControl*)sender) setEnabled:YES];
                
                switch (ret) {
                    case CARD_ALREADY_ENABLED: {
                        [self showMessage:@"La CIE risulta essere già stata associata precedentemente, per cui l'operazione di firma è stata annullata. Ripetere il procedimento, selezionando la CIE dal selettore presente in 'Firma Elettronica'." withTitle:@"CIE già abilitata" exitAfter:NO];
                        [self showHomeFirstPage];
                        break;
                    }
                        
                    case CKR_OK: {
                        self.tmpPANCIE = [[NSString alloc] initWithCString:sPAN.c_str() encoding:NSUTF8StringEncoding];
                        NSString *serialNumber = [[NSString alloc] initWithCString:sEfSeriale.c_str() encoding:NSUTF8StringEncoding];
                        NSString *name = [[NSString alloc] initWithCString:sName.c_str() encoding:NSUTF8StringEncoding];
                        Cie *cie = [[Cie alloc] init:name serial:serialNumber pan:self.tmpPANCIE];
                        [cieList addCie:self.tmpPANCIE owner:cie];
                        [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        [self signMWCall:sender inputFilePath:inPath outFilePath:outPath signImagePath:signImagePath pin:[pin substringFromIndex:4] x:x y:y w:w h:h fileType:fileType];
                        break;
                    }
                        
                    default:
                        NSLog(@"Ret value: %ld", ret);
                        [self showMessage:@"Si è verificato un errore durante la lettura dei dati della CIE." withTitle:@"Errore durante la firma" exitAfter:NO];
                        [self showHomeFirstPage];
                }
            });
        });
    }
    
    else {
        [self signMWCall:sender inputFilePath:inPath outFilePath:outPath signImagePath:signImagePath pin:pin x:x y:y w:w h:h fileType:fileType];
    }
}

- (void)showFirmaPinView {
    [logger info:@"showFirmaPinView - Inizia funzione"];
    
    self.fullPINSignature = [[cieList getDictionary] count] == 0 || [self.carouselView shouldUseFullPINForSignature];
    
    int pinLength = ((self.fullPINSignature) ? 8 : 4);
    int tagIndexStart = 9;
    
    NSLog(@"PIN Length: %d", pinLength);
    
    for (int i = tagIndexStart; i < 17; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        txtField.stringValue = @"";
        
        if(i >= tagIndexStart + pinLength)
            txtField.hidden = YES;
        else
            txtField.hidden = NO;
    }
    
    _lblInsertPIN.stringValue = ((pinLength == 8) ? @"Inserisci le 8 cifre del PIN" : @"Inserisci le ultime 4 cifre del PIN");
    _lblInsertPIN.hidden = NO;
    _cvInsertPIN.hidden = NO;
    _btnAbort.hidden = NO;
    _btnSign.enabled = YES;
    _btnAbortSignature.enabled = YES;
    _progressSignature.hidden = YES;
    _lblProgressSignature.stringValue = @"Firma in corso...";
    _lblProgressSignature.hidden = YES;
    _btnSignatureCompleted.hidden = YES;
    imgSignatureOKPointer.hidden = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSTextField* txtField = [self.view viewWithTag:tagIndexStart];
        if(txtField != nil)
            [txtField selectText:nil];
    });
}

- (IBAction)concludiClick:(id)sender {
    [logger info:@"concludiClick: - Inizia funzione"];
    _lblInsertPIN.hidden = NO;
    _cvInsertPIN.hidden = NO;
    _btnAbortSignature.hidden = NO;
    _btnSign.hidden = NO;
    _btnSign.enabled = YES;
    _btnAbortSignature.enabled = YES;
    _progressSignature.hidden = YES;
    _lblProgressSignature.stringValue = @"Firma in corso...";
    _lblProgressSignature.hidden = YES;
    progressIndicatorSignaturePointer.doubleValue = 0;
    _btnSignatureCompleted.hidden = YES;
    imgSignatureOKPointer.hidden = YES;
    
    for (int i = 9; i < 17; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        txtField.stringValue = @"";
    }
    
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:SELECT_FILE_PAGE];
}

- (IBAction)personalizzaClick:(id)sender {
    [logger info:@"personalizzaClick: - Inizia funzione"];
    Cie* selectedCie = [self.carouselView getSelectedCard];
    NSString* signImgPath = [self getSignImagePath:[selectedCie getSerialNumber]];
    
    if ([selectedCie getCustomSign]) {
        _lblCustomizeGraphicSignature.stringValue = @"Una tua firma grafica personalizzata è già stata caricata. Vuoi aggiornarla?";
        _btnGenerateGraphicSignature.enabled = YES;
    } else {
        _lblCustomizeGraphicSignature.stringValue = @"Abbiamo creato per te una firma grafica, ma se preferisci puoi personalizzarla. Questo passaggio non è indispensabile, ma ti consentirà di dare un tocco personale ai documenti firmati.";
        _btnGenerateGraphicSignature.enabled = NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:signImgPath]) {
        [logger debug:@"Firma grafica non presente, verrà creata"];
        [self drawText:[selectedCie getName].capitalizedString pathToFile:signImgPath];
    }
    
    _signImageView.image = [[NSImage alloc] initWithContentsOfFile:signImgPath];
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:PERSONALIZZA_FIRMA_PAGE];
}

- (IBAction)indietroClick:(id)sender {
    [logger info:@"indietroClick: - Inizia funzione"];
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:SELECT_FILE_PAGE];
}

- (IBAction)creaFirmaClick:(id)sender {
    [logger info:@"creaFirmaClick: - Inizia funzione"];
    Cie* selectedCie = [self.carouselView getSelectedCard];
    NSString* signImgPath = [self getSignImagePath:[selectedCie getSerialNumber]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:signImgPath] == YES) {
        [fileManager removeItemAtPath:signImgPath error:&error];
    }
    
    [self drawText:[selectedCie getName].capitalizedString pathToFile:signImgPath];
    _lblCustomizeGraphicSignature.stringValue = @"Abbiamo creato per te una firma grafica, ma se preferisci puoi personalizzarla. Questo passaggio non è indispensabile, ma ti consentirà di dare un tocco personale ai documenti firmati.";
    [_btnCustomizeGraphicSignature setTitle:@"Personalizza"];
    [_lblCustomized setHidden:YES];
    [_lblGraphicSignatureCustomizationDesc setHidden:NO];
    _signImageView.image = [[NSImage alloc] initWithContentsOfFile:signImgPath];
    [selectedCie customSignSet:false];
    Cie* cie = [[cieList getDictionary] valueForKey:[selectedCie getPan]];
    [cie customSignSet:false];
    [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
    [NSUserDefaults.standardUserDefaults synchronize];
    _btnGenerateGraphicSignature.enabled = NO;
}

- (IBAction)selectFirmaSignClick:(id)sender {
    [logger info:@"selectFirmaSignClick: - Inizia funzione"];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setMessage:@"Selezionare una firma personalizzata"];
    [panel setExtensionHidden:NO];
    [panel setCanCreateDirectories:YES];
    [panel setAllowsOtherFileTypes:NO];
    [panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"png", nil]];
    [panel beginWithCompletionHandler: ^ (NSInteger result) {
        if (result == NSModalResponseOK) {
            NSString *customImgPath = [[panel URL] path];
            Cie* selectedCie = [self.carouselView getSelectedCard];
            NSString* signImgPath = [self getSignImagePath:[selectedCie getSerialNumber]];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error = nil;
            
            if ([fileManager fileExistsAtPath:signImgPath] == YES) {
                [fileManager removeItemAtPath:signImgPath error:&error];
            }
            
            if ([fileManager copyItemAtPath:customImgPath toPath:signImgPath error:&error]) {
                _signImageView.image = [[NSImage alloc] initWithContentsOfFile:signImgPath];
                [selectedCie customSignSet:true];
                Cie* cie = [[cieList getDictionary] valueForKey:[selectedCie getPan]];
                [cie customSignSet:true];
                [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
                [NSUserDefaults.standardUserDefaults synchronize];
                _lblCustomizeGraphicSignature.stringValue = @"Una tua firma grafica personalizzata è già stata caricata. Vuoi aggiornarla?";
                [_btnCustomizeGraphicSignature setTitle:@"Aggiorna"];
                [_lblCustomized setHidden:NO];
                [_lblGraphicSignatureCustomizationDesc setHidden:YES];
                _btnGenerateGraphicSignature.enabled = YES;
            }
        }
    }];
}

- (void)verificaConCie:(NSControl*)sender inputFilePath:(NSString*)inPath {
    [logger info:@"verificaConCie:inputFilePath: - Inizia funzione"];
    //NSString* fileType = @"pdf";
    [sender setEnabled:NO];
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {
        
        verificaConCIEfn pfnVerificaConCie = (verificaConCIEfn)dlsym(hModule, "verificaConCIE");
        getVerifyInfofn pfnGetVerifyInfo = (getVerifyInfofn)dlsym(hModule, "getVerifyInfo");
        
        if (!pfnVerificaConCie) {
            dlclose(hModule);
            [self showMessage:@"Funzione verificaConCIE non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
            return;
        }
        
        if (!pfnGetVerifyInfo) {
            dlclose(hModule);
            [self showMessage:@"Funzione getVerifyInfo non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
            return;
        }
        
        NSString* proxyAddress = nil;
        NSString* credentials = nil;
        int proxyPort = 0;
        
        if ([NSUserDefaults.standardUserDefaults objectForKey:@"proxyUrl"] && ![[NSUserDefaults.standardUserDefaults objectForKey:@"proxyUrl"] isEqual:@""]) {
            proxyPort = [[NSUserDefaults.standardUserDefaults objectForKey:@"proxyPort"] intValue];
            proxyAddress = [NSUserDefaults.standardUserDefaults objectForKey:@"proxyUrl"];
            
            if ([NSUserDefaults.standardUserDefaults objectForKey:@"credentials"] && ![[NSUserDefaults.standardUserDefaults objectForKey:@"credentials"] isEqual:@""]) {
                NSString* encryptedCredentials = [NSUserDefaults.standardUserDefaults objectForKey:@"credentials"];
                [logger debug:[NSString stringWithFormat:@"Encrypted Credentials: %@", encryptedCredentials]];
                ProxyInfoManager *proxyInfoManager = [[ProxyInfoManager alloc] init];
                NSString* decrypted = [proxyInfoManager getDecryptedCredentials:encryptedCredentials];
                
                if ([[decrypted substringToIndex:5] isEqual:@"cred="]) {
                    credentials = [decrypted substringFromIndex:5];
                }
            }
        }
        
        [logger debug:[NSString stringWithFormat:@"Verifica con CIE - Url: %@, Port: %d", proxyAddress, proxyPort]];
        
        long ret = pfnVerificaConCie([inPath UTF8String], [proxyAddress UTF8String], proxyPort, [credentials UTF8String]);
        
        if (ret != 0 && ret != DISIGON_ERROR_INVALID_FILE) {
            verifyItems = [NSMutableArray new];
            
            for (int i = 0; i < ret; i++) {
                verifyInfo_t info;
                CK_RV res = pfnGetVerifyInfo(i, info);
                
                NSString *name = [NSString stringWithFormat:@"%s %s\n%s", info.name, info.surname, info.cn];
                VerifyItem *nameItem = [[VerifyItem alloc] initWithImage:[NSImage imageNamed:@"user"] value:name];
                NSString * signingTime = [[NSString alloc] initWithCString:info.signingTime encoding:NSUTF8StringEncoding];
                
                if (strcmp(info.signingTime, "") == 0) {
                    signingTime = @"Attributo Signing Time non presente";
                } else {
                    //YYMMGGHHmmSS
                    NSDateFormatter *objDateFormatter = [[NSDateFormatter alloc] init];
                    [objDateFormatter setDateFormat:@"yyMMddHHmmss"];
                    NSDate *date  = [objDateFormatter dateFromString:[signingTime substringToIndex:(signingTime.length - 1)]];
                    [objDateFormatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
                    signingTime = [objDateFormatter stringFromDate:date];
                }
                
                VerifyItem *signingTimeItem = [[VerifyItem alloc] initWithImage:[NSImage imageNamed:@"calendar"] value:signingTime];
                NSString * signValidity = @"La firma non è valida";
                NSImage *signValidityImg = [NSImage imageNamed:@"orange_checkbox"];
                
                if (info.isSignValid) {
                    signValidity = @"La firma è valida";
                    signValidityImg = [NSImage imageNamed:@"green_checkbox"];
                }
                
                VerifyItem *signValidtyItem = [[VerifyItem alloc] initWithImage:signValidityImg value:signValidity];
                NSString * certValidity = @"Il certificato non è valido";
                NSImage * certValidityImg = [NSImage imageNamed:@"orange_checkbox"];
                
                if (info.isCertValid) {
                    certValidity = @"Il certificato è valido";
                    certValidityImg = [NSImage imageNamed:@"green_checkbox"];
                }
                
                VerifyItem *certValidityItem = [[VerifyItem alloc] initWithImage:certValidityImg value:certValidity];
                NSString * certStatus = @"Servizio di revoca non raggiungibile";
                NSImage * certStatusImg = [NSImage imageNamed:@"orange_checkbox"];
                
                switch (info.CertRevocStatus) {
                    case REVOCATION_STATUS_GOOD:
                        certStatus = @"Il certificato non è stato revocato";
                        certStatusImg = [NSImage imageNamed:@"green_checkbox"];
                        break;
                        
                    case REVOCATION_STATUS_REVOKED:
                        certStatus = @"Il certificato è stato revocato";
                        break;
                        
                    case REVOCATION_STATUS_SUSPENDED:
                        certStatus = @"Il certificato è stato sospeso";
                        break;
                        
                    case REVOCATION_STATUS_UNKNOWN:
                        certValidityItem.value = @"Certificato non verificato";
                        break;
                        
                    default:
                        break;
                }
                
                VerifyItem *certStatusItem = [[VerifyItem alloc] initWithImage:certStatusImg value:certStatus];
                NSString *cadn = [[NSString alloc] initWithCString:info.cadn encoding:NSUTF8StringEncoding];
                NSImage *cadnImg = [NSImage imageNamed:@"medal"];
                VerifyItem *cadnItem = [[VerifyItem alloc] initWithImage:cadnImg value:cadn];
                //[cadnItem setEnlarge:true];
                cadnItem.enlarge = true;
                [verifyItems addObject:nameItem];
                [verifyItems addObject:signingTimeItem];
                [verifyItems addObject:signValidtyItem];
                [verifyItems addObject:certValidityItem];
                [verifyItems addObject:certStatusItem];
                [verifyItems addObject:cadnItem];
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [sender setEnabled:YES];
                    [self.tbVerifyInfo reloadData];
                    self->_lblSignersNumber.stringValue = [NSString stringWithFormat:@"Numero di sottoscrittori: %d", ret];
                    ChangeView *cG = [ChangeView getInstance];
                    
                    if ([[filePath pathExtension] isEqualToString:@"p7m"]) {
                        _btnExtractFile.enabled = YES;
                    } else {
                        _btnExtractFile.enabled = NO;
                    }
                    [cG showSubView:VERIFICA_PAGE];
                });
            }
        } else if (ret == DISIGON_ERROR_INVALID_FILE) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [sender setEnabled:YES];
            });
            [self showMessage:@"Il file selezionato non è un file valido. E' possibile verificare solo file con estensione .p7m o.pdf" withTitle:@"Errore nella verifica" exitAfter:false];
            ChangeView *cG = [ChangeView getInstance];
            [cG showSubView:SELECT_FILE_PAGE];
        } else if (ret == 0) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [sender setEnabled:YES];
            });
            [self showMessage:@"Il file selezionato non contiene firme" withTitle:@"Verifica completata" exitAfter:false];
            ChangeView *cG = [ChangeView getInstance];
            [cG showSubView:SELECT_FILE_PAGE];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [sender setEnabled:YES];
            });
            [self showMessage:@"Errore nella verifica del file" withTitle:@"Errore nella verifica" exitAfter:false];
            ChangeView *cG = [ChangeView getInstance];
            [cG showSubView:SELECT_FILE_PAGE];
        }
        
    });
}

- (IBAction)salvaImpostazioni:(id)sender {
    [logger info:@"salvaImpostazioni: - Inizia funzione"];
    BOOL closeEditing = YES,
    syncUserDefaults = NO;
    struct logLevels levels;
    NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    
    if (([_txtUsername.stringValue isEqual:@""] && ![_txtPassword.stringValue isEqual:@""]) || (![_txtUsername.stringValue isEqual:@""] && [_txtPassword.stringValue isEqual:@""])) {
        [logger debug:@"Campo username o password mancante"];
        [self showMessage:@"Campo username o password mancante" withTitle:@"Credenziali proxy mancanti" exitAfter:false];
        closeEditing = NO;
    } else {
        if ([_txtUsername.stringValue isEqual:@""] ) {
            [logger debug:@"Campo username vuoto, credenziali svuotate"];
            [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"credentials"];
        } else {
            NSString* credentials = [NSString stringWithFormat:@"cred=%@:%@", _txtUsername.stringValue, _txtPassword.stringValue];
            ProxyInfoManager *proxyInfoManager = [[ProxyInfoManager alloc] init];
            NSString* encryptedCredentials = [proxyInfoManager getEncryptedCredentials:credentials];
            [NSUserDefaults.standardUserDefaults setObject:encryptedCredentials forKey:@"credentials"];
            [logger debug:@"Credenziali salvate!"];
        }
        
        syncUserDefaults = YES;
    }
    
    if (([_txtPort.stringValue isEqual:@""] && ![_txtProxyAddr.stringValue isEqual:@""]) || (![_txtPort.stringValue isEqual:@""] && [_txtProxyAddr.stringValue isEqual:@""])) {
        [logger debug:@"Indirizzo o porta del proxy mancante"];
        [self showMessage:@"Indirizzo o porta del proxy mancante" withTitle:@"Informazioni proxy mancanti" exitAfter:false];
        closeEditing = NO;
    } else if ([_txtPort.stringValue rangeOfCharacterFromSet:nonDigits].location != NSNotFound) {
        [logger debug:@"Il campo porta deve contenere solo numeri"];
        [self showMessage:@"Il campo porta deve contenere solo numeri" withTitle:@"Porta del proxy errata" exitAfter:false];
        closeEditing = NO;
    } else {
        [NSUserDefaults.standardUserDefaults setObject:_txtProxyAddr.stringValue forKey:@"proxyUrl"];
        
        if ([_txtPort.stringValue isEqual:@""]) {
            [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"proxyPort"];
        } else {
            [NSUserDefaults.standardUserDefaults setObject:_txtPort.stringValue forKey:@"proxyPort"];
        }
        
        syncUserDefaults = YES;
    }
    
    if ([_rbLoggingAppError state] == YES) {
        levels.logLevelApp = AppLogLevel_ERROR;
    } else if ([_rbLoggingAppInfo state] == YES) {
        levels.logLevelApp = AppLogLevel_INFO;
    } else if ([_rbLoggingAppDebug state] == YES) {
        levels.logLevelApp = AppLogLevel_DEBUG;
    } else if ([_rbLoggingAppNone state] == YES) {
        levels.logLevelApp = AppLogLevel_NONE;
    }
    
    if ([_rbLoggingLibError state] == YES) {
        levels.logLevelLib = AppLogLevel_ERROR;
    } else if ([_rbLoggingLibInfo state] == YES) {
        levels.logLevelLib = AppLogLevel_INFO;
    } else if ([_rbLoggingLibDebug state] == YES) {
        levels.logLevelLib = AppLogLevel_DEBUG;
    } else if ([_rbLoggingLibNone state] == YES) {
        levels.logLevelLib = AppLogLevel_NONE;
    }
    
    [self setLogConfigToLevels:levels];
    [self saveCurrentLogConfigToFile];
    
    NSString *value = ([(NSButton *)_cbShouldRunInBackground state] == NSOnState) ? @"YES" : @"NO";
    [_prefManager setConfigKeyValue:@"RUN_IN_BACKGROUND" : value];
    
    value = ([(NSButton *)_cbShowTutorial state] == NSOnState) ? @"YES" : @"NO";
    [_prefManager setConfigKeyValue:@"SHOW_TUTORIAL" : value];
    
    if (syncUserDefaults == YES) {
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    
    if (closeEditing == YES) {
        [self disableSettingsFormEditing];
    }
}

- (void)setSettingsFormEditingState:(BOOL)value {
    [logger info:@"setSettingsFormEditingState: - Inizia funzione"];
    [_txtPort setEnabled:value];
    [_txtProxyAddr setEnabled:value];
    [_txtPassword setEnabled:value];
    [_txtUsername setEnabled:value];
    [_cbShowPsw setEnabled:value];
    _cbShowPsw.state = NSOffState;
    [_btnSaveProxy setEnabled:value];
    [_btnEditProxy setEnabled:!value];
    [_rbLoggingAppNone setEnabled:value];
    [_rbLoggingAppError setEnabled:value];
    [_rbLoggingAppInfo setEnabled:value];
    [_rbLoggingAppDebug setEnabled:value];
    [_rbLoggingLibNone setEnabled:value];
    [_rbLoggingLibError setEnabled:value];
    [_rbLoggingLibInfo setEnabled:value];
    [_rbLoggingLibDebug setEnabled:value];
    [_cbShouldRunInBackground setEnabled:value];
    [_cbShowTutorial setEnabled:value];
}

- (void)disableSettingsFormEditing {
    [logger info:@"disableSettingsFormEditing - Inizia funzione"];
    [self setSettingsFormEditingState:NO];
}

- (void)enableSettingsFormEditing {
    [logger info:@"enableSettingsFormEditing - Inizia funzione"];
    [self setSettingsFormEditingState:YES];
}

- (IBAction)modificaProxyInfo:(id)sender {
    [logger info:@"modificaProxyInfo: - Inizia funzione"];
    [self enableSettingsFormEditing];
}

- (IBAction)mostraPassword:(id)sender {
    [logger info:@"mostraPassword: - Inizia funzione"];
    
    if (_cbShowPsw.state == NSControlStateValueOn && ![_txtPassword.stringValue isEqual:@""]) {
        _plainPassword.stringValue = _txtPassword.stringValue;
        [_txtPassword setHidden:TRUE];
        [_plainPassword setHidden:FALSE];
    } else {
        [_txtPassword setHidden:FALSE];
        [_plainPassword setHidden:TRUE];
    }
}

- (IBAction)collectLogClick:(id)sender {
    [self collectLogFiles];
}

- (IBAction)deleteLogClick:(id)sender {
    [self askRemoveLogs:@"Avanzando con l'operazione, verranno eliminati tutti i file di log generati da Software CIE. Confermi di voler procedere?" withTitle:@"Eliminazione log"];
}

- (BOOL) deleteLogFiles {
    BOOL res = true;
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logFolder = [[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.it.ipzs.SoftwareCIE"] path] stringByAppendingString:@"/Library/Caches/CIEPKI/"];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:logFolder error:nil];

    for (NSString *file in contents) {
        if ([[file pathExtension] isEqualToString:@"log"]) {
            NSString *fullPath = [logFolder stringByAppendingPathComponent:file];
            [fileManager removeItemAtURL:[NSURL fileURLWithPath:fullPath] error:&error];
        }
    }
    
    if(error != nil)
        res = false;
    
    return res;
}

- (void) collectLogFiles {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setTitle:@"Salva l'archivio zip dei log"];
    [savePanel setMessage:@"Software CIE\nSelezionare il percorso in cui salvare l'archivio\ncontenente i log per la diagnostica."];
    [savePanel setAllowedFileTypes:@[@"zip"]];
    [savePanel setPrompt:@"Conferma"];
    [savePanel setNameFieldStringValue:@"SoftwareCIE_Logs.zip"];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setExtensionHidden:NO];
    [savePanel setCanCreateDirectories:YES];
 
    [savePanel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *fileURL = [savePanel URL];
            BOOL success = [self createZipWithLogFiles:[fileURL path]];
            if (!success) {
                [self showMessage:@"Si è verificato un problema durante l'acquisizione dei log." withTitle:@"Raccolta fallita" exitAfter:false];
                [logger error:@"Errore nel salvataggio dell'archivio dei log."];
            } else {
                [self showMessage:@"La raccolta dei log di diagnostica è avvenuta con successo. Puoi adesso condividere con gli sviluppatori l'archivio generato per un'analisi della problematica riscontrata." withTitle:@"Raccolta completata" exitAfter:false];
                [logger info:[@"File salvato con successo in: " stringByAppendingString:[fileURL path]]];
            }
        }
    }];
}

- (BOOL)createZipWithLogFiles:(NSString *)zipPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *logFiles = [NSMutableArray array];
    NSString *logFolder = [[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.it.ipzs.SoftwareCIE"] path] stringByAppendingString:@"/Library/Caches/CIEPKI/"];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:logFolder error:nil];

    for (NSString *file in contents) {
        if ([[file pathExtension] isEqualToString:@"log"]) {
            NSString *fullPath = [logFolder stringByAppendingPathComponent:file];
            [logFiles addObject:fullPath];
        }
    }

    if ([logFiles count] == 0) {
        [self showMessage:@"Non sono presenti log. Effettua prima delle operazioni con l'applicativo, quindi ripeti l'operazione di raccolta dei log." withTitle:@"Raccolta completata" exitAfter:false];
       [logger info:@"Non ci sono file .log nella directory."];
       return FALSE;
    }

    return [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:logFiles];
}

- (IBAction)btnEstraiClick:(id)sender {
    [logger info:@"btnEstraiClick: - Inizia funzione"];
    estraiP7mfn pfnEstraiP7m = (estraiP7mfn)dlsym(hModule, "estraiP7m");

    if (!pfnEstraiP7m) {
        dlclose(hModule);
        [self showMessage:@"Funzione estraiP7m non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
        return;
    }

    NSSavePanel *panel = [NSSavePanel savePanel];
    NSString* fileName = [[[filePath lastPathComponent] stringByDeletingPathExtension]stringByReplacingOccurrencesOfString:@"-signed" withString:@""];
    [logger debug:[NSString stringWithFormat:@"Nome file originale: %@", fileName]];
    NSString *saveFileName = fileName;
    [panel setMessage:@"Scegliere dove salvare il file estratto"]; // Message inside modal window
    [panel setExtensionHidden:NO];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:@"Salva file estratto"];
    [panel setAllowsOtherFileTypes:NO];
    [panel setNameFieldStringValue:saveFileName];
    NSString* fileExtension = [fileName pathExtension];
    [panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:fileExtension, nil]];
    [panel beginWithCompletionHandler: ^ (NSInteger result) {
              if (result == NSModalResponseOK) {
                  NSString *outPath = [[panel URL] path];
            [logger debug:[NSString stringWithFormat:@"Path file estratto: %@", outPath]];
            long res = pfnEstraiP7m([filePath UTF8String], [outPath UTF8String]);

            if (res == 0) {
                [self showMessage:@"File estratto correttamente" withTitle:@"Estrazione file completata" exitAfter:false];
            } else {
                [self showMessage:@"Impossibile estrarre il file" withTitle:@"Estrazione file completata" exitAfter:false];
            }
        }
    }];
}

- (IBAction)showInformation:(id)sender {
    NSString *appDescription = @"Il software rilasciato dall’Istituto Poligrafico e Zecca dello Stato S.p.A. per conto del Ministero dell’Interno, per consentire l’autenticazione ai servizi digitali, l’apposizione della firma elettronica avanzata mediante la CIE, nonché la gestione dei codici PIN e PUK della carta.\n\nVersione: ";
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    [self showMessage:[appDescription stringByAppendingString:version] withTitle:@"Informazioni su CIE ID" exitAfter:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    [logger info:@"numberOfRowsInTableView: - Inizia funzione"];

    if (verifyItems != nil) {
        return verifyItems.count;
    }

    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    [logger info:@"tableView:viewForTableColumn:row: - Inizia funzione"];
    NSView* cell = [tableView makeViewWithIdentifier:@"verifyCellID" owner:nil];

    if ([cell isKindOfClass:[VerifyCell class]]) {
        VerifyCell* verifyCell = (VerifyCell*)cell;
        VerifyItem* item = verifyItems[row];
        [verifyCell configureWith:item];
        return verifyCell;
    }

    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn {
    [logger info:@"tableView:shouldSelectTableColumn: - Inizia funzione"];
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    [logger info:@"tableView:shouldSelectRow: - Inizia funzione"];
    return NO;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    [logger info:@"tableView:heightOfRow: - Inizia funzione"];
    VerifyItem* item = verifyItems[row];

    if (item.enlarge == true) {
        return 110;
    }

    return 40;
}

- (IBAction)concludiVerificaClick:(id)sender {
    [logger info:@"concludiVerificaClick: - Inizia funzione"];
    self->_lblSignersNumber.stringValue =  @"Numero di sottoscrittori";
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:SELECT_FILE_PAGE];
}

#pragma mark - CarouselViewDelegate

- (void)shouldAddCard {
    [logger info:@"shouldAddCard - Inizia funzione"];

    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:HOME_FIRST_PAGE];

    for (int i = 1; i < 9; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        txtField.stringValue = @"";
    }

    NSTextField* txtField = [self.view viewWithTag:1];
    [txtField selectText:nil];
}

- (void)shouldRemoveAllCards {
    [logger info:@"shouldRemoveAllCards - Inizia funzione"];
    [self askRemoveAll:@"Vuoi rimuovere tutte le CIE attualmente abbinate?" withTitle:@"Rimozione CIE"];
}

- (void)shouldRemoveCard:(nonnull Cie *)card {
    [logger info:@"shouldRemoveCard: - Inizia funzione"];
    removingCie = card;
    [self askRemove:[NSString stringWithFormat:@"Stai rimuovendo la Carta di Identità di %@ dal sistema, per utilizzarla nuovamente dovrai ripetere l'abbinamento.", [card getName]] withTitle:@"Rimozione CIE"];
}

#pragma mark - AppLogger

- (void)LoadLogConfigFromFile {
    [logger info:@"LoadLogConfigFromFile - Inizia funzione"];
    BOOL writeLogConfigFile = NO,
         logConfigLineAppPresent = NO,
         logConfigLineLibPresent = NO;
    struct logLevels levels;
    levels.logLevelApp = [logger defaultLevel];
    levels.logLevelLib = [logger defaultLevel];
    
    [logger debug:[NSString stringWithFormat:@"LoadLogConfigFromFile configconfigFilePath: /.CIEPKI/config"]];
    
    [logger debug:@"Leggo file configurazione log"];
    
    NSString *value = [_prefManager getConfigKeyValue:LogConfigPrefixApp];
    
    if(![value isEqualToString:@""]) {
        logConfigLineAppPresent = YES;
        [logger debug:[NSString stringWithFormat:@"Configurazione log applicazione: %@=%@", LogConfigPrefixApp, value]];
        NSInteger integerValueAppLogLevel = [value integerValue];
        
        if ((integerValueAppLogLevel >= AppLogLevel_NONE && integerValueAppLogLevel <= AppLogLevel_ERROR)) {
            levels.logLevelApp = (AppLogLevel)integerValueAppLogLevel;
        } else {
            [logger debug:[NSString stringWithFormat:@"valore '%d' del livello di log applicazione fuori intervallo - uso default", integerValueAppLogLevel]];
            writeLogConfigFile = YES;
        }
    }
    
    value = [_prefManager getConfigKeyValue:LogConfigPrefixLib];
    
    if(![value isEqualToString:@""]) {
        logConfigLineLibPresent = YES;
        [logger debug:[NSString stringWithFormat:@"Configurazione log libreria: %@=%@", LogConfigPrefixLib, value]];
        NSInteger integerValue = [value integerValue];

        if ((integerValue >= AppLogLevel_NONE && integerValue <= AppLogLevel_ERROR)) {
            levels.logLevelLib = (AppLogLevel)integerValue;
        } else {
            [logger debug:[NSString stringWithFormat:@"valore '%d' del livello di log libreria fuori intervallo - uso default", integerValue]];
            writeLogConfigFile = YES;
        }
    }

    if (logConfigLineAppPresent == NO || logConfigLineLibPresent == NO) {
        writeLogConfigFile = YES;
    }

    [self setLogConfigToLevels:levels];

    if (writeLogConfigFile == YES) {
        [self saveCurrentLogConfigToFile];
    }
}

- (void)setLogConfigToLevels:(struct logLevels)levels {
    [logger setLevel:levels.logLevelApp];
    [self setLogLevelApp:levels.logLevelApp];
    [self setLogLevelLib:levels.logLevelLib];
    [logger info:@"setLogConfigToLevels: - Inizia funzione"];
    [logger debug:[NSString stringWithFormat:@"setLogConfigToLevels: - logLevelApp:%d", levels.logLevelApp]];
    [logger debug:[NSString stringWithFormat:@"setLogConfigToLevels: - logLevelLib:%d", levels.logLevelLib]];
}

- (void)saveCurrentLogConfigToFile {
    [logger info:@"saveCurrentLogConfigToFile - Inizia funzione"];
    struct logLevels levels;
    levels.logLevelApp = [self logLevelApp];
    levels.logLevelLib = [self logLevelLib];
    [self saveLogConfigToFileWithLevels:levels];
}

- (void)saveLogConfigToFileWithLevels:(struct logLevels)levels {
    [logger info:@"saveLogConfigToFileWithLevels: - Inizia funzione"];
    [logger debug:[NSString stringWithFormat:@"saveLogConfigToFileWithLevels: - levels.logLevelApp: %ld", levels.logLevelApp]];
    [logger debug:[NSString stringWithFormat:@"saveLogConfigToFileWithLevels: - levels.logLevelLib: %ld", levels.logLevelLib]];
    [_prefManager setConfigKeyValue:LogConfigPrefixLib : [NSString stringWithFormat:@"%ld", levels.logLevelLib]];
    [_prefManager setConfigKeyValue:LogConfigPrefixApp : [NSString stringWithFormat:@"%ld", levels.logLevelApp]];
}

@end

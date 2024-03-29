//
//  MainViewController.m
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "MainViewController.h"
#import <IOKit/IOKitLib.h>
#import <CommonCrypto/CommonDigest.h>
#import "ProxyInfoManager.h"

#import "PINNoticeViewController.h"
#import "CieList.h"
#import "Cie.h"
#import "ChangeView.h"
#import "CIE_ID-Swift.h"
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
@property (weak) IBOutlet NSButton *cbFirmaGrafica;
@property (weak) IBOutlet NSView *viewFirmaSelectOp;
@property (weak) IBOutlet NSView *prevImageView;
@property (weak) IBOutlet NSTextField* lblPathFirmaPrev;
@property (weak) IBOutlet NSTextField *lblPathFirmaPin;
@property (weak) IBOutlet NSTextField *lblInsertPin;
@property (weak) IBOutlet NSProgressIndicator *progressFirma;
@property (weak) IBOutlet NSTextField *lblProgressFirma;
@property (weak) IBOutlet NSImageView *imgFirmaOk;
@property (weak) IBOutlet NSView *cvInsertPin;
@property (weak) IBOutlet NSButton *btnAnnullaFirma;
@property (weak) IBOutlet NSButton *btnConcludiFirma;
@property (weak) IBOutlet NSButton *btnFirma;
@property (weak) IBOutlet NSButton *btnFirmaElettronica;
@property (weak) IBOutlet NSButton *btnVerificaFirma;
@property (weak) IBOutlet NSTextField *lblPathOp;
@property (weak) IBOutlet NSButton *btnProseguiFirmaOp;
@property (weak) IBOutlet NSImageView *signImageView;
@property (weak) IBOutlet NSTextField *lblFirmaHome;
@property (weak) IBOutlet NSTextField *lblSubFirmaHome;
@property (weak) IBOutlet NSView *fileSelectionSignatureBlockView;
@property (weak) IBOutlet NSTextFieldCell *lblFirmaPersonalizata;
@property (weak) IBOutlet NSButton *btnPersonalizza;
@property (weak) IBOutlet NSTextField *lblFirmaPersonalizzataSub;
@property (weak) IBOutlet NSTextField *lblPersonalizzata;
@property (weak) IBOutlet NSTableView *tbVerificaInfo;
@property (weak) IBOutlet NSTextField *lblVerificaPath;
@property (weak) IBOutlet NSTextField *lblSottoscrittori;
@property (weak) IBOutlet NSImageView *imgUpload;
@property (weak) IBOutlet NSButton *btnCreaFirma;
@property (weak) IBOutlet NSTextField *txtProxyAddr;
@property (weak) IBOutlet NSTextField *txtUsername;
@property (weak) IBOutlet NSSecureTextField *txtPassword;
@property (weak) IBOutlet NSTextField *plainPassword;

@property (weak) IBOutlet NSTextField *txtPorta;
@property (weak) IBOutlet NSButton *cbMostraPsw;
@property (weak) IBOutlet NSButton *btnSalvaProxy;
@property (weak) IBOutlet NSButton *btnModificaProxy;
@property (weak) IBOutlet NSButton *btnEstrai;

@property (weak) IBOutlet NSLayoutConstraint *abbinaButtonWhenAnnullaVisible;

@property (weak) IBOutlet NSLayoutConstraint *abbinaButtonWhenAnnullaInvisible;
@property (weak) IBOutlet NSView *mainCustomView;

typedef NS_ENUM(NSUInteger, signOp) {
    NO_OP,
    FIRMA_CADES,
    FIRMA_PADES,
    VERIFY,
};

@end

@implementation MainViewController

NSTextField* labelProgressPointer;
NSProgressIndicator* progressIndicatorPointer;

NSTextField* labelProgressPointerCambioPIN;
NSProgressIndicator* progressIndicatorPointerCambioPIN;

NSTextField* labelProgressPointerSbloccoPIN;
NSProgressIndicator* progressIndicatorPointerSbloccoPIN;

NSProgressIndicator* progressIndicatorPointerFirma;
NSTextField* lblInsertPinPointer;
NSTextField* lblProgressFirmaPointer;
NSView* cvInsertPinPointer;
NSButton* btnAnnullPointer;
NSButton* btnAnnullaFirmaPointer;
NSButton* btnFirmaPointer;
NSButton* btnConcludiFirmaPointer;
NSImageView* imgFirmaOkPointer;
NSButton* cbFirmaGraficaPointer;

string sPAN;
string sName;
string sEfSeriale;

NSString* filePath;
NSString *path;
NSArray *viewArray;
NSMutableArray <VerifyItem *> *verifyItems;

signOp operation;
PdfPreview* pdfPreview;

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
                                 _cambioPINPageView,
                                 _cambioPINOKPageView,
                                 _sbloccoPageView,
                                 _sbloccoOKPageView,
                                 _helpPageView,
                                 _infoPageView,
                                 _selectFilePageView,
                                 _selectOperationView,
                                 _firmaOperationView,
                                 _firmaPrevView,
                                 _firmaPinView,
                                 _personalizzaFirmaView,
                                 _verificaView,
                                 _impostazioniView,
                                 nil];
    ChangeView *cG = [ChangeView getInstance];
    cG.viewArray = viewArray;
    [self showHomeFirstPage];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    logger = [AppLogger sharedInstanceWithDefaultLogLevel];
    [self LoadLogConfigFromFile];
    [logger info:@"App CIE - logger inizializzato"];
    [logger debug:@"App CIE - debug"];
    [logger error:@"App CIE - error"];
    [logger info:[NSString stringWithFormat:@"[I] Livello di log applicazione: %ld", [self logLevelApp]]];
    [logger info:[NSString stringWithFormat:@"[I] Livello di log libreria: %ld", [self logLevelLib]]];
    [logger info:@"Inizializzo view principale"];
    [_viewFirmaSelectOp updateLayer];
    [self addSubviewToMainCustomView:_homeFirstPageView];
    [self addSubviewToMainCustomView:_homeSecondPageView];
    [self addSubviewToMainCustomView:_homeThirdPageView];
    [self addSubviewToMainCustomView:_homeFourthPageView];
    [self addSubviewToMainCustomView:_cambioPINPageView];
    [self addSubviewToMainCustomView:_cambioPINOKPageView];
    [self addSubviewToMainCustomView:_sbloccoPageView];
    [self addSubviewToMainCustomView:_sbloccoOKPageView];
    [self addSubviewToMainCustomView:_helpPageView];
    [self addSubviewToMainCustomView:_infoPageView];
    [self addSubviewToMainCustomView:_selectFilePageView];
    [self addSubviewToMainCustomView:_selectOperationView];
    [self addSubviewToMainCustomView:_firmaOperationView];
    [self addSubviewToMainCustomView:_firmaPrevView];
    [self addSubviewToMainCustomView:_firmaPinView];
    [self addSubviewToMainCustomView:_personalizzaFirmaView];
    [self addSubviewToMainCustomView:_verificaView];
    [self addSubviewToMainCustomView:_impostazioniView];
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
    labelProgressPointerCambioPIN = _labelProgressCambioPIN;
    progressIndicatorPointerCambioPIN = _progressIndicatorCambioPIN;
    labelProgressPointerSbloccoPIN = _labelProgressSbloccoPIN;
    progressIndicatorPointerSbloccoPIN = _progressIndicatorSbloccoPIN;
    progressIndicatorPointerFirma = _progressFirma;
    lblInsertPinPointer =  _lblInsertPin;
    lblProgressFirmaPointer = _lblProgressFirma;
    cvInsertPinPointer = _cvInsertPin;
    btnAnnullPointer = _btnAnnulla;
    btnAnnullaFirmaPointer = _btnAnnullaFirma;
    btnFirmaPointer = _btnFirma;
    btnConcludiFirmaPointer = _btnConcludiFirma;
    imgFirmaOkPointer = _imgFirmaOk;
    cbFirmaGraficaPointer = _cbFirmaGrafica;
    self.carouselView.delegate = self;
    [self.tbVerificaInfo registerNib:[[NSNib alloc] initWithNibNamed:@"VerifyCell" bundle:nil]forIdentifier:@"verifyCellID"];
    self.tbVerificaInfo.delegate = self;
    self.tbVerificaInfo.dataSource = self;
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

    if (![NSUserDefaults.standardUserDefaults objectForKey:@"dontShowIntro"]) {
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
        if (textField.tag < 13) {
            if (textField.tag == 8 || textField.tag == 12) {
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

CK_RV progressFirmaCallback(const int progress,
                            const char* szMessage) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        progressIndicatorPointerFirma.doubleValue = progress;
    });
    return 0;
}

CK_RV progressCallbackCambioPIN(const int progress,
                                const char* szMessage) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        labelProgressPointerCambioPIN.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointerCambioPIN.doubleValue = progress;
    });
    return 0;
}

CK_RV progressCallbackSbloccoPIN(const int progress,
                                 const char* szMessage) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        labelProgressPointerSbloccoPIN.stringValue = [NSString stringWithUTF8String:szMessage];
        progressIndicatorPointerSbloccoPIN.doubleValue = progress;
    });
    return 0;
}

CK_RV completedFirmaCallback(int ret) {
    [logger info:@"completedFirmaCallback: - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        if (ret == 0) {
            lblProgressFirmaPointer.stringValue = @"File firmato con successo";
            [logger debug:lblProgressFirmaPointer.stringValue];
            imgFirmaOkPointer.hidden = NO;
            imgFirmaOkPointer.image = [NSImage imageNamed:@"check"];
        } else {
            lblProgressFirmaPointer.stringValue = @"Si è verificato un errore durante la firma";
            [logger debug:lblProgressFirmaPointer.stringValue];
            //TODO impostare immagine errore
            imgFirmaOkPointer.hidden = NO;
            imgFirmaOkPointer.image = [NSImage imageNamed:@"cross"];
        }

        progressIndicatorPointerFirma.hidden = YES;
        btnConcludiFirmaPointer.hidden = NO;
        btnAnnullaFirmaPointer.hidden = YES;
        btnFirmaPointer.hidden = YES;

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
    /*
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
    */
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
    NSString* pan = [removingCie getPan];
    NSString* serialNumber = [removingCie getSerialNumber];
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
            /*
            [self showMessage:@"CIE non abilitata" withTitle:@"Verifica CIE" exitAfter:false];
            return;
            */
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
            [self showMessage:@"CIE disabilitata con successo" withTitle:@"CIE disabilitata" exitAfter:NO];
            [cieList removeCie:pan];
            [self.carouselView configureWithCards:[[cieList getDictionary] allValues]];
            NSFileManager *manager = [NSFileManager defaultManager];
            [manager removeItemAtPath:[self getSignImagePath:serialNumber] error:NULL];
            [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
            [NSUserDefaults.standardUserDefaults synchronize];
            [self showHomeFirstPage];
            break;
        }

        case CKR_TOKEN_NOT_PRESENT:
            [self showMessage:@"CIE non presente sul lettore" withTitle:@"Abilitazione CIE" exitAfter:false];
            break;

        default:
            [self showMessage:@"Impossibile disabilitare la CIE" withTitle:@"CIE non disabilitata" exitAfter:NO];
            break;
    }
}

- (IBAction)rbLoggingAppAction:(NSButton *)sender {
    [logger info:@"rbLoggingAppAction: - Inizia funzione"];
}

- (IBAction)rbLoggingLibAction:(NSButton *)sender {
    [logger info:@"rbLoggingLibAction: - Inizia funzione"];
}

- (IBAction)home:(id)sender {
    [logger info:@"home: - Inizia funzione"];
    _lblFirmaHome.stringValue = @"CIE ID";
    _lblSubFirmaHome.stringValue = @"Carta di Identità Elettronica abbinata correttamente";
    [self showHomeFirstPage];
}

- (IBAction)impostazioni:(id)sender {
    [logger info:@"impostazioni: - Inizia funzione"];
    [self showImpostazioniPage];
}

- (IBAction)firmaElettronica:(id)sender {
    [logger info:@"firmaElettronica: - Inizia funzione"];
    [self showFirmaPinView];
    [self showFirmaElettronica];
}

- (IBAction)verificaFirma:(id)sender {
    [logger info:@"verificaFirma: - Inizia funzione"];
    // [self showFirmaPinView];
    [self showVerificaFirma];
}

- (IBAction)cambioPIN:(id)sender {
    [logger info:@"cambioPIN: - Inizia funzione"];
    [self showCambioPINPage];
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
    NSString* newpin = self.textFieldNewPINSblocco.stringValue;
    NSString* confirmpin = self.textFieldConfirmPINSbloco.stringValue;

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
    self.progressIndicatorSbloccoPIN.hidden = NO;
    self.labelProgressSbloccoPIN.hidden = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {

        SbloccoPINfn pfnSbloccoPIN = (SbloccoPINfn)dlsym(hModule, "SbloccoPIN");

        if (!pfnSbloccoPIN) {
            dlclose(hModule);
            [self showMessage:@"Funzione SbloccoPIN non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:false];
            return;
        }

        int attempts = -1;

        long ret = pfnSbloccoPIN([puk cStringUsingEncoding:NSUTF8StringEncoding], [newpin cStringUsingEncoding:NSUTF8StringEncoding], &attempts, &progressCallbackSbloccoPIN);

        dispatch_async(dispatch_get_main_queue(), ^{

            self.progressIndicatorSbloccoPIN.hidden = YES;
            self.labelProgressSbloccoPIN.hidden = YES;

            [((NSControl*)sender) setEnabled:YES];

            switch (ret) {
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
    self.progressIndicatorCambioPIN.hidden = NO;
    self.labelProgressCambioPIN.hidden = NO;
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

            self.progressIndicatorCambioPIN.hidden = YES;
            self.labelProgressCambioPIN.hidden = YES;

            [((NSControl*)sender) setEnabled:YES];

            switch (ret) {
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
        /*
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
         */
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
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;

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
            _txtPorta.stringValue = [NSUserDefaults.standardUserDefaults objectForKey:@"proxyPort"];
        }

        [_rbLoggingAppError setState:NSOffState];
        [_rbLoggingAppInfo setState:NSOffState];
        [_rbLoggingAppDebug setState:NSOffState];
        [_rbLoggingAppNone setState:NSOffState];

        [_rbLoggingLibError setState:NSOffState];
        [_rbLoggingLibInfo setState:NSOffState];
        [_rbLoggingLibDebug setState:NSOffState];
        [_rbLoggingLibNone setState:NSOffState];

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
        [self updateAbbinaAndAnnullaLayout]; \
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = NO;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = YES;
        self.sbloccoOKPageView.hidden = YES;
         */
        _lblCades.textColor = NSColor.grayColor;
        _lblCadesSub.textColor = NSColor.grayColor;
        _lblPades.textColor = NSColor.grayColor;
        _lblPadesSub.textColor = NSColor.grayColor;
        _cbFirmaGrafica.state = NSOffState;
        _btnProseguiFirmaOp.enabled = NO;
        operation = NO_OP;
        _lblFirmaHome.stringValue = @"Firma Elettronica";
        _lblSubFirmaHome.stringValue = @"Seleziona la CIE da utilizzare";
        [self.carouselView changeButtonViews];
        ChangeView *cG = [ChangeView getInstance];
        [_fileSelectionSignatureBlockView setHidden:NO];
        [cG showSubView:HOME_FOURTH_PAGE];
    });
}

- (void)showVerificaFirma {
    [logger info:@"showVerificaFirma - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self updateAbbinaAndAnnullaLayout];
        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = NO;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = YES;
        self.sbloccoOKPageView.hidden = YES;
         */
        _lblCades.textColor = NSColor.grayColor;
        _lblCadesSub.textColor = NSColor.grayColor;
        _lblPades.textColor = NSColor.grayColor;
        _lblPadesSub.textColor = NSColor.grayColor;
        _cbFirmaGrafica.state = NSOffState;
        _btnProseguiFirmaOp.enabled = NO;
        operation = VERIFY;
        _lblFirmaHome.stringValue = @"Firma Elettronica";
        _lblSubFirmaHome.stringValue = @"Seleziona la CIE da utilizzare";
        [_fileSelectionSignatureBlockView setHidden:YES];
        // [self.carouselView changeButtonViews];
        [[ChangeView getInstance] showSubView:SELECT_FILE_PAGE];
    });
}

- (void)showHomeFirstPage {
    [logger info:@"showHomeFirstPage - Inizia funzione"];
    //[NSUserDefaults.standardUserDefaults removeObjectForKey:@"cieDictionary"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        [self updateAbbinaAndAnnullaLayout];

        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

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
        /*
        else if((![NSUserDefaults.standardUserDefaults objectForKey:@"efSeriale"]) and [NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"])
        {
            [self askRiabbina:@"E' necessario effettuare un nuovo abbinamento. Procedere?" withTitle:@"Abbinare nuovamente la CIE"];

        }
        else if([NSUserDefaults.standardUserDefaults objectForKey:@"efSeriale"] and [NSUserDefaults.standardUserDefaults objectForKey:@"cardholder"])
        {
            [self showHomeFourthPage];
        }
         */
        else {
            /*
            self.homeFirstPageView.hidden = NO;
            self.homeSecondPageView.hidden = YES;
            self.homeThirdPageView.hidden = YES;
            self.homeFourthPageView.hidden = YES;
            self.cambioPINPageView.hidden = YES;
            self.cambioPINOKPageView.hidden = YES;
            self.sbloccoPageView.hidden = YES;
            self.sbloccoOKPageView.hidden = YES;
            */
            ChangeView *cG = [ChangeView getInstance];
            [cG showSubView:HOME_FIRST_PAGE];
            [_btnFirmaElettronica setEnabled:NO];

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
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        /*
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeThirdPageView.hidden = NO;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
         */

        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HOME_THIRD_PAGE];

        //[self showSubView:HOME_THIRD_PAGE];
    });
}

- (void)showHomeSecondPage {
    [logger info:@"showHomeSecondPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = NO;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;

        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HOME_SECOND_PAGE];

    });
}

- (void)showHomeFourthPage {
    [logger info:@"showHomeFourthPage - Inizia funzione"];
    [self.carouselView configureWithCards:[[cieList getDictionary] allValues]];
    [_btnFirmaElettronica setEnabled:YES];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        [self updateAbbinaAndAnnullaLayout];

        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = NO;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
        self.sbloccoPageView.hidden = YES;
        self.sbloccoOKPageView.hidden = YES;
        */

        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HOME_FOURTH_PAGE];

    });
}

- (void)showCambioPINPage {
    [logger info:@"showCambioPINPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        self.progressIndicatorCambioPIN.hidden = YES;
        self.labelProgressCambioPIN.hidden = YES;

        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = NO;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = YES;
        self.sbloccoOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
         */
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:CAMBIO_PIN_PAGE];

    });
}

- (void)showCambioPINOKPage {
    [logger info:@"showCambioPINOKPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = NO;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
         */
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:CAMBIO_PIN_OK_PAGE];
    });
}

- (void)showSbloccoPage {
    [logger info:@"showSbloccoPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        self.progressIndicatorSbloccoPIN.hidden = YES;
        self.labelProgressSbloccoPIN.hidden = YES;

        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = NO;
        self.sbloccoOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
         */

        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:SBLOCCO_PAGE];

    });
}

- (void)showSbloccoOKPage {
    [logger info:@"showSbloccoOKPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.sbloccoPageView.hidden = YES;
        self.sbloccoOKPageView.hidden = NO;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = YES;
         */

        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:SBLOCCO_OK_PAGE];

    });
}

- (void)showHelpPage {
    [logger info:@"showHelpPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        self.labelHelp.stringValue = @"Aiuto";
        self.assistenzaImageView.hidden = NO;
        self.sbloccoImageView.hidden = NO;

        /*
        self.homeFirstPageView.hidden = YES;
        self.selectFilePageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = NO;
        self.infoPageView.hidden = YES;
         */
        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HELP_PAGE];

        [self.helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/aiuto.jsp"]]];
    });
}

- (void)showTutorialPage {
    [logger info:@"showTutorialPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        self.labelHelp.stringValue = @"Tutorial";
        self.assistenzaImageView.hidden = YES;
        self.sbloccoImageView.hidden = YES;

        /*
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = NO;
        self.infoPageView.hidden = YES;
         */

        ChangeView *cG = [ChangeView getInstance];
        [cG showSubView:HELP_PAGE];

        [self.helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://idserver.servizicie.interno.gov.it/idp/tutorial_mac.jsp"]]];
    });
}

- (void)showInfoPage {
    [logger info:@"showInfoPage - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {

        self.homeButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.firmaElettronicaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.verificaFirmaButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.cambioPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.sbloccoPINButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.tutorialButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.helpButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.infoButtonView.layer.backgroundColor = NSColor.grayColor.CGColor;
        self.impostazioniButtonView.layer.backgroundColor = NSColor.clearColor.CGColor;

        /*
        self.homeFirstPageView.hidden = YES;
        self.homeSecondPageView.hidden = YES;
        self.homeThirdPageView.hidden = YES;
        self.homeFourthPageView.hidden = YES;
        self.cambioPINPageView.hidden = YES;
        self.cambioPINOKPageView.hidden = YES;
        self.helpPageView.hidden = YES;
        self.infoPageView.hidden = NO;
         */
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
        [alert addButtonWithTitle:@"Ok"];
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

- (void)askRemove:(NSString*)message withTitle:(NSString*)title {
    [logger info:@"askRemove:withTitle: - Inizia funzione"];
    dispatch_async(dispatch_get_main_queue(), ^ {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Ok"];
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
        [alert addButtonWithTitle:@"SI"];
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

- (void)updateAbbinaAndAnnullaLayout {
    [logger info:@"updateAbbinaAndAnnullaLayout - Inizia funzione"];

    if ( [[cieList getDictionary] count] >= 1) {
        self.btnAnnulla.hidden = NO;
        self.abbinaButtonWhenAnnullaVisible.priority = NSLayoutPriorityDefaultHigh;
        self.abbinaButtonWhenAnnullaInvisible.priority = NSLayoutPriorityDefaultLow;
    } else {
        self.btnAnnulla.hidden = YES;
        self.abbinaButtonWhenAnnullaVisible.priority = NSLayoutPriorityDefaultLow;
        self.abbinaButtonWhenAnnullaInvisible.priority = NSLayoutPriorityDefaultHigh;
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
        // [cG showSubView:SELECT_OP_PAGE];
    } else {
        // [cG showSubView:SELECT_OP_PAGE];
        [self btnFirmaOp:nil];
    }
}

- (IBAction)btnFirmaOp:(id)sender {
    [logger info:@"btnFirmaOp: - Inizia funzione"];
    filePath = _lblPathOp.stringValue;
    _filePathSignOp.stringValue = filePath;
    _btnProseguiFirmaOp.enabled = NO;
    _lblCades.textColor = NSColor.grayColor;
    _lblCadesSub.textColor = NSColor.grayColor;
    _lblPades.textColor = NSColor.grayColor;
    _lblPadesSub.textColor = NSColor.grayColor;
    _pictureCades.image = [NSImage imageNamed:@"p7m_gray"];
    _picturePades.image = [NSImage imageNamed:@"pdf_gray"];
    _cbFirmaGrafica.enabled = NO;
    _cbFirmaGrafica.state = NSOffState;
    NSColor *color = [NSColor grayColor];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_cbFirmaGrafica attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_cbFirmaGrafica setAttributedTitle:colorTitle];
    operation = NO_OP;
    NSString *filePathNoSpaces = [filePath stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* fileType = [[NSURL URLWithString:filePathNoSpaces] pathExtension];

    if ([fileType isEqualTo:@"pdf"]) {
        [_cbFirmaGrafica setEnabled:YES];
    } else {
        [_cbFirmaGrafica setEnabled:NO];
    }

    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:SELECT_FIRMA_OP];
    //_filePathSignOp.stringValue = [filePath stringByReplacingOccurrencesOfString:@"/" withString:@" ▶︎ "];
}

- (IBAction)btnVerificaOp:(id)sender {
    [logger info:@"btnVerificaOp: - Inizia funzione"];
    [logger debug:@"Selected Verifica Operation"];
    filePath = _lblPathOp.stringValue;
    _lblVerificaPath.stringValue = filePath;
    [self verificaConCie:sender inputFilePath:filePath];
}

- (IBAction)btnAnnullaOp:(id)sender {
    [logger info:@"btnAnnullaOp: - Inizia funzione"];
    _btnProseguiFirmaOp.enabled = NO;
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
    _btnProseguiFirmaOp.enabled = YES;
    NSColor *color = [NSColor grayColor];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_cbFirmaGrafica attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_cbFirmaGrafica setAttributedTitle:colorTitle];
    _pictureCades.image = [NSImage imageNamed:@"p7m"];
    _picturePades.image = [NSImage imageNamed:@"pdf_gray"];
    operation = FIRMA_CADES;
    _cbFirmaGrafica.state = NSOffState;
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
        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_cbFirmaGrafica attributedTitle]];
        NSRange titleRange = NSMakeRange(0, [colorTitle length]);
        [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
        [_cbFirmaGrafica setAttributedTitle:colorTitle];
        _btnProseguiFirmaOp.enabled = YES;
        _pictureCades.image = [NSImage imageNamed:@"p7m_gray"];
        _picturePades.image = [NSImage imageNamed:@"pdf"];
        operation = FIRMA_PADES;
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

- (IBAction)btnProseguiFirmaOp:(id)sender {
    [logger info:@"btnProseguiFirmaOp: - Inizia funzione"];

    for (NSView * aSubview in [[self prevImageView] subviews]) {
        [aSubview removeFromSuperview];
    }

    ChangeView *cG = [ChangeView getInstance];

    if (operation == FIRMA_PADES && (_cbFirmaGrafica.state == NSOnState)) {
        [logger debug:@"Firma pades con firma grafica"];
        Cie* selectedCie = [self.carouselView getSelectedCard];
        NSString* signImgPath = [self getSignImagePath:[selectedCie getSerialNumber]];
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if (![fileManager fileExistsAtPath:signImgPath]) {
            [self drawText:[selectedCie getName].capitalizedString pathToFile:signImgPath];
        }

        pdfPreview = [[PdfPreview alloc] initWithPrImageView:[self prevImageView] pdfPath:filePath signImagePath:signImgPath];
        _lblPathFirmaPrev.stringValue = filePath ;
        [cG showSubView:FIRMA_PDF_PREVIEW];
    } else {
        [logger debug:@"Firma senza grafica"];
        _lblPathFirmaPin.stringValue = filePath;
        [cG showSubView:FIRMA_PIN_PAGE];
    }
}

- (IBAction)btnAnnullaFirmaOp:(id)sender {
    [logger info:@"btnAnnullaFirmaOp: - Inizia funzione"];
    _lblCades.textColor = NSColor.grayColor;
    _lblCadesSub.textColor = NSColor.grayColor;
    _lblPades.textColor = NSColor.grayColor;
    _lblPadesSub.textColor = NSColor.grayColor;
    _btnProseguiFirmaOp.enabled = NO;
    _cbFirmaGrafica.state = NSOffState;
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
    _lblPathFirmaPin.stringValue = filePath;
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:FIRMA_PIN_PAGE];
}
- (IBAction)annullaFirmaClick:(id)sender {
    [logger info:@"annullaFirmaClick: - Inizia funzione"];
    _lblInsertPin.hidden = NO;
    _cvInsertPin.hidden = NO;
    _btnAnnulla.hidden = NO;
    _btnConcludiFirma.hidden = YES;
    _progressFirma.hidden = YES;
    _lblProgressFirma.hidden = YES;

    for (int i = 9; i < 13; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        txtField.stringValue = @"";
    }

    ChangeView *cG = [ChangeView getInstance];

    if (_cbFirmaGrafica.state == NSOnState) {
        [cG showSubView:FIRMA_PDF_PREVIEW];
    } else {
        [cG showSubView:SELECT_FIRMA_OP];
    }
}

- (IBAction)firmaClick:(id)sender {
    [logger info:@"firmaClick: - Inizia funzione"];
    //_btnFirmaElettronica.enabled = NO;
    NSString* pin = @"";

    for (int i = 9; i < 13; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        pin = [pin stringByAppendingString:txtField.stringValue];
    }

    if (pin.length != 4) {
        [self showMessage:@"Inserire le ultime 4 cifre del PIN" withTitle:@"PIN non corretto" exitAfter:false];
        [self showFirmaPinView];
        return;
    }

    unichar c = [pin characterAtIndex:0];
    int i = 1;

    for (i = 1; i < pin.length && (c >= '0' && c <= '9'); i++) {
        c = [pin characterAtIndex:i];
    }

    if (i < pin.length || !(c >= '0' && c <= '9')) {
        [self showMessage:@"Il PIN deve essere composto da 4 numeri" withTitle:@"PIN non corretto" exitAfter:false];
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

    if (operation == FIRMA_PADES) {
        [panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"pdf", nil]];
        NSString *saveFileName = [NSString stringWithFormat:@"%@%@", [fileName stringByDeletingPathExtension], @"-signed"];
        [panel setNameFieldStringValue:saveFileName];
        [panel beginWithCompletionHandler: ^ (NSInteger result) {
                  if (result == NSModalResponseOK) {
                      _lblInsertPin.hidden = YES;
                      _cvInsertPin.hidden = YES;
                      _btnConcludiFirma.hidden = YES;
                      _btnFirma.enabled = NO;
                      _btnAnnullaFirma.enabled = NO;
                      _progressFirma.hidden = NO;
                      _lblProgressFirma.hidden = NO;
                NSString *outPath = [[panel URL] path];

                if (_cbFirmaGrafica.state == NSOnState) {
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
                      _lblInsertPin.hidden = YES;
                      _cvInsertPin.hidden = YES;
                      _btnConcludiFirma.hidden = YES;
                      _btnFirma.enabled = NO;
                      _btnAnnullaFirma.enabled = NO;
                      _progressFirma.hidden = NO;
                      _lblProgressFirma.hidden = NO;
                NSString *outPath = [[panel URL] path];
                [self firmaConCie:sender inputFilePath:filePath outFilePath:outPath signImagePath:NULL pin:pin x:0.0 y:0.0 w:0.0 h:0.0 fileType:@"p7m"];
            }
        }];
    }
}

- (void)firmaConCie:(NSControl*)sender inputFilePath:(NSString*)inPath outFilePath:(NSString*)outPath  signImagePath:(NSString*)signImagePath pin:(NSString*)pin x:(float)x y:(float)y w:(float)w h:(float)h fileType:(NSString*)fileType {
    [logger info:@"firmaConCie:inputFilePath:outFilePath:signImagePath:pin:x:y:w:h:fileType: - Inizia funzione"];
    int pageNumber = [pdfPreview getSelectedPage];
    //NSString* fileType = @"pdf";
    [sender setEnabled:NO];
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {

        firmaConCIEfn pfnFirmaConCie = (firmaConCIEfn)dlsym(hModule, "firmaConCIE");

        if (!pfnFirmaConCie) {
            dlclose(hModule);
            [self showMessage:@"Funzione firmaConCie non trovata nel middleware" withTitle:@"Errore inaspettato" exitAfter:NO];
            return;
        }

        NSString *pan = [[self.carouselView getSelectedCard] getPan];

        long ret = pfnFirmaConCie([inPath UTF8String], [fileType UTF8String], [pin UTF8String], [pan UTF8String], pageNumber, x, y, w, h, [signImagePath UTF8String], [outPath UTF8String], &progressFirmaCallback, &completedFirmaCallback);

        dispatch_async(dispatch_get_main_queue(), ^{

            [((NSControl*)sender) setEnabled:YES];

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

- (void)showFirmaPinView {
    [logger info:@"showFirmaPinView - Inizia funzione"];

    for (int i = 9; i < 13; i++) {
        NSTextField* txtField = [self.view viewWithTag:i];
        txtField.stringValue = @"";
    }

    _lblInsertPin.hidden = NO;
    _cvInsertPin.hidden = NO;
    _btnAnnulla.hidden = NO;
    _btnFirma.enabled = YES;
    _btnAnnullaFirma.enabled = YES;
    _progressFirma.hidden = YES;
    _lblProgressFirma.stringValue = @"Firma in corso...";
    _lblProgressFirma.hidden = YES;
    _btnConcludiFirma.hidden = YES;
    imgFirmaOkPointer.hidden = YES;
}

- (IBAction)concludiClick:(id)sender {
    [logger info:@"concludiClick: - Inizia funzione"];
    _lblInsertPin.hidden = NO;
    _cvInsertPin.hidden = NO;
    _btnAnnullaFirma.hidden = NO;
    _btnFirma.hidden = NO;
    _btnFirma.enabled = YES;
    _btnAnnullaFirma.enabled = YES;
    _progressFirma.hidden = YES;
    _lblProgressFirma.stringValue = @"Firma in corso...";
    _lblProgressFirma.hidden = YES;
    progressIndicatorPointerFirma.doubleValue = 0;
    _btnConcludiFirma.hidden = YES;
    imgFirmaOkPointer.hidden = YES;

    for (int i = 9; i < 13; i++) {
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
        _lblFirmaPersonalizata.stringValue = @"Una tua firma grafica personalizzata è già stata caricata. Vuoi aggiornarla?";
        _btnCreaFirma.enabled = YES;
    } else {
        _lblFirmaPersonalizata.stringValue = @"Abbiamo creato per te una firma grafica, ma se preferisci puoi personalizzarla. Questo passaggio non è indispensabile, ma ti consentirà di dare un tocco personale ai documenti firmati.";
        _btnCreaFirma.enabled = NO;
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
    _lblFirmaPersonalizata.stringValue = @"Abbiamo creato per te una firma grafica, ma se preferisci puoi personalizzarla. Questo passaggio non è indispensabile, ma ti consentirà di dare un tocco personale ai documenti firmati.";
    [_btnPersonalizza setTitle:@"Personalizza"];
    [_lblPersonalizzata setHidden:YES];
    [_lblFirmaPersonalizzataSub setHidden:NO];
    _signImageView.image = [[NSImage alloc] initWithContentsOfFile:signImgPath];
    [selectedCie customSignSet:false];
    Cie* cie = [[cieList getDictionary] valueForKey:[selectedCie getPan]];
    [cie customSignSet:false];
    [NSUserDefaults.standardUserDefaults setObject:[cieList getData] forKey:@"cieDictionary"];
    [NSUserDefaults.standardUserDefaults synchronize];
    _btnCreaFirma.enabled = NO;
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
                _lblFirmaPersonalizata.stringValue = @"Una tua firma grafica personalizzata è già stata caricata. Vuoi aggiornarla?";
                [_btnPersonalizza setTitle:@"Aggiorna"];
                [_lblPersonalizzata setHidden:NO];
                [_lblFirmaPersonalizzataSub setHidden:YES];
                _btnCreaFirma.enabled = YES;
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
                    [self.tbVerificaInfo reloadData];
                    self->_lblSottoscrittori.stringValue = [NSString stringWithFormat:@"Numero di sottoscrittori: %d", ret];
                    ChangeView *cG = [ChangeView getInstance];

                    if ([[filePath pathExtension] isEqualToString:@"p7m"]) {
                        _btnEstrai.enabled = YES;
                    } else {
                        _btnEstrai.enabled = NO;
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
            [logger debug:@"Credenziali salvate!!!"];
        }

        syncUserDefaults = YES;
    }

    if (([_txtPorta.stringValue isEqual:@""] && ![_txtProxyAddr.stringValue isEqual:@""]) || (![_txtPorta.stringValue isEqual:@""] && [_txtProxyAddr.stringValue isEqual:@""])) {
        [logger debug:@"Indirizzo o porta del proxy mancante"];
        [self showMessage:@"Indirizzo o porta del proxy mancante" withTitle:@"Informazioni proxy mancanti" exitAfter:false];
        closeEditing = NO;
    } else if ([_txtPorta.stringValue rangeOfCharacterFromSet:nonDigits].location != NSNotFound) {
        [logger debug:@"Il campo porta deve contenere solo numeri"];
        [self showMessage:@"Il campo porta deve contenere solo numeri" withTitle:@"Porta del proxy errata" exitAfter:false];
        closeEditing = NO;
    } else {
        [NSUserDefaults.standardUserDefaults setObject:_txtProxyAddr.stringValue forKey:@"proxyUrl"];

        if ([_txtPorta.stringValue isEqual:@""]) {
            [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"proxyPort"];
        } else {
            [NSUserDefaults.standardUserDefaults setObject:_txtPorta.stringValue forKey:@"proxyPort"];
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

    if (syncUserDefaults == YES) {
        [NSUserDefaults.standardUserDefaults synchronize];
    }

    if (closeEditing == YES) {
        [self disableSettingsFormEditing];
    }
}

- (void)setSettingsFormEditingState:(BOOL)value {
    [logger info:@"setSettingsFormEditingState: - Inizia funzione"];
    [_txtPorta setEnabled:value];
    [_txtProxyAddr setEnabled:value];
    [_txtPassword setEnabled:value];
    [_txtUsername setEnabled:value];
    [_cbMostraPsw setEnabled:value];
    _cbMostraPsw.state = NSOffState;
    [_btnSalvaProxy setEnabled:value];
    [_btnModificaProxy setEnabled:!value];
    [_rbLoggingAppNone setEnabled:value];
    [_rbLoggingAppError setEnabled:value];
    [_rbLoggingAppInfo setEnabled:value];
    [_rbLoggingAppDebug setEnabled:value];
    [_rbLoggingLibNone setEnabled:value];
    [_rbLoggingLibError setEnabled:value];
    [_rbLoggingLibInfo setEnabled:value];
    [_rbLoggingLibDebug setEnabled:value];
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

    if (_cbMostraPsw.state == NSControlStateValueOn && ![_txtPassword.stringValue isEqual:@""]) {
        _plainPassword.stringValue = _txtPassword.stringValue;
        [_txtPassword setHidden:TRUE];
        [_plainPassword setHidden:FALSE];
    } else {
        [_txtPassword setHidden:FALSE];
        [_plainPassword setHidden:TRUE];
    }
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
    self->_lblSottoscrittori.stringValue =  @"Numero di sottoscrittori";
    ChangeView *cG = [ChangeView getInstance];
    [cG showSubView:SELECT_FILE_PAGE];
}

#pragma mark - CarouselViewDelegate

- (void)shouldAddCard {
    [logger info:@"shouldAddCard - Inizia funzione"];
    /*
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
     */
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
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *configFilePath = [NSString stringWithFormat:@"%@/Library/Containers/it.ipzs.CIE-ID.CIEToken/Data/.CIEPKI/config",
                                         NSHomeDirectory()];
    [logger debug:[NSString stringWithFormat:@"LoadLogConfigFromFile configconfigFilePath:%@", configFilePath]];
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/readingFiles.html
    // stringWithContentsOfFile:encoding:error
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:configFilePath] == YES) {
        [logger debug:@"Leggo file configurazione log"];
        NSData *fileData = [fileManager contentsAtPath:configFilePath];
        NSString *fileContent = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        NSArray *configFileLines = [fileContent componentsSeparatedByString:@"\n"];

        for (NSString * line in configFileLines) {
            if ([line containsString:LogConfigPrefixApp] == YES) {
                logConfigLineAppPresent = YES;
                [logger debug:[NSString stringWithFormat:@"Configurazione log applicazione: %@", line]];
                NSString *value = [line componentsSeparatedByString:@"="][1];
                NSInteger integerValue = [value integerValue];

                if ((integerValue >= AppLogLevel_NONE && integerValue <= AppLogLevel_ERROR)
                        && ([value rangeOfCharacterFromSet:nonDigits].location == NSNotFound)) {
                    levels.logLevelApp = (AppLogLevel)integerValue;
                } else {
                    [logger debug:[NSString stringWithFormat:@"valore '%d' del livello di log applicazione fuori intervallo - uso default", integerValue]];
                    writeLogConfigFile = YES;
                }
            } else if ([line containsString:LogConfigPrefixLib] == YES) {
                logConfigLineLibPresent = YES;
                [logger debug:[NSString stringWithFormat:@"Configurazione log libreria: %@", line]];
                NSString *value = [line componentsSeparatedByString:@"="][1];
                NSInteger integerValue = [value integerValue];

                if ((integerValue >= AppLogLevel_NONE && integerValue <= AppLogLevel_ERROR)
                        && ([value rangeOfCharacterFromSet:nonDigits].location == NSNotFound)) {
                    levels.logLevelLib = (AppLogLevel)integerValue;
                } else {
                    [logger debug:[NSString stringWithFormat:@"valore '%d' del livello di log applicazione fuori intervallo - uso default", integerValue]];
                    writeLogConfigFile = YES;
                }
            } else if ([line containsString:@"="] == YES) {
                [logger debug:[NSString stringWithFormat:@"Riga di configurazione log ignorata: length:%@, %@", [line length], line]];
            }
        }

        if (logConfigLineAppPresent == NO || logConfigLineLibPresent == NO) {
            writeLogConfigFile = YES;
        }
    } else {
        [logger debug:@"File configurazione log non trovato, lo creo con valori di default"];
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
    NSFileManager *fileManager;
    NSString *configFilePath;
    NSString *configLines;
    fileManager = [NSFileManager defaultManager];
    configLines = [NSString stringWithFormat:@"LIB_LOG_LEVEL=%ld\nAPP_LOG_LEVEL=%ld\n", levels.logLevelLib, levels.logLevelApp];
    configFilePath = [NSString stringWithFormat:@"%@/Library/Containers/it.ipzs.CIE-ID.CIEToken/Data/.CIEPKI/config", NSHomeDirectory()];

    if ([configLines writeToFile:configFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil] == NO) {
        NSString *message = @"Errore nel salvare il file di configurazione dei log";
        [logger error:message];
        NSLog(message);
    } else {
        [logger debug:@"File di configurazione dei log correttamente salvato"];
    }
}

@end

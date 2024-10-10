//
//  MainViewController.h
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "AppLogger.h"
#import "CarouselView.h"

NS_ASSUME_NONNULL_BEGIN


@interface MainViewController : NSViewController <NSWindowDelegate>

@property IBOutlet NSView* homeFirstPageView;
@property IBOutlet NSView* homeSecondPageView;
@property IBOutlet NSView* homeThirdPageView;
@property IBOutlet NSView* homeFourthPageView;
@property IBOutlet NSView* changePINPageView;
@property IBOutlet NSView* changePINOKPageView;
@property IBOutlet NSView* unlockPageView;
@property IBOutlet NSView* unlockOKPageView;
@property IBOutlet NSView* changePINPageView;
@property IBOutlet NSView* changePINOKPageView;
@property IBOutlet NSView* unlockPageView;
@property IBOutlet NSView* unlockOKPageView;
@property IBOutlet NSView* helpPageView;
@property IBOutlet NSView* infoPageView;
@property IBOutlet NSView* selectFilePageView;
@property IBOutlet NSView* selectOperationView;
@property IBOutlet NSView* signOperationView;
@property IBOutlet NSView* signPreView;
@property IBOutlet NSView* signPINView;
@property IBOutlet NSView* customizeGraphicSignatureView;
@property IBOutlet NSView* verifyView;
@property IBOutlet NSView* settingsView;
@property IBOutlet NSView* signOperationView;
@property IBOutlet NSView* signPreView;
@property IBOutlet NSView* signPINView;
@property IBOutlet NSView* customizeGraphicSignatureView;
@property IBOutlet NSView* verifyView;
@property IBOutlet NSView* settingsView;

@property IBOutlet NSTextField* labelHelp;
@property IBOutlet WKWebView* helpWebView;
@property IBOutlet WKWebView* infoWebView;

@property (weak) IBOutlet NSButton* btnPair;
@property (weak) IBOutlet NSButton* btnAbort;
@property (weak) IBOutlet NSButton* btnPair;
@property (weak) IBOutlet NSButton* btnAbort;

@property IBOutlet NSImageView* helpImageView;
@property IBOutlet NSImageView* unlockImageView;
@property IBOutlet NSImageView* helpImageView;
@property IBOutlet NSImageView* unlockImageView;

@property IBOutlet NSTextField* labelProgress;
@property IBOutlet NSProgressIndicator* progressIndicator;

@property IBOutlet NSTextField* labelProgressChangePIN;
@property IBOutlet NSProgressIndicator* progressIndicatorChangePIN;
@property IBOutlet NSTextField* labelProgressChangePIN;
@property IBOutlet NSProgressIndicator* progressIndicatorChangePIN;

@property IBOutlet NSTextField* labelProgressUnlockPIN;
@property IBOutlet NSProgressIndicator* progressIndicatorUnlockPIN;
@property IBOutlet NSTextField* labelProgressUnlockPIN;
@property IBOutlet NSProgressIndicator* progressIndicatorUnlockPIN;

@property IBOutlet NSTextField* textFieldPIN;
@property IBOutlet NSTextField* textFieldNewPIN;
@property IBOutlet NSTextField* textFieldConfirmPIN;

@property IBOutlet NSTextField* textFieldPUK;
@property IBOutlet NSTextField* textFieldNewUnlockPIN;
@property IBOutlet NSTextField* textFieldConfirmUnlockPIN;
@property IBOutlet NSTextField* textFieldNewUnlockPIN;
@property IBOutlet NSTextField* textFieldConfirmUnlockPIN;

@property IBOutlet NSView* homeButtonView;
@property IBOutlet NSView* changePINButtonView;
@property IBOutlet NSView* unlockPINButtonView;
@property IBOutlet NSView* changePINButtonView;
@property IBOutlet NSView* unlockPINButtonView;
@property IBOutlet NSView* tutorialButtonView;
@property IBOutlet NSView* helpButtonView;
@property IBOutlet NSView* infoButtonView;
@property IBOutlet NSView* digitalSignatureButtonView;
@property IBOutlet NSView* verifySignatureButtonView;
@property IBOutlet NSView* settingsButtonView;
@property IBOutlet NSView* digitalSignatureButtonView;
@property IBOutlet NSView* verifySignatureButtonView;
@property IBOutlet NSView* settingsButtonView;

@property (weak) IBOutlet CarouselView *carouselView;

@property (weak) IBOutlet NSButton *rbLoggingAppNone;
@property (weak) IBOutlet NSButton *rbLoggingAppError;
@property (weak) IBOutlet NSButton *rbLoggingAppInfo;
@property (weak) IBOutlet NSButton *rbLoggingAppDebug;
@property (weak) IBOutlet NSButton *rbLoggingLibNone;
@property (weak) IBOutlet NSButton *rbLoggingLibError;
@property (weak) IBOutlet NSButton *rbLoggingLibInfo;
@property (weak) IBOutlet NSButton *rbLoggingLibDebug;
@property (weak) IBOutlet NSButton *cbShouldRunInBackground;
@property (weak) IBOutlet NSButton *cbShowTutorial;
@property (weak) IBOutlet NSButton *collectLogButton;
@property (weak) IBOutlet NSButton *deleteLogButton;

@property AppLogLevel logLevelApp;
@property AppLogLevel logLevelLib;

- (void)LoadLogConfigFromFile;
- (void)setLogConfigToLevels:(struct logLevels)levels;
- (void)saveCurrentLogConfigToFile;
- (void)saveLogConfigToFileWithLevels:(struct logLevels)levels;
- (void)chooseSignOrVerifyFileOperation:(NSString*)_filePath;
- (void)signMWCall:(NSControl*)sender inputFilePath:(NSString*)inPath outFilePath:(NSString*)outPath signImagePath:(NSString*)signImagePath pin:(NSString*)pin x:(float)x y:(float)y w:(float)w h:(float)h fileType:(NSString*)fileType;

@end

NS_ASSUME_NONNULL_END

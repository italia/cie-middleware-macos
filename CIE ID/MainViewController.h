//
//  MainViewController.h
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "CarouselView.h"

NS_ASSUME_NONNULL_BEGIN


@interface MainViewController : NSViewController <NSWindowDelegate>

@property IBOutlet NSView* homeFirstPageView;
@property IBOutlet NSView* homeSecondPageView;
@property IBOutlet NSView* homeThirdPageView;
@property IBOutlet NSView* homeFourthPageView;
@property IBOutlet NSView* cambioPINPageView;
@property IBOutlet NSView* cambioPINOKPageView;
@property IBOutlet NSView* sbloccoPageView;
@property IBOutlet NSView* sbloccoOKPageView;
@property IBOutlet NSView* helpPageView;
@property IBOutlet NSView* infoPageView;
@property IBOutlet NSView* selectFilePageView;
@property IBOutlet NSView* selectOperationView;
@property IBOutlet NSView* firmaOperationView;
@property IBOutlet NSView* firmaPrevView;
@property IBOutlet NSView* firmaPinView;
@property IBOutlet NSView* personalizzaFirmaView;
@property IBOutlet NSView* verificaView;
@property IBOutlet NSView *impostazioniView;

@property IBOutlet NSTextField* labelHelp;
@property IBOutlet WKWebView* helpWebView;
@property IBOutlet WKWebView* infoWebView;

@property (weak) IBOutlet NSButton *btnAbbina;
@property (weak) IBOutlet NSButton *btnAnnulla;

@property IBOutlet NSImageView* assistenzaImageView;
@property IBOutlet NSImageView* sbloccoImageView;

@property IBOutlet NSTextField* labelProgress;
@property IBOutlet NSProgressIndicator* progressIndicator;

@property IBOutlet NSTextField* labelProgressCambioPIN;
@property IBOutlet NSProgressIndicator* progressIndicatorCambioPIN;

@property IBOutlet NSTextField* labelProgressSbloccoPIN;
@property IBOutlet NSProgressIndicator* progressIndicatorSbloccoPIN;

@property IBOutlet NSTextField* textFieldPIN;
@property IBOutlet NSTextField* textFieldNewPIN;
@property IBOutlet NSTextField* textFieldConfirmPIN;

@property IBOutlet NSTextField* textFieldPUK;
@property IBOutlet NSTextField* textFieldNewPINSblocco;
@property IBOutlet NSTextField* textFieldConfirmPINSbloco;

@property IBOutlet NSView* homeButtonView;
@property IBOutlet NSView* cambioPINButtonView;
@property IBOutlet NSView* sbloccoPINButtonView;
@property IBOutlet NSView* tutorialButtonView;
@property IBOutlet NSView* helpButtonView;
@property IBOutlet NSView* infoButtonView;
@property IBOutlet NSView* firmaElettronicaButtonView;
@property IBOutlet NSView* impostazioniButtonView;


@property (weak) IBOutlet CarouselView *carouselView;

@end

NS_ASSUME_NONNULL_END

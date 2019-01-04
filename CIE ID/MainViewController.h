//
//  MainViewController.h
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

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
@property IBOutlet NSTextField* labelHelp;
@property IBOutlet WKWebView* helpWebView;
@property IBOutlet WKWebView* infoWebView;

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

@property IBOutlet NSTextField* labelSerialNumber;
@property IBOutlet NSTextField* labelCardHolder;

@property IBOutlet NSView* homeButtonView;
@property IBOutlet NSView* cambioPINButtonView;
@property IBOutlet NSView* sbloccoPINButtonView;
@property IBOutlet NSView* tutorialButtonView;
@property IBOutlet NSView* helpButtonView;
@property IBOutlet NSView* infoButtonView;


@end

NS_ASSUME_NONNULL_END

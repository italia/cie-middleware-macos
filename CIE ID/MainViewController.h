//
//  MainViewController.h
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainViewController : NSViewController

@property IBOutlet NSView* homeFirstPageView;
@property IBOutlet NSView* homeSecondPageView;
@property IBOutlet NSView* homeThirdPageView;
@property IBOutlet NSView* homeFourthPageView;
@property IBOutlet NSView* cambioPINPageView;
@property IBOutlet NSView* cambioPINOKPageView;
@property IBOutlet NSTextField* labelProgress;
@property IBOutlet NSProgressIndicator* progressIndicator;

@property IBOutlet NSTextField* textFieldPIN;
@property IBOutlet NSTextField* textFieldNewPIN;
@property IBOutlet NSTextField* textFieldConfirmPIN;

@property IBOutlet NSTextField* labelSerialNumber;
@property IBOutlet NSTextField* labelCardHolder;

@end

NS_ASSUME_NONNULL_END

//
//  IntroViewController.h
//  CIE ID
//
//  Created by ugo chirico on 14/12/2018.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface IntroViewController : NSViewController

@property IBOutlet NSView* firstPageView;
@property IBOutlet NSView* secondPageView;
@property IBOutlet NSButton* checkDontShowAnymore;

@end

NS_ASSUME_NONNULL_END

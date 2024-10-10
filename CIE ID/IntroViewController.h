//
//  IntroViewController.h
//  CIE ID
//
//  Created by ugo chirico on 14/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface IntroViewController : NSViewController <NSWindowDelegate>

@property IBOutlet NSView* firstPageView;
@property IBOutlet NSView* secondPageView;
@property IBOutlet NSButton* checkDontShowAnymore;

@end

NS_ASSUME_NONNULL_END

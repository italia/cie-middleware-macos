//
//  MessageViewController.h
//  CIEIDBar
//
//  Created by ugo chirico on 05/01/2019.
//  Copyright © 2019 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CIEPopoverProtocol

- (void) showPopover: (NSObject*) sender;
- (void) closePopover: (NSObject*) sender;

@end

@interface MessageViewController : NSViewController

@property (weak) IBOutlet NSTextField *messageLabel;
@property (weak) IBOutlet NSButton *cieidButton;
@property (weak) IBOutlet NSButton *closeButton;

@property NSPopover* popover;

+ (MessageViewController*) freshController;

@end

NS_ASSUME_NONNULL_END

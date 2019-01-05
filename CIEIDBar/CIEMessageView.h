//
//  CIEMessageView.h
//  CIEIDBar
//
//  Created by ugo chirico on 05/01/2019.
//  Copyright © 2019 IPZS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CIEMessageView : NSView
@property (weak) IBOutlet NSTextFieldCell *messageLabel;

@end

NS_ASSUME_NONNULL_END

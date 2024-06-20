//
//  MessageViewController.m
//
//  Copyright © 2024 IPZS. All rights reserved.
//

#import "AppDelegate.h"
#import "MessageViewController.h"

@interface MessageViewController ()

@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

// MARK: Storyboard instantiation
+ (MessageViewController*) freshController {
    MessageViewController* vc = (MessageViewController*)[[MessageViewController alloc] initWithNibName:@"MessageViewController" bundle:nil];
    return vc;
}

- (IBAction)openCIEID:(NSButton*)sender {
    
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp unhide: NSApplication.sharedApplication];
    
    if(sender && sender.tag == 100)
    {
        NSString* url = [NSUserDefaults.standardUserDefaults objectForKey:@"url"];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: url]];
    }
    
    [_popover performClose:sender];
}

- (IBAction)close:(id)sender {
    [_popover performClose:sender];
}

@end

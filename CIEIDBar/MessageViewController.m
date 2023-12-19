//
//  MessageViewController.m
//  CIEIDBar
//
//  Created by ugo chirico on 05/01/2019. http://www.ugochirico.com
//  Copyright © 2019 IPZS. All rights reserved.
//


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
    
    if(sender && sender.tag == 100)
    {
        NSString* url = [NSUserDefaults.standardUserDefaults objectForKey:@"url"];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: url]];
    }
    else
    {
        NSTask *task = [[NSTask alloc] init];
        
        task.launchPath = @"/usr/bin/open";
        task.arguments = @[@"-n", @"/Applications/CIE ID.app"];//, [NSString stringWithUTF8String:szPAN]];
        
        [task launch];
    }
    
    [_popover performClose:sender];
}

- (IBAction)close:(id)sender {
    [_popover performClose:sender];
}

@end

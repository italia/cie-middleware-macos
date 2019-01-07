//
//  MessageViewController.m
//  CIEIDBar
//
//  Created by ugo chirico on 05/01/2019.
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
- (IBAction)openCIEID:(id)sender {
    NSTask *task = [[NSTask alloc] init];
    
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-n", @"/Applications/CIE ID.app"];//, [NSString stringWithUTF8String:szPAN]];
    
    [task launch];
}

- (IBAction)close:(id)sender {
    [_popover performClose:sender];
}

 
@end

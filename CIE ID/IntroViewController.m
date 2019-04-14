//
//  IntroViewController.m
//  CIE ID
//
//  Created by ugo chirico on 14/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "IntroViewController.h"

@interface IntroViewController ()

@end

@implementation IntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    //NSUserDefaults.standardUserDefaults
    
    self.preferredContentSize = self.view.frame.size;
    
    self.view.window.delegate = self;
}

- (BOOL) windowShouldClose: (NSObject*) sender
{
    [NSApplication.sharedApplication terminate:self];
    
    return YES;
}

- (IBAction)nextPage:(id)sender
{
    _firstPageView.hidden = YES;
    _secondPageView.hidden = NO;
}

- (IBAction)start:(id)sender
{
    if(_checkDontShowAnymore.state == NSOnState)
    {
        [NSUserDefaults.standardUserDefaults setObject:@"OK" forKey:@"dontShowIntro"];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    
    [self dismissViewController:self];
}

@end

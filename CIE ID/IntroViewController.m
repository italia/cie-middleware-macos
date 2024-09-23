//
//  IntroViewController.m
//  CIE ID
//
//  Created by ugo chirico on 14/12/2018. http://www.ugochirico.com
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "IntroViewController.h"
#import "PreferencesManager.h"


@interface IntroViewController ()
@property PreferencesManager *prefManager;
@end

@implementation IntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    //NSUserDefaults.standardUserDefaults
    _prefManager = PreferencesManager.sharedInstance;
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
        [_prefManager setConfigKeyValue:@"SHOW_TUTORIAL": @"NO"];
    }
    
    [self dismissViewController:self];
}

@end

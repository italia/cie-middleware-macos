//
//  IntroViewController.m
//  CIE ID
//
//  Created by ugo chirico on 14/12/2018.
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
}

- (IBAction)nextPage:(id)sender
{
    _firstPageView.hidden = YES;
    _secondPageView.hidden = NO;
}

- (IBAction)start:(id)sender
{
    [self dismissViewController:self];
}

@end

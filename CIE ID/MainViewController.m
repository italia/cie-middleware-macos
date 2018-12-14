//
//  MainViewController.m
//  CIE ID
//
//  Created by ugo chirico on 11/12/2018.
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tabView.tabViewType = NSNoTabsNoBorder;
}

- (void) viewWillAppear
{
    [super viewWillAppear];
    
    if(![NSUserDefaults.standardUserDefaults objectForKey:@"firstTime"])
    {
        NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        NSViewController* viewController = [storyboard instantiateControllerWithIdentifier:@"IntroViewController"];
        
        [self presentViewControllerAsModalWindow:viewController];
    }
}

@end

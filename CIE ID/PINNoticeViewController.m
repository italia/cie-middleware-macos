//
//  PINNoticeViewController.m
//  CIE ID
//
//  Created by ugo chirico on 01/07/2019.
//  Copyright © 2019 IPZS. All rights reserved.
//

#import "PINNoticeViewController.h"

@interface PINNoticeViewController ()

@property (weak) IBOutlet NSButton *btnOK;

@property NSTimer* timer;
@property int countDown;
@end

@implementation PINNoticeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _countDown = 6;
    
    [self performSelectorOnMainThread:@selector(onTimerTick:) withObject:nil waitUntilDone:false];
}

- (void)onTimerTick:(NSTimer *)timer {
    _countDown--;
    
    if(_countDown < 0)
    {
        [self onOk:nil];
        return;
    }
    
    [self.btnOK setTitle:[NSString stringWithFormat:@" OK (%d) " , _countDown]];
    
    dispatch_async(dispatch_get_global_queue(0,0),  ^{
        [NSThread sleepForTimeInterval:1.0f];
        [self performSelectorOnMainThread:@selector(onTimerTick:) withObject:nil waitUntilDone:false];
    });
}

- (IBAction)onOk:(id)sender {
    [self dismissViewController:self];
}

@end

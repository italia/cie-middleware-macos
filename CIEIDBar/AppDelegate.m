//
//  AppDelegate.m
//  CIEIDBar
//
//  Created by ugo chirico on 05/01/2019.
//  Copyright © 2019 IPZS. All rights reserved.
//

#import "AppDelegate.h"
#import "CIEMessageView.h"
#import "MessageViewController.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *statusMenu;
@property NSStatusItem* statusItem;
@property NSPopover* popover;

@property (weak) IBOutlet CIEMessageView *messageView;

@end

@implementation AppDelegate

- (IBAction)menuItemQuit:(id)sender {
    [NSApplication.sharedApplication terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
    
    NSImage* icon = [NSImage imageNamed:@"icona_minimize_01"];
    //icon.template = true; // best for dark mode
    _statusItem.image = icon;
    _statusItem.menu = _statusMenu;
    
//    NSButton* button = _statusItem.button;
//    button.image = icon;
//    button.action = @selector(togglePopover:);
    
    _popover = [[NSPopover alloc] init];
    
    _popover.contentViewController = MessageViewController.freshController;
    
}

- (void) togglePopover: (NSObject*) sender {
    if (_popover.isShown) {
        [self closePopover:sender];
    } else {
        [self showPopover:sender];
    }
}

- (void) showPopover: (NSObject*) sender {
    NSButton* button = _statusItem.button;
    
    [_popover showRelativeToRect:button.frame ofView:button preferredEdge:NSRectEdgeMinY];
}

- (void) closePopover: (NSObject*) sender {
    [_popover performClose: sender];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)showHelp:(id)sender
{
    NSURL * helpFile = [[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"];
    [[NSWorkspace sharedWorkspace] openURL:helpFile];
}


@end

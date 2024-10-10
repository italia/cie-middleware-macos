//
//  AppDelegate.m
//  CIE ID
//
//  Copyright © 2018 IPZS. All rights reserved.
//

#import "AppDelegate.h"
#import "PreferencesManager.h"
#import "MainViewController.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>    //strlen
#include <sys/socket.h>
#include <arpa/inet.h>    //inet_addr
#include <unistd.h>    //write
#include "../cie-pkcs11/Crypto/CryptoUtil.h"
#include "../cie-pkcs11/Util/UUCProperties.h"

USING_NAMESPACE(CryptoPP);
#import "PreferencesManager.h"
#import "MainViewController.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>    //strlen
#include <sys/socket.h>
#include <arpa/inet.h>    //inet_addr
#include <unistd.h>    //write
#include "../cie-pkcs11/Crypto/CryptoUtil.h"
#include "../cie-pkcs11/Util/UUCProperties.h"

USING_NAMESPACE(CryptoPP);

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *statusMenu;
@property NSStatusItem* statusItem;
@property NSPopover* popover;
@property NSTextField* messageLabel;
@property PreferencesManager* prefManager;
@property (strong, nonatomic) MainViewController *mainViewController;
@end

@implementation AppDelegate

bool isRunning = false;
int socket_desc;

#pragma mark Application Delegate Methods

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if ([[_prefManager getConfigKeyValue:@"RUN_IN_BACKGROUND"] isEqual: @"YES"] && _closeAppFromStatusBar == NO)
    {
        [self switchToBackgroundMode];
        return NSTerminateCancel;
    }
    
    return NSTerminateNow;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    if ([[_prefManager getConfigKeyValue:@"RUN_IN_BACKGROUND"] isEqual: @"YES"]) {
        if (([NSApp activationPolicy] == NSApplicationActivationPolicyRegular))
            [NSApp unhide: NSApplication.sharedApplication];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    _prefManager = [[PreferencesManager alloc] init];
    _closeAppFromStatusBar = NO;
    
    _prefManager = [[PreferencesManager alloc] init];
    _closeAppFromStatusBar = NO;
    
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier: NSBundle.mainBundle.bundleIdentifier].count > 1)
    {
        _closeAppFromStatusBar = YES;
        _closeAppFromStatusBar = YES;
        [NSApplication.sharedApplication terminate:self];
    }
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
    
    NSImage* icon = [NSImage imageNamed:@"icona_minimize_01"];
    _statusItem.image = icon;
    _statusItem.menu = self.statusMenu;
    
    NSButton* button = _statusItem.button;
    button.image = icon;
    button.action = @selector(togglePopover:);
    
    _popover = [[NSPopover alloc] init];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startServer];
    });
    
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _popover.contentViewController = vc;
    
    [self copyLibCieInSharedFolder];
}

- (IBAction)openCIEID:(id)sender {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [[NSApplication sharedApplication] unhide:nil];
}

- (IBAction)killCIEID:(id)sender {
    _closeAppFromStatusBar = YES;
    [NSApplication.sharedApplication terminate:self];
}

- (BOOL) copyLibCieInSharedFolder {
    NSString *source, *destination, *libname;
    
    libname = @"/libcie-pkcs11.dylib";
    source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: libname];
    destination = [[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.it.ipzs.SoftwareCIE"] path] stringByAppendingString:@"/Library/Caches"];
    destination = [destination stringByAppendingString: libname];
    
    if ([[NSFileManager defaultManager] isReadableFileAtPath: source]) {
        [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
        return [[NSFileManager defaultManager] copyItemAtPath: source toPath:destination error:nil];
    }
    
    return NO;
}

- (int) startServer
{
    int client_sock, c;
    long read_size;
    struct sockaddr_in server, client;
    char szEncryptedClientMessage[1000];
    memset(szEncryptedClientMessage, 0, 1000);
    
    //Create socket
    socket_desc = socket(AF_INET, SOCK_STREAM, 0);
    if (socket_desc == -1)
    {
        printf("Could not create socket");
        return -1;
    }
    
    puts("Socket created");
    
    //Prepare the sockaddr_in structure
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = INADDR_ANY;
    server.sin_port = htons( 88888 );
    
    //Bind
    if( bind(socket_desc,(struct sockaddr *)&server , sizeof(server)) < 0)
    {
        //print the error message
        perror("bind failed. Error");
        return 1;
    }
    
    puts("bind done");
    
    //Listen
    listen(socket_desc , 3);
    
    //Accept and incoming connection
    puts("Waiting for incoming connections...");
    c = sizeof(struct sockaddr_in);
    
    while((client_sock = accept(socket_desc, (struct sockaddr *)&client, (socklen_t*)&c)))
    {
        puts("Connection accepted");
        
        //Receive a message from client
        while( (read_size = recv(client_sock , szEncryptedClientMessage , 1000 , 0)) > 0 )
        {
            int messagelen;
            int headerlen = sizeof(messagelen);
            
            messagelen = *((int*)szEncryptedClientMessage);
            
            std::string sCipherText(szEncryptedClientMessage + headerlen, messagelen);
            std::string sMessage;
            
            decrypt(sCipherText, sMessage);
            
            NSLog(@"message received: %s", sMessage.c_str());
            
            const char* szClientMessage = sMessage.c_str();
            
            if(strstr(szClientMessage, "pinlocked") == szClientMessage)
            {
                //Send the message back to client
                write(client_sock , szClientMessage , strlen(szClientMessage));
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pinLocked];
                });
            }
            else if(strstr(szClientMessage, "pinwrong") == szClientMessage)
            {
                //Send the message back to client
                write(client_sock , szClientMessage , strlen(szClientMessage));
                
                char* szTok = strtok((char*)szClientMessage, ":");
                szTok = strtok(NULL, ":");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pinWrong: atoi(szTok)];
                });
                
            }
            else if(strstr(szClientMessage, "cardnotregistered") == szClientMessage)
            {
                //Send the message back to client
                write(client_sock , szClientMessage , strlen(szClientMessage));
                
                char* szTok = strtok((char*)szClientMessage, ":");
                szTok = strtok(NULL, ":");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cardNotRegistered:[NSString stringWithUTF8String:szTok]];
                });
            }
            else
            {
                NSLog(@"invalid message received: %s", sMessage.c_str());
            }
        }
        
        if(read_size == 0)
        {
            puts("Client disconnected");
            fflush(stdout);
        }
        else if(read_size == -1)
        {
            perror("recv failed");
        }
    }
    
    return 0;
}

- (void) switchToBackgroundMode
{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
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

- (bool) cieidIsRunning
{
    return [NSRunningApplication runningApplicationsWithBundleIdentifier: @"it.ipzs.SoftwareCIE"].count > 0;
}

- (void) pinLocked
{
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _popover.contentViewController = vc;
    [self showPopover:self];
    
    BOOL processIsRunning = self.cieidIsRunning;
    
    if(processIsRunning)
    {
        vc.messageLabel.stringValue = @"La carta è bloccata. Sbloccarla usando il PUK";
        vc.cieidButton.hidden = YES;
        vc.closeButton.frame = CGRectMake((vc.view.frame.size.width - vc.closeButton.frame.size.width) / 2, vc.closeButton.frame.origin.y, vc.closeButton.frame.size.width, vc.closeButton.frame.size.height);
    }
    else
    {
        vc.messageLabel.stringValue = @"La carta è bloccata. Aprire CIE ID e sbloccarla usando il PUK";
    }
}

- (void) pinWrong: (int) remainingTrials
{
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _popover.contentViewController = vc;
    [self showPopover:self];
    
    vc.messageLabel.stringValue = @"Il PIN digitato è errato";
    
    vc.cieidButton.hidden = YES;
    vc.closeButton.frame = CGRectMake((vc.view.frame.size.width - vc.closeButton.frame.size.width) / 2, vc.closeButton.frame.origin.y, vc.closeButton.frame.size.width, vc.closeButton.frame.size.height);
}

- (void) cardNotRegistered: (NSString*) pan
{
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _popover.contentViewController = vc;
    [self showPopover:self];
    
    BOOL processIsRunning = self.cieidIsRunning;
    
    if(processIsRunning)
    {
        vc.messageLabel.stringValue = @"La carta non è stata abbinata. Abbinare la carta";
        vc.cieidButton.hidden = YES;
        vc.closeButton.frame = CGRectMake((vc.view.frame.size.width - vc.closeButton.frame.size.width) / 2, vc.closeButton.frame.origin.y, vc.closeButton.frame.size.width, vc.closeButton.frame.size.height);
    }
    else
        vc.messageLabel.stringValue = @"La carta non è stata abbinata. Aprire CIE ID per abbinare la carta";
}

- (bool) cieidIsRunning
{
    return [NSRunningApplication runningApplicationsWithBundleIdentifier: @"it.ipzs.SoftwareCIE"].count > 0;
}

- (void) pinLocked
{
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _popover.contentViewController = vc;
    [self showPopover:self];
    
    BOOL processIsRunning = self.cieidIsRunning;
    
    if(processIsRunning)
    {
        vc.messageLabel.stringValue = @"La carta è bloccata. Sbloccarla usando il PUK";
        vc.cieidButton.hidden = YES;
        vc.closeButton.frame = CGRectMake((vc.view.frame.size.width - vc.closeButton.frame.size.width) / 2, vc.closeButton.frame.origin.y, vc.closeButton.frame.size.width, vc.closeButton.frame.size.height);
    }
    else
    {
        vc.messageLabel.stringValue = @"La carta è bloccata. Aprire CIE ID e sbloccarla usando il PUK";
    }
}

- (void) pinWrong: (int) remainingTrials
{
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _popover.contentViewController = vc;
    [self showPopover:self];
    
    vc.messageLabel.stringValue = @"Il PIN digitato è errato";
    
    vc.cieidButton.hidden = YES;
    vc.closeButton.frame = CGRectMake((vc.view.frame.size.width - vc.closeButton.frame.size.width) / 2, vc.closeButton.frame.origin.y, vc.closeButton.frame.size.width, vc.closeButton.frame.size.height);
}

- (void) cardNotRegistered: (NSString*) pan
{
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _popover.contentViewController = vc;
    [self showPopover:self];
    
    BOOL processIsRunning = self.cieidIsRunning;
    
    if(processIsRunning)
    {
        vc.messageLabel.stringValue = @"La carta non è stata abbinata. Abbinare la carta";
        vc.cieidButton.hidden = YES;
        vc.closeButton.frame = CGRectMake((vc.view.frame.size.width - vc.closeButton.frame.size.width) / 2, vc.closeButton.frame.origin.y, vc.closeButton.frame.size.width, vc.closeButton.frame.size.height);
    }
    else
        vc.messageLabel.stringValue = @"La carta non è stata abbinata. Aprire CIE ID per abbinare la carta";
}

@end

//
//  AppDelegate.m
//  CIEIDBar
//
//  Created by ugo chirico on 05/01/2019.
//  Copyright © 2019 IPZS. All rights reserved.
//

#import "AppDelegate.h"
#include<stdio.h>
#include<string.h>    //strlen
#include<sys/socket.h>
#include<arpa/inet.h>    //inet_addr
#include<unistd.h>    //write

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *statusMenu;
@property NSStatusItem* statusItem;
@property NSPopover* popover;
@property NSTextField* messageLabel;
@end

@implementation AppDelegate

bool isRunning = false;
int socket_desc;


- (IBAction)menuItemQuit:(id)sender {
    [NSApplication.sharedApplication terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
    
    NSImage* icon = [NSImage imageNamed:@"icona_minimize_01"];
    //icon.template = true; // best for dark mode
    _statusItem.image = icon;
    //_statusItem.menu = _statusMenu;
    
    NSButton* button = _statusItem.button;
    button.image = icon;
    button.action = @selector(togglePopover:);
    
    _popover = [[NSPopover alloc] init];
    
    MessageViewController* vc = MessageViewController.freshController;
    vc.popover = _popover;
    _messageLabel = vc.messageLabel;
    
    _popover.contentViewController = vc;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startServer];
    });
}

- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)reply
{
    NSLog(@"geturl %@", [[event paramDescriptorForKeyword:keyDirectObject] stringValue]);
    
    //[[[event paramDescriptorForKeyword:keyDirectObject] stringValue] writeToFile:@"/testbed/complete_url.txt" atomically:YES];
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
    isRunning = false;
    close(socket_desc);
    
//    [_daemon stop];
}

- (void) pinLocked
{
    _messageLabel.stringValue = @"La carta è bloccata. Aprire CIE ID e sbloccarla usando il PUK";
    [self showPopover:self];
}

- (void) pinWrong: (int) remainingTrials
{
    _messageLabel.stringValue = @"Il PIN digitato è errato";
    [self showPopover:self];
}

- (void) cardNotRegistered: (NSString*) pan
{
    _messageLabel.stringValue = @"La carta non abbinata. Aprire CIE ID per abbinare la carta";
    [self showPopover:self];
}


- (int) startServer
{
    int client_sock , c;
    long read_size;
    struct sockaddr_in server , client;
    char szClientMessage[100];
    
    //Create socket
    socket_desc = socket(AF_INET , SOCK_STREAM , 0);
    if (socket_desc == -1)
    {
        printf("Could not create socket");
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
        while( (read_size = recv(client_sock , szClientMessage , 100 , 0)) > 0 )
        {
            NSLog(@"message received: %s", szClientMessage);
            
            //Send the message back to client
            write(client_sock , szClientMessage , strlen(szClientMessage));
            
            if(strstr(szClientMessage, "pinlocked") == szClientMessage)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pinLocked];
                });
            }
            else if(strstr(szClientMessage, "pinwrong") == szClientMessage)
            {
                char* szTok = strtok(szClientMessage, ":");
                szTok = strtok(NULL, ":");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pinWrong: atoi(szTok)];
                });
            }
            
            else if(strstr(szClientMessage, "cardnotregistered") == szClientMessage)
            {
                char* szTok = strtok(szClientMessage, ":");
                szTok = strtok(NULL, ":");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cardNotRegistered:[NSString stringWithUTF8String:szTok]];
                });
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


- (IBAction)showHelp:(id)sender
{
    NSURL * helpFile = [[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"];
    [[NSWorkspace sharedWorkspace] openURL:helpFile];
}


@end

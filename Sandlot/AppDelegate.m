//
//  AppDelegate.m
//  Sandlot
//
//  Created by Joe Conway on 10/22/14.
//  Copyright (c) 2014 Stable Kernel. All rights reserved.
//

#import "AppDelegate.h"
#import "STKSimulatorStore.h"
#import "STKCommandWindowController.h"

// /Users/joeconway/Library/Developer/CoreSimulator/Devices/2E55096E-80E1-43F9-8B44-7930470FEB39/data/Library/BackBoard/applicationState.plist
// // /Users/joeconway/Library/Developer/CoreSimulator/Devices/2E55096E-80E1-43F9-8B44-7930470FEB39/device.plist

@interface AppDelegate ()

@property (nonatomic, strong) STKCommandWindowController *windowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    [[STKSimulatorStore store] constructSimulatorGraphWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Developer/CoreSimulator/Devices"]];    

    _windowController = [[STKCommandWindowController alloc] initWithWindowNibName:@"STKCommandWindowController"];
    
    [[self windowController] showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end

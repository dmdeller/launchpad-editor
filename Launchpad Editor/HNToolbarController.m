//
//  HNToolbarController.m
//  Launchpad Editor
//
//  Created by David Deller on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNToolbarController.h"

#import "HNAppDelegate.h"

@implementation HNToolbarController

@synthesize appDelegate;
@synthesize syncButton;

#pragma mark -

- (void)awakeFromNib
{
    [self.syncButton setTarget:self];
    [self.syncButton setAction:@selector(confirmSync)];
}

#pragma mark -
#pragma mark Sync button

- (void)confirmSync
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Sync & Relaunch Dock"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Dock needs to be relaunched"];
    [alert setInformativeText:@"Syncing will cause changes you've made in either Launchpad Editor or Launchpad to show up in both places.\n\nTo do this, the Dock needs to be relaunched."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:self.appDelegate.window modalDelegate:self didEndSelector:@selector(syncAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)syncAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [self.appDelegate.outlineView reloadData];
        [self.appDelegate restartDock];
    }
}

@end

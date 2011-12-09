//
//  HNToolbarController.m
//  Launchpad Editor
//
//  Created by David Deller on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNToolbarController.h"

#import "HNAppDelegate.h"
#import "HNOutlineViewController.h"
#import "HNLaunchpadEntity.h"
#import "HNLaunchpadContainer.h"

@implementation HNToolbarController

@synthesize appDelegate;
@synthesize addPageButton;
@synthesize addGroupButton;
@synthesize deleteButton;
@synthesize syncButton;

#pragma mark -

- (void)awakeFromNib
{
    [self.addPageButton setTarget:self];
    [self.addPageButton setAction:@selector(addPage)];
    
    [self.addGroupButton setTarget:self];
    [self.addGroupButton setAction:@selector(addGroup)];
    
    [self.deleteButton setTarget:self];
    [self.deleteButton setAction:@selector(delete)];
    
    [self.syncButton setTarget:self];
    [self.syncButton setAction:@selector(confirmSync)];
}

#pragma mark -
#pragma mark NSToolbarItemValidation

/**
 * This is called 'on a regular basis', apparently!
 */
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    id <HNLaunchpadEntity> selectedItem = [self.appDelegate.outlineViewController selectedItem];
    
    if (theItem == self.addPageButton)
    {
        return YES;
    }
    else if (theItem == self.addGroupButton)
    {
        if (selectedItem != nil)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else if (theItem == self.deleteButton)
    {
        if ([selectedItem conformsToProtocol:@protocol(HNLaunchpadContainer)])
        {
            id <HNLaunchpadContainer> selectedContainer = (id)selectedItem;
            
            // can only delete a container if it's empty
            if (selectedContainer.items == 0)
            {
                return YES;
            }
            else
            {
                return NO;
            }
        }
        else
        {
            return NO;
        }
    }
    else if (theItem == self.syncButton)
    {
        return YES;
    }
    else
    {
        return YES;
    }
}

#pragma mark -
#pragma mark Add Page button

- (void)addPage
{
}

#pragma mark -
#pragma mark Add Group button

- (void)addGroup
{
    
}

#pragma mark -
#pragma mark Delete button

- (void)delete
{

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

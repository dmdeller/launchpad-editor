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
#import "HNLaunchpadDataSet.h"
#import "HNLaunchpadEntity.h"
#import "HNLaunchpadContainer.h"
#import "HNLaunchpadPage.h"
#import "HNLaunchpadGroup.h"
#import "HNLaunchpadApp.h"
#import "HNException.h"

#import "FMDatabase.h"

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
            if ([selectedItem isKindOfClass:[HNLaunchpadApp class]])
            {
                // only create groups when the selected app is a direct descendant of a page; don't want to encourage the impression that we can create groups inside of groups
                if ([[self.appDelegate.dataSet parentForEntity:selectedItem] isKindOfClass:[HNLaunchpadPage class]])
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
                return YES;
            }
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
            if ([selectedContainer.items count] == 0)
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
    FMDatabase *db = [self.appDelegate openDb];
    
    HNLaunchpadPage *newPage = [[HNLaunchpadPage alloc] init];
    
    NSUInteger insertPosition = [self.appDelegate.dataSet.itemTree count];
    
    [self.appDelegate.dataSet createPage:newPage atPosition:insertPosition inDb:db];
    [self.appDelegate.dataSet saveContainerOrdering:nil inDb:db];
    
    [db close];
    
    [self.appDelegate.outlineView reloadData];
    
    // highlight new row
    NSInteger row = [self.appDelegate.outlineView rowForItem:newPage];
    [self.appDelegate.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

#pragma mark -
#pragma mark Add Group button

- (void)addGroup
{
    FMDatabase *db = [self.appDelegate openDb];
    id <HNLaunchpadEntity> selectedItem = [self.appDelegate.outlineViewController selectedItem];
    
    HNLaunchpadPage *insertIntoPage;
    NSUInteger insertPosition;
    
    if ([selectedItem isKindOfClass:[HNLaunchpadPage class]])
    {
        insertIntoPage = (HNLaunchpadPage *)selectedItem;
        
        // insert into last position within selected page
        insertPosition = [insertIntoPage.items count];
    }
    else if ([selectedItem isKindOfClass:[HNLaunchpadGroup class]])
    {
        insertIntoPage = (HNLaunchpadPage *)[self.appDelegate.dataSet parentForEntity:selectedItem];
        
        // insert into position that the selected group occupies
        insertPosition = [insertIntoPage.items indexForKey:selectedItem.id];
    }
    else if ([selectedItem isKindOfClass:[HNLaunchpadApp class]])
    {
        insertIntoPage = (HNLaunchpadPage *)[self.appDelegate.dataSet rootParentForEntity:selectedItem];
        
        id <HNLaunchpadEntity> parent = [self.appDelegate.dataSet parentForEntity:selectedItem];
        
        if ([parent isKindOfClass:[HNLaunchpadPage class]])
        {
            // insert into position that the selected app occupies
            insertPosition = [insertIntoPage.items indexForKey:selectedItem.id];
        }
        else if ([parent isKindOfClass:[HNLaunchpadGroup class]])
        {
            // insert into position that the selected app's parent group occupies
            insertPosition = [insertIntoPage.items indexForKey:parent.id];
        }
        else
        {
            [HNException raise:HNInvalidClassException format:@"Unusable class: %@", [selectedItem class]];
        }
    }
    else
    {
        [HNException raise:HNInvalidClassException format:@"Unknown class: %@", [selectedItem class]];
    }
    
    HNLaunchpadGroup *newGroup = [[HNLaunchpadGroup alloc] init];
    newGroup.title = @"Untitled Group";
    
    [self.appDelegate.dataSet createGroup:newGroup inPage:insertIntoPage atPosition:insertPosition inDb:db];
    [self.appDelegate.dataSet saveContainerOrdering:insertIntoPage inDb:db];
    
    [db close];
    
    [self.appDelegate.outlineView reloadItem:insertIntoPage reloadChildren:YES];
    
    // highlight new row for editing, to suggest that the user should rename it
    NSInteger row = [self.appDelegate.outlineView rowForItem:newGroup];
    [self.appDelegate.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self.appDelegate.outlineView editColumn:0 row:row withEvent:nil select:YES];
}

#pragma mark -
#pragma mark Delete button

- (void)delete
{
    FMDatabase *db = [self.appDelegate openDb];
    id <HNLaunchpadEntity> selectedItem = [self.appDelegate.outlineViewController selectedItem];
    id <HNLaunchpadEntity> parentItem = [self.appDelegate.dataSet parentForEntity:selectedItem];
    
    if ([selectedItem isKindOfClass:[HNLaunchpadGroup class]] || [selectedItem isKindOfClass:[HNLaunchpadPage class]])
    {
        [self.appDelegate.dataSet deleteContainer:(id)selectedItem inDb:db];
    }
    else
    {
        [HNException raise:HNInvalidClassException format:@"Cannot use this class in this context: %@", [selectedItem class]];
    }
    
    selectedItem = nil;
    
    if (parentItem == nil)
    {
        [self.appDelegate.outlineView reloadData];
    }
    else
    {
        [self.appDelegate.outlineView reloadItem:parentItem reloadChildren:YES];
    }
    
    [db close];
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

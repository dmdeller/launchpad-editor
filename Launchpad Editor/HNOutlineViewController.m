//
//  HNOutlineViewController.m
//  Launchpad Editor
//
//  Created by David Deller on 12/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNOutlineViewController.h"

#import "Constants.h"
#import "HNException.h"
#import "HNAppDelegate.h"
#import "HNLaunchpadDataSet.h"
#import "HNLaunchpadPage.h"
#import "HNLaunchpadGroup.h"
#import "HNLaunchpadApp.h"
#import "HNToolbarController.h"

#import "FMDatabase.h"

@implementation HNOutlineViewController

@synthesize appDelegate;
@synthesize dataSet;

#pragma mark -

- (void)awakeFromNib
{
    [self.appDelegate.outlineView registerForDraggedTypes:[NSArray arrayWithObject:HNLaunchpadPasteboardType]];
    
    @try
    {
        FMDatabase *db = [self.appDelegate openDb];
        self.dataSet = [[HNLaunchpadDataSet alloc] init];
        [self.dataSet loadFromDb:db];
        [db close];
    }
    @catch (HNException *e)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Error loading Launchpad database"];
        [alert setInformativeText:[e reason]];
        [alert setAlertStyle:NSCriticalAlertStyle];
        
        [alert beginSheetModalForWindow:self.appDelegate.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
}

- (id)selectedItem
{
    return [self.appDelegate.outlineView itemAtRow:self.appDelegate.outlineView.selectedRow];
}

#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil)
    {
        return [self.dataSet.itemTree count];
    }
    else if ([item isKindOfClass:[HNLaunchpadPage class]])
    {
        HNLaunchpadPage *page = (HNLaunchpadPage *)item;
        
        return [page.items count];
    }
    else if ([item isKindOfClass:[HNLaunchpadGroup class]])
    {
        HNLaunchpadGroup *group = (HNLaunchpadGroup *)item;
        
        return [group.items count];
    }
    else if ([item isKindOfClass:[HNLaunchpadApp class]])
    {
        return 0;
    }
    else
    {
        [HNException raise:HNInvalidClassException format:@"Unknown kind of item"];
        return 0;
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item conformsToProtocol:@protocol(HNLaunchpadContainer)])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    
    if (item == nil)
    {
        return [self.dataSet.itemTree objectForKey:[self.dataSet.itemTree keyAtIndex:index]];
    }
    else if ([item isKindOfClass:[HNLaunchpadPage class]])
    {
        HNLaunchpadPage *page = (HNLaunchpadPage *)item;
        
        return [page.items objectForKey:[page.items keyAtIndex:index]];
    }
    else if ([item isKindOfClass:[HNLaunchpadGroup class]])
    {
        HNLaunchpadGroup *group = (HNLaunchpadGroup *)item;
        
        return [group.items objectForKey:[group.items keyAtIndex:index]];
    }
    else
    {
        [HNException raise:NSInternalInconsistencyException format:@"Item has no children"];
        return nil;
    }
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[HNLaunchpadPage class]])
    {
        HNLaunchpadPage *page = (HNLaunchpadPage *)item;
        
        return [NSString stringWithFormat:@"Page %i", page.pageNumber];
    }
    else if ([item isKindOfClass:[HNLaunchpadGroup class]])
    {
        HNLaunchpadGroup *group = (HNLaunchpadGroup *)item;
        
        return group.title;
    }
    else if ([item isKindOfClass:[HNLaunchpadApp class]])
    {
        HNLaunchpadApp *app = (HNLaunchpadApp *)item;
        
        return app.title;
    }
    else
    {
        [HNException raise:NSInternalInconsistencyException format:@"Unknown kind of item"];
        return @"Unknown";
    }
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[HNLaunchpadGroup class]])
    {
        HNLaunchpadGroup *group = (HNLaunchpadGroup *)item;
        NSString *newTitle = (NSString *)object;
        
        group.title = newTitle;
        
        FMDatabase *db = [self.appDelegate openDb];
        [self.dataSet saveGroup:group inDb:db];
        [db close];
    }
    else
    {
        [HNException raise:HNInvalidClassException format:@"Only HNLaunchpadGroup objects can be renamed"];
        return;
    }
}

#pragma mark -
#pragma mark Drag & drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
    if ([items count] > 1)
    {
        return NO;
    }
    
    [pboard declareTypes:[NSArray arrayWithObject:HNLaunchpadPasteboardType] owner:nil];
    
    id <HNLaunchpadEntity> item = [items objectAtIndex:0];
    NSString *itemId = [item.id stringValue];
    
#ifdef DEBUG
    //id <HNLaunchpadItem> debugItem = (id)item;
    //NSLog(@"drag item title: %@, id: %@, ordering: %d", debugItem.title, debugItem.id, debugItem.ordering);
#endif
    
    [pboard setString:itemId forType:HNLaunchpadPasteboardType];
    
    return YES;
}

/**
 * Some types of items can be drag-and-dropped into some types of containers. Given an item and a container, this method tells you if it's possible.
 */
- (BOOL)entity:(id <HNLaunchpadEntity>)entity canBeDroppedIntoContainer:(id <HNLaunchpadContainer>)container
{
    // pages can only be reordered at the top level
    if ([entity isKindOfClass:[HNLaunchpadPage class]])
    {
        // nil means top level
        if (container == nil)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    // groups can only be reordered within pages (not within groups)
    else if ([entity isKindOfClass:[HNLaunchpadGroup class]])
    {
        if ([container isKindOfClass:[HNLaunchpadPage class]])
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    // apps can be reordered within pages or groups, not within apps 
    else if ([entity isKindOfClass:[HNLaunchpadApp class]])
    {
        if ([container isKindOfClass:[HNLaunchpadPage class]])
        {
            return YES;
        }
        else if ([container isKindOfClass:[HNLaunchpadGroup class]])
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    // what.
    else
    {
        return NO;
    }
}

/**
 * TODO: Allow reordering of Pages
 */
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    NSNumber *sourceItemId = [NSNumber numberWithInteger:[[[info draggingPasteboard] stringForType:HNLaunchpadPasteboardType] integerValue]];
    id <HNLaunchpadEntity> sourceItem = [self.dataSet.itemList objectForKey:sourceItemId];
    
#ifdef DEBUG
    //id <HNLaunchpadEntity> debugItem = (id)item;
    //id <HNLaunchpadItem> debugSourceItem = (id)sourceItem;
    //NSLog(@"validate drop item title: %@, id: %@, ordering: %d -- onto item id: %@, ordering: %d", debugSourceItem.title, debugSourceItem.id, debugSourceItem.ordering, debugItem.id, debugItem.ordering);
#endif
    
    if (
        // Item being dropped onto must be a container
        [item conformsToProtocol:@protocol(HNLaunchpadContainer)] &&
        
        // Check to see if this is a valid drop
        [self entity:sourceItem canBeDroppedIntoContainer:item]
        )
    {
        return NSDragOperationEvery;
    }
    else
    {
        return NSDragOperationNone;
    }
}

/**
 * TODO: Allow reordering of Pages
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    NSNumber *childId = [NSNumber numberWithInteger:[[[info draggingPasteboard] stringForType:HNLaunchpadPasteboardType] integerValue]];
    
    id <HNLaunchpadEntity> child = [self.dataSet.itemList objectForKey:childId];
    id <HNLaunchpadContainer> oldParent = [self.dataSet.itemList objectForKey:child.parentId];
    id <HNLaunchpadContainer> newParent = item;
    
#ifdef DEBUG
    //id <HNLaunchpadEntity> debugItem = (id)item;
    //id <HNLaunchpadItem> debugSourceItem = (id)child;
    //NSLog(@"accept drop item title: %@, id: %@, ordering: %d -- onto item id: %@, ordering: %d", debugSourceItem.title, debugSourceItem.id, debugSourceItem.ordering, debugItem.id, debugItem.ordering);
#endif
    
    if (!(
          // Item being dropped onto must be a container
          [newParent conformsToProtocol:@protocol(HNLaunchpadContainer)] &&
          
          // Check to see if this is a valid drop
          [self entity:child canBeDroppedIntoContainer:item]
          ))
    {
        return NO;
    }
    
    // Make sure the new parent container is not going to exceed its maximum number of items
    if (oldParent != newParent &&
        (([newParent isKindOfClass:[HNLaunchpadGroup class]] && [newParent.items count] >= HNLaunchpadGroupMaxItems) ||
        ([newParent isKindOfClass:[HNLaunchpadPage class]] && [newParent.items count] >= HNLaunchpadPageMaxItems)))
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Too many items"];
        [alert setInformativeText:[NSString stringWithFormat:@"The %@ you tried to drag to already contains the maximum number of items (%i).",
                                   ([newParent isKindOfClass:[HNLaunchpadGroup class]] ? @"group" : @"page"),
                                   ([newParent isKindOfClass:[HNLaunchpadGroup class]] ? HNLaunchpadGroupMaxItems : HNLaunchpadPageMaxItems)]];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:self.appDelegate.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        
        return NO;
    }
    
    FMDatabase *db = [self.appDelegate openDb];
    
    // remove child from old placement
    if (oldParent == newParent)
    {
        [newParent.items removeObjectForKey:child.id];
    }
    else
    {
        [oldParent.items removeObjectForKey:child.id];
        
        child.parentId = newParent.id;
        [self.dataSet saveEntity:child inDb:db];
    }
    
    // add child in new placement
    // if item dropped on container with no specific position, then place at end
    if (index == -1)
    {
        [newParent.items setObject:child forKey:child.id];
    }
    // otherwise, insert in proper place
    else
    {
        [newParent.items insertObject:child forKey:child.id atIndex:index];
    }
    
    [self.dataSet saveContainerOrdering:newParent inDb:db];
    
    // reload view data 
    if (oldParent != newParent)
    {
        [outlineView reloadItem:oldParent reloadChildren:YES];
    }
    [outlineView reloadItem:newParent reloadChildren:YES];
    
    [db close];
    
    return YES;
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if ([item isKindOfClass:[HNLaunchpadPage class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[HNLaunchpadGroup class]])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

/*- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
    id <HNLaunchpadEntity> item = [self.appDelegate.outlineView itemAtRow:self.appDelegate.outlineView.selectedRow];
    
    NSLog(@"selected: %@", item);
    
    if ([item isKindOfClass:[HNLaunchpadApp class]])
    {
        [self.appDelegate.toolbarController.addGroupButton setEnabled:YES];
    }
    else
    {
        [self.appDelegate.toolbarController.addGroupButton setEnabled:NO];
    }
}*/

@end

//
//  HNLaunchpadDataSet.m
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNLaunchpadDataSet.h"

#import "HNLaunchpadContainer.h"
#import "HNLaunchpadPage.h"
#import "HNLaunchpadGroup.h"
#import "HNLaunchpadApp.h"
#import "Constants.h"
#import "HNException.h"

#import "FMDatabase.h"
#import "FMResultSet.h"

@implementation HNLaunchpadDataSet

@synthesize itemTree;
@synthesize itemList;

#pragma mark -
#pragma mark Loading data

- (void)loadFromDb:(FMDatabase *)db
{
    MGOrderedDictionary *pages = [self loadPagesFromDb:db];
    NSDictionary *groups = [self loadGroupsFromDb:db];
    NSDictionary *apps = [self loadAppsFromDb:db];
    
    [self collateApps:apps andGroups:groups intoPages:pages fromDb:db];
    
    self.itemTree = pages;
    
    self.itemList = [NSMutableDictionary dictionaryWithCapacity:2000];
    [self.itemList addEntriesFromDictionary:pages];
    [self.itemList addEntriesFromDictionary:groups];
    [self.itemList addEntriesFromDictionary:apps];
}

- (MGOrderedDictionary *)loadPagesFromDb:(FMDatabase *)db
{
    MGOrderedDictionary *pages = [MGOrderedDictionary dictionaryWithCapacity:10];
    
    NSString *sql = @"SELECT *"
                        " FROM items i"
                            " JOIN groups g ON i.rowid = g.item_id"
                        " WHERE i.type = ?"
                        " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInt:HNLaunchpadTypePage]];
    
    if (results == nil)
    {
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        return nil;
    }
    
    int pageNumber = 0;
    
    while ([results next])
    {
        // FIXME: hacky
        if ([[results stringForColumn:@"uuid"] isEqualToString:@"HOLDINGPAGE"])
        {
            continue;
        }
        
        HNLaunchpadPage *page = [[HNLaunchpadPage alloc] init];
        
        pageNumber++;
        
        page.uuid = [results stringForColumn:@"uuid"];
        page.id = [NSNumber numberWithInt:[results intForColumn:@"rowid"]];
        page.ordering = [results intForColumn:@"ordering"];
        page.pageNumber = pageNumber;
        page.items = [MGOrderedDictionary dictionaryWithCapacity:40];
        
        [pages setObject:page forKey:page.id];
    }
    
    return pages;
}

- (NSDictionary *)loadGroupsFromDb:(FMDatabase *)db
{
    NSMutableDictionary *groups = [NSMutableDictionary dictionaryWithCapacity:100];
    
    NSString *sql = @"SELECT *"
                    " FROM items i"
                        " JOIN groups g ON i.rowid = g.item_id"
                    " WHERE i.type = ?"
                    " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInt:HNLaunchpadTypeGroup]];
    
    if (results == nil)
    {
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        return nil;
    }
    
    while ([results next])
    {
        HNLaunchpadGroup *group = [[HNLaunchpadGroup alloc] init];
        
        group.uuid = [results stringForColumn:@"uuid"];
        group.id = [NSNumber numberWithInt:[results intForColumn:@"item_id"]];
        group.ordering = [results intForColumn:@"ordering"];
        group.parentId = [NSNumber numberWithInt:[results intForColumn:@"parent_id"]];
        group.title = [results stringForColumn:@"title"];
        group.items = [MGOrderedDictionary dictionaryWithCapacity:40];
        
        [groups setObject:group forKey:group.id];
    }
    
    return [NSDictionary dictionaryWithDictionary:groups];
}

- (NSDictionary *)loadAppsFromDb:(FMDatabase *)db
{
    NSMutableDictionary *apps = [NSMutableDictionary dictionaryWithCapacity:1000];
    
    NSString *sql = @"SELECT *"
                    " FROM items i"
                        " JOIN apps a ON i.rowid = a.item_id"
                    " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql];
    
    if (results == nil)
    {
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        return nil;
    }
    
    while ([results next])
    {
        HNLaunchpadApp *app = [[HNLaunchpadApp alloc] init];
        
        app.uuid = [results stringForColumn:@"uuid"];
        app.id = [NSNumber numberWithInt:[results intForColumn:@"item_id"]];
        app.ordering = [results intForColumn:@"ordering"];
        app.parentId = [NSNumber numberWithInt:[results intForColumn:@"parent_id"]];
        app.title = [results stringForColumn:@"title"];
        
        [apps setObject:app forKey:app.id];
    }
    
    return [NSDictionary dictionaryWithDictionary:apps];
}

/**
 * This takes the apps and groups that have already been loaded, and puts them into the proper hierarchical order.
 * I couldn't find a way to do this during the first pass, because it might have been necessary to insert apps into parent objects that had not appeared yet based on the ordering.
 * From my observation, pages seem to appear before groups based on this ordering, but none of this behaviour is documented so I'm being extra careful.
 */
- (void)collateApps:(NSDictionary *)apps andGroups:(NSDictionary *)groups intoPages:(MGOrderedDictionary *)pages fromDb:(FMDatabase *)db
{
    NSString *sql = @"SELECT i.rowid AS item_id, i.parent_id, i.type"
                        " FROM items i"
                            " JOIN items parent ON i.parent_id = parent.rowid"
                            " LEFT JOIN groups g ON i.rowid = g.item_id"
                            " LEFT JOIN apps a ON i.rowid = a.item_id"
                        " WHERE i.type = ? OR i.type = ?"
                        " ORDER BY parent.ordering, i.ordering";
    
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInt:HNLaunchpadTypeApp], [NSNumber numberWithInt:HNLaunchpadTypeGroup]];
    
    while ([results next])
    {
        if ([results intForColumn:@"type"] == HNLaunchpadTypeApp)
        {
            HNLaunchpadApp *app = [apps objectForKey:[NSNumber numberWithInt:[results intForColumn:@"item_id"]]];
            
            // is this app in a page?
            HNLaunchpadPage *containerPage = [pages objectForKey:[NSNumber numberWithInt:[results intForColumn:@"parent_id"]]];
            if (containerPage != nil)
            {
                [containerPage.items setObject:app forKey:app.id];
            }
            else
            {
                // is this app in a group?
                HNLaunchpadGroup *containerGroup = [groups objectForKey:[NSNumber numberWithInt:[results intForColumn:@"parent_id"]]];
                if (containerGroup != nil)
                {
                    [containerGroup.items setObject:app forKey:app.id];
                }
                else if ([results intForColumn:@"parent_id"] == HNLaunchpadHoldingPageId)
                {
                    NSLog(@"App only exists in temporary holding page, unable to display app: %@, title: %@", app, app.title);
                    continue;
                }
                else
                {
                    // exception
                    [HNException raise:@"Container not found" format:@"Could not find container object for app: %@, title: %@", app, app.title];
                    continue;
                }
            }
        }
        else if ([results intForColumn:@"type"] == HNLaunchpadTypeGroup)
        {
            HNLaunchpadGroup *group = [groups objectForKey:[NSNumber numberWithInt:[results intForColumn:@"item_id"]]];
            
            HNLaunchpadPage *containerPage = [pages objectForKey:[NSNumber numberWithInt:[results intForColumn:@"parent_id"]]];
            if (containerPage != nil)
            {
                [containerPage.items setObject:group forKey:group.id];
            }
            else
            {
                // exception
                [HNException raise:@"Container not found" format:@"Could not find container object for group: %@, title: %@", group, group.title];
                continue;
            }
        }
        else
        {
            //exception
            [HNException raise:@"Unknown entity type" format:@"Unknown entity type: %i", [results intForColumn:@"type"]];
            continue;
        }
    }
}

#pragma mark -
#pragma mark Saving data

/**
 * Get the next usable ID in the items table
 */
- (NSNumber *)nextIdInDb:(FMDatabase *)db
{
    NSNumber *nextId;
    
    NSString *sql = @"SELECT max(id)"
                        " FROM items";
    
    FMResultSet *results = [db executeQuery:sql];
    
    if (results == nil)
    {
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        return nil;
    }
    
    if ([results next])
    {
        nextId = [NSNumber numberWithInt:([results intForColumnIndex:0] + 1)];
    }
    else
    {
        [HNException raise:@"Database query failure" format:@"No results returned for SQL: %@", sql];
        return nil;
    }
    
    return nextId;
}

- (void)createGroup:(HNLaunchpadGroup *)group inPage:(HNLaunchpadPage *)page atPosition:(NSUInteger)position inDb:(FMDatabase *)db
{
    //[db beginTransaction];
    
    group.parentId = page.id;
    [page.items insertObject:group forKey:group.id atIndex:position];
    
    NSString *sql = @"INSERT INTO items (rowid, uuid, flags, type, parent_id, ordering) VALUES (?, ?, ?, ?, ?, ?)";
    
    // create new UUID
    CFUUIDRef uuidObj = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObj);
    CFRelease(uuidObj);
    
    NSLog(@"uuid: %@", uuid);
    
    /*if (![db executeUpdate:sql, group.id, uuid, HNLaunchpadDefaultFlags, HNLaunchpadTypeGroup, group.parentId, HNLaunchpadDefaultOrdering])
    {
        [db rollback];
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        [db close];
        return;
    }*/
    
    
}

- (void)saveGroup:(HNLaunchpadGroup *)group inDb:(FMDatabase *)db
{
    NSString *sql = @"UPDATE groups"
                        " SET title = ?"
                        " WHERE item_id = ?";
    
    if (![db executeUpdate:sql, group.title, group.id])
    {
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        [db close];
        return;
    }
}

- (void)saveEntity:(id <HNLaunchpadEntity>)entity inDb:(FMDatabase *)db
{
    NSString *sql = @"UPDATE items"
                        " SET parent_id = ?"
                        " WHERE rowid = ?";
    
    if (![db executeUpdate:sql, entity.parentId, entity.id])
    {
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        [db close];
        return;
    }
}

/**
 * Loops through all of the items in a container, and makes the database ordering match the current MGOrderedDictionary ordering.
 */
- (void)saveContainerOrdering:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db
{
    [self setTriggerDisabled:YES inDb:db];
    
    int i = 0;
    
    for (id <HNLaunchpadItem> item in [container.items allValues])
    {
        item.ordering = i;
        
        NSString *sql = @"UPDATE items"
                            " SET ordering = ?"
                            " WHERE rowid = ?";
        
        if (![db executeUpdate:sql, [NSNumber numberWithInt:item.ordering], item.id])
        {
            [HNException raise:@"Database error" format:[db lastErrorMessage]];
            [self setTriggerDisabled:NO inDb:db];
            [db close];
            return;
        }
        
        i++;
    }
    
    [self setTriggerDisabled:NO inDb:db];
}

/**
 * The database has a trigger called update_items_order - it's not clear what it's supposed to do, but it interferes with our adjustment of the ordering, so we need a way to temporarily disable it.
 */
- (void)setTriggerDisabled:(BOOL)isDisabled inDb:(FMDatabase *)db
{
    NSString *sql = @"UPDATE dbinfo"
                        " SET value = ?"
                        " WHERE key = 'ignore_items_update_triggers'";
    
    if (![db executeUpdate:sql, [NSNumber numberWithBool:isDisabled]])
    {
        [HNException raise:@"Database error" format:[db lastErrorMessage]];
        return;
    }
}

@end

//
//  HNLaunchpadDataSet.m
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 D.M.Deller. All rights reserved.
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
@synthesize appIcons;
@synthesize isLoaded;

- (id)init
{
    if ((self = [super init]))
    {
        self.isLoaded = NO;
    }
    
    return self;
}

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
    
    self.isLoaded = YES;
}

- (MGOrderedDictionary *)loadPagesFromDb:(FMDatabase *)db
{
    MGOrderedDictionary *pages = [MGOrderedDictionary dictionaryWithCapacity:10];
    
    NSString *sql = @"SELECT *"
                        " FROM items i"
                            " JOIN groups g ON i.rowid = g.item_id"
                        " WHERE i.type = ?"
                            " AND i.parent_id = ?"
                        " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInt:HNLaunchpadTypePage], [NSNumber numberWithInt:HNLaunchpadPageParentId]];
    
    if (results == nil)
    {
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        return nil;
    }
    
    NSMutableSet *blacklist = NSMutableSet.set;
    
    while ([results next])
    {
        NSString *uuid = [results stringForColumn:@"uuid"];
        NSNumber *ID = [NSNumber numberWithInt:[results intForColumn:@"rowid"]];
        NSNumber *parentID = [NSNumber numberWithInt:[results intForColumn:@"parent_id"]];
        
        // Valid pages have a 'uuid' column which contains an actual UUID (a long hexadecimal string separated by hyphens at certain points).
        // There are also some 'holding' pages which are some kind of temporary storage that doesn't actually appear in Launchpad - so we don't want to show those.
        // In 10.7, there was only one holding page, identified by the text 'HOLDINGPAGE' instead of a UUID.
        // In 10.8, there are multiple holding pages with different names, and at least one of them might have a child that has a real UUID! We need to ignore these children as well.
        // So, any page that doesn't have a proper UUID, or has an ancestor without a proper UUID, we ignore.
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" options:NSRegularExpressionCaseInsensitive error:&error];
        if (error != nil)
        {
            NSLog(@"Error evaluating regex: %@", error.userInfo);
        }
        else if ([regex numberOfMatchesInString:uuid options:0 range:NSMakeRange(0, uuid.length)] == 0)
        {
            NSLog(@"Blacklisting page with ID: %@ because it has an invalid UUID: %@", ID, uuid);
            
            [blacklist addObject:ID];
            continue;
        }
        else if ([blacklist containsObject:ID] || [blacklist containsObject:parentID])
        {
            NSLog(@"Blacklisting page with ID: %@ because it has a blacklisted ancestor with ID: %@", ID, parentID);
            
            [blacklist addObject:ID];
            continue;
        }
        
        HNLaunchpadPage *page = [[HNLaunchpadPage alloc] init];
        
        page.uuid = uuid;
        page.id = ID;
        page.ordering = [results intForColumn:@"ordering"];
        
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
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
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
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
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
                else
                {
                    NSLog(@"Could not find container object for app: %@, title: %@", app, app.title);
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
                NSLog(@"Could not find container object for group: %@, title: %@", group, group.title);
                continue;
            }
        }
        else
        {
            NSLog(@"Unknown entity type: %i", [results intForColumn:@"type"]);
            continue;
        }
    }
}

/**
 * This method is prone to miss some applications, because the only data we get from Launchpad to identify an app is its name...
 * This doesn't account for multiple apps with the same name, apps outside of normal Application folders, etc.
 * So we just do the best we can.
 */
- (void)loadAppIcons
{
    NSArray *dirs = [NSArray arrayWithObjects:@"/Applications", [NSHomeDirectory() stringByAppendingPathComponent:@"Applications"], @"/Developer/Applications", nil];
    NSString *file;
    NSDirectoryEnumerator *enumerator;
    NSString *appPath;
    NSImage *appIcon;
    self.appIcons = [NSMutableDictionary dictionaryWithCapacity:1000];
    
    NSImage *genericApplicationIcon = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"];
    [genericApplicationIcon setSize:NSMakeSize(16, 16)];
    [self.appIcons setObject:genericApplicationIcon forKey:@"GenericApplicationIcon"];
    
    NSImage *genericFolderIcon = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns"];
    [genericFolderIcon setSize:NSMakeSize(16, 16)];
    [self.appIcons setObject:genericFolderIcon forKey:@"GenericFolderIcon"];
    
    for (NSString *dir in dirs)
    {
        enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
        while (file = [enumerator nextObject])
        {
            if ([[file pathExtension] isEqualToString:@"app"])
            {
                NSString *appName = [[[file pathComponents] lastObject] stringByDeletingPathExtension];
                
                if (![self.appIcons objectForKey:appName])
                {
                    appPath = [dir stringByAppendingPathComponent:file];
                    
                    appIcon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
                    [appIcon setSize:NSMakeSize(16, 16)];
                    
                    [self.appIcons setObject:appIcon forKey:appName];
                }
                
                [enumerator skipDescendants];
            }
            else if ([[file pathExtension] isEqualToString:@"framework"] || [[file pathExtension] isEqualToString:@"platform"] || [[file pathExtension] isEqualToString:@"sdk"] ||
                     [file isEqualToString:@"usr"] || [file isEqualToString:@"Library"])
            {
                [enumerator skipDescendants];
            }
        }
    }
}

#pragma mark -
#pragma mark Querying loaded data

- (id <HNLaunchpadEntity>)parentForEntity:(id <HNLaunchpadEntity>)entity
{
    return [self.itemList objectForKey:entity.parentId];
}

/**
 * Finds the highest-level parent (should be a page, in this model)
 */
- (id <HNLaunchpadEntity>)rootParentForEntity:(id <HNLaunchpadEntity>)entity
{
    id <HNLaunchpadEntity> parent = [self parentForEntity:entity];
    
    if (parent != nil)
    {
        id <HNLaunchpadEntity> root = [self rootParentForEntity:parent];
        
        if (root != nil)
        {
            return root;
        }
        else
        {
            return parent;
        }
    }
    else
    {
        return parent;
    }
}

- (NSImage *)iconForEntity:(id <HNLaunchpadEntity>)entity
{
    if ([entity conformsToProtocol:@protocol(HNLaunchpadContainer)])
    {
        return [self.appIcons objectForKey:@"GenericFolderIcon"];
    }
    else if ([entity isKindOfClass:[HNLaunchpadApp class]])
    {
        HNLaunchpadApp *app = (HNLaunchpadApp *)entity;
        NSImage *appIcon = [self.appIcons objectForKey:app.title];
        
        if (appIcon == nil)
        {
            appIcon = [self.appIcons objectForKey:@"GenericApplicationIcon"];
            
            [self.appIcons setObject:appIcon forKey:app.title];
        }
        
        return appIcon;
    }
    else
    {
        [HNException raise:HNInvalidClassException format:@"Unusable class: %@", [entity class]];
        return nil;
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
    
    NSString *sql = @"SELECT max(rowid)"
                        " FROM items";
    
    FMResultSet *results = [db executeQuery:sql];
    
    if (results == nil)
    {
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        return nil;
    }
    
    if ([results next])
    {
        nextId = [NSNumber numberWithInt:([results intForColumnIndex:0] + 1)];
    }
    else
    {
        [HNException raise:HNDatabaseException format:@"No results returned for SQL: %@", sql];
        return nil;
    }
    
    return nextId;
}

- (void)createPage:(HNLaunchpadPage *)page atPosition:(NSUInteger)position inDb:(FMDatabase *)db
{
    [db beginTransaction];
    
    page.id = [self nextIdInDb:db];
    page.parentId = [NSNumber numberWithInt:HNLaunchpadPageParentId];
    
    [self.itemTree insertObject:page forKey:page.id atIndex:position];
    [self.itemList setObject:page forKey:page.id];
    
    NSString *sql = @"INSERT INTO items (rowid, uuid, flags, type, parent_id, ordering) VALUES (?, ?, ?, ?, ?, ?)";
    
    // create new UUID
    CFUUIDRef uuidObj = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObj);
    CFRelease(uuidObj);
    
    page.uuid = uuid;
    
    if (![db executeUpdate:sql, page.id, page.uuid, [NSNumber numberWithInt:HNLaunchpadDefaultFlags], [NSNumber numberWithInt:HNLaunchpadTypePage], page.parentId, [NSNumber numberWithInt:HNLaunchpadDefaultOrdering]])
    {
        [db rollback];
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        [db close];
        return;
    }
    
    sql = @"INSERT INTO groups (item_id) VALUES (?)";
    
    if (![db executeUpdate:sql, page.id])
    {
        [db rollback];
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        [db close];
        return;
    }
    
    [db commit];
}

- (void)createGroup:(HNLaunchpadGroup *)group inPage:(HNLaunchpadPage *)page atPosition:(NSUInteger)position inDb:(FMDatabase *)db
{
    [db beginTransaction];
    
    group.id = [self nextIdInDb:db];
    group.parentId = page.id;
    [page.items insertObject:group forKey:group.id atIndex:position];
    [self.itemList setObject:group forKey:group.id];
    
    NSString *sql = @"INSERT INTO items (rowid, uuid, flags, type, parent_id, ordering) VALUES (?, ?, ?, ?, ?, ?)";
    
    // create new UUID
    CFUUIDRef uuidObj = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObj);
    CFRelease(uuidObj);
    
    group.uuid = uuid;
    
    if (![db executeUpdate:sql, group.id, group.uuid, [NSNumber numberWithInt:HNLaunchpadDefaultFlags], [NSNumber numberWithInt:HNLaunchpadTypeGroup], group.parentId, [NSNumber numberWithInt:HNLaunchpadDefaultOrdering]])
    {
        [db rollback];
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        [db close];
        return;
    }
    
    sql = @"INSERT INTO groups (item_id, title) VALUES (?, ?)";
    
    if (![db executeUpdate:sql, group.id, group.title])
    {
        [db rollback];
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        [db close];
        return;
    }
    
    [db commit];
}

- (void)saveGroup:(HNLaunchpadGroup *)group inDb:(FMDatabase *)db
{
    NSString *sql = @"UPDATE groups"
                        " SET title = ?"
                        " WHERE item_id = ?";
    
    if (![db executeUpdate:sql, group.title, group.id])
    {
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
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
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        [db close];
        return;
    }
}

/**
 * Loops through all of the items in a container, and makes the database ordering match the current MGOrderedDictionary ordering.
 *
 * If container is nil, loops through all of the pages at the root.
 */
- (void)saveContainerOrdering:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db
{
    [self setTriggerDisabled:YES inDb:db];
    
    NSArray *items;
    
    if (container == nil)
    {
        items = [self.itemTree allValues];
    }
    else
    {
        items = [container.items allValues];
    }
    
    int i = 0;
    
    for (id <HNLaunchpadItem> item in [container.items allValues])
    {
        item.ordering = i;
        
        NSString *sql = @"UPDATE items"
                            " SET ordering = ?"
                            " WHERE rowid = ?";
        
        if (![db executeUpdate:sql, [NSNumber numberWithInt:item.ordering], item.id])
        {
            [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
            [self setTriggerDisabled:NO inDb:db];
            [db close];
            return;
        }
        
        i++;
    }
    
    [self setTriggerDisabled:NO inDb:db];
}

- (int)numberOfItemsForContainer:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db
{
    NSString *sql = @"SELECT count(rowid)"
                        " FROM items"
                        " WHERE parent_id = ?";
    
    FMResultSet *results = [db executeQuery:sql, container.id];
    
    if (results == nil)
    {
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        return 0;
    }
    
    if ([results next])
    {
        return [results intForColumnIndex:0];
    }
    else
    {
        [HNException raise:HNDatabaseException format:@"No results returned for SQL: %@", sql];
        return 0;
    }
}

- (void)deleteContainer:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db
{
    if ([self numberOfItemsForContainer:container inDb:db] != 0)
    {
        [HNException raise:NSInternalInconsistencyException format:@"Cannot delete non-empty container"];
    }
    
    NSNumber *containerId = container.id;
    id <HNLaunchpadContainer> parentContainer = (id)[self parentForEntity:container];
    
    [db beginTransaction];
    
    NSString *sql = @"DELETE FROM items WHERE rowid = ?";
    
    if (![db executeUpdate:sql, container.id])
    {
        [db rollback];
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        return;
    }
    
    sql = @"DELETE FROM groups WHERE item_id = ?";
    
    if (![db executeUpdate:sql, container.id])
    {
        [db rollback];
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        return;
    }
    
    [db commit];
    
    container = nil;
    
    if (parentContainer == nil)
    {
        [self.itemTree removeObjectForKey:containerId];
    }
    else
    {
        [parentContainer.items removeObjectForKey:containerId];
    }
    
    [self.itemList removeObjectForKey:containerId];
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
        [HNException raise:HNDatabaseException format:@"%@", [db lastErrorMessage]];
        return;
    }
}

@end

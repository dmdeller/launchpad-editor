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

#import "FMDatabase.h"
#import "FMResultSet.h"

@implementation HNLaunchpadDataSet

static int const TYPE_PAGE = 3;
static int const TYPE_GROUP = 2;

@synthesize pages;
@synthesize containers;

#pragma mark -
#pragma mark Loading data

- (id)init
{
    [self load];
    
    return [super init];
}

- (void)load
{
    [self loadFromFile:[NSString stringWithFormat:@"%@/Desktop/launchpad.db", NSHomeDirectory()]];
}

- (void)loadFromFile:(NSString *)filename
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename])
    {
        [NSException raise:@"Database read error" format:@"Database at path: %@ does not exist", filename];
        return;
    }
    
    FMDatabase *db = [FMDatabase databaseWithPath:filename];
    
    if (![db open])
    {
        [NSException raise:@"Database open error" format:@"Could not open database: %@", filename];
        return;
    }
    
    [self loadPagesFromDb:db];
    [self loadGroupsFromDb:db];
    [self loadAppsFromDb:db];
}

- (void)loadPagesFromDb:(FMDatabase *)db
{
    self.pages = [MGOrderedDictionary dictionaryWithCapacity:10];
    self.containers = [NSMutableDictionary dictionaryWithCapacity:200];
    
    NSString *sql = @"SELECT *"
                        " FROM items i"
                            " JOIN groups g ON i.rowid = g.item_id"
                        " WHERE i.type = ?"
                        " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInt:TYPE_PAGE]];
    
    while ([results next])
    {
        // FIXME: hacky
        if ([[results stringForColumn:@"uuid"] isEqualToString:@"HOLDINGPAGE"])
        {
            continue;
        }
        
        HNLaunchpadPage *page = [[HNLaunchpadPage alloc] init];
        
        page.uuid = [results stringForColumn:@"uuid"];
        page.pageId = [NSNumber numberWithInt:[results intForColumn:@"rowid"]];
        page.items = [MGOrderedDictionary dictionaryWithCapacity:40];
        
        [self.pages setObject:page forKey:page.pageId];
        [self.containers setObject:page forKey:page.pageId];
    }
}

- (void)loadGroupsFromDb:(FMDatabase *)db
{
    NSString *sql = @"SELECT *"
                    " FROM items i"
                        " JOIN groups g ON i.rowid = g.item_id"
                    " WHERE i.type = ?"
                    " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInt:TYPE_GROUP]];
    
    while ([results next])
    {
        HNLaunchpadPage *page = [self.pages objectForKey:[NSNumber numberWithInt:[results intForColumn:@"parent_id"]]];
        if (page == nil)
        {
            [NSException raise:@"Page not found error" format:@"Could not find page: %d for group: %d", [results intForColumn:@"parent_id"], [results intForColumn:@"item_id"]];
            continue;
        }
        
        HNLaunchpadGroup *group = [[HNLaunchpadGroup alloc] init];
        
        group.uuid = [results stringForColumn:@"uuid"];
        group.itemId = [NSNumber numberWithInt:[results intForColumn:@"item_id"]];
        group.parentId = [NSNumber numberWithInt:[results intForColumn:@"parent_id"]];
        group.title = [results stringForColumn:@"title"];
        group.items = [MGOrderedDictionary dictionaryWithCapacity:40];
        
        [page.items setObject:group forKey:group.itemId];
        
        [self.containers setObject:group forKey:group.itemId];
    }
}

- (void)loadAppsFromDb:(FMDatabase *)db
{
    NSString *sql = @"SELECT *"
                    " FROM items i"
                        " JOIN apps a ON i.rowid = a.item_id"
                    " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql];
    
    while ([results next])
    {
        // should properly be HNLaunchpadContainer... but you can't do that in Objective-C
        NSObject *container = [self.containers objectForKey:[NSNumber numberWithInt:[results intForColumn:@"parent_id"]]];
        if (container == nil)
        {
            [NSException raise:@"Page or group not found error" format:@"Could not find page or group: %d for app: %d", [results intForColumn:@"parent_id"], [results intForColumn:@"item_id"]];
            continue;
        }
        
        HNLaunchpadApp *app = [[HNLaunchpadApp alloc] init];
        
        app.uuid = [results stringForColumn:@"uuid"];
        app.itemId = [NSNumber numberWithInt:[results intForColumn:@"item_id"]];
        app.parentId = [NSNumber numberWithInt:[results intForColumn:@"parent_id"]];
        app.title = [results stringForColumn:@"title"];
        
        if ([container isKindOfClass:[HNLaunchpadGroup class]])
        {
            HNLaunchpadGroup *group = (HNLaunchpadGroup *)container;
            
            [group.items setObject:app forKey:app.itemId];
        }
        else if ([container isKindOfClass:[HNLaunchpadPage class]])
        {
            HNLaunchpadPage *page = (HNLaunchpadPage *)container;
            
            [page.items setObject:app forKey:app.itemId];
        }
        else
        {
            [NSException raise:@"Bad type" format:@"Unknown kind of container class: %@", [container class]];
        }
    }
}

#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil)
    {
        return [self.pages count];
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
        [NSException raise:@"Unknown NSOutlineViewDatasource item" format:@"Unknown kind of item"];
        return 0;
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([self outlineView:outlineView numberOfChildrenOfItem:item] > 0)
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
        return [self.pages objectForKey:[self.pages keyAtIndex:index]];
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
        [NSException raise:@"Unknown NSOutlineViewDataSource child" format:@"Item has no children"];
        return nil;
    }
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[HNLaunchpadPage class]])
    {
        HNLaunchpadPage *page = (HNLaunchpadPage *)item;
        
        return @"Page";
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
        [NSException raise:@"Unknown NSOutlineViewDatasource item" format:@"Unknown kind of item"];
        return @"Unknown";
    }
}

@end

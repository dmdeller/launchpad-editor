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
        
        NSLog(@"%@", app);
        
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

@end

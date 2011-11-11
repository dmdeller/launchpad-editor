//
//  HNLaunchpadDataSet.m
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNLaunchpadDataSet.h"

#import "HNLaunchpadPage.h"
#import "HNLaunchpadGroup.h"
#import "HNLaunchpadApp.h"

#import "FMDatabase.h"
#import "FMResultSet.h"

@implementation HNLaunchpadDataSet

@synthesize pages;

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
    
    [self loadPagesWithDb:db];
    [self loadGroupsWithDb:db];
}

- (void)loadPagesWithDb:(FMDatabase *)db
{
    self.pages = [MGOrderedDictionary dictionaryWithCapacity:10];
    
    NSString *sql = @"SELECT *"
                        " FROM items i"
                            " JOIN groups g ON i.rowid = g.item_id"
                        " WHERE i.type = 3" // 3 means 'page'
                        " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql];
    
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
    }
}

- (void)loadGroupsWithDb:(FMDatabase *)db
{
    NSString *sql = @"SELECT *"
                    " FROM items i"
                        " JOIN groups g ON i.rowid = g.item_id"
                    " WHERE i.type = 2" // 3 means 'group'
                    " ORDER BY i.ordering";
    
    FMResultSet *results = [db executeQuery:sql];
    
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
        
        NSLog(@"%@", group);
        
        [page.items setObject:group forKey:group.itemId];
    }
}

@end

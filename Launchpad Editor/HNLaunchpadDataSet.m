//
//  HNLaunchpadDataSet.m
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNLaunchpadDataSet.h"

#import "FMDatabase.h"
#import "FMResultSet.h"

@implementation HNLaunchpadDataSet

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
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM items"];
    
    while ([results next])
    {
        NSLog(@"%@", [results stringForColumn:@"uuid"]);
    }
}

@end

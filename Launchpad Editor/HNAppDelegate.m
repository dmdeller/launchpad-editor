//
//  HNAppDelegate.m
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNAppDelegate.h"
#import "HNLaunchpadDataSet.h"
#import "Constants.h"

#import "FMDatabase.h"

@implementation HNAppDelegate

@synthesize window = _window;
@synthesize outlineView;
@synthesize controller;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
}

/**
 * Determines the filename of the Launchpad database.
 */
- (NSString *)dbFilename
{
    return [NSString stringWithFormat:@"%@/Desktop/launchpad.db", NSHomeDirectory()];
}

/**
 * Opens a database connection and returns it. Don't forget to close it when you're done.
 */
- (FMDatabase *)openDb
{
    NSString *filename = [self dbFilename];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename])
    {
        [NSException raise:@"Database read error" format:@"Database at path: %@ does not exist", filename];
        return nil;
    }
    
    FMDatabase *db = [FMDatabase databaseWithPath:filename];
    
    if (![db open])
    {
        [NSException raise:@"Database open error" format:@"Could not open database: %@", filename];
        return nil;
    }
    
    return db;
}

@end

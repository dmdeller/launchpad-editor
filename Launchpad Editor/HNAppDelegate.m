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
@synthesize dbFilename;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
}

/**
 * Determines the filename of the Launchpad database.
 */
- (NSString *)dbFilename
{
    if (dbFilename)
    {
        return dbFilename;
    }
    
    NSString *dir = [NSString stringWithFormat:@"%@/Library/Application Support/Dock", NSHomeDirectory()];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\\.db$" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&error];
    
    if (error)
    {
        [NSException raise:@"Directory read error" format:@"Unable to read directory: %@, error: %@", dir, error];
    }
    
    NSString *matchFile;
    for (NSString *file in files)
    {
        if ([regex numberOfMatchesInString:file options:0 range:NSMakeRange(0, [file length])] > 0)
        {
            matchFile = file;
            break;
        }
    }
    
    if (matchFile == nil)
    {
        [NSException raise:@"File not found" format:@"No Launchpad database file could be found in directory: %@", dir];
    }
    
    dbFilename = [NSString stringWithFormat:@"%@/%@", dir, matchFile];
    
    return dbFilename;
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

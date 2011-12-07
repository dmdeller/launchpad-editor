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
#import "HNException.h"

#import "FMDatabase.h"

@implementation HNAppDelegate

@synthesize window = _window;
@synthesize toolbarController;
@synthesize outlineView;
@synthesize outlineViewController;
@synthesize dbFilename;

#pragma mark -
#pragma mark Application delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([self shouldMakeDailyBackup])
    {
        [self makeBackup];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Quit & Relaunch Dock"];
    [alert addButtonWithTitle:@"Quit"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Dock needs to be relaunched"];
    [alert setInformativeText:@"The changes you made won't show up in Launchpad until you relaunch the Dock."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(restartDockAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    
    return NSTerminateLater;
}

#pragma mark -
#pragma mark Window delegate


- (BOOL)windowShouldClose:(id)sender
{
    [[NSApplication sharedApplication] terminate:sender];
    
    return NO;
}

#pragma mark -
#pragma mark Dock

- (void)restartDockAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [self restartDock];
    }
    
    if (returnCode == NSAlertFirstButtonReturn || returnCode == NSAlertSecondButtonReturn)
    {
        [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
    }
    else
    {
        [[NSApplication sharedApplication] replyToApplicationShouldTerminate:NO];
    }
}

- (void)restartDock
{
    int returnCode = system("killall Dock");
    
    if (returnCode != 0)
    {
        [HNException raise:@"Unable to kill process" format:@"Error killing Dock process. system() returned code: %i", returnCode];
    }
}

#pragma mark -
#pragma mark Database file management

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
        [HNException raise:@"Directory read error" format:@"Unable to open location: %@\n\n%@", dir, [error localizedFailureReason]];
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
        [HNException raise:@"File not found" format:@"No Launchpad database file could be found in directory: %@", dir];
    }
    
    dbFilename = [NSString stringWithFormat:@"%@/%@", dir, matchFile];
    
    return dbFilename;
}

- (NSString *)backupsPath
{
    return [NSString stringWithFormat:@"%@/Library/Application Support/Dock/Launchpad Editor Backups", NSHomeDirectory()];
}

- (BOOL)shouldMakeDailyBackup
{
    NSString *dir = [self backupsPath];
    NSError *error;
    
    // no backups folder, even? better make one.
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
    {
        return YES;
    }
    
    error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&error];
    
    if (error)
    {
        [HNException raise:@"Directory read error" format:@"Unable to open location: %@\n\n%@", dir, [error localizedFailureReason]];
    }
    
    // loop through all existing backups and see if there is one from today.
    // this is pretty inefficient and could probably be refactored.
    for (NSString *file in files)
    {
        if (![[[file componentsSeparatedByString:@"."] lastObject] isEqualToString:@"backup"])
        {
            continue;
        }
        
        error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@", dir, file] error:&error];
        
        if (error)
        {
            [HNException raise:@"File read error" format:@"Unable to read file attributes: %@/%@\n\n%@", dir, file, [error localizedFailureReason]];
            continue;
        }
        
        NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        
        NSString *nowDateString = [dateFormatter stringFromDate:[NSDate date]];
        NSString *creationDateString = [dateFormatter stringFromDate:creationDate];
        
        // if the backup is from today, no need to make another one.
        if ([nowDateString isEqualToString:creationDateString])
        {
            return NO;
        }
    }
    
    // no backup from today found? better make one.
    return YES;
}

- (void)makeBackup
{
    NSString *dir = [self backupsPath];
    NSError *error;
    
    // create folder if it doesn't exist
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDirectory] || !isDirectory)
    {
        error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error)
        {
            [HNException raise:@"Directory creation error" format:@"Unable to create folder: %@\n\n", dir, [error localizedFailureReason]];
        }
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ssZ"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];

    NSString *newDbFilename = [NSString stringWithFormat:@"%@/%@.%@.auto.backup", dir, [[[self dbFilename] componentsSeparatedByString:@"/"] lastObject], dateString];
    error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:[self dbFilename] toPath:newDbFilename error:&error];
    
    if (error)
    {
        [HNException raise:@"File creation error" format:@"Unable to copy file: %@ to location: %@\n\n%@", [self dbFilename], newDbFilename, [error localizedFailureReason]];
    }
    
    // Set creation date to now, so we can later check when the backup was made
    error = nil;
    [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileCreationDate] ofItemAtPath:newDbFilename error:&error];
    
    if (error)
    {
        [HNException raise:@"File attribute modification error" format:@"Unable to set attributes on file: %@\n\n%@", newDbFilename, [error localizedFailureReason]];
    }
}

/**
 * Opens a database connection and returns it. Don't forget to close it when you're done.
 */
- (FMDatabase *)openDb
{
    NSString *filename = [self dbFilename];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename])
    {
        [HNException raise:@"Database read error" format:@"Database at path: %@ does not exist", filename];
        return nil;
    }
    
    FMDatabase *db = [FMDatabase databaseWithPath:filename];
    
    if (![db open])
    {
        [HNException raise:@"Database open error" format:@"Could not open database: %@", filename];
        return nil;
    }
    
    return db;
}

@end

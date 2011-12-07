//
//  HNAppDelegate.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HNLaunchpadController;

@class FMDatabase;

@interface HNAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet HNLaunchpadController *controller;
@property (strong, nonatomic, readonly) NSString *dbFilename;

- (void)restartDockAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)restartDock;

- (NSString *)backupsPath;
- (BOOL)shouldMakeDailyBackup;
- (void)makeBackup;
- (FMDatabase *)openDb;


@end

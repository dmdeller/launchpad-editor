//
//  HNAppDelegate.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HNToolbarController;
@class HNOutlineViewController;
@class HNLaunchpadDataSet;

@class FMDatabase;

@interface HNAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet HNToolbarController *toolbarController;
@property (strong) IBOutlet HNOutlineViewController *outlineViewController;
@property (strong, nonatomic, readonly) NSString *dbFilename;
@property (strong) HNLaunchpadDataSet *dataSet;

- (void)restartDockAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)restartDock;

- (NSString *)backupsPath;
- (BOOL)shouldMakeDailyBackup;
- (void)makeBackup;
- (FMDatabase *)openDb;


@end

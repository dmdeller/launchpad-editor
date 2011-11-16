//
//  HNAppDelegate.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HNLaunchpadDataSet;
@class HNLaunchpadDataDelegate;

@interface HNAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSOutlineView *dataOutline;
@property (retain) IBOutlet HNLaunchpadDataSet *dataSet;
@property (strong) IBOutlet HNLaunchpadDataDelegate *dataDelegate;

@end

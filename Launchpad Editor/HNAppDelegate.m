//
//  HNAppDelegate.m
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HNAppDelegate.h"
#import "HNLaunchpadDataSet.h"
#import "HNLaunchpadPasteboardType.h"

@implementation HNAppDelegate

@synthesize window = _window;
@synthesize outlineView;
@synthesize dataSet;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.outlineView registerForDraggedTypes:[NSArray arrayWithObject:HNLaunchpadPasteboardType]];
}

@end

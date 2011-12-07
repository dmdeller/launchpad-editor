//
//  HNToolbarController.h
//  Launchpad Editor
//
//  Created by David Deller on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HNAppDelegate;

@interface HNToolbarController : NSObject

@property (weak) IBOutlet HNAppDelegate *appDelegate;
@property (strong) IBOutlet NSToolbarItem *addGroupButton;
@property (strong) IBOutlet NSToolbarItem *syncButton;

- (void)addGroup;
- (void)confirmSync;

@end

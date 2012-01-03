//
//  HNToolbarController.h
//  Launchpad Editor
//
//  Created by David Deller on 12/7/11.
//  Copyright (c) 2011 D.M.Deller. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HNAppDelegate;

@interface HNToolbarController : NSObject

@property (weak) IBOutlet HNAppDelegate *appDelegate;
@property (strong) IBOutlet NSToolbarItem *addPageButton;
@property (strong) IBOutlet NSToolbarItem *addGroupButton;
@property (strong) IBOutlet NSToolbarItem *deleteButton;
@property (strong) IBOutlet NSToolbarItem *syncButton;
@property (strong) IBOutlet NSToolbarItem *revealDataButton;

- (void)addPage;
- (void)addGroup;
- (void)delete;
- (void)confirmSync;
- (void)revealData;

@end

//
//  HNLaunchpadDataSet.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MGOrderedDictionary.h"

@class FMDatabase;

@protocol HNLaunchpadEntity;
@protocol HNLaunchpadItem;
@protocol HNLaunchpadContainer;

@class HNLaunchpadGroup;
@class HNLaunchpadApp;

@interface HNLaunchpadDataSet : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (retain) MGOrderedDictionary *itemTree;
@property (strong) NSMutableDictionary *itemList;

- (void)load;
- (NSString *)dbFilename;
- (FMDatabase *)db;

- (MGOrderedDictionary *)loadPagesFromDb:(FMDatabase *)db;
- (NSDictionary *)loadGroupsFromDb:(FMDatabase *)db;
- (NSDictionary *)loadAppsFromDb:(FMDatabase *)db;
- (void)collateApps:(NSDictionary *)apps andGroups:(NSDictionary *)groups intoPages:(MGOrderedDictionary *)pages fromDb:(FMDatabase *)db;

- (void)saveGroup:(HNLaunchpadGroup *)group inDb:(FMDatabase *)db;
- (void)saveApp:(HNLaunchpadApp *)app inDb:(FMDatabase *)db;
- (void)saveContainerOrdering:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db;
- (void)setTriggerDisabled:(BOOL)isDisabled inDb:(FMDatabase *)db;

@end

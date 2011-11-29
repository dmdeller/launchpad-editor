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

@interface HNLaunchpadDataSet : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (retain) MGOrderedDictionary *itemTree;
@property (strong) NSMutableDictionary *itemList;
@property (strong) IBOutlet NSOutlineView *outlineView;

- (void)load;
- (NSString *)dbFilename;
- (FMDatabase *)db;

- (MGOrderedDictionary *)loadPagesFromDb:(FMDatabase *)db;
- (NSDictionary *)loadGroupsFromDb:(FMDatabase *)db;
- (NSDictionary *)loadAppsFromDb:(FMDatabase *)db;
- (void)collateApps:(NSDictionary *)apps andGroups:(NSDictionary *)groups intoPages:(MGOrderedDictionary *)pages fromDb:(FMDatabase *)db;

@end

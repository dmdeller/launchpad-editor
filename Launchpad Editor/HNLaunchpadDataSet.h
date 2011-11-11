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

@interface HNLaunchpadDataSet : NSObject <NSOutlineViewDataSource>

@property (retain) MGOrderedDictionary *pages;
@property (retain) NSMutableDictionary *containers;

- (void)load;
- (void)loadFromFile:(NSString *)filename;
- (void)loadPagesFromDb:(FMDatabase *)db;
- (void)loadGroupsFromDb:(FMDatabase *)db;
- (void)loadAppsFromDb:(FMDatabase *)db;

@end

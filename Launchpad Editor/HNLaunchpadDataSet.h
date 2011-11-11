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

@interface HNLaunchpadDataSet : NSObject

@property (retain) MGOrderedDictionary *pages;
@property (retain) NSMutableDictionary *containers;

- (void)load;
- (void)loadFromFile:(NSString *)filename;
- (void)loadPagesWithDb:(FMDatabase *)db;
- (void)loadGroupsWithDb:(FMDatabase *)db;
- (void)loadAppsWithDb:(FMDatabase *)db;

@end

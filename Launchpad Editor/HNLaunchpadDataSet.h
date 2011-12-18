//
//  HNLaunchpadDataSet.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 D.M.Deller. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MGOrderedDictionary.h"

@class FMDatabase;

@protocol HNLaunchpadEntity;
@protocol HNLaunchpadItem;
@protocol HNLaunchpadContainer;

@class HNLaunchpadPage;
@class HNLaunchpadGroup;
@class HNLaunchpadApp;

@interface HNLaunchpadDataSet : NSObject

@property (strong) MGOrderedDictionary *itemTree;
@property (strong) NSMutableDictionary *itemList;
@property (strong) NSMutableDictionary *appIcons;
@property (assign) BOOL isLoaded;

- (void)loadFromDb:(FMDatabase *)db;

- (MGOrderedDictionary *)loadPagesFromDb:(FMDatabase *)db;
- (NSDictionary *)loadGroupsFromDb:(FMDatabase *)db;
- (NSDictionary *)loadAppsFromDb:(FMDatabase *)db;
- (void)collateApps:(NSDictionary *)apps andGroups:(NSDictionary *)groups intoPages:(MGOrderedDictionary *)pages fromDb:(FMDatabase *)db;
- (void)loadAppIcons;

- (id <HNLaunchpadEntity>)parentForEntity:(id <HNLaunchpadEntity>)entity;
- (id <HNLaunchpadEntity>)rootParentForEntity:(id <HNLaunchpadEntity>)entity;
- (NSImage *)iconForEntity:(id <HNLaunchpadEntity>)entity;

- (NSNumber *)nextIdInDb:(FMDatabase *)db;
- (void)createPage:(HNLaunchpadPage *)page atPosition:(NSUInteger)position inDb:(FMDatabase *)db;
- (void)createGroup:(HNLaunchpadGroup *)group inPage:(HNLaunchpadPage *)page atPosition:(NSUInteger)position inDb:(FMDatabase *)db;
- (void)saveGroup:(HNLaunchpadGroup *)group inDb:(FMDatabase *)db;
- (void)saveEntity:(id <HNLaunchpadEntity>)entity inDb:(FMDatabase *)db;
- (void)saveContainerOrdering:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db;
- (int)numberOfItemsForContainer:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db;
- (void)deleteContainer:(id <HNLaunchpadContainer>)container inDb:(FMDatabase *)db;
- (void)setTriggerDisabled:(BOOL)isDisabled inDb:(FMDatabase *)db;

@end

//
//  HNOutlineViewController.h
//  Launchpad Editor
//
//  Created by David Deller on 12/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HNLaunchpadEntity;
@protocol HNLaunchpadContainer;

@class HNAppDelegate;
@class HNLaunchpadDataSet;
@class HNLaunchpadGroup;

@class FMDatabase;

@interface HNOutlineViewController : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet HNAppDelegate *appDelegate;
@property (strong) HNLaunchpadDataSet *dataSet;

@end

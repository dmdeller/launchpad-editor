//
//  HNLaunchpadGroup.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HNLaunchpadItem.h"

@interface HNLaunchpadGroup : NSObject <HNLaunchpadItem>

@property (retain) NSMutableArray *items;

@end

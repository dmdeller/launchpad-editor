//
//  HNLaunchpadContainer.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HNLaunchpadEntity.h"

#import "MGOrderedDictionary.h"

/**
 * A Container is an Entity that contains Items.
 */
@protocol HNLaunchpadContainer <HNLaunchpadEntity>

@property (strong) MGOrderedDictionary *items;

@end

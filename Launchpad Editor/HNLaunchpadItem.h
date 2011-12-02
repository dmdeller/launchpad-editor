//
//  HNLaunchpadItem.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HNLaunchpadEntity.h"

/**
 * An Item is an Entity that the user directly interacts with.
 */
@protocol HNLaunchpadItem <HNLaunchpadEntity>

@property (retain) NSString *title;

@end

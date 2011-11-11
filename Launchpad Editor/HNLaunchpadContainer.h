//
//  HNLaunchpadContainer.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MGOrderedDictionary.h"

@protocol HNLaunchpadContainer <NSObject>

@property (retain) MGOrderedDictionary *items;

@end

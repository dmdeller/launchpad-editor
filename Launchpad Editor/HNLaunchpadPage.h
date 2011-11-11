//
//  HNLaunchpadPage.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MGOrderedDictionary.h"

@interface HNLaunchpadPage : NSObject

@property (retain) NSString *uuid;
@property (retain) NSNumber *pageId;
@property (retain) MGOrderedDictionary *items;

@end

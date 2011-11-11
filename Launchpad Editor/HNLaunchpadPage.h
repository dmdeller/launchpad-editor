//
//  HNLaunchpadPage.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MGOrderedDictionary.h"

#import "HNLaunchpadContainer.h"

@interface HNLaunchpadPage : NSObject <HNLaunchpadContainer>

@property (retain) NSString *uuid;
@property (retain) NSNumber *pageId;

@end

//
//  HNLaunchpadItem.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HNLaunchpadItem <NSObject>

@property (retain) NSString *uuid;
@property (retain) NSNumber *itemId;
@property (retain) NSNumber *parentId;
@property (retain) NSString *title;

@end

//
//  HNLaunchpadGroup.m
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 D.M.Deller. All rights reserved.
//

#import "HNLaunchpadGroup.h"

@implementation HNLaunchpadGroup

@synthesize uuid;
@synthesize id;
@synthesize ordering;
@synthesize parentId;
@synthesize title;
@synthesize items;

- (id)init
{
    if ((self = [super init]))
    {
        self.items = [MGOrderedDictionary dictionaryWithCapacity:40];
    }
    
    return self;
}

@end

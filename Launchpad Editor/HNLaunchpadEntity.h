//
//  HNLaunchpadEntity.h
//  Launchpad Editor
//
//  Created by David Deller on 11/29/11.
//  Copyright (c) 2011 D.M.Deller. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * An Entity is any kind of object that represents a row in the database.
 */
@protocol HNLaunchpadEntity <NSObject>

@property (strong) NSNumber *id;
@property (strong) NSString *uuid;
@property (strong) NSNumber *parentId;
@property (assign) int ordering;

@end

//
//  HNLaunchpadDataSet.h
//  Launchpad Editor
//
//  Created by David Deller on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HNLaunchpadDataSet : NSObject

- (void)load;
- (void)loadFromFile:(NSString *)filename;

@end

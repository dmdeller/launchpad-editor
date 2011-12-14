//
//  OrderedDictionary.h
//  OrderedDictionary
//
//  Created by Matt Gallagher on 19/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//
//  http://cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html
//

NSString *DescriptionForObject(NSObject *object, id locale, NSUInteger indent);

@interface MGOrderedDictionary : NSMutableDictionary
{
	NSMutableDictionary *dictionary;
	NSMutableArray *array;
}

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex;
- (id)keyAtIndex:(NSUInteger)anIndex;
- (NSEnumerator *)reverseKeyEnumerator;

/**
 * Added by D.M.Deller
 */
- (NSUInteger)indexForKey:(id)key;

@end

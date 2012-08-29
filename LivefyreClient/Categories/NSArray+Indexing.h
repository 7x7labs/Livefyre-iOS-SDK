//
//  NSArray+NSArray_Indexing.h
//  Smile
//
//  Created by Thomas Goyne on 7/30/12.
//

#import <Foundation/Foundation.h>

@interface NSArray (Indexing)
- (id)objectAtIndexedSubscript:(NSUInteger)index;
@end

@interface NSMutableArray (Indexing)
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
@end

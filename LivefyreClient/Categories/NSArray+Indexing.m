//
//  NSArray+NSArray_Indexing.m
//  Smile
//
//  Created by Thomas Goyne on 7/30/12.
//
//

#import "NSArray+Indexing.h"

@implementation NSArray (Indexing)
- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}
@end

@implementation NSMutableArray (Indexing)
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index {
    [self replaceObjectAtIndex:index withObject:object];
}
@end

//
//  NSDictionary+Indexing.m
//  Smile
//
//  Created by Thomas Goyne on 7/30/12.
//

#import "NSDictionary+Indexing.h"

@implementation  NSDictionary (Indexing)
- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}
@end

@implementation  NSMutableDictionary (Indexing)
- (void)setObject:(id)object forKeyedSubscript:(id)key {
    [self setObject:object forKey:key];
}
@end

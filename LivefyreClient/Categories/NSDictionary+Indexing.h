//
//  NSDictionary+Indexing.h
//  Smile
//
//  Created by Thomas Goyne on 7/30/12.
//

#import <Foundation/Foundation.h>

@interface  NSDictionary (Indexing)
- (id)objectForKeyedSubscript:(id)key;
@end

@interface  NSMutableDictionary (Indexing)
- (void)setObject:(id)object forKeyedSubscript:(id)key;
@end

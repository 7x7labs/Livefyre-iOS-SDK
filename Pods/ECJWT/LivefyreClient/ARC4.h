//
//  ARC4.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARC4 : NSObject
+ (NSString *)decrypt:(NSString *)string withKey:(NSString *)key;
@end

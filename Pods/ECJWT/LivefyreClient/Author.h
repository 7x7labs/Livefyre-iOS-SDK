//
//  Author.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Author : NSObject
@property (strong, nonatomic) NSString *authorId;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSString *profileUrl;
@property (strong, nonatomic) NSString *avatarUrl;

+ (Author *)authorWithDictionary:(NSDictionary *)authorData;
@end

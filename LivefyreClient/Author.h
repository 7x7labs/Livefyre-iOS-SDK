//
//  Author.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

/// The author of an entry in a collection.
@interface Author : NSObject
/// The Livefyre author ID, which may not be the same as the user ID used to
/// log in.
@property (strong, nonatomic) NSString *authorId;
/// The user's displayed name.
@property (strong, nonatomic) NSString *displayName;
/// The URL of the user's public profile, or nil if not applicable.
@property (strong, nonatomic) NSString *profileUrl;
/// The URL of the user's avatar, or nil if the user has none.
@property (strong, nonatomic) NSString *avatarUrl;

+ (Author *)authorPlaceholder:(NSString *)authorId;

- (void)setTo:(NSDictionary *)authorData;
@end

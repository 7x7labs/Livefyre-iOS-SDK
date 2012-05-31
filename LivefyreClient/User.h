//
//  User.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Entry;

@interface User : NSObject
@property (strong, nonatomic, readonly) NSString *userId;
@property (strong, nonatomic, readonly) NSString *displayName;
@property (strong, nonatomic, readonly) NSString *settingsUrl;
@property (strong, nonatomic, readonly) NSString *profileUrl;
@property (strong, nonatomic, readonly) NSString *avatarUrl;
@property (strong, nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) BOOL isModerator;

+ (User *)userWithDictionary:(NSDictionary *)userData;

- (NSString *)tryToDecodeEref:(NSString *)eref;
- (BOOL)canViewEntry:(Entry *)entry;
@end

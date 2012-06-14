//
//  User.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Content;

/// A logged-in User.
///
/// Instances of this class are created through LivefyreClient. See the
/// following methods:
///
/// * -[LivefyreClient authenticateUser:forCollection:gotUser:]
/// * -[LivefyreClient authenticateUser:forSite:forArticle:gotUser:]
/// * -[LivefyreClient authenticateUserWithToken:forCollection:gotUser:]
/// * -[LivefyreClient authenticateUserWithToken:forSite:forArticle:gotUser:]
@interface User : NSObject
/// The Livefyre user ID. May not be the same as the user ID used to log in.
@property (strong, nonatomic, readonly) NSString *userId;
/// The user's publicly displayed name.
@property (strong, nonatomic, readonly) NSString *displayName;
/// The URL for the user's control panel to customize their profile, or `nil`
/// if not applicable.
@property (strong, nonatomic, readonly) NSString *settingsUrl;
/// The URL for the user's public profile, or `nil` if not applicable.
@property (strong, nonatomic, readonly) NSString *profileUrl;
/// The URL for the user's avatar image, or `nil` if not applicable.
@property (strong, nonatomic, readonly) NSString *avatarUrl;
/// The user's Livefyre authentication token. Usually should not need to be
/// used directly.
@property (strong, nonatomic, readonly) NSString *token;
/// Is this user a moderator for the collection they were authenticated for?
@property (nonatomic, readonly) BOOL isModerator;

+ (User *)userWithDictionary:(NSDictionary *)userData;

- (NSString *)tryToDecodeEref:(NSString *)eref;
- (BOOL)canViewContent:(Content *)content;
@end

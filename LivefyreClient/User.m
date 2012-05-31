//
//  User.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "User.h"

#import "ARC4.h"
#import "Author.h"
#import "Entry.h"

@interface User ()
@property (strong, nonatomic) NSMutableArray *decryptionKeys;
@end

@implementation User
@synthesize userId = userId_;
@synthesize displayName = displayName_;
@synthesize settingsUrl = settingsUrl_;
@synthesize profileUrl = profileUrl_;
@synthesize avatarUrl = avatarUrl_;
@synthesize token = token_;
@synthesize isModerator = isModerator_;

@synthesize decryptionKeys = decryptionKeys_;

+ (User *)userWithDictionary:(NSDictionary *)userData {
    if (!userData || [userData count] <= 1)
        return nil;

    NSDictionary *profile = [userData objectForKey:@"profile"];
    NSDictionary *permissions = [userData objectForKey:@"permissions"];

    User *user = [[User alloc] init];
    user->userId_ = [profile objectForKey:@"id"];
    user->displayName_ = [profile objectForKey:@"displayName"];
    user->settingsUrl_ = [profile objectForKey:@"settingsUrl"];
    user->profileUrl_ = [profile objectForKey:@"profileUrl"];
    user->avatarUrl_ = [profile objectForKey:@"avatar"];
    user->token_ = [userData objectForKey:@"token"];

    user.decryptionKeys = [[NSMutableArray alloc] init];

    id moderatorKey = [permissions objectForKey:@"moderator_key"];
    if ([moderatorKey length]) {
        [user.decryptionKeys addObject:moderatorKey];
        user->isModerator_ = YES;
    }

    for (NSDictionary *author in [permissions objectForKey:@"authors"]) {
        // erefs don't contain the author id so don't bother storing the id this
        // key goes with
        [user.decryptionKeys addObject:[author objectForKey:@"key"]];
    }

    return user;
}

- (NSString *)tryToDecodeEref:(NSString *)eref {
    for (NSString *key in self.decryptionKeys) {
        NSString *decryptedPath = [ARC4 decrypt:eref withKey:key];
        if ([decryptedPath hasPrefix:@"eref://"])
            return decryptedPath;
    }
    return nil;
}

- (BOOL)canViewEntry:(Entry *)entry {
    switch (entry.visibility) {
        case ContentVisibilityNone:
            return NO;
        case ContentVisibilityEveryone:
            return YES;
        case ContentVisibilityOwner:
            return [entry.author.authorId isEqualToString:self.userId];
        case ContentVisibilityGroup:
            return self.isModerator || [entry.author.authorId isEqualToString:self.userId];
        default:
            // error?
            return NO;
    }
}
@end

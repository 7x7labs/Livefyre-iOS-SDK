//
//  Author.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Author.h"

#import "User.h"

@interface Author()
@property (strong, nonatomic) NSString *authorId;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSString *profileUrl;
@property (strong, nonatomic) NSString *avatarUrl;
@property (nonatomic) BOOL placeholder;
@end

@implementation Author
@synthesize authorId = authorId_;
@synthesize displayName = displayName_;
@synthesize profileUrl = profileUrl_;
@synthesize avatarUrl = avatarUrl_;
@synthesize placeholder = placeholder_;

+ (Author *)authorPlaceholder:(NSString *)authorId {
    Author *ret = [[Author alloc] init];
    ret.placeholder = YES;
    ret.authorId = authorId;
    return ret;
}

- (void)setTo:(NSDictionary *)authorData {
    if (self.placeholder) {
        self.authorId = [authorData objectForKey:@"id"];
        self.displayName = [authorData objectForKey:@"displayName"];
        self.profileUrl = [authorData objectForKey:@"profileUrl"];
        self.avatarUrl = [authorData objectForKey:@"avatar"];
        self.placeholder = NO;
    }
}

- (void)setToUser:(User *)user {
    if (self.placeholder) {
        self.authorId = user.userId;
        self.displayName = user.displayName;
        self.profileUrl = user.profileUrl;
        self.avatarUrl = user.avatarUrl;
        self.placeholder = NO;
    }
}

@end

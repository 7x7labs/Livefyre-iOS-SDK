//
//  Author.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Author.h"

@implementation Author {
    BOOL placeholder;
}

@synthesize authorId = authorId_;
@synthesize displayName = displayName_;
@synthesize profileUrl = profileUrl_;
@synthesize avatarUrl = avatarUrl_;

+ (Author *)authorPlaceholder:(NSString *)authorId {
    Author *ret = [[Author alloc] init];
    ret->placeholder = YES;
    ret.authorId = authorId;
    return ret;
}

- (void)setTo:(NSDictionary *)authorData {
    if (placeholder) {
        self.authorId = [authorData objectForKey:@"id"];
        self.displayName = [authorData objectForKey:@"displayName"];
        self.profileUrl = [authorData objectForKey:@"profileUrl"];
        self.avatarUrl = [authorData objectForKey:@"avatar"];
        placeholder = NO;
    }
}
@end

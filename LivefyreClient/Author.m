//
//  Author.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Author.h"

@implementation Author
@synthesize authorId = authorId_;
@synthesize displayName = displayName_;
@synthesize profileUrl = profileUrl_;
@synthesize avatarUrl = avatarUrl_;

+ (Author *)authorWithDictionary:(NSDictionary *)authorData {
    Author *ret = [[Author alloc] init];
    ret.authorId = [authorData objectForKey:@"id"];
    ret.displayName = [authorData objectForKey:@"displayName"];
    ret.profileUrl = [authorData objectForKey:@"profileUrl"];
    ret.avatarUrl = [authorData objectForKey:@"avatar"];
    return ret;
}
@end

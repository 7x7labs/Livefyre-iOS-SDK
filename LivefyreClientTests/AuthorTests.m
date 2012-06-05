//
//  AuthorTests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "AuthorTests.h"

#import "Author.h"

@implementation AuthorTests
-(void)testAuthor {
    Author *author = [Author authorPlaceholder:@"id"];
    [author setTo:[NSDictionary dictionaryWithObjectsAndKeys:
                   @"author id", @"id",
                   @"profile url", @"profileUrl",
                   @"display name", @"displayName",
                   @"avatar", @"avatar",
                   nil]];

    STAssertEqualObjects(author.authorId, @"author id", nil);
    STAssertEqualObjects(author.profileUrl, @"profile url", nil);
    STAssertEqualObjects(author.displayName, @"display name", nil);
    STAssertEqualObjects(author.avatarUrl, @"avatar", nil);
}
@end

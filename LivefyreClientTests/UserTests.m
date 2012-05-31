//
//  UserTests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "UserTests.h"

#import "Author.h"
#import "Entry.h"
#import "JSONKit.h"
#import "User.h"

@interface MockAuthor : NSObject
@property (strong, nonatomic) NSString *authorId;
@end

@implementation MockAuthor
@synthesize authorId;
@end

@interface MockEntry : NSObject
@property (strong, nonatomic) MockAuthor *author;
@property (nonatomic) enum ContentVisibility visibility;
@end

@implementation MockEntry
@synthesize author;
@synthesize visibility;

+ (id)entryWithAuthorId:(NSString *)authorId visbility:(enum ContentVisibility)visibility {
    MockEntry *entry = [[MockEntry alloc] init];
    entry.author = [[MockAuthor alloc] init];
    entry.author.authorId = authorId;
    entry.visibility = visibility;
    return entry;
}
@end

@implementation UserTests
- (void)testConstruction {
    NSString *userJson = @"{\"profile\":{\"profileUrl\":\"http://admin.t405.livefyre.com/profile/5011/\",\"settingsUrl\":\"http://admin.t405.livefyre.com/profile/edit/info\",\"displayName\":\"ben\",\"avatar\":\"http://livefyre-avatar.s3.amazonaws.com/a/1/d627b1ba3fce6ab0af872ed3d65278fd/50.jpg\",\"id\":\"_u2012@livefyre.com\"},\"isModAnywhere\":true,\"version\":\"00001\",\"token\":\"eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJkb21haW4iOiAibGl2ZWZ5cmUuY29tIiwgImV4cGlyZXMiOiAxMzM4MDI5MjQ5LjE1NDE0NCwgInVzZXJfaWQiOiAiX3UyMDEyIn0.21b5y_Q7PyH2EubLtEE7Wu4K7oHKExX4wPs1KBzRXGQ\",\"permissions\":{\"moderator_key\":\"c6da4b1d248e07dc534da83691f74676490f591b\",\"authors\":[{\"id\":\"_u2012@livefyre.com\",\"key\":\"38177f6dd07f3928f078a20401e5090b686ee280\"}]}}";

    User *user = [User userWithDictionary:[userJson objectFromJSONString]];
    STAssertEqualObjects(user.userId, @"_u2012@livefyre.com", nil);
    STAssertEqualObjects(user.displayName, @"ben", nil);
    STAssertEqualObjects(user.profileUrl, @"http://admin.t405.livefyre.com/profile/5011/", nil);
    STAssertEqualObjects(user.settingsUrl, @"http://admin.t405.livefyre.com/profile/edit/info", nil);
    STAssertEqualObjects(user.avatarUrl, @"http://livefyre-avatar.s3.amazonaws.com/a/1/d627b1ba3fce6ab0af872ed3d65278fd/50.jpg", nil);
    STAssertEqualObjects(user.token, @"eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJkb21haW4iOiAibGl2ZWZ5cmUuY29tIiwgImV4cGlyZXMiOiAxMzM4MDI5MjQ5LjE1NDE0NCwgInVzZXJfaWQiOiAiX3UyMDEyIn0.21b5y_Q7PyH2EubLtEE7Wu4K7oHKExX4wPs1KBzRXGQ", nil);
    STAssertEquals(user.isModerator, YES, nil);
}

- (void)testCanViewEntry {
    NSString *modUserJson = @"{\"profile\":{\"id\":\"mod user\"},\"permissions\":{\"moderator_key\":\"c6da4b1d248e07dc534da83691f74676490f591b\"}}";
    NSString *nonModUserJson = @"{\"profile\":{\"id\":\"non mod user\"},\"permissions\":{}}";

    User *modUser = [User userWithDictionary:[modUserJson objectFromJSONString]];
    User *nonModUser = [User userWithDictionary:[nonModUserJson objectFromJSONString]];

    id visibleToNone = [MockEntry entryWithAuthorId:@"" visbility:ContentVisibilityNone];
    id visibleToAll = [MockEntry entryWithAuthorId:@"" visbility:ContentVisibilityEveryone];
    id visibleToModUser = [MockEntry entryWithAuthorId:@"mod user" visbility:ContentVisibilityOwner];
    id visibleToNonModUser = [MockEntry entryWithAuthorId:@"non mod user" visbility:ContentVisibilityOwner];
    id visibleToOtherUser = [MockEntry entryWithAuthorId:@"other user" visbility:ContentVisibilityOwner];
    id visibleToModsAndNonModUser = [MockEntry entryWithAuthorId:@"non mod user" visbility:ContentVisibilityGroup];
    id visibleToModsAndOtherUser = [MockEntry entryWithAuthorId:@"other user" visbility:ContentVisibilityGroup];

    STAssertEquals([modUser canViewEntry:visibleToNone], NO, nil);
    STAssertEquals([modUser canViewEntry:visibleToAll], YES, nil);
    STAssertEquals([modUser canViewEntry:visibleToModUser], YES, nil);
    STAssertEquals([modUser canViewEntry:visibleToNonModUser], NO, nil);
    STAssertEquals([modUser canViewEntry:visibleToOtherUser], NO, nil);
    STAssertEquals([modUser canViewEntry:visibleToModsAndNonModUser], YES, nil);
    STAssertEquals([modUser canViewEntry:visibleToModsAndOtherUser], YES, nil);

    STAssertEquals([nonModUser canViewEntry:visibleToNone], NO, nil);
    STAssertEquals([nonModUser canViewEntry:visibleToAll], YES, nil);
    STAssertEquals([nonModUser canViewEntry:visibleToModUser], NO, nil);
    STAssertEquals([nonModUser canViewEntry:visibleToNonModUser], YES, nil);
    STAssertEquals([nonModUser canViewEntry:visibleToOtherUser], NO, nil);
    STAssertEquals([nonModUser canViewEntry:visibleToModsAndNonModUser], YES, nil);
    STAssertEquals([nonModUser canViewEntry:visibleToModsAndOtherUser], NO, nil);
}

- (void)testEref {
    // key is "secret key"
    NSString *modUserJson = @"{\"profile\":{\"id\":\"mod user\"},\"permissions\":{\"moderator_key\":\"736563726574206B6579\"}}";

    User *modUser = [User userWithDictionary:[modUserJson objectFromJSONString]];

    NSString *notAnEref = @"0286D0DC1853370C1B0938"; // "not an eref"
    NSString *vaildEref = @"099BC19A4312381A1D1938DB"; // "eref://stuff"
    NSString *differentKey = @"6CB331EEB7D1881E647D5579"; // "eref://stuff" with "another key"

    STAssertNil([modUser tryToDecodeEref:notAnEref], nil);
    STAssertEqualObjects([modUser tryToDecodeEref:vaildEref], @"eref://stuff", nil);
    STAssertNil([modUser tryToDecodeEref:differentKey], nil);

    // first two keys are gibberish, third is "another key"
    NSString *authorsJson = @"{\"profile\":{\"id\":\"another user\"},\"permissions\":{\"authors\":[{\"key\":\"38177f6dd07f3928f078a20401e5090b686ee280\"},{\"key\":\"sdkfgljdhgfjkhsdgfa\"},{\"key\":\"616e6f74686572206b6579\"}]}}";

    User *userWithAuthors = [User userWithDictionary:[authorsJson objectFromJSONString]];

    STAssertNil([userWithAuthors tryToDecodeEref:notAnEref], nil);
    STAssertNil([userWithAuthors tryToDecodeEref:vaildEref], nil);
    STAssertEqualObjects([userWithAuthors tryToDecodeEref:differentKey], @"eref://stuff", nil);
}

@end

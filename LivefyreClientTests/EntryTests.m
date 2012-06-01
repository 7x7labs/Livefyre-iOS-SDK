//
//  EntryTests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "EntryTests.h"

#import "Author.h"
#import "Entry.h"
#import "JSONKit.h"

@interface AuthorLookup : NSObject<AuthorLookup>
- (Author *)authorForId:(NSString *)authorId;
@end

@implementation AuthorLookup {
    Author *author;
}
- (Author *)authorForId:(NSString *)authorId {
    if (!author) {
        author = [Author authorWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                               @"author id", @"id",
                                               @"profile url", @"profileUrl",
                                               @"display name", @"displayName",
                                               @"avatar", @"avatar",
                                               nil]];
    }
    if ([author.authorId isEqualToString:authorId])
        return author;
    return nil;
}
@end

@implementation EntryTests
- (void)testPostConstruction {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *postJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"<p>I love portobellos.</p>\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"23788087\",\"createdAt\":1336604424},\"childContent\":[],\"source\":5,\"type\":0,\"event\":1336604424890719}";
    Entry *entry = [Entry entryWithDictionary:[postJson objectFromJSONString] authorsFrom:authorLookup];

    STAssertNotNil(entry, nil);
    STAssertTrue([entry isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(entry.entryId, @"23788087", nil);
    STAssertEquals(entry.author, [authorLookup authorForId:@"author id"], nil);
    STAssertEquals(entry.createdAt, 1336604424, nil);
    STAssertEquals(entry.source, 5, nil);
    STAssertEquals(entry.contentType, ContentTypeMessage, nil);
    STAssertEquals(entry.visibility, ContentVisibilityEveryone, nil);
    STAssertNil(entry.replaces, nil);
    STAssertNil(entry.parentId, nil);

    Post *post = (Post *)entry;
    STAssertEqualObjects(post.body, @"<p>I love portobellos.</p>", nil);
    STAssertEquals(post.authorPermissions, PermissionsNone, nil);
    STAssertEquals(post.permissionScope, PermissionScopeGlobal, nil);
    STAssertNotNil(post.children, nil);
    STAssertEquals([post.children count], 0u, nil);
    STAssertNotNil(post.embed, nil);
    STAssertEquals([post.embed count], 0u, nil);
}

- (void)testPostBadValues {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *badContentTypeJson = @"{\"vis\":8,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"<p>I love portobellos.</p>\",\"authorId\":\"-\",\"parentId\":\"\",\"permissionScope\":8,\"authorPermission\":8,\"id\":\"23788087\",\"createdAt\":1336604424},\"childContent\":[],\"source\":9,\"type\":8,\"event\":1336604424890719}";
    Entry *entry = [Entry entryWithDictionary:[badContentTypeJson objectFromJSONString] authorsFrom:authorLookup];
    STAssertNil(entry, nil);

    NSString *postJson = @"{\"vis\":8,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"<p>I love portobellos.</p>\",\"authorId\":\"-\",\"parentId\":\"\",\"permissionScope\":8,\"authorPermission\":8,\"id\":\"23788087\",\"createdAt\":1336604424},\"childContent\":[],\"source\":9,\"type\":0,\"event\":1336604424890719}";
    entry = [Entry entryWithDictionary:[postJson objectFromJSONString] authorsFrom:authorLookup];

    STAssertNotNil(entry, nil);
    STAssertTrue([entry isKindOfClass:[Post class]], nil);
    STAssertNil(entry.author, nil);
    STAssertEquals(entry.source, 0, nil);
    STAssertEquals(entry.contentType, ContentTypeMessage, nil);
    STAssertEquals(entry.visibility, ContentVisibilityNone, nil);

    Post *post = (Post *)entry;
    STAssertEquals(post.authorPermissions, PermissionsNone, nil);
    STAssertEquals(post.permissionScope, PermissionScopeCollectionRule, nil);
}

- (void)testPostChildren {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *postJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child\",\"authorId\":\"author id\",\"parentId\":\"1\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"2\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}],\"source\":5,\"type\":0,\"event\":0}";
    NSDictionary *postDict = [postJson objectFromJSONString];
    Entry *entry = [Entry entryWithDictionary:postDict authorsFrom:authorLookup];
    [entry addChild:[Entry entryWithDictionary:[[postDict objectForKey:@"childContent"] objectAtIndex:0]
                                   authorsFrom:authorLookup]];
    STAssertNotNil(entry, nil);
    STAssertTrue([entry isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(entry.entryId, @"1", nil);
    STAssertEquals(entry.author, [authorLookup authorForId:@"author id"], nil);
    STAssertNil(entry.replaces, nil);
    STAssertNil(entry.parentId, nil);

    Post *post = (Post *)entry;
    STAssertEqualObjects(post.body, @"parent", nil);
    STAssertNotNil(post.children, nil);
    STAssertEquals([post.children count], 1u, nil);
    STAssertNotNil(post.embed, nil);
    STAssertEquals([post.embed count], 0u, nil);

    Post *child = [[post children] objectAtIndex:0];
    STAssertNotNil(child, nil);
    STAssertTrue([child isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(child.entryId, @"2", nil);
    STAssertEquals(child.author, [authorLookup authorForId:@"author id"], nil);
    STAssertNil(child.replaces, nil);
    STAssertEqualObjects(child.parentId, @"1", nil);
    STAssertEqualObjects(child.body, @"child", nil);
    STAssertNotNil(child.children, nil);
    STAssertEquals([child.children count], 0u, nil);
    STAssertNotNil(child.embed, nil);
    STAssertEquals([child.embed count], 0u, nil);
}

- (void)testPostEmbed {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *postJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[{\"content\":{\"targetId\":\"1\", \"authorId\":\"-\", \"link\":\"http://twitter.com/HannahRobbb29/status/202895710654431232/photo/1\", \"oembed\":{\"provider_url\":\"http://twitter.com\", \"title\":\"Hannah Robinson's Twitter Photo\", \"url\":\"http://p.twimg.com/AtDUkuhCAAA9oQh.jpg:large\", \"type\":\"photo\", \"html\":\"\", \"author_name\":\"Hannah Robinson\", \"height\":960, \"thumbnail_width\":150, \"width\":640, \"version\":\"1.0\", \"author_url\":\"http://twitter.com/HannahRobbb29\", \"provider_name\":\"Twitter\", \"thumbnail_url\":\"http://p.twimg.com/AtDUkuhCAAA9oQh.jpg:thumb\", \"thumbnail_height\":150}, \"position\":3, \"id\":\"2\"}, \"vis\":1, \"type\":3, \"event\":1337210428274340, \"source\":1}],\"source\":5,\"type\":0,\"event\":0}";
    NSDictionary *postDict = [postJson objectFromJSONString];
    Entry *entry = [Entry entryWithDictionary:postDict authorsFrom:authorLookup];
    [entry addChild:[Entry entryWithDictionary:[[postDict objectForKey:@"childContent"] objectAtIndex:0]
                                   authorsFrom:authorLookup]];

    STAssertNotNil(entry, nil);
    STAssertTrue([entry isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(entry.entryId, @"1", nil);
    STAssertEquals(entry.author, [authorLookup authorForId:@"author id"], nil);
    STAssertNil(entry.replaces, nil);
    STAssertNil(entry.parentId, nil);

    Post *post = (Post *)entry;
    STAssertEqualObjects(post.body, @"parent", nil);
    STAssertNotNil(post.children, nil);
    STAssertEquals([post.children count], 0u, nil);
    STAssertNotNil(post.embed, nil);
    STAssertEquals([post.embed count], 1u, nil);

    Embed *child = [[post embed] objectAtIndex:0];
    STAssertNotNil(child, nil);
    STAssertTrue([child isKindOfClass:[Embed class]], nil);
    STAssertEqualObjects(child.entryId, @"2", nil);
    STAssertEquals(child.author, [authorLookup authorForId:@"author id"], nil);
    STAssertNil(child.replaces, nil);
    STAssertEqualObjects(child.parentId, @"1", nil);

    STAssertEqualObjects(child.link, @"http://twitter.com/HannahRobbb29/status/202895710654431232/photo/1", nil);
    STAssertEqualObjects(child.providerUrl, @"http://twitter.com", nil);
    STAssertEqualObjects(child.title, @"Hannah Robinson's Twitter Photo", nil);
    STAssertEqualObjects(child.url, @"http://p.twimg.com/AtDUkuhCAAA9oQh.jpg:large", nil);
    STAssertEqualObjects(child.type, @"photo", nil);
    STAssertEqualObjects(child.authorName, @"Hannah Robinson", nil);
    STAssertEqualObjects(child.html, @"", nil);
    STAssertEqualObjects(child.version, @"1.0", nil);
    STAssertEqualObjects(child.authorUrl, @"http://twitter.com/HannahRobbb29", nil);
    STAssertEqualObjects(child.providerName, @"Twitter", nil);
    STAssertEqualObjects(child.thumbnailUrl, @"http://p.twimg.com/AtDUkuhCAAA9oQh.jpg:thumb", nil);
    STAssertEquals(child.height, 960, nil);
    STAssertEquals(child.width, 640, nil);
    STAssertEquals(child.thumbnailHeight, 150, nil);
    STAssertEquals(child.thumbnailWidth, 150, nil);
    STAssertEquals(child.position, 3, nil);
}

- (void)testReplaceEmbed {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *parentJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";
    NSString *originalChild = @"{\"content\":{\"targetId\":\"1\", \"authorId\":\"-\", \"link\":\"\", \"oembed\":{\"title\":\"original title\"}, \"position\":3, \"id\":\"2\"}, \"vis\":1, \"type\":3, \"event\":1337210428274340, \"source\":1}";
    NSString *replacementChild = @"{\"content\":{\"replaces\":\"2\",\"targetId\":\"1\", \"authorId\":\"-\", \"link\":\"\", \"oembed\":{\"title\":\"replacement title\"}, \"position\":3, \"id\":\"3\"}, \"vis\":1, \"type\":3, \"event\":1337210428274340, \"source\":1}";


    Entry *entry = [Entry entryWithDictionary:[parentJson objectFromJSONString]
                                  authorsFrom:authorLookup];
    [entry addChild:[Entry entryWithDictionary:[originalChild objectFromJSONString]
                                   authorsFrom:authorLookup]];
    Post *post = (Post *)entry;

    STAssertEquals([post.embed count], 1u, nil);
    STAssertEqualObjects([[post.embed objectAtIndex:0] title], @"original title", nil);

    [entry replaceChild:[Entry entryWithDictionary:[replacementChild objectFromJSONString]
                                       authorsFrom:authorLookup]];

    STAssertEquals([post.embed count], 1u, nil);
    STAssertEqualObjects([[post.embed objectAtIndex:0] title], @"replacement title", nil);
}

- (void)testReplacePost {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *parentJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";
    NSString *originalChild = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child\",\"authorId\":\"author id\",\"parentId\":\"1\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"2\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";
    NSString *replacementChild = @"{\"vis\":1,\"content\":{\"replaces\":\"2\",\"bodyHtml\":\"replacement\",\"authorId\":\"author id\",\"parentId\":\"1\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"3\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";


    Entry *entry = [Entry entryWithDictionary:[parentJson objectFromJSONString]
                                  authorsFrom:authorLookup];
    [entry addChild:[Entry entryWithDictionary:[originalChild objectFromJSONString]
                                   authorsFrom:authorLookup]];
    Post *post = (Post *)entry;

    STAssertEquals([post.children count], 1u, nil);
    STAssertEqualObjects([[post.children objectAtIndex:0] body], @"child", nil);

    [entry replaceChild:[Entry entryWithDictionary:[replacementChild objectFromJSONString]
                                       authorsFrom:authorLookup]];

    STAssertEquals([post.children count], 1u, nil);
    STAssertEqualObjects([[post.children objectAtIndex:0] body], @"replacement", nil);
}

- (void)testAddLike {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *postJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"a really great post\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";
    NSString *likeJson = @"{\"vis\":1,\"content\":{\"targetId\":\"1\",\"authorId\":\"author id\",\"id\":\"2\"},\"source\":5,\"type\":1,\"event\":1}";

    Entry *entry = [Entry entryWithDictionary:[postJson objectFromJSONString]
                                  authorsFrom:authorLookup];

    STAssertNotNil(entry, nil);
    STAssertEquals([entry.likes count], 0u, nil);

    [entry addChild:[Entry entryWithDictionary:[likeJson objectFromJSONString]
                                   authorsFrom:authorLookup]];

    STAssertEquals([entry.likes count], 1u, nil);
    STAssertEqualObjects([[entry.likes objectAtIndex:0] entryId], @"2", nil);
}

@end

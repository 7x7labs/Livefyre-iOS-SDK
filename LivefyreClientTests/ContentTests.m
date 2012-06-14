//
//  ContentTests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "ContentTests.h"

#import "Author.h"
#import "Content.h"
#import "JSONKit.h"

@interface AuthorLookup : NSObject<AuthorLookup>
- (Author *)authorForId:(NSString *)authorId;
@end

@implementation AuthorLookup {
    Author *author;
}
- (Author *)authorForId:(NSString *)authorId {
    if (!author) {
        author = [Author authorPlaceholder:@"author id"];
        [author setTo:[NSDictionary dictionaryWithObjectsAndKeys:
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

@implementation ContentTests
- (void)testPostConstruction {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *postJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"<p>I love portobellos.</p>\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"23788087\",\"createdAt\":1336604424},\"childContent\":[],\"source\":5,\"type\":0,\"event\":1336604424890719}";
    Content *content = [Content contentWithDictionary:[postJson objectFromJSONString]
                                  authorsFrom:authorLookup
                                 inCollection:nil];

    STAssertNotNil(content, nil);
    STAssertTrue([content isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(content.contentId, @"23788087", nil);
    STAssertEquals(content.author, [authorLookup authorForId:@"author id"], nil);
    STAssertEquals(content.createdAt, 1336604424, nil);
    STAssertEquals(content.source, 5, nil);
    STAssertEquals(content.contentType, ContentTypeMessage, nil);
    STAssertEquals(content.visibility, ContentVisibilityEveryone, nil);
    STAssertNil(content.replaces, nil);
    STAssertNil(content.parentId, nil);

    Post *post = (Post *)content;
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
    Content *content = [Content contentWithDictionary:[badContentTypeJson objectFromJSONString]
                                  authorsFrom:authorLookup
                                 inCollection:nil];
    STAssertNil(content, nil);

    NSString *postJson = @"{\"vis\":8,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"<p>I love portobellos.</p>\",\"authorId\":\"-\",\"parentId\":\"\",\"permissionScope\":8,\"authorPermission\":8,\"id\":\"23788087\",\"createdAt\":1336604424},\"childContent\":[],\"source\":9,\"type\":0,\"event\":1336604424890719}";
    content = [Content contentWithDictionary:[postJson objectFromJSONString]
                           authorsFrom:authorLookup
                          inCollection:nil];

    STAssertNotNil(content, nil);
    STAssertTrue([content isKindOfClass:[Post class]], nil);
    STAssertNil(content.author, nil);
    STAssertEquals(content.source, 0, nil);
    STAssertEquals(content.contentType, ContentTypeMessage, nil);
    STAssertEquals(content.visibility, ContentVisibilityNone, nil);

    Post *post = (Post *)content;
    STAssertEquals(post.authorPermissions, PermissionsNone, nil);
    STAssertEquals(post.permissionScope, PermissionScopeCollectionRule, nil);
}

- (void)testPostChildren {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *postJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child\",\"authorId\":\"author id\",\"parentId\":\"1\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"2\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}],\"source\":5,\"type\":0,\"event\":0}";
    NSDictionary *postDict = [postJson objectFromJSONString];
    Content *content = [Content contentWithDictionary:postDict
                                  authorsFrom:authorLookup
                                 inCollection:nil];
    [content addChild:[Content contentWithDictionary:[[postDict objectForKey:@"childContent"] objectAtIndex:0]
                                   authorsFrom:authorLookup
                                  inCollection:nil]];
    STAssertNotNil(content, nil);
    STAssertTrue([content isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(content.contentId, @"1", nil);
    STAssertEquals(content.author, [authorLookup authorForId:@"author id"], nil);
    STAssertNil(content.replaces, nil);
    STAssertNil(content.parentId, nil);

    Post *post = (Post *)content;
    STAssertEqualObjects(post.body, @"parent", nil);
    STAssertNotNil(post.children, nil);
    STAssertEquals([post.children count], 1u, nil);
    STAssertNotNil(post.embed, nil);
    STAssertEquals([post.embed count], 0u, nil);

    Post *child = [[post children] objectAtIndex:0];
    STAssertNotNil(child, nil);
    STAssertTrue([child isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(child.contentId, @"2", nil);
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
    Content *content = [Content contentWithDictionary:postDict
                                  authorsFrom:authorLookup
                                 inCollection:nil];
    [content addChild:[Content contentWithDictionary:[[postDict objectForKey:@"childContent"] objectAtIndex:0]
                                   authorsFrom:authorLookup
                                  inCollection:nil]];

    STAssertNotNil(content, nil);
    STAssertTrue([content isKindOfClass:[Post class]], nil);
    STAssertEqualObjects(content.contentId, @"1", nil);
    STAssertEquals(content.author, [authorLookup authorForId:@"author id"], nil);
    STAssertNil(content.replaces, nil);
    STAssertNil(content.parentId, nil);

    Post *post = (Post *)content;
    STAssertEqualObjects(post.body, @"parent", nil);
    STAssertNotNil(post.children, nil);
    STAssertEquals([post.children count], 0u, nil);
    STAssertNotNil(post.embed, nil);
    STAssertEquals([post.embed count], 1u, nil);

    Embed *child = [[post embed] objectAtIndex:0];
    STAssertNotNil(child, nil);
    STAssertTrue([child isKindOfClass:[Embed class]], nil);
    STAssertEqualObjects(child.contentId, @"2", nil);
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
    NSString *replacementChild = @"{\"content\":{\"replaces\":\"2\",\"targetId\":\"1\", \"authorId\":\"-\", \"link\":\"\", \"oembed\":{\"title\":\"replacement title\"}, \"position\":3, \"id\":\"3\"}, \"vis\":1, \"type\":3, \"event\":1337210429274340, \"source\":1}";


    Content *content = [Content contentWithDictionary:[parentJson objectFromJSONString]
                                  authorsFrom:authorLookup
                                 inCollection:nil];
    [content addChild:[Content contentWithDictionary:[originalChild objectFromJSONString]
                                   authorsFrom:authorLookup
                                  inCollection:nil]];
    STAssertEquals([content.embed count], 1u, nil);
    STAssertEqualObjects([[content.embed objectAtIndex:0] title], @"original title", nil);

    [[content.embed objectAtIndex:0] copyFrom:[Content contentWithDictionary:[replacementChild objectFromJSONString]
                                                           authorsFrom:authorLookup
                                                          inCollection:nil]];

    STAssertEquals([content.embed count], 1u, nil);
    STAssertEqualObjects([[content.embed objectAtIndex:0] title], @"replacement title", nil);
}

- (void)testReplacePost {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *parentJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";
    NSString *originalChild = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child\",\"authorId\":\"author id\",\"parentId\":\"1\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"2\",\"createdAt\":1},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";
    NSString *replacementChild = @"{\"vis\":1,\"content\":{\"replaces\":\"2\",\"bodyHtml\":\"replacement\",\"authorId\":\"author id\",\"parentId\":\"1\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"3\",\"createdAt\":2},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";


    Content *content = [Content contentWithDictionary:[parentJson objectFromJSONString]
                                  authorsFrom:authorLookup
                                 inCollection:nil];
    [content addChild:[Content contentWithDictionary:[originalChild objectFromJSONString]
                                   authorsFrom:authorLookup
                                  inCollection:nil]];

    STAssertEquals([content.children count], 1u, nil);
    STAssertEqualObjects([[content.children objectAtIndex:0] body], @"child", nil);

    [[content.children objectAtIndex:0] copyFrom:[Content contentWithDictionary:[replacementChild objectFromJSONString]
                                                              authorsFrom:authorLookup
                                                             inCollection:nil]];

    STAssertEquals([content.children count], 1u, nil);
    STAssertEqualObjects([[content.children objectAtIndex:0] body], @"replacement", nil);
}

- (void)testAddLike {
    AuthorLookup *authorLookup = [[AuthorLookup alloc] init];

    NSString *postJson = @"{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"a really great post\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"1\",\"createdAt\":0},\"childContent\":[],\"source\":5,\"type\":0,\"event\":0}";
    NSString *likeJson = @"{\"vis\":1,\"content\":{\"targetId\":\"1\",\"authorId\":\"author id\",\"id\":\"2\"},\"source\":5,\"type\":1,\"event\":1}";

    Content *content = [Content contentWithDictionary:[postJson objectFromJSONString]
                                  authorsFrom:authorLookup
                                 inCollection:nil];

    STAssertNotNil(content, nil);
    STAssertEquals([content.likes count], 0u, nil);

    [content addChild:[Content contentWithDictionary:[likeJson objectFromJSONString]
                                   authorsFrom:authorLookup
                                  inCollection:nil]];

    STAssertEquals([content.likes count], 1u, nil);
    STAssertEqualObjects([[content.likes objectAtIndex:0] contentId], @"2", nil);
}

@end

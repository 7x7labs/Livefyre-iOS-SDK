//
//  CollectionTests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "CollectionTests.h"

#import "Config.h"
#import "JSONKit.h"

@implementation CollectionTests

- (void)getCollection:(void (^)(Collection *))handler {
    User *user = [User userWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"dev01@7x7-1.fyre.co", @"id",
                                            @"dev01", @"displayName",
                                            nil], @"profile",
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"", @"moderator_key",
                                            nil], @"permissions",
                                           nil]];

    [self.client getCollectionForArticle:[Config objectForKey:@"existing article"]
                                  inSite:[Config objectForKey:@"site"]
                                 forUser:user
                           gotCollection:^(BOOL error, id resultOrError)
     {
         [self completedTest];

         if (error) {
             STFail(resultOrError);
         }
         else {
             STAssertTrue([resultOrError isKindOfClass:[Collection class]], nil);
             if ([resultOrError isKindOfClass:[Collection class]])
                 handler(resultOrError);
         }
     }];

    [self waitForTests];
}

- (void)testInit {
    [self getCollection:^(Collection *collection) {
        STAssertTrue([collection.collectionId length] > 0, nil);
        STAssertTrue([collection.user isKindOfClass:[User class]], nil);
        STAssertTrue(collection.numberOfPages > 0, nil);
        STAssertEquals([collection.posts count], 0u, @"Collections should not have any initial data");
        STAssertEquals([collection.authors count], 0u, @"Collections should not have any initial data");
        STAssertEquals([collection.followers count], 0u, @"Collections should not have any initial data");
    }];
}

- (void)testBadCollectionId {
    [self.client getCollectionForArticle:[Config objectForKey:@"nonexistant article"]
                                  inSite:[Config objectForKey:@"site"]
                                 forUser:nil
                           gotCollection:^(BOOL error, id resultOrError)
     {
         [self completedTest];
         STAssertTrue(error, @"Should not get a collection for a nonexistant article");
     }];

    [self waitForTests];
}

- (void)testOutOfBoundsPage {
    [self getCollection:^(Collection *collection) {
        [collection fetchPage:collection.numberOfPages
                      gotPage:^(BOOL error, id resultOrError) {
                          STAssertTrue(error, nil);
                          [self completedTest];
                      }];
        [self waitForTests];
    }];
}

- (void)testGetPage {
    __block int postCount = 0;
    [self getCollection:^(Collection *collection) {
        for (NSUInteger i = 0; i < collection.numberOfPages; ++i) {
            [collection fetchPage:i
                          gotPage:^(BOOL error, id resultOrError)
             {
                 [self completedTest];

                 STAssertFalse(error, nil);
                 STAssertTrue([collection.posts count] >= postCount, @"Fetching a page removed data");
                 STAssertTrue([resultOrError count] >= [collection.posts count] - postCount, @"Not all new posts were returned");
                 postCount = [collection.posts count];

                 for (Post *post in collection.posts) {
                     STAssertNotNil(post.author, nil);
                 }
             }];
        }
        [self waitForTests];
    }];
}

- (Collection *)basicCollection {
    User *user = [User userWithDictionary:[@"{\"profile\":{\"id\":\"non mod user\"},\"permissions\":{}}" objectFromJSONString]];
    void (^bootstrap)(Collection *, RequestComplete) = ^(Collection *c, RequestComplete r) {};
    NSMutableArray *additionalPages = [NSMutableArray arrayWithObject:
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        [DateRange dateRangeWithStart:0 end:1], @"range",
                                        [^(Collection *c, RequestComplete r){} copy], @"callback",
                                        nil]];

    return [Collection collectionWithId:@"collection id"
                                   user:user
                              nestLevel:4
                          numberVisible:20
                      numberOfFollowers:11
                              lastEvent:1234
                              bootstrap:[bootstrap copy]
                        additionalPages:additionalPages];
}

- (void)testAddFollowers {
    Collection *collection = [self basicCollection];
    STAssertNotNil(collection.followers, nil);
    STAssertEquals([collection.followers count], 0u, nil);

    NSArray *followers = [NSArray arrayWithObjects:@"user 1", @"user 2", nil];
    [collection addAuthors:nil andPosts:nil andFollowers:followers lastEvent:0];
    STAssertEqualObjects(followers, collection.followers, nil);
}

- (void)testAddPosts {
    Collection *collection = [self basicCollection];
    STAssertNotNil(collection.posts, nil);
    STAssertEquals([collection.posts count], 0u, nil);
    STAssertNotNil(collection.authors, nil);
    STAssertEquals([collection.authors count], 0u, nil);

    NSString *authors = @"{\"306445453@twitter.com\":{\"profileUrl\":\"http://twitter.com/#!/IAmDesseBoo\",\"displayName\":\"Dess❤\",\"id\":\"306445453@twitter.com\",\"avatar\":\"http://a0.twimg.com/profile_images/2200306122/image_normal.jpg\"},\"_u221@livefyre.com\":{\"profileUrl\":\"http://admin.t101.livefyre.com/profile/221/\",\"displayName\":\"jkretch\",\"id\":\"_u221@livefyre.com\",\"avatar\":\"http://livefyre-avatar-sandbox.s3.amazonaws.com/a/1/ec52354733f6d6b92adbe2ba83aa066c/50.jpg\"}}";
    NSString *posts = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"RT <span class=\\\"namespace tw\\\" provider=\\\"tw\\\" user_name=\\\"@BballProblemz\\\" screen_name=\\\"399190783\\\" jid=\\\"399190783\\\" profile_url=\\\"\\\" ns=\\\"true\\\">@BballProblemz</span>: If I'm not at school, eating, or playing basketball, I'm probably asleep... <span class=\\\"fyre-hashtag\\\" hashtag=\\\"BasketballProblems\\\" rel=\\\"tag\\\">#BasketballProblems</span>\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392960@twitter.com\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";

    [collection addAuthors:[authors objectFromJSONString]
                  andPosts:[posts objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 2u, nil);
    STAssertEquals([collection.posts count], 1u, nil);
    STAssertEqualObjects([[[collection.posts objectAtIndex:0] author] authorId], @"306445453@twitter.com", nil);
}

- (void)testChildAfterParent {
    Collection *collection = [self basicCollection];
    STAssertNotNil(collection.posts, nil);
    STAssertEquals([collection.posts count], 0u, nil);
    STAssertNotNil(collection.authors, nil);
    STAssertEquals([collection.authors count], 0u, nil);

    NSString *author = @"{\"306445453@twitter.com\":{\"profileUrl\":\"http://twitter.com/#!/IAmDesseBoo\",\"displayName\":\"Dess❤\",\"id\":\"306445453@twitter.com\",\"avatar\":\"http://a0.twimg.com/profile_images/2200306122/image_normal.jpg\"}}";
    NSString *parentPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392960@twitter.com\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";
    NSString *childPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"tweet-200315761892392960@twitter.com\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392961@twitter.com\",\"createdAt\":1336593975},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662155}]";


    [collection addAuthors:[author objectFromJSONString]
                  andPosts:[parentPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    Post *parent = [collection.posts objectAtIndex:0];
    STAssertEquals([parent.children count], 0u, nil);

    [collection addAuthors:[author objectFromJSONString]
                  andPosts:[childPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    STAssertEquals([parent.children count], 1u, nil);
    STAssertEqualObjects([[parent.children objectAtIndex:0] body], @"child body", nil);
}

- (void)testParentAfterChild {
    Collection *collection = [self basicCollection];

    STAssertNotNil(collection.posts, nil);
    STAssertEquals([collection.posts count], 0u, nil);
    STAssertNotNil(collection.authors, nil);
    STAssertEquals([collection.authors count], 0u, nil);

    NSString *author = @"{\"306445453@twitter.com\":{\"profileUrl\":\"http://twitter.com/#!/IAmDesseBoo\",\"displayName\":\"Dess❤\",\"id\":\"306445453@twitter.com\",\"avatar\":\"http://a0.twimg.com/profile_images/2200306122/image_normal.jpg\"}}";
    NSString *parentPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392960@twitter.com\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";
    NSString *childPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"tweet-200315761892392960@twitter.com\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392961@twitter.com\",\"createdAt\":1336593975},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662155}]";


    [collection addAuthors:[author objectFromJSONString]
                  andPosts:[childPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 0u, nil);

    [collection addAuthors:[author objectFromJSONString]
                  andPosts:[parentPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    Post *parent = [collection.posts objectAtIndex:0];
    STAssertEquals([parent.children count], 1u, nil);
    STAssertEqualObjects([[parent.children objectAtIndex:0] body], @"child body", nil);
}

- (void)testReplaceAfterOriginal {
    Collection *collection = [self basicCollection];
    STAssertNotNil(collection.posts, nil);
    STAssertEquals([collection.posts count], 0u, nil);
    STAssertNotNil(collection.authors, nil);
    STAssertEquals([collection.authors count], 0u, nil);

    NSString *author = @"{\"306445453@twitter.com\":{\"profileUrl\":\"http://twitter.com/#!/IAmDesseBoo\",\"displayName\":\"Dess❤\",\"id\":\"306445453@twitter.com\",\"avatar\":\"http://a0.twimg.com/profile_images/2200306122/image_normal.jpg\"}}";
    NSString *originalPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"original body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392960@twitter.com\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";
    NSString *replacementPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"tweet-200315761892392960@twitter.com\",\"bodyHtml\":\"replacement body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392961@twitter.com\",\"createdAt\":1336593975},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662155}]";
    NSString *childPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"tweet-200315761892392960@twitter.com\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392962@twitter.com\",\"createdAt\":1336593975},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662156}]";


    [collection addAuthors:[author objectFromJSONString]
                  andPosts:[originalPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    Post *post = [collection.posts objectAtIndex:0];
    STAssertEquals([post.children count], 0u, nil);
    STAssertEqualObjects(post.body, @"original body", nil);
    STAssertEqualObjects(post.entryId, @"tweet-200315761892392960@twitter.com", nil);

    [collection addAuthors:nil
                  andPosts:[replacementPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    post = [collection.posts objectAtIndex:0];
    STAssertEqualObjects(post.body, @"replacement body", nil);
    STAssertEqualObjects(post.entryId, @"tweet-200315761892392961@twitter.com", nil);

    // note: using original post id
    [collection addAuthors:nil
                  andPosts:[childPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([post.children count], 1u, nil);
    STAssertEqualObjects([[post.children objectAtIndex:0] body], @"child body", nil);
}

- (void)testReplaceBeforeOriginal {
    Collection *collection = [self basicCollection];

    STAssertNotNil(collection.posts, nil);
    STAssertEquals([collection.posts count], 0u, nil);
    STAssertNotNil(collection.authors, nil);
    STAssertEquals([collection.authors count], 0u, nil);

    NSString *author = @"{\"306445453@twitter.com\":{\"profileUrl\":\"http://twitter.com/#!/IAmDesseBoo\",\"displayName\":\"Dess❤\",\"id\":\"306445453@twitter.com\",\"avatar\":\"http://a0.twimg.com/profile_images/2200306122/image_normal.jpg\"}}";
    NSString *originalPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"original body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392960@twitter.com\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";
    NSString *replacementPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"tweet-200315761892392960@twitter.com\",\"bodyHtml\":\"replacement body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392961@twitter.com\",\"createdAt\":1336593975},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662155}]";
    NSString *childPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"child body\",\"authorId\":\"306445453@twitter.com\",\"parentId\":\"tweet-200315761892392960@twitter.com\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"tweet-200315761892392962@twitter.com\",\"createdAt\":1336593975},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662156}]";


    [collection addAuthors:[author objectFromJSONString]
                  andPosts:[replacementPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    Post *post = [collection.posts objectAtIndex:0];
    STAssertEqualObjects(post.body, @"replacement body", nil);
    STAssertEqualObjects(post.entryId, @"tweet-200315761892392961@twitter.com", nil);

    [collection addAuthors:nil
                  andPosts:[originalPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    post = [collection.posts objectAtIndex:0];
    STAssertEqualObjects(post.body, @"replacement body", nil);
    STAssertEqualObjects(post.entryId, @"tweet-200315761892392961@twitter.com", nil);

    // note: using original post id
    [collection addAuthors:nil
                  andPosts:[childPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([post.children count], 1u, nil);
    STAssertEqualObjects([[post.children objectAtIndex:0] body], @"child body", nil);
}

- (void)testReplaceChildWaitingForParent {
    Collection *collection = [self basicCollection];

    STAssertNotNil(collection.posts, nil);
    STAssertEquals([collection.posts count], 0u, nil);
    STAssertNotNil(collection.authors, nil);
    STAssertEquals([collection.authors count], 0u, nil);

    NSString *author = @"{\"author id\":{\"profileUrl\":\"\",\"displayName\":\"Author\",\"id\":\"author id\",\"avatar\":\"\"}}";
    NSString *originalChild = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"original child\",\"authorId\":\"author id\",\"parentId\":\"parent id\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"original child\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";
    NSString *replacementChild = @"[{\"vis\":1,\"content\":{\"replaces\":\"original child\",\"bodyHtml\":\"replacement child\",\"authorId\":\"author id\",\"parentId\":\"parent id\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"replacement child\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";
    NSString *parentPost = @"[{\"vis\":1,\"content\":{\"replaces\":\"\",\"bodyHtml\":\"parent body\",\"authorId\":\"author id\",\"parentId\":\"\",\"permissionScope\":0,\"authorPermission\":0,\"id\":\"parent id\",\"createdAt\":1336593974},\"childContent\":[],\"source\":1,\"type\":0,\"event\":1336593974662154}]";

    [collection addAuthors:[author objectFromJSONString]
                  andPosts:[originalChild objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 0u, nil);

    [collection addAuthors:nil
                  andPosts:[replacementChild objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 0u, nil);

    [collection addAuthors:nil
                  andPosts:[parentPost objectFromJSONString]
              andFollowers:nil
                 lastEvent:0];

    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals([collection.posts count], 1u, nil);

    Post *post = [collection.posts objectAtIndex:0];
    STAssertEqualObjects(post.body, @"parent body", nil);

    STAssertEquals([post.children count], 1u, nil);
    STAssertEqualObjects([[post.children objectAtIndex:0] body], @"replacement child", nil);
}

- (void)testCollectionConstruction {
    Collection *collection = [self basicCollection];

    STAssertNotNil(collection, nil);
    STAssertEqualObjects(collection.collectionId, @"collection id", nil);
    STAssertNotNil(collection.user, nil);
    STAssertEquals(collection.nestLevel, 4, nil);
    STAssertEquals(collection.numberVisible, 20, nil);
    STAssertEquals(collection.numberOfFollowers, 11, nil);
    STAssertEquals(collection.lastEvent, 1234LL, nil);
    STAssertEquals(collection.numberOfPages, 1u, nil);
    STAssertEqualObjects([(DateRange *)[collection.availableDataRanges objectAtIndex:0] start],
                         [NSDate dateWithTimeIntervalSince1970:0],
                         nil);
    STAssertEqualObjects([(DateRange *)[collection.availableDataRanges objectAtIndex:0] end],
                         [NSDate dateWithTimeIntervalSince1970:1],
                         nil);

}

- (void)testMultipleBootstrapCallsIsAnError {
    User *user = [User userWithDictionary:[[NSDictionary alloc] init]];
    NSMutableArray *additionalPages = [NSMutableArray arrayWithObject:
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        [DateRange dateRangeWithStart:0 end:1], @"range",
                                        [^(Collection *c, RequestComplete r){} copy], @"callback",
                                        nil]];

    __block BOOL bootstrapCalled = NO;
    void (^bootstrap)(Collection *, RequestComplete) = ^(Collection *c, RequestComplete r)
    {
        if (bootstrapCalled)
            STFail(@"Bootstrap fetcher invoked twice");
        bootstrapCalled = YES;
    };

    Collection *collection = [Collection collectionWithId:@"collection id"
                                                     user:user
                                                nestLevel:4
                                            numberVisible:20
                                        numberOfFollowers:11
                                                lastEvent:1234
                                                bootstrap:bootstrap
                                          additionalPages:additionalPages];

    [collection fetchBootstrap:^(BOOL error, id resultOrError) {
        // shouldn't be called since the fetcher doesn't call it
        STFail(@"Bootstrap callback invokved unexpectedly");
    }];

    __block BOOL callbackCalled = NO;
    [collection fetchBootstrap:^(BOOL error, id resultOrError) {
        STAssertTrue(error, @"Fetching bootstrap twice didn't fail");
        callbackCalled = YES;
    }];
    STAssertTrue(callbackCalled, @"Fetching bootstrap twice didn't fail");
}

- (void)testMultipleRetrievalsOfAPageIsAnError {
    __block BOOL pageCalled = NO;
    void (^fetchPage0)(Collection *, RequestComplete) = ^(Collection *c, RequestComplete r)
    {
        if (pageCalled)
            STFail(@"Page fetcher invoked twice");
        pageCalled = YES;
    };

    User *user = [User userWithDictionary:[[NSDictionary alloc] init]];
    void (^bootstrap)(Collection *, RequestComplete) = ^(Collection *c, RequestComplete r) {};
    NSMutableArray *additionalPages = [NSMutableArray arrayWithObject:
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        [DateRange dateRangeWithStart:0 end:1], @"range",
                                        fetchPage0, @"callback",
                                        nil]];

    Collection *collection = [Collection collectionWithId:@"collection id"
                                                     user:user
                                                nestLevel:4
                                            numberVisible:20
                                        numberOfFollowers:11
                                                lastEvent:1234
                                                bootstrap:bootstrap
                                          additionalPages:additionalPages];

    [collection fetchPage:0 gotPage:^(BOOL error, id resultOrError) {
        // shouldn't be called since the fetcher doesn't call it
        STFail(@"Page retrieved callback invokved unexpectedly");
    }];

    __block BOOL callbackCalled = NO;
    [collection fetchPage:0 gotPage:^(BOOL error, id resultOrError) {
        STAssertTrue(error, @"Fetching page twice didn't fail");
        callbackCalled = YES;
    }];
    STAssertTrue(callbackCalled, @"Fetching page twice didn't fail");
}

- (void)testSetLastEvent {
    Collection *collection = [self basicCollection];
    STAssertEquals(collection.lastEvent, 1234LL, nil);
    [collection addAuthors:nil andPosts:nil andFollowers:nil lastEvent:0];
    STAssertEquals(collection.lastEvent, 1234LL, nil);
    [collection addAuthors:nil andPosts:nil andFollowers:nil lastEvent:1];
    STAssertEquals(collection.lastEvent, 1LL, nil);
}

- (void)testFetchPagesByDateRange {
    User *user = [User userWithDictionary:[@"{\"profile\":{\"id\":\"non mod user\"},\"permissions\":{}}" objectFromJSONString]];

    __block struct { BOOL arr[5]; } pagesFetched = { NO, NO, NO, NO, NO };

    NSMutableArray *additionalPages = [NSMutableArray arrayWithCapacity:5];
    for (int i = 0; i < 5; ++i) {
        [additionalPages addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [DateRange dateRangeWithStart:i end:(i + 1)], @"range",
                                    [^(Collection *c, RequestComplete r) { pagesFetched.arr[i] = YES; } copy], @"callback",
                                    nil]];
    }

    Collection *collection = [Collection collectionWithId:@"collection id"
                                                     user:user
                                                nestLevel:4
                                            numberVisible:20
                                        numberOfFollowers:11
                                                lastEvent:1234
                                                bootstrap:nil
                                          additionalPages:additionalPages];

    DateRange *range = [collection fetchRange:[DateRange dateRangeWithStart:0 end:2]
                                     gotRange:^(BOOL error, id resultOrError) {
                                         STAssertFalse(error, resultOrError);
                                     }];
    STAssertEqualObjects(range, [DateRange dateRangeWithStart:0 end:3], nil);
    for (int i = 0; i < 3; ++i) {
        STAssertTrue(pagesFetched.arr[i], nil);
    }
    STAssertFalse(pagesFetched.arr[3], nil);
    STAssertFalse(pagesFetched.arr[4], nil);

    range = [collection fetchRange:[DateRange dateRangeWithStart:0 end:3]
                          gotRange:^(BOOL error, id resultOrError) {
                              STAssertFalse(error, resultOrError);
                          }];
    STAssertEqualObjects(range, [DateRange dateRangeWithStart:3 end:4], nil);
    for (int i = 0; i < 4; ++i) {
        STAssertTrue(pagesFetched.arr[i], nil);
    }
    STAssertFalse(pagesFetched.arr[4], nil);

    range = [collection fetchRange:[DateRange dateRangeWithStart:4 end:10]
                          gotRange:^(BOOL error, id resultOrError) {
                              STAssertFalse(error, resultOrError);
                          }];
    STAssertEqualObjects(range, [DateRange dateRangeWithStart:4 end:5], nil);
    for (int i = 0; i < 5; ++i) {
        STAssertTrue(pagesFetched.arr[i], nil);
    }

    range = [collection fetchRange:[DateRange dateRangeWithStart:0 end:10]
                          gotRange:^(BOOL error, id resultOrError) {
                              STAssertFalse(error, resultOrError);
                          }];
    STAssertNil(range, @"");
}

- (void)testStreamResponseHandling {
    NSString *initialPostJson = @"{\"states\":{\"25802158\":{\"content\":{\"replaces\":\"\", \"bodyHtml\":\"<p>\\u00a0new post</p>\", \"annotations\":{}, \"authorId\":\"2@7x7-1.fyre.co\", \"parentId\":\"\", \"id\":\"25802158\", \"createdAt\":1338400428}, \"source\":5, \"type\":0, \"event\":1338400428925945, \"vis\":1}}, \"authors\":{\"2@7x7-1.fyre.co\":{\"profileUrl\":\"\", \"avatar\":\"http://t402-avatars.s3.amazonaws.com/a/anon/50.jpg\", \"displayName\":\"regUser\", \"id\":\"2@7x7-1.fyre.co\"}}, \"jsver\":\"00003\", \"maxEventId\":1338400428925945}";
    NSString *replyJson = @"{\"states\":{\"25802159\":{\"content\":{\"replaces\":\"\", \"bodyHtml\":\"<p>\\u00a0 <a vocab=\\\"http://schema.org\\\" typeof=\\\"Person\\\" rel=\\\"nofollow\\\" resource=\\\"acct:2@7x7-1.fyre.co\\\" data-lf-provider=\\\"livefyre\\\" property=\\\"url\\\"  target=\\\"_blank\\\" class=\\\"fyre-mention fyre-mention-livefyre\\\">@<span property=\\\"name\\\">regUser</span></a>\\u00a0reply to new post</p>\", \"annotations\":{}, \"authorId\":\"2@7x7-1.fyre.co\", \"parentId\":\"25802158\", \"id\":\"25802159\", \"createdAt\":1338400452}, \"source\":5, \"type\":0, \"event\":1338400452481309, \"vis\":1}}, \"authors\":{\"2@7x7-1.fyre.co\":{\"profileUrl\":\"\", \"displayName\":\"regUser\", \"avatar\":\"http://t402-avatars.s3.amazonaws.com/a/anon/50.jpg\", \"id\":\"2@7x7-1.fyre.co\"}}, \"jsver\":\"00003\", \"maxEventId\":1338400452481309}";
    NSString *editParent = @"{\"states\":{\"a9cebf68aa8111e18a421231390eae31@7x7-1.fyre.co\":{\"content\":{\"replaces\":\"25802158.fbc98b9317094c8f964084923a901c77\", \"bodyHtml\":\"<p>edit post with reply</p>\", \"annotations\":{\"moderator\":true}, \"authorId\":\"2@7x7-1.fyre.co\", \"parentId\":\"None\", \"id\":\"a9cebf68aa8111e18a421231390eae31@7x7-1.fyre.co\", \"createdAt\":1338400967}, \"source\":5, \"type\":0, \"event\":1338400967479010, \"vis\":1}}, \"authors\":{\"2@7x7-1.fyre.co\":{\"profileUrl\":\"\", \"avatar\":\"http://t402-avatars.s3.amazonaws.com/a/anon/50.jpg\", \"displayName\":\"regUser\", \"id\":\"2@7x7-1.fyre.co\"}}, \"jsver\":\"00003\", \"maxEventId\":1338400967479010}";
    NSString *deleteParent = @"{\"states\":{\"a9cebf68aa8111e18a421231390eae31@7x7-1.fyre.co\":{\"content\":{\"id\":\"a9cebf68aa8111e18a421231390eae31@7x7-1.fyre.co\"}, \"source\":5, \"type\":0, \"event\":1338413150921195, \"vis\":0}}, \"authors\":{}, \"jsver\":\"00003\", \"maxEventId\":1338413150921195}";

    Collection *collection = [self basicCollection];
    STAssertNotNil(collection, nil);
    STAssertNotNil(collection.posts, nil);
    STAssertEquals([collection.posts count], 0u, nil);

    [collection addCollectionContent:[initialPostJson objectFromJSONString] erefFetcher:nil];
    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals(collection.lastEvent, 1338400428925945LL, nil);
    STAssertEquals([collection.posts count], 1u, nil);
    Post *firstPost = [collection.posts objectAtIndex:0];
    STAssertEqualObjects(firstPost.entryId, @"25802158", nil);
    STAssertEqualObjects(firstPost.body, @"<p>\u00a0new post</p>", nil);
    STAssertEqualObjects(firstPost.author.displayName, @"regUser", nil);
    STAssertEquals([firstPost.children count], 0u, nil);

    // Adding data twice shouldn't do anything
    [collection addCollectionContent:[initialPostJson objectFromJSONString] erefFetcher:nil];
    STAssertEquals([collection.posts count], 1u, nil);

    [collection addCollectionContent:[replyJson objectFromJSONString] erefFetcher:nil];
    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals(collection.lastEvent, 1338400452481309LL, nil);
    STAssertEquals([collection.posts count], 1u, nil);
    STAssertEquals(firstPost, [collection.posts objectAtIndex:0], nil);
    STAssertEquals([firstPost.children count], 1u, nil);
    Post *child = [firstPost.children objectAtIndex:0];
    STAssertEqualObjects(child.entryId, @"25802159", nil);
    STAssertEqualObjects(child.body,  @"<p>\u00a0 <a vocab=\"http://schema.org\" typeof=\"Person\" rel=\"nofollow\" resource=\"acct:2@7x7-1.fyre.co\" data-lf-provider=\"livefyre\" property=\"url\"  target=\"_blank\" class=\"fyre-mention fyre-mention-livefyre\">@<span property=\"name\">regUser</span></a>\u00a0reply to new post</p>", nil);

    [collection addCollectionContent:[editParent objectFromJSONString] erefFetcher:nil];
    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals(collection.lastEvent, 1338400967479010LL, nil);
    STAssertEquals([collection.posts count], 1u, nil);
    STAssertFalse(firstPost == [collection.posts objectAtIndex:0], nil);
    firstPost = [collection.posts objectAtIndex:0];
    STAssertEqualObjects(firstPost.entryId, @"a9cebf68aa8111e18a421231390eae31@7x7-1.fyre.co", nil);
    STAssertEqualObjects(firstPost.body, @"<p>edit post with reply</p>", nil);
    STAssertEqualObjects(firstPost.author.displayName, @"regUser", nil);
    STAssertEquals([firstPost.children count], 1u, nil);
    STAssertEquals(child, [firstPost.children objectAtIndex:0], nil);

    [collection addCollectionContent:[deleteParent objectFromJSONString] erefFetcher:nil];
    STAssertEquals([collection.authors count], 1u, nil);
    STAssertEquals(collection.lastEvent, 1338413150921195LL, nil);
    STAssertEquals([collection.posts count], 1u, nil);
    STAssertFalse(firstPost == [collection.posts objectAtIndex:0], nil);
    firstPost = [collection.posts objectAtIndex:0];
    STAssertEqualObjects(firstPost.entryId, @"a9cebf68aa8111e18a421231390eae31@7x7-1.fyre.co", nil);
    STAssertTrue(firstPost.deleted, nil);
    STAssertNil(firstPost.author, nil);
    STAssertEquals([firstPost.children count], 1u, nil);
    STAssertEquals(child, [firstPost.children objectAtIndex:0], nil);
}

- (void)testCollectionWithoutUser {
    Collection *collection = [Collection collectionWithId:@"collection id"
                                                     user:nil
                                                nestLevel:4
                                            numberVisible:20
                                        numberOfFollowers:11
                                                lastEvent:1234
                                                bootstrap:nil
                                          additionalPages:nil];

    NSString *content = @"{\"states\":{\"25802158\":{\"content\":{\"replaces\":\"\", \"bodyHtml\":\"<p>\\u00a0new post</p>\", \"annotations\":{}, \"authorId\":\"2@7x7-1.fyre.co\", \"parentId\":\"\", \"id\":\"25802158\", \"createdAt\":1338400428}, \"source\":5, \"type\":0, \"event\":1338400428925945, \"vis\":1}}, \"authors\":{\"2@7x7-1.fyre.co\":{\"profileUrl\":\"\", \"avatar\":\"http://t402-avatars.s3.amazonaws.com/a/anon/50.jpg\", \"displayName\":\"regUser\", \"id\":\"2@7x7-1.fyre.co\"}}, \"jsver\":\"00003\", \"maxEventId\":1338400428925945}";

    [collection addCollectionContent:[content objectFromJSONString]
                         erefFetcher:nil];

    STAssertEquals([collection.posts count], 1u, nil);
}

@end

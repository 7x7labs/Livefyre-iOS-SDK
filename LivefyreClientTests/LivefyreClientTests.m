//
//  LivefyreClientTests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LivefyreClientTests.h"

#import "Config.h"
#import "JSONKit.h"
#import "LivefyreClient.h"

@implementation LivefyreClientTests

- (Collection *)collection {
    NSString *userJson = @"{\"profile\":{\"profileUrl\":null, \"settingsUrl\":null, \"displayName\":\"dev00\", \"avatar\":\"http://t402-avatars.s3.amazonaws.com/a/anon/50.jpg\", \"id\":\"dev00@7x7-1.fyre.co\"}, \"token\":\"eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJkb21haW4iOiAiN3g3LTEuZnlyZS5jbyIsICJleHBpcmVzIjogMTMzODQ2MzYzNi45Mzg4NzgsICJ1c2VyX2lkIjogImRldjAwIn0.xiDtuEbhkJvN0uTWe_Rg-ki8DN2y5DgNn_OAZP2XdUM\", \"version\":\"00004\", \"isModAnywhere\":true, \"permissions\":{\"moderator_key\":\"0d1886e6e868117d32154920a6cd637497b73bdd\", \"authors\":[]}}";
    User *user = [User userWithDictionary:[userJson objectFromJSONString]];

    return [Collection collectionWithId:@"10581382"
                                   user:user
                              nestLevel:0
                          numberVisible:0
                      numberOfFollowers:0
                              lastEvent:0
                              bootstrap:nil
                        additionalPages:nil];
}

- (void)testLike {
    Collection *collection = [self collection];

    Entry *entry = [Entry entryWithDictionary:[@"{\"vis\":1, \"content\":{\"replaces\":\"\", \"bodyHtml\":\"<p>\\u00a0woah</p>\", \"authorId\":\"6@7x7-1.fyre.co\", \"parentId\":\"\", \"id\":\"25802143\", \"createdAt\":1338321741}, \"childContent\":[], \"source\":5, \"type\":0, \"event\":1338321741951711}" objectFromJSONString]
                                  authorsFrom:nil
                                 inCollection:collection];

    [self.client likeContent:entry onComplete:^(BOOL error, id resultOrError) {
        if (error) {
            STFail(resultOrError);
        }
        else {
            STAssertEquals(entry, resultOrError, nil);
        }
    }];

    [self waitForTests];
}

- (void)testUnlike {
    Collection *collection = [self collection];

    Entry *entry = [Entry entryWithDictionary:[@"{\"vis\":1, \"content\":{\"replaces\":\"\", \"bodyHtml\":\"<p>\\u00a0woah</p>\", \"authorId\":\"6@7x7-1.fyre.co\", \"parentId\":\"\", \"id\":\"25802143\", \"createdAt\":1338321741}, \"childContent\":[], \"source\":5, \"type\":0, \"event\":1338321741951711}" objectFromJSONString]
                                  authorsFrom:nil
                                 inCollection:collection];

    [self.client unlikeContent:entry onComplete:^(BOOL error, id resultOrError) {
        if (error) {
            STFail(resultOrError);
        }
        else {
            STAssertEquals(entry, resultOrError, nil);
        }
    }];

    [self waitForTests];
}

#define SetOrFail(obj) \
    (^(BOOL error, id resultOrError) { \
        if (error) { \
            STFail(resultOrError); \
        } \
        else { \
            obj = resultOrError; \
        } \
    })

- (NSString *)createTestCollection:(NSString *)articleId {
    __block NSString *collectionId = nil;

    [self.client createCollection:@"integration test collection"
                       forArticle:articleId
                            atUrl:@"http://www.example.com"
                          forSite:[Config objectForKey:@"site"]
                          withKey:[Config objectForKey:@"site key"]
                         withTags:@""
                collectionCreated:SetOrFail(collectionId)];

    [self waitForTests];
    if (!collectionId)
        return nil;

    [self.client updateCollection:@"integration test collection"
                       forArticle:articleId
                            atUrl:@"http://www.example.com/url"
                          forSite:[Config objectForKey:@"site"]
                          withKey:[Config objectForKey:@"site key"]
                         withTags:@"tag"
                collectionUpdated:^(BOOL error, id resultOrError) {
                    if (error) {
                        STFail(resultOrError);
                    }
                    else {
                        STAssertEqualObjects(collectionId, resultOrError, nil);
                        if (![collectionId isEqual:resultOrError])
                            collectionId = nil;
                    }
                }];

    [self waitForTests];
    return collectionId;
}

- (User *)authUser:(NSString*)userId collectionId:(NSString *)collectionId {
    __block User *user = nil;
    [self.client authenticateUser:userId
                    forCollection:collectionId
                          gotUser:SetOrFail(user)];
    [self waitForTests];
    return user;
}

#define AssertEqualsOrReturn(a1, a2) \
    do { \
        STAssertEquals(a1, a2, nil); \
        if (a1 != a2) { \
            die = YES; \
            return; \
        } \
    } while (0)

#define AssertTrueOrReturn(a) \
    do { \
        STAssertTrue(a, nil); \
        if (!a) { \
            die = YES; \
            return; \
        } \
    } while (0)

#define CheckError(errmsg) \
    do { \
        if (error) { \
            STFail(errmsg); \
            die = YES; \
            return; \
        } \
    } while (0)

- (void)getCollectionPost:(Collection *)collection {
    __block BOOL die = NO;
    [collection fetchBootstrap:^(BOOL error, id resultOrError) {
        CheckError(resultOrError);
    }];

    // There might not be any extra pages if the one post is in the bootstrap data
    if (collection.numberOfPages) {
        STAssertEquals(collection.numberOfPages, 1u, nil);
        [collection fetchPage:0 gotPage:^(BOOL error, id resultOrError) {
            CheckError(resultOrError);
        }];
    }

    [self waitForTests];
    if (die)
        return;

    // Might still not have gotten the post, in which case there should be data
    // available immediately in the stream;
    if (![collection.posts count]) {
        [self.client startPollingForUpdates:collection
                              pollFrequency:30
                             requestTimeout:1
                                gotNewPosts:^(BOOL error, id resultOrError) {
                                    [self.client stopPollingForUpdates:collection];

                                    CheckError(resultOrError);
                                }];
    }
    [self waitForTests];
}

- (void)testTwoUserPostingAndStream {
    // Flow tested here:
    //
    // 1. Create a new collection
    // 2. Edit it
    // 3. Authenticate as dev00 and load the collection
    // 4. Create a post in the collection
    // 5. Load the collection as an anonymous user, verify the post created in
    //    #4 is present after loading all data
    // 6. Start streaming as the anon user
    // 7. Make another post, verify that anon got it
    // 8. Make a reply, verify that anon got it
    // 9. Like a post, verify that anon got it
    // 10. Unlike the post, verify that anon got it
    //
    // Editing and deleting posts are not tested here as they're currently not
    // supported

    NSString *articleId = [NSString stringWithFormat:@"integration test collection %d", (int)time(NULL)];
    NSString *collectionId = [self createTestCollection:articleId];
    if (!collectionId)
        return;

    User *readOnlyUser = nil;
    User *readWriteUser = [self authUser:@"dev00" collectionId:collectionId];
    if (!readWriteUser)
        return;

    __block Collection *readWriteCollection = nil;
    [self.client getCollectionForArticle:articleId
                                  inSite:[Config objectForKey:@"site"]
                                 forUser:readWriteUser
                           gotCollection:SetOrFail(readWriteCollection)];

    [self waitForTests];
    if (!readWriteCollection)
        return;

    STAssertEquals([readWriteCollection.authors count], 0u, nil);
    STAssertEquals([readWriteCollection.followers count], 0u, nil);
    STAssertEquals([readWriteCollection.posts count], 0u, nil);
    STAssertEqualObjects(readWriteCollection.collectionId, collectionId, nil);
    STAssertEquals(readWriteCollection.user, readWriteUser, nil);
    STAssertEquals(readWriteCollection.numberOfPages, 0u, nil);

    NSString *postBody = @"first post body";
    __block BOOL die = NO;
    [self.client createPost:postBody
               inCollection:readWriteCollection
                 onComplete:^(BOOL error, id newPost)
     {
         CheckError(newPost);

         STAssertNotNil(newPost, nil);
         STAssertTrue([newPost isKindOfClass:[Post class]], nil);
         STAssertTrue([[newPost body] rangeOfString:postBody].location != NSNotFound, nil);
         STAssertTrue([[[newPost author] authorId] hasPrefix:readWriteUser.userId], nil);
         STAssertEquals([readWriteCollection.posts count], 1u, nil);
         STAssertEquals([readWriteCollection.posts objectAtIndex:0], newPost, nil);
     }];

    [self waitForTests];
    if (die)
        return;

    __block Collection *readOnlyCollection = nil;
    [self.client getCollectionForArticle:articleId
                                  inSite:[Config objectForKey:@"site"]
                                 forUser:readOnlyUser
                           gotCollection:SetOrFail(readOnlyCollection)];

    [self waitForTests];
    if (!readOnlyCollection)
        return;

    STAssertEquals([readOnlyCollection.authors count], 0u, nil);
    STAssertEquals([readOnlyCollection.followers count], 0u, nil);
    STAssertEquals([readOnlyCollection.posts count], 0u, nil);
    STAssertEqualObjects(readOnlyCollection.collectionId, collectionId, nil);
    STAssertNil(readOnlyCollection.user, nil);

    [self getCollectionPost:readOnlyCollection];

    AssertEqualsOrReturn([readOnlyCollection.posts count], 1u);
    Post *firstPost = [readOnlyCollection.posts objectAtIndex:0];
    STAssertTrue([firstPost isKindOfClass:[Post class]], nil);
    STAssertTrue([[firstPost body] rangeOfString:postBody].location != NSNotFound, nil);
    STAssertTrue([[[firstPost author] authorId] hasPrefix:readWriteUser.userId], nil);

    [self.client startPollingForUpdates:readOnlyCollection
                          pollFrequency:30
                         requestTimeout:30
                            gotNewPosts:^(BOOL error, id resultOrError) {
                                // Stopping and restarting polling each time
                                // so that waitForTests works
                                [self.client stopPollingForUpdates:readOnlyCollection];

                                CheckError(resultOrError);

                                AssertTrueOrReturn([resultOrError respondsToSelector:@selector(count)]);
                                AssertEqualsOrReturn([resultOrError count], 1u);
                                Post *newPost = [resultOrError objectAtIndex:0];
                                AssertTrueOrReturn([newPost isKindOfClass:[Post class]]);

                                STAssertTrue([newPost.body rangeOfString:@"reply body"].location != NSNotFound, nil);
                                STAssertTrue([newPost.author.authorId hasPrefix:readWriteUser.userId], nil);
                            }];

    [self.client createPost:@"reply body"
                  inReplyTo:[readWriteCollection.posts objectAtIndex:0]
                 onComplete:^(BOOL error, id resultOrError) {
                     CheckError(resultOrError);
                     STAssertTrue([[resultOrError body] rangeOfString:@"reply body"].location != NSNotFound, nil);
                     STAssertTrue([[[resultOrError author] authorId] hasPrefix:readWriteUser.userId], nil);
                 }];

    [self waitForTests];
    if (die)
        return;

    AssertEqualsOrReturn([[[readOnlyCollection.posts objectAtIndex:0] children] count], 1u);
    AssertEqualsOrReturn([[[readWriteCollection.posts objectAtIndex:0] children] count], 1u);
    Post *roReply = [[[readOnlyCollection.posts objectAtIndex:0] children] objectAtIndex:0];
    Post *rwReply = [[[readOnlyCollection.posts objectAtIndex:0] children] objectAtIndex:0];

    STAssertEqualObjects(roReply.entryId, rwReply.entryId, nil);
    STAssertEqualObjects(roReply.author.authorId, rwReply.author.authorId, nil);
    STAssertEquals(roReply.createdAt, rwReply.createdAt, nil);
    STAssertEquals(roReply.editedAt, rwReply.editedAt, nil);
    STAssertEquals(roReply.source, rwReply.source, nil);
    STAssertEquals(roReply.contentType, rwReply.contentType, nil);
    STAssertEquals(roReply.visibility, rwReply.visibility, nil);
    STAssertEqualObjects(roReply.replaces, rwReply.replaces, nil);
    STAssertEqualObjects(roReply.parentId, rwReply.parentId, nil);
    STAssertEquals(roReply.deleted, rwReply.deleted, nil);
    STAssertEqualObjects(roReply.body, rwReply.body, nil);

    // Need another user for likes as users can't like their own posts
    __block Collection *likeUserCollection = nil;
    [self.client getCollectionForArticle:articleId
                                  inSite:[Config objectForKey:@"site"]
                             forUserName:@"dev01"
                           gotCollection:SetOrFail(likeUserCollection)];

    [self waitForTests];
    if (!likeUserCollection)
        return;

    User *likeUser = likeUserCollection.user;
    STAssertNotNil(likeUser, nil);

    STAssertEquals([likeUserCollection.authors count], 0u, nil);
    STAssertEquals([likeUserCollection.followers count], 0u, nil);
    STAssertEquals([likeUserCollection.posts count], 0u, nil);
    STAssertEqualObjects(likeUserCollection.collectionId, collectionId, nil);
    AssertEqualsOrReturn(likeUserCollection.user, likeUser);

    [self getCollectionPost:likeUserCollection];
    AssertEqualsOrReturn([likeUserCollection.posts count], 1u);

    [self.client startPollingForUpdates:readOnlyCollection
                          pollFrequency:30
                         requestTimeout:30
                            gotNewPosts:^(BOOL error, id resultOrError) {
                                // Stopping and restarting polling each time
                                // so that waitForTests works
                                [self.client stopPollingForUpdates:readOnlyCollection];

                                CheckError(resultOrError);
                                AssertTrueOrReturn([resultOrError respondsToSelector:@selector(count)]);
                                AssertEqualsOrReturn([resultOrError count], 1u);
                                Post *likedPost = [resultOrError objectAtIndex:0];
                                AssertEqualsOrReturn(likedPost, firstPost);

                                AssertEqualsOrReturn([likedPost.likes count], 1u);
                                 STAssertTrue([[[[likedPost.likes objectAtIndex:0] author] authorId] hasPrefix:likeUser.userId], nil);
                            }];

    [self.client likeContent:[likeUserCollection.posts objectAtIndex:0]
                  onComplete:^(BOOL error, id resultOrError) {
                      CheckError(resultOrError);
                      Post *likedPost = resultOrError;
                      AssertEqualsOrReturn(likedPost, [likeUserCollection.posts objectAtIndex:0]);
                      AssertEqualsOrReturn([likedPost.likes count], 1u);
                      STAssertTrue([[[[likedPost.likes objectAtIndex:0] author] authorId] hasPrefix:likeUser.userId], nil);
                  }];

    [self waitForTests];
    if (die)
        return;

    [self.client startPollingForUpdates:readOnlyCollection
                          pollFrequency:30
                         requestTimeout:30
                            gotNewPosts:^(BOOL error, id resultOrError) {
                                // Stopping and restarting polling each time
                                // so that waitForTests works
                                [self.client stopPollingForUpdates:readOnlyCollection];

                                CheckError(resultOrError);
                                AssertTrueOrReturn([resultOrError respondsToSelector:@selector(count)]);
                                AssertEqualsOrReturn([resultOrError count], 1u);
                                Post *unlikedPost = [resultOrError objectAtIndex:0];
                                AssertEqualsOrReturn(unlikedPost, firstPost);

                                AssertEqualsOrReturn([unlikedPost.likes count], 0u);
                            }];

    [self.client unlikeContent:[likeUserCollection.posts objectAtIndex:0]
                    onComplete:^(BOOL error, id resultOrError) {
                        CheckError(resultOrError);
                        Post *unlikedPost = resultOrError;
                        AssertEqualsOrReturn(unlikedPost, [likeUserCollection.posts objectAtIndex:0]);
                        AssertEqualsOrReturn([unlikedPost.likes count], 0u);
                    }];

    [self waitForTests];
}

#if 0
- (void)testCreatePost {
    Collection *collection = [self collection];

    NSString *postBody = [NSString stringWithFormat:@"test post body %d", (int)time(NULL)];
    [self.client createPost:postBody
               inCollection:collection
                 onComplete:^(BOOL error, id newPost)
    {
        [self completedTest];
        if (error) {
            STFail(newPost);
        }
        else {
            STAssertNotNil(newPost, nil);
            STAssertTrue([newPost isKindOfClass:[Post class]], nil);
            STAssertTrue([[newPost body] rangeOfString:postBody].location != NSNotFound, nil);
        }
    }];

    [self waitForTests];
}
#endif

@end

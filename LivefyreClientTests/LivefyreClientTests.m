//
//  LivefyreClientTests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LivefyreClientTests.h"

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

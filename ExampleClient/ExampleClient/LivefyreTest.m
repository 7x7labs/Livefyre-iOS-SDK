//
//  LivefyreTest.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/14/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LivefyreTest.h"

#import <LivefyreClient/LivefyreClient.h>

@interface LivefyreTest ()
@property (weak, nonatomic) id <LogSink> log;
@property (strong, nonatomic) Collection *collectionData;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) LivefyreClient *client;
@property (strong, nonatomic) NSString *siteId;
@property (strong, nonatomic) NSString *siteKey;
@end

@implementation LivefyreTest
@synthesize log = log_;
@synthesize userName = userName_;
@synthesize articleId = articleId_;
@synthesize collectionData = collectionData_;
@synthesize user = user_;
@synthesize client = client_;
@synthesize siteId = siteId_;
@synthesize siteKey = siteKey_;

- (id)initWithLogger:(id<LogSink>)logger {
    self = [super init];
    if (self) {
        self.log = logger;

        NSString *path = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"plist"];
        NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:path];

        self.siteId = [settings objectForKey:@"site"];
        self.siteKey = [settings objectForKey:@"site key"];

        self.client = [LivefyreClient clientWithDomain:[settings objectForKey:@"domain"]
                                           environment:[settings objectForKey:@"environment"]
                                         bootstrapHost:[settings objectForKey:@"bootstrap host"]
                                             domainKey:[settings objectForKey:@"domain key"]];
    }
    return self;
}

- (void)createCollection {
    [self.client createCollection:@"Test Article Name"
                       forArticle:self.articleId
                            atUrl:@"http://www.example.com"
                          forSite:self.siteId
                          withKey:self.siteKey
                         withTags:@"tag1,tag2"
                collectionCreated:^(BOOL error, NSString *collectionId) {
                    if (error)
                        [self.log log:collectionId];
                    else
                        [self.log logWithFormat:@"collection created: %@\n", collectionId];
                }];
}

- (void)createPost {
    [self.log clear];
    [self.client createPost:[NSString stringWithFormat:@"test post body %d", (int)time(NULL)]
               inCollection:self.collectionData
                 onComplete:^(BOOL error, id newPost) {
                     if (error)
                         [self.log log:newPost];
                     else
                         [self printEvents:newPost indent:0];
                 }];
}

- (void)authenticate {
    [self.client authenticateUser:self.userName
                          forSite:self.siteId
                       forArticle:self.articleId
                          gotUser:^(BOOL error, id user)
     {
         if (error) {
             [self.log log:user];
             return;
         }

         self.user = user;
         [self.log logWithFormat:@"ID: %@\nDisplay Name: %@\nSettings URL:%@\nProfile URL: %@\nAvatar URL: %@\nIs Moderator: %@\n\n",
          self.user.userId, self.user.displayName,
          self.user.settingsUrl, self.user.profileUrl,
          self.user.avatarUrl,
          self.user.isModerator ? @"Yes" : @"No",
          nil];
     }];
}

- (void)getCollectionData {
    [self.client getCollectionForArticle:self.articleId
                                  inSite:self.siteId
                                 forUser:self.user
                                gotCollection:^(BOOL error, id newCollection)
     {
         [self.log clear];
         if (error)
             [self.log log:newCollection];
         else {
             self.collectionData = newCollection;
             [newCollection fetchBootstrap:^(BOOL error, id resultOrError) {
                 if (error)
                     [self.log log:resultOrError];
                 else
                     [self collectionChanged:newCollection];
             }];
         }
     }];
}

- (void)collectionChanged:(Collection *)collection {
    [self.log clear];
    [self.log logWithFormat:@"collectionId: %@\nentries: %d\nauthors: %d\nfollowing: %d\n",
     self.collectionData.collectionId,
     self.collectionData.posts.count,
     self.collectionData.authors.count,
     self.collectionData.followers.count];

    for (Post *event in collection.posts) {
        [self printEvents:event indent:0];
    }

    if ([[collection availableDataRanges] count])
        [collection fetchRange:[[collection availableDataRanges] lastObject]
                      gotRange:^(BOOL error, id resultOrError) {
                          if (error)
                              [self.log log:resultOrError];
                          else
                              [self collectionChanged:collection];
                      }];
}

- (void)printEvents:(Post *)post indent:(int)indent {
    NSString *displayName = post.author.displayName;
    if (!displayName)
        displayName = @"AUTHOR NOT FOUND";

    if (post.deleted) {
        [self.log logWithFormat:@"\n%@deleted post\n",
         [@"" stringByPaddingToLength:(indent * 4) withString:@" " startingAtIndex:0]];
    }
    else {
        [self.log logWithFormat:@"\n%@%@: %@\n",
         [@"" stringByPaddingToLength:(indent * 4) withString:@" " startingAtIndex:0],
         displayName,
         post.body];
    }

    for (Post *child in post.children) {
        [self printEvents:child indent:(indent + 1)];
    }

    for (Embed *embed in post.embed) {
        [self.log logWithFormat:@"\n%@Embed: %@\n",
         [@"" stringByPaddingToLength:((indent + 1) * 4) withString:@" " startingAtIndex:0],
         embed.title];
    }
}

- (void)startPolling {
    [self.client startPollingForUpdates:self.collectionData
                          pollFrequency:30
                         requestTimeout:30
                            gotNewPosts:^(BOOL error, id resultOrError) {
                                if (error) {
                                    [self.log clear];
                                    [self.log log:resultOrError];
                                }
                                else {
                                    [self collectionChanged:self.collectionData];
                                }
                            }];
}

- (void)stopPolling {
    [self.client stopPollingForUpdates:self.collectionData];
}

@end

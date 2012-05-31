//
//  LivefyreTest.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LivefyreTest.h"

#import <LivefyreClient/LivefyreClient.h>

@interface LivefyreTest () <CollectionObserver>
@property (weak, nonatomic) id <LogSink> log;
@property (strong, nonatomic) CollectionData *collectionData;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) LivefyreClient *client;
@end

@implementation LivefyreTest
@synthesize log = log_;
@synthesize userName = userName_;
@synthesize articleId = articleId_;
@synthesize collectionData = collectionData_;
@synthesize user = user_;
@synthesize client = client_;

static NSString *domain = @"7x7-1.fyre.co";
static NSString *domainKey = @"eTvNxyEDiCV8OGuH6m4lk5q//C8=";
static NSString *siteKey = @"bNyBbN0BWAZ46w3fGBGg9ziB0U4=";
static NSString *siteId = @"303617";

- (id)initWithLogger:(id<LogSink>)logger {
    self = [super init];
    if (self) {
        self.log = logger;
        self.client = [LivefyreClient clientWithDomain:domain domainKey:domainKey];
    }
    return self;
}

- (void)createCollection {
    [self.client createCollection:@"Test Article Name"
                       forArticle:self.articleId
                            atUrl:@"http://www.example.com"
                          forSite:siteId
                          withKey:siteKey
                         withTags:@"tag1,tag2"
                collectionCreated:^(NSString *collectionId, NSString *checksum) {
                    [self.log logWithFormat:@"collection created: %@ %@\n", collectionId, checksum];
                }];
}

- (void)authenticate {
    [self.client authenticateUser:self.userName
                          forSite:siteId
                       forArticle:self.articleId
                          gotUser:^(User *user) {
                              if (user) {
                                  self.user = user;
                                  [self.log logWithFormat:@"ID: %@\nDisplay Name: %@\nSettings URL:%@\nProfile URL: %@\nAvatar URL: %@\nIs Moderator: %@\n\n",
                                   user.userId, user.displayName,
                                   user.settingsUrl, user.profileUrl,
                                   user.avatarUrl,
                                   user.isModerator ? @"Yes" : @"No",
                                   nil];
                              }
                              else {
                                  [self.log log:@"get user failed\n"];
                              }
                          }];
}

- (void)getCollectionData {
    self.collectionData = [self.client getCollectionForArticle:self.articleId
                                                        inSite:siteId
                                                       forUser:self.user];
    [self.collectionData addCollectionObserver:self];
}

- (void)collectionChanged:(CollectionData *)collection {
    [self.log clear];
    [self.log logWithFormat:@"collectionId: %@\nentries: %d\nauthors: %d\nfollowing: %d\n",
     self.collectionData.collectionId,
     self.collectionData.events.count,
     self.collectionData.authors.count,
     self.collectionData.followers.count];

    for (Post *event in collection.events) {
        [self printEvents:event indent:0];
    }

    if ([[collection availableDataRanges] count])
        [collection fetchRange:[[collection availableDataRanges] lastObject]];
}

- (void)printEvents:(Post *)post indent:(int)indent {
    NSString *displayName = post.author.displayName;
    if (!displayName)
        displayName = @"AUTHOR NOT FOUND";

    [self.log logWithFormat:@"\n%@%@: %@\n",
     [@"" stringByPaddingToLength:(indent * 4) withString:@" " startingAtIndex:0],
     displayName,
     post.body];

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
    [self.client startPollingForUpdates:self.collectionData pollFrequency:30 requestTimeout:30];
}

- (void)stopPolling {
    [self.client stopPollingForUpdates:self.collectionData];
}

@end

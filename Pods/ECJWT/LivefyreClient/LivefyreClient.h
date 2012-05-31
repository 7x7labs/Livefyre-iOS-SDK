//
//  LivefyreClient.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <LivefyreClient/Author.h>
#import <LivefyreClient/CollectionData.h>
#import <LivefyreClient/Entry.h>
#import <LivefyreClient/User.h>

@class CollectionData;
@class Entry;
@class User;

typedef void (^UserCallback)(User *);
typedef void (^CreateCollectionCallback)(NSString *collectionId, NSString *checksum);
typedef void (^LikeCallback)(NSString *messageIdOrError);

@interface LivefyreClient : NSObject
+ (LivefyreClient *)clientWithDomain:(NSString *)domain domainKey:(NSString *)key;

- (void)authenticateUser:(NSString *)userName
           forCollection:(NSString *)collectionId
                 gotUser:(UserCallback)callback;

- (void)authenticateUser:(NSString *)userName
                 forSite:(NSString *)siteId
              forArticle:(NSString *)articleId
                 gotUser:(UserCallback)callback;

- (void)createCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionCreated:(CreateCollectionCallback)callback;

- (void)updateCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionUpdated:(CreateCollectionCallback)callback;

- (CollectionData *)getCollectionForArticle:(NSString *)articleId
                                     inSite:(NSString *)siteId
                                    forUser:(User *)user;

- (void)startPollingForUpdates:(CollectionData *)collection
                 pollFrequency:(NSTimeInterval)frequency
                requestTimeout:(NSTimeInterval)timeout;

- (void)stopPollingForUpdates:(CollectionData *)collection;

- (void)likeContent:(Entry *)entry
       inCollection:(CollectionData *)collection
         onComplete:(LikeCallback)callback;

- (void)unlikeContent:(Entry *)entry
         inCollection:(CollectionData *)collection
           onComplete:(LikeCallback)callback;

@end

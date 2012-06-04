//
//  LivefyreClient.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/18/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <LivefyreClient/Author.h>
#import <LivefyreClient/Collection.h>
#import <LivefyreClient/Entry.h>
#import <LivefyreClient/User.h>

/// LivefyreClient is the top-level interface to the Livefyre SDK.
@interface LivefyreClient : NSObject
/// Create a new Livefyre client.
/// @param domain The Livefyre domain, including TLD, but not protocol.
/// @param key    The Livefyre API key for the domain.
+ (LivefyreClient *)clientWithDomain:(NSString *)domain
                           domainKey:(NSString *)key;

/// Are there currently any running asynchronous requests triggered by this
/// client?
- (BOOL)pendingAsyncRequests;

/// Authenticate a user for accessing and posting to a collection.
/// @param userName The user's ID.
/// @param collectionId The ID of the collection to get access to.
/// @param callback Block to call with the `User` object.
- (void)authenticateUser:(NSString *)userName
           forCollection:(NSString *)collectionId
                 gotUser:(RequestComplete)callback;

/// Authenticate a user for accessing and posting to a collection.
/// @param userName The user's ID.
/// @param siteId The site containing the desired collection.
/// @param articleId The article which the collection is for.
/// @param callback Block to call with the `User` object.
- (void)authenticateUser:(NSString *)userName
                 forSite:(NSString *)siteId
              forArticle:(NSString *)articleId
                 gotUser:(RequestComplete)callback;

/// Create a new collection for comments on an article.
/// @param title Title of the article.
/// @param articleId Unique ID of the article.
/// @param url URL of the article.
/// @param siteId ID of the site the article is in.
/// @param siteKey Livefyre API key for the site.
/// @param tags Comma separated list of tags for the collection.
/// @param callback Block to call with the ID of the new collection.
- (void)createCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionCreated:(RequestComplete)callback;

/// Update the metadata for an existing collection.
/// @param title New title of the article.
/// @param articleId Unique ID of the article.
/// @param url New URL of the article.
/// @param siteId ID of the site the article is in.
/// @param siteKey Livefyre API key for the site.
/// @param tags New comma separated list of tags for the collection.
/// @param callback Block to call with the ID of the updated collection.
- (void)updateCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionUpdated:(RequestComplete)callback;

/// Get the collection for an article.
/// @param articleId The ID of the article to get the collection for.
/// @param siteId    The ID of the site the article is in.
/// @param user      The user to get the collection for, or nil to access the
/// collection anonymously.
/// @param callback Callback called with the Collection once the metadata has
/// been retrieved.
- (void)getCollectionForArticle:(NSString *)articleId
                         inSite:(NSString *)siteId
                        forUser:(User *)user
                  gotCollection:(RequestComplete)callback;

/// Start polling for updates made to the contents of a Collection.
/// @param collection Collection to start polling for updates.
/// @param frequency How often in seconds to check for new content.
/// @param timeout Timeout in seconds for the long-poll requests.
/// @param callback Callback to call when new data arrives.
- (void)startPollingForUpdates:(Collection *)collection
                 pollFrequency:(NSTimeInterval)frequency
                requestTimeout:(NSTimeInterval)timeout
                   gotNewPosts:(RequestComplete)callback;

/// Stop polling for new posts made to a collection.
/// @param collection Collection to start polling.
- (void)stopPollingForUpdates:(Collection *)collection;

/// Like a post in a collection.
/// @param entry The post to Like.
/// @param callback Callback called with the ID of the post which was liked.
///
/// The post must be from a logged-in user's Collection and posted by a
/// different user.
- (void)likeContent:(Entry *)entry
         onComplete:(RequestComplete)callback;

/// Unlike a post in a collection.
/// @param entry The post to Unlike.
/// @param callback Callback called with the ID of the post which was unliked.
///
/// The post must be from a logged-in user's Collection and posted by a
/// different user.
///
/// This has no effect if the post was not previously liked.
- (void)unlikeContent:(Entry *)entry
           onComplete:(RequestComplete)callback;

/// Create a new top-level post in a collection.
/// @param body HTML body of the new post.
/// @param collection Collection to add the post to.
/// @param callback Callback called with the new `Post`.
- (void)createPost:(NSString *)body
      inCollection:(Collection *)collection
        onComplete:(RequestComplete)callback;

/// Create a reply to an existing post in a collection.
/// @param body HTML body of the new post.
/// @param parent Parent post to reply to.
/// @param callback Callback called with the new `Post`.
- (void)createPost:(NSString *)body
         inReplyTo:(Post *)parent
        onComplete:(RequestComplete)callback;

@end

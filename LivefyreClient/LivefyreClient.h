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
#import <LivefyreClient/Content.h>
#import <LivefyreClient/User.h>

/// LivefyreClient is the top-level interface to the Livefyre SDK.
///
/// As most of the client operations require accessing the Livefyre servers,
/// they follow a consistent asynchronous design. Rather than returning the
/// result of the operation, they take a RequestComplete block, which is
/// invoked when the operation completes or fails. This block is called with
/// two parameters: a `BOOL` which indicates whether or not the operation
/// failed, and an `id` which is either the error message (if the `BOOL` is
/// `YES`), or the return value. The type of the return value varies between
/// operations, and is documented with each method.
@interface LivefyreClient : NSObject
/// Create a new Livefyre client.
/// @param domain The Livefyre domain, including TLD, but not protocol (e.g.
/// @"7x7-1.fyre.co").
/// @param key The Livefyre API key for authenticating users on the domain.
///
/// The domain key is optional; if not supplied then authenticateUserWithToken
/// must be used rather than authenticateUser. Not supplying the key is
/// potentially more secure, as it makes it possible to avoid ever having the
/// domain key on the user's device.
+ (LivefyreClient *)clientWithDomain:(NSString *)domain
                           domainKey:(NSString *)key;

/// Create a new Livefyre client.
/// @param domain The Livefyre domain, including TLD, but not protocol (e.g.
/// @"7x7-1.fyre.co").
/// @param bootstrapHost The server hostname for the bootstrap data. If `nil` or
/// not specified, the standard production server is used.
/// @param key The Livefyre API key for authenticating users on the domain.
///
/// The domain key is optional; if not supplied then authenticateUserWithToken
/// must be used rather than authenticateUser. Not supplying the key is
/// potentially more secure, as it makes it possible to avoid ever having the
/// domain key on the user's device.
+ (LivefyreClient *)clientWithDomain:(NSString *)domain
                       bootstrapHost:(NSString *)bootstrapRoot
                           domainKey:(NSString *)key;

/// Create a new Livefyre client.
/// @param domain The Livefyre domain, including TLD, but not protocol (e.g.
/// @"7x7-1.fyre.co").
/// @param environment The server environment to use. If not specified the
/// standard production environment is used.
/// @param key The Livefyre API key for authenticating users on the domain.
///
/// The domain key is optional; if not supplied then authenticateUserWithToken
/// must be used rather than authenticateUser. Not supplying the key is
/// potentially more secure, as it makes it possible to avoid ever having the
/// domain key on the user's device.
+ (LivefyreClient *)clientWithDomain:(NSString *)domain
                         environment:(NSString *)environment
                           domainKey:(NSString *)key;

/// Create a new Livefyre client.
/// @param domain The Livefyre domain, including TLD, but not protocol (e.g.
/// @"7x7-1.fyre.co").
/// @param bootstrapHost The server hostname for the bootstrap data. If `nil` or
/// not specified, the standard production server is used.
/// @param environment The server environment to use. If `nil` or not specified
/// the standard production environment is used.
/// @param key The Livefyre API key for authenticating users on the domain.
///
/// The domain key is optional; if not supplied then authenticateUserWithToken
/// must be used rather than authenticateUser. Not supplying the key is
/// potentially more secure, as it makes it possible to avoid ever having the
/// domain key on the user's device.
+ (LivefyreClient *)clientWithDomain:(NSString *)domain
                         environment:(NSString *)environment
                       bootstrapHost:(NSString *)bootstrapHost
                           domainKey:(NSString *)key;


/// Are there currently any running asynchronous requests triggered by this
/// client?
- (BOOL)pendingAsyncRequests;

/// @name User Authentication

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

/// Authenticate a user for accessing and posting to a collection.
/// @param userToken The user's Livefyre token.
/// @param collectionId The ID of the collection to get access to.
/// @param callback Block to call with the `User` object.
- (void)authenticateUserWithToken:(NSString *)userToken
                    forCollection:(NSString *)collectionId
                          gotUser:(RequestComplete)callback;

/// Authenticate a user for accessing and posting to a collection.
/// @param userToken The user's Livefyre token.
/// @param siteId The site containing the desired collection.
/// @param articleId The article which the collection is for.
/// @param callback Block to call with the `User` object.
- (void)authenticateUserWithToken:(NSString *)userToken
                          forSite:(NSString *)siteId
                       forArticle:(NSString *)articleId
                          gotUser:(RequestComplete)callback;

/// @name Collection Management

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

/// @name Collection Retrieval

/// Get the collection of comments for an article.
/// @param articleId The ID of the article to get the collection for.
/// @param siteId    The ID of the site the article is in.
/// @param user      The user to get the collection for, or nil to access the
/// collection anonymously.
/// @param callback Callback called with the Collection once the metadata has
/// been retrieved.
///
/// If no user is supplied, it will not be possible to create new posts or
/// (un)like existing posts, and only publicly-visible comments will be
/// displayed.
///
/// This method does not get any of the contents of the Collection; only the
/// metadata and information need to retrieve the contents. To fetch the posts,
/// see -[Collection fetchBootstrap:], -[Collection fetchPage:gotPage:], and
/// -[Collection fetchRange:gotRange:].
- (void)getCollectionForArticle:(NSString *)articleId
                         inSite:(NSString *)siteId
                        forUser:(User *)user
                  gotCollection:(RequestComplete)callback;

/// Get the collection for an article.
/// @param articleId The ID of the article to get the collection for.
/// @param siteId    The ID of the site the article is in.
/// @param userName  The ID of the user to get the collection for. Must not be nil.
/// @param callback Callback called with the Collection once the metadata has
/// been retrieved.
///
/// This method cannot be used for anonymous access; use
/// -[LivefyreClient getCollectionForArticle:inSite:forUser:gotCollection:] for
/// that.
///
/// This method does not get any of the contents of the Collection; only the
/// metadata and information need to retrieve the contents. To fetch the posts,
/// see -[Collection fetchBootstrap:], -[Collection fetchPage:gotPage:], and
/// -[Collection fetchRange:gotRange:].
- (void)getCollectionForArticle:(NSString *)articleId
                         inSite:(NSString *)siteId
                    forUserName:(NSString *)userName
                  gotCollection:(RequestComplete)callback;

/// Get the collection for an article.
/// @param articleId The ID of the article to get the collection for.
/// @param siteId    The ID of the site the article is in.
/// @param userToken A signed Livefyre token for the user to get the collection
/// for. Must not be nil.
/// @param callback Callback called with the Collection once the metadata has
/// been retrieved.
///
/// This method cannot be used for anonymous access; use
/// -[LivefyreClient getCollectionForArticle:inSite:forUser:gotCollection:] for
/// that.
///
/// This method does not get any of the contents of the Collection; only the
/// metadata and information need to retrieve the contents. To fetch the posts,
/// see -[Collection fetchBootstrap:], -[Collection fetchPage:gotPage:], and
/// -[Collection fetchRange:gotRange:].
- (void)getCollectionForArticle:(NSString *)articleId
                         inSite:(NSString *)siteId
                   forUserToken:(NSString *)userToken
                  gotCollection:(RequestComplete)callback;

/// Start polling for updates made to the contents of a Collection.
/// @param collection Collection to start polling for updates.
/// @param frequency How often in seconds to check for new content.
/// @param timeout Timeout in seconds for the long-poll requests.
/// @param callback Callback to call when new data arrives.
///
/// The gotNewPosts callback is invoked with an array of new or modified
/// contents when new content arrives from the server.
///
/// Content can only be streamed to a single callback for each collection.
/// Calling startPollingForUpdates while data is already being streamed for the
/// given collection will result in stopPollingForUpdates being called first.
///
/// Streamed content may or may not include new posts made via the same
/// collection as is being polled.
- (void)startPollingForUpdates:(Collection *)collection
                 pollFrequency:(NSTimeInterval)frequency
                requestTimeout:(NSTimeInterval)timeout
                   gotNewPosts:(RequestComplete)callback;

/// Stop polling for new posts made to a collection.
/// @param collection Collection to start polling.
- (void)stopPollingForUpdates:(Collection *)collection;

/// @name Content Creation

/// Like a post in a collection.
/// @param content The post to Like.
/// @param callback Callback called with the Post which was liked.
///
/// The post must be from a logged-in user's Collection and posted by a
/// different user.
///
/// Trying to Like things other than Posts may have odd results.
- (void)likeContent:(Content *)content
         onComplete:(RequestComplete)callback;

/// Unlike a post in a collection.
/// @param content The post to Unlike.
/// @param callback Callback called with Post which was unliked.
///
/// The post must be from a logged-in user's Collection and posted by a
/// different user.
///
/// This has no effect if the post was not previously liked.
- (void)unlikeContent:(Content *)content
           onComplete:(RequestComplete)callback;

/// Create a new top-level post in a collection.
/// @param body HTML body of the new post.
/// @param collection Collection to add the post to.
/// @param callback Callback called with the new `Post`.
///
/// Creating new posts requires that the Collection was created with a
/// logged-in user who has permission to post in the collection.
- (void)createPost:(NSString *)body
      inCollection:(Collection *)collection
        onComplete:(RequestComplete)callback;

/// Create a reply to an existing post in a collection.
/// @param body HTML body of the new post.
/// @param parent Parent post to reply to.
/// @param callback Callback called with the new `Post`.
///
/// Creating new posts requires that the Collection was created with a
/// logged-in user who has permission to post in the collection.
- (void)createPost:(NSString *)body
         inReplyTo:(Post *)parent
        onComplete:(RequestComplete)callback;

@end

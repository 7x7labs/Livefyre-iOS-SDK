//
//  CollectionData.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Author;
@class User;

/// A pair of a start and end date
@interface DateRange : NSObject
/// Start date/time, inclusive
@property (strong, nonatomic, readonly) NSDate *start;
/// End date/time, exclusive
@property (strong, nonatomic, readonly) NSDate *end;

/// Initialize a DateRange with the given start and end times
- (DateRange *)initWithStart:(NSDate *)start end:(NSDate *)end;
/// Create a DateRange with the given start and end times
+ (DateRange *)dateRangeWithStart:(int)start end:(int)end;
@end

/// The callback handler for an asynchronous method
///
/// @param error Did the operation fail? If this is `YES`, `resultOrError` is a
///              NSString with an error message.
/// @param resultOrError If error is `NO`, the return value of the operation.
typedef void (^RequestComplete)(BOOL error, id resultOrError);

/// `Collection` represents a single user's view of a Livefyre collection for
/// an article. When initially created, collections have the metadata fields
/// populated, but none of the contents such as authors and posts. To retrieve
/// the contents, `fetchBootstrap` can be called to retrieve the newest posts
/// in the collection, or `fetchPage` or `fetchRange` can be called to retrieve
/// a specific range of posts.
@interface Collection : NSObject
/// The authors of posts in this collection.
///
/// The key the author ID; the value is an `Author` object for the author.
@property (strong, nonatomic, readonly) NSDictionary *authors;
/// User IDs of users currently following this collection
@property (strong, nonatomic, readonly) NSArray *followers;
/// Top-level posts in this collection
@property (strong, nonatomic, readonly) NSArray *posts;

/// Livefyre ID of the collection
@property (strong, nonatomic, readonly) NSString *collectionId;
/// The User which this collection is for. May be `nil` if the collection was
/// fetched anonymously.
@property (strong, nonatomic, readonly) User *user;
/// Recommended maximum nesting level for replies to comments. Not enforced.
@property (nonatomic, readonly) int nestLevel;
/// The total number of visible comments in the collection, including ones
/// which have not been retrieved from the server yet.
@property (nonatomic, readonly) int numberVisible;
/// The number of users currently following the collection.
@property (nonatomic, readonly) int numberOfFollowers;
/// An array of DateRanges which are available but have not been fetched from
/// the server yet.
@property (nonatomic, readonly) NSArray *availableDataRanges;
/// The total number of pages of comments in the collection.
@property (nonatomic, readonly) NSUInteger numberOfPages;

@property (nonatomic, readonly) int64_t lastEvent;

+ (Collection *)collectionWithId:(NSString *)collectionId
                            user:(User *)user
                       nestLevel:(int)nestLevel
                   numberVisible:(int)numberVisible
               numberOfFollowers:(int)numberOfFollowers
                       lastEvent:(int64_t)lastEvent
                       bootstrap:(void(^)(Collection *, RequestComplete))bootstrap
                 additionalPages:(NSMutableArray *)additionalPages;

- (NSArray *)addAuthors:(NSDictionary *)authorData
               andPosts:(NSArray *)postData
           andFollowers:(NSArray *)followerData
              lastEvent:(int64_t)lastEvent;

- (NSArray *)addCollectionContent:(NSDictionary *)content
                      erefFetcher:(void (^)(NSString *))erefFetcher;

/// Fetch all posts within the given date range
/// @param range Range to retrieve posts for
/// @param callback Callback called with the array of new posts found in that
/// date range. May be called multiple times if the requested time range
/// requires multiple requests to retrieve.
/// @return The date range which was actually requested from the server.
- (DateRange *)fetchRange:(DateRange *)range gotRange:(RequestComplete)callback;

/// Fetch a single page of posts
/// @param pageNumber Page number to fetch
/// @param callback Callback to call with an array of the new posts.
///
/// Requesting the same page multiple times is an error.
- (void)fetchPage:(NSUInteger)pageNumber gotPage:(RequestComplete)callback;

/// Fetch the initial bootstrap data of the latest posts
/// @param callback Callback to call with the array of new posts
///
/// Fetching the bootstrap data multiple times is an error.
- (void)fetchBootstrap:(RequestComplete)callback;
@end

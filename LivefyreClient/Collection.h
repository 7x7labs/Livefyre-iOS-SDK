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

- (DateRange *)initWithStart:(NSDate *)start end:(NSDate *)end;
+ (DateRange *)dateRangeWithStart:(int)start end:(int)end;
@end

/// The callback handler for an asynchronous method
///
/// @param error Did the operation fail? If this is `YES`, `resultOrError` is a
///              NSString with an error message.
/// @param resultOrError If error is `NO`, the return value of the operation.
typedef void (^RequestComplete)(BOOL error, id resultOrError);

/// `Collection` represents a single user's view of a Livefyre collection for an
/// article. When initially created, collections have the metadata fields
/// populated, but no posts. To retrieve the posts, `fetchBootstrap` can be
/// called to retrieve the newest posts in the collection, or `fetchPage` or
/// `fetchRange` can be called to retrieve a specific range of posts
@interface Collection : NSObject
/// The authors of posts in this collection. Key is author Id, value is an
/// `Author` object for the author.
@property (strong, nonatomic, readonly) NSDictionary *authors;
/// IDs of users currently following this collection
@property (strong, nonatomic, readonly) NSArray *followers;
/// Top-level posts in this collection
@property (strong, nonatomic, readonly) NSArray *posts;

@property (strong, nonatomic, readonly) NSString *collectionId;
@property (strong, nonatomic, readonly) User *user;
@property (nonatomic, readonly) int nestLevel;
@property (nonatomic, readonly) int numberVisible;
@property (nonatomic, readonly) int numberOfFollowers;
@property (nonatomic, readonly) int64_t lastEvent;
@property (nonatomic, readonly) NSArray *availableDataRanges;
@property (nonatomic, readonly) NSUInteger numberOfPages;

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
/// @param callback Callback called with the array of new posts. May be called
///                 multiple times if the requested time range requires mulitple
///                 requests to retrieve.
/// @return The date range which was actually requested
- (DateRange *)fetchRange:(DateRange *)range gotRange:(RequestComplete)callback;

/// Fetch a single page of posts
/// @param pageNumber Page number to fetch
/// @param gotPage Callback to call with an array of the new posts. Will not be
///                called if the page was already retrieved.
- (void)fetchPage:(NSUInteger)pageNumber gotPage:(RequestComplete)callback;

/// Fetch the initial bootstrap data of the latest posts
/// @param callback Callback to call with the array of new posts
- (void)fetchBootstrap:(RequestComplete)callback;
@end

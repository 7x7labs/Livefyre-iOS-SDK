//
//  CollectionData.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Author;
@class CollectionData;
@class User;

@protocol CollectionObserver <NSObject>
- (void)collectionChanged:(CollectionData *)collection;
@end

@interface DateRange : NSObject
@property (strong, nonatomic, readonly) NSDate *start;
@property (strong, nonatomic, readonly) NSDate *end;

- (DateRange *)initWithStart:(NSDate *)start end:(NSDate *)end;
+ (DateRange *)dateRangeWithStart:(int)start end:(int)end;
@end

@interface CollectionData : NSObject
@property (strong, nonatomic, readonly) NSDictionary *authors;
@property (strong, nonatomic, readonly) NSArray *followers;
@property (strong, nonatomic, readonly) NSDictionary *events;

@property (strong, nonatomic, readonly) NSString *collectionId;
@property (strong, nonatomic, readonly) User *user;
@property (nonatomic, readonly) int nestLevel;
@property (nonatomic, readonly) int numberVisible;
@property (nonatomic, readonly) int numberOfFollowers;
@property (nonatomic, readonly) int64_t lastEvent;
@property (nonatomic, readonly) NSArray *availableDataRanges;
@property (nonatomic, readonly) NSUInteger numberOfPages;

- (id)init;

- (void)addAuthors:(NSDictionary *)authorData
          andPosts:(NSArray *)postData
      andFollowers:(NSArray *)followerData;

- (void)addAuthors:(NSDictionary *)authorData
          andPosts:(NSArray *)postData
         lastEvent:(int64_t)lastEvent;

- (void)setCollectionId:(NSString *)collectionId
                   user:(User *)user
              nestLevel:(int)nestLevel
          numberVisible:(int)numberVisible
      numberOfFollowers:(int)numberOfFollowers
              lastEvent:(int64_t)lastEvent
        additionalPages:(NSMutableArray *)additionalPages;

- (void)addCollectionObserver:(id <CollectionObserver>)observer;
- (void)removeCollectionObserver:(id <CollectionObserver>)observer;

- (DateRange *)fetchRange:(DateRange *)range;
- (void)fetchPage:(NSUInteger)pageNumber;
@end

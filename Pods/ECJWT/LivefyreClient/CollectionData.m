//
//  CollectionData.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CollectionData.h"

#import "Author.h"
#import "Entry.h"
#import "User.h"

@implementation DateRange
@synthesize start = start_;
@synthesize end = end_;

- (DateRange *)initWithStart:(NSDate *)start end:(NSDate *)end {
    if ([start compare:end] == NSOrderedDescending)
        return nil;

    self = [super init];
    if (self) {
        self->start_ = start;
        self->end_ = end;
    }
    return self;
}

+ (DateRange *)dateRangeWithStart:(int)start end:(int)end {
    return [[DateRange alloc] initWithStart:[NSDate dateWithTimeIntervalSince1970:start]
                                        end:[NSDate dateWithTimeIntervalSince1970:end]];
}
@end

@interface CollectionData () <AuthorLookup>
@property (strong, nonatomic) NSMutableArray *observers;
@property (strong, nonatomic) NSMutableArray *topLevelPosts;
@property (strong, nonatomic) NSMutableArray *additionalPages;
@property (strong, nonatomic) NSMutableDictionary *orphans;

- (Author *)authorForId:(NSString *)authorId;
@end

@implementation CollectionData {
    NSMutableDictionary *authors_;
    NSMutableDictionary *entries_;
    NSMutableArray *followers_;
}

@synthesize topLevelPosts = topLevelPosts_;
@synthesize observers = observers_;
@synthesize additionalPages = additionalPages_;
@synthesize orphans = orphans_;

@synthesize authors = authors_;
@synthesize followers = followers_;
@synthesize collectionId = collectionId_;
@synthesize user = user_;
@synthesize nestLevel = nestLevel_;
@synthesize numberVisible = numberVisible_;
@synthesize numberOfFollowers = numberOfFollowers_;
@synthesize lastEvent = lastEvent_;

- (NSArray *)events {
    return self.topLevelPosts;
}

- (NSArray *)availableDataRanges {
    BOOL (^notNull)(id, NSDictionary *) = ^BOOL(id evaluatedObject, NSDictionary *bindings){
        return evaluatedObject != [NSNull null];
    };

    return [[self.additionalPages valueForKey:@"range"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:notNull]];
}

- (NSUInteger)numberOfPages {
    return [self.additionalPages count];
}

- (id)init {
    self = [super init];
    if (self) {
        self->authors_ = [[NSMutableDictionary alloc] init];
        self->entries_ = [[NSMutableDictionary alloc] init];
        self->followers_ = [[NSMutableArray alloc] init];
        self.topLevelPosts = [[NSMutableArray alloc] init];
        self.orphans = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (Author *)authorForId:(NSString *)authorId {
    return [self.authors objectForKey:authorId];
}

- (void)addEntry:(NSDictionary *)entryData {
    Entry *entry = [Entry entryWithDictionary:entryData authorsFrom:self];

    if (!entry || ![self.user canViewEntry:entry])
        return;

    // There's two cases where the entry could already exist:
    // 1. We just got an earlier version of an already-replaced entry
    // 2. We got a second copy of the entry, as there's some overlap between
    //    the bootstrap data and the additional data
    //
    // In the second case we obviously don't need to do anything, but the first
    // probably does need some logic
    if ([self entryForKey:entry.entryId])
        return;

    [entries_ setObject:entry forKey:entry.entryId];

    Entry *parent = [self entryForKey:entry.parentId];
    if (entry.replaces) {
        Entry *replaced = [self entryForKey:entry.replaces];
        if (replaced) {
            [parent replaceChild:entry];
            [self.topLevelPosts removeObject:replaced];
        }

        [entries_ setObject:entry.entryId forKey:entry.replaces];
    }
    else if (parent) {
        [parent addChild:entry];
    }
    else if (entry.parentId) {
        // Has a parent but we haven't read the parent yet, so remember it until
        // the parent arrives
        NSMutableArray *siblings = [self.orphans objectForKey:entry.parentId];
        if (!siblings) {
            siblings = [[NSMutableArray alloc] init];
            [self.orphans setObject:siblings forKey:entry.parentId];
        }
        [siblings addObject:entry];
    }
    else if ([entry isKindOfClass:[Post class]])
        [self.topLevelPosts addObject:entry];

    for (NSDictionary *child in [entryData objectForKey:@"childContent"]) {
        [self addEntry:child];
    }

    NSMutableArray *children = [self.orphans objectForKey:entry.entryId];
    if (children) {
        for (Entry *child in children) {
            [entry addChild:child];
        }
        [self.orphans setObject:nil forKey:entry.entryId];
    }
}

- (Entry *)entryForKey:(NSString *)entryId {
    if (!entryId)
        return nil;

    id entry = [entries_ objectForKey:entryId];
    while ([entry isKindOfClass:[NSString class]]) {
        entry = [entries_ objectForKey:entry];
    }
    return entry;
}

- (void)addAuthors:(NSDictionary *)authorData
          andPosts:(NSArray *)postData
      andFollowers:(NSArray *)followerData
{
    [followers_ addObjectsFromArray:followerData];

    for (NSString *authorId in authorData) {
        if (![authors_ objectForKey:authorId])
            [authors_ setObject:[Author authorWithDictionary:[authorData objectForKey:authorId]]
                         forKey:authorId];
    }

    for (NSDictionary *post in postData) {
        [self addEntry:post];

    }

    [self.observers makeObjectsPerformSelector:@selector(collectionChanged:) withObject:self];
}

- (void)addAuthors:(NSDictionary *)authorData
          andPosts:(NSArray *)postData
         lastEvent:(int64_t)lastEvent
{
    for (NSString *authorId in authorData) {
        if (![authors_ objectForKey:authorId])
            [authors_ setObject:[Author authorWithDictionary:[authorData objectForKey:authorId]]
                         forKey:authorId];
    }

    for (NSDictionary *post in postData) {
        [self addEntry:post];

    }

    lastEvent_ = lastEvent;

    [self.observers makeObjectsPerformSelector:@selector(collectionChanged:) withObject:self];
}

- (void)setCollectionId:(NSString *)collectionId
                   user:(User *)user
              nestLevel:(int)nestLevel
          numberVisible:(int)numberVisible
      numberOfFollowers:(int)numberOfFollowers
              lastEvent:(int64_t)lastEvent
        additionalPages:(NSMutableArray *)additionalPages
{
    collectionId_ = collectionId;
    user_ = user;
    nestLevel_ = nestLevel;
    numberVisible_ = numberVisible;
    numberOfFollowers_ = numberOfFollowers;
    lastEvent_ = lastEvent;
    self.additionalPages = additionalPages;

    [self.observers makeObjectsPerformSelector:@selector(collectionChanged:) withObject:self];
}

- (void)addCollectionObserver:(id<CollectionObserver>)observer {
    if (!self.observers)
        self.observers = [[NSMutableArray alloc] init];
    [self.observers addObject:observer];
}

- (void)removeCollectionObserver:(id<CollectionObserver>)observer {
    [self.observers removeObject:observer];
}

- (DateRange *)fetchRange:(DateRange *)range {
    NSDate *start = nil, *end = nil;

    for (NSUInteger i = 0; i < self.additionalPages.count; ++i) {
        NSDictionary *availablePage = [self.additionalPages objectAtIndex:i];
        if ((id)availablePage == [NSNull null])
            continue;

        DateRange *pageRange = [availablePage objectForKey:@"range"];
        if ([range.start compare:pageRange.end] != NSOrderedAscending)
            continue;
        if ([range.end compare:pageRange.start] == NSOrderedAscending)
            break;

        if (!start)
            start = pageRange.start;
        end = pageRange.end;

        [self fetchPage:i];
    }

    if (start && end)
        return [[DateRange alloc] initWithStart:start end:end];
    return nil;
}

- (void)fetchPage:(NSUInteger)pageNumber {
    NSDictionary *page = [self.additionalPages objectAtIndex:pageNumber];
    if ((id)page != [NSNull null]) {
        ((void (^)(CollectionData *))[page objectForKey:@"callback"])(self);

        [self.additionalPages replaceObjectAtIndex:pageNumber withObject:[NSNull null]];
    }
}

@end

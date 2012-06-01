//
//  CollectionData.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Collection.h"

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

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]])
        return NO;
    DateRange *other = (DateRange *)object;
    return [self.start isEqual:other.start] && [self.end isEqual:other.end];
}

- (NSUInteger)hash {
    return (31 + [self.start hash]) * 31 + [self.end hash];
}
@end

@interface Collection () <AuthorLookup>
@property (strong, nonatomic) NSMutableArray *topLevelPosts;
@property (strong, nonatomic) NSMutableArray *additionalPages;
@property (strong, nonatomic) NSMutableDictionary *orphans;
@property (strong, nonatomic) void(^boostrap)(Collection *, RequestComplete);

- (Author *)authorForId:(NSString *)authorId;
@end

@implementation Collection {
    NSMutableDictionary *authors_;
    NSMutableDictionary *entries_;
    NSMutableArray *followers_;
}

@synthesize topLevelPosts = topLevelPosts_;
@synthesize additionalPages = additionalPages_;
@synthesize orphans = orphans_;
@synthesize boostrap = bootstrap_;

@synthesize authors = authors_;
@synthesize followers = followers_;
@synthesize collectionId = collectionId_;
@synthesize user = user_;
@synthesize nestLevel = nestLevel_;
@synthesize numberVisible = numberVisible_;
@synthesize numberOfFollowers = numberOfFollowers_;
@synthesize lastEvent = lastEvent_;

- (NSArray *)posts {
    return self.topLevelPosts;
}

- (NSArray *)availableDataRanges {
    BOOL (^notNull)(id, NSDictionary *) = ^BOOL(id evaluatedObject, NSDictionary *bindings){
        return evaluatedObject != [NSNull null];
    };

    return [[self.additionalPages valueForKey:@"range"]
            filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:notNull]];
}

- (NSUInteger)numberOfPages {
    return [self.additionalPages count];
}

+ (Collection *)collectionWithId:(NSString *)collectionId
                            user:(User *)user
                       nestLevel:(int)nestLevel
                   numberVisible:(int)numberVisible
               numberOfFollowers:(int)numberOfFollowers
                       lastEvent:(int64_t)lastEvent
                       bootstrap:(void(^)(Collection *, RequestComplete))bootstrap
                 additionalPages:(NSMutableArray *)additionalPages
{
    Collection *collection = [[Collection alloc] init];
    if (!collection) return collection;

    collection->authors_ = [[NSMutableDictionary alloc] init];
    collection->entries_ = [[NSMutableDictionary alloc] init];
    collection->followers_ = [[NSMutableArray alloc] init];
    collection.topLevelPosts = [[NSMutableArray alloc] init];
    collection.orphans = [[NSMutableDictionary alloc] init];

    collection->collectionId_ = collectionId;
    collection->user_ = user;
    collection->nestLevel_ = nestLevel;
    collection->numberVisible_ = numberVisible;
    collection->numberOfFollowers_ = numberOfFollowers;
    collection->lastEvent_ = lastEvent;
    collection.boostrap = bootstrap;
    collection.additionalPages = additionalPages;

    return collection;
}

- (Author *)authorForId:(NSString *)authorId {
    return [self.authors objectForKey:authorId];
}

- (BOOL)replaceEntryWithId:(NSString *)entryId withEntry:(Entry *)entry {
    if (!entryId)
        return NO;

    Entry *replaced = [self entryForKey:entryId];
    if (!replaced) {
        // edit stream responses come with a suffix on the entry id of
        // unknown meaning
        NSUInteger dotPos = [entryId rangeOfString:@"."].location;
        if (dotPos != NSNotFound) {
            NSString *prefix = [entryId substringToIndex:dotPos];
            replaced = [self entryForKey:prefix];
            [entries_ setObject:entry.entryId forKey:prefix];
        }
    }

    if (replaced) {
        [[self entryForKey:entry.parentId] replaceChild:entry];
        [self.topLevelPosts removeObject:replaced];
        if (entry.parentId)
            [[self.orphans objectForKey:entry.parentId] removeObject:replaced];
        [replaced moveChildrenTo:entry];
    }

    [entries_ setObject:entry.entryId forKey:entryId];
    return !!replaced;
}

- (void)insertEntry:(Entry *)entry replaceId:(NSString *)replaceId {
    Entry *parent = [self entryForKey:entry.parentId];
    BOOL didReplace = [self replaceEntryWithId:replaceId withEntry:entry];
    [entries_ setObject:entry forKey:entry.entryId];

    if (parent) {
        if (!didReplace)
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
    else if (![entry isKindOfClass:[Embed class]])
        [self.topLevelPosts addObject:entry];
}

- (Entry *)addEntry:(NSDictionary *)entryData {
    Entry *entry = [Entry entryWithDictionary:entryData authorsFrom:self];

    if (!entry)
        return nil;

    if (entry.deleted) {
        // Deleted posts have entries in the bootstrap data for both the
        // pre-delete and post-delete IDs. Barring replies made after the parent
        // was deleted, the post-delete ID is never useful.
        NSUInteger dotPos = [entry.entryId rangeOfString:@"."].location;
        if (dotPos != NSNotFound) {
            NSString *prefix = [entry.entryId substringToIndex:dotPos];
            if ([[self entryForKey:prefix] deleted])
                return nil;
        }

        [self insertEntry:entry replaceId:entry.entryId];
    }
    else if ([self userCanViewEntry:entry] && ![self entryForKey:entry.entryId]) {
        [self insertEntry:entry replaceId:entry.replaces];
    }

    for (NSDictionary *child in [entryData objectForKey:@"childContent"]) {
        [self addEntry:child];
    }

    NSMutableArray *children = [self.orphans objectForKey:entry.entryId];
    if (children) {
        for (Entry *child in children) {
            [entry addChild:child];
        }
        [self.orphans removeObjectForKey:entry.entryId];
    }

    return entry;
}

- (BOOL)userCanViewEntry:(Entry *)entry {
    if (self.user)
        return [self.user canViewEntry:entry];
    return entry.visibility == ContentVisibilityEveryone;
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

- (NSArray *)addCollectionContent:(NSDictionary *)content
                      erefFetcher:(void (^)(NSString *))erefFetcher
{
    NSArray *entries = [content objectForKey:@"content"];
    if (!entries)
        entries = [content objectForKey:@"messages"];
    if (!entries)
        entries = [[content objectForKey:@"states"] allValues];

    NSDictionary *authors = [content objectForKey:@"authors"];
    NSArray *followers = [content objectForKey:@"followers"];
    int64_t lastEvent = [[content objectForKey:@"maxEventId"] longLongValue];

    NSArray *filteredPosts = [[NSArray alloc] init];

    for (NSDictionary *entry in entries) {
        NSArray *erefs = [entry objectForKey:@"erefs"];
        if (erefs) {
            if (erefFetcher) {
                for (NSString *eref in erefs) {
                    erefFetcher(eref);
                }
            }
        }
        else {
            filteredPosts = [filteredPosts arrayByAddingObject:entry];
        }
    }

    return [self
            addAuthors:authors
            andPosts:filteredPosts
            andFollowers:followers
            lastEvent:lastEvent];
}

- (NSArray *)addAuthors:(NSDictionary *)authorData
               andPosts:(NSArray *)postData
           andFollowers:(NSArray *)followerData
              lastEvent:(int64_t)lastEvent
{
    if (followerData)
        [followers_ addObjectsFromArray:followerData];

    for (NSString *authorId in authorData) {
        if (![authors_ objectForKey:authorId])
            [authors_ setObject:[Author authorWithDictionary:[authorData objectForKey:authorId]]
                         forKey:authorId];
    }

    NSMutableArray *newEntries = [[NSMutableArray alloc] initWithCapacity:[postData count]];
    for (NSDictionary *post in postData) {
        Entry *newEntry = [self addEntry:post];
        if (newEntry)
            [newEntries addObject:newEntry];
    }

    if (lastEvent)
        lastEvent_ = lastEvent;

    return newEntries;
}

- (DateRange *)fetchRange:(DateRange *)range
                 gotRange:(RequestComplete)callback
{
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

        [self fetchPage:i gotPage:callback];
    }

    if (start && end)
        return [[DateRange alloc] initWithStart:start end:end];
    return nil;
}

- (void)fetchPage:(NSUInteger)pageNumber
          gotPage:(RequestComplete)callback
{
    if (pageNumber >= [self.additionalPages count]) {
        callback(YES, [NSString stringWithFormat:@"Page %u is out of range", pageNumber]);
        return;
    }

    NSDictionary *page = [self.additionalPages objectAtIndex:pageNumber];
    if ((id)page == [NSNull null]) {
        callback(YES, [NSString stringWithFormat:@"Page %u has already been fetched", pageNumber]);
    }
    else {
        ((void (^)(Collection *, RequestComplete))[page objectForKey:@"callback"])(self, callback);

        [self.additionalPages replaceObjectAtIndex:pageNumber withObject:[NSNull null]];
    }
}

- (void)fetchBootstrap:(RequestComplete)callback {
    if (!self.boostrap) {
        callback(YES, @"Bootstrap data has already been fetched");
    }
    else {
        self.boostrap(self, callback);
        self.boostrap = nil;
    }
}

@end

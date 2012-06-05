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

#include <sys/time.h>

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
    if (![self.authors objectForKey:authorId])
        [authors_ setObject:[Author authorPlaceholder:authorId]
                     forKey:authorId];

    return [self.authors objectForKey:authorId];
}

- (NSString *)removeEntryIdSuffix:(NSString *)string {
    NSUInteger pos = [string rangeOfString:@"."].location;
    if (pos == NSNotFound)
        return nil;
    return [string substringToIndex:pos];
}

- (Entry *)handleDeletion:(Entry *)entry
                   parent:(Entry *)parent
          updatePostCount:(BOOL)updatePostCount
{
    // In stream responses, deleted posts have the same ID as the original
    // post. In bootstrap responses, deleted posts have the original ID,
    // plus a child with the suffixed version of the original ID
    Entry *original = [self entryForKey:entry.entryId];
    if (original) {
        if (!original.deleted)
            --numberVisible_;
        [original copyFrom:entry];
        return original;
    }

    if (parent && [entry.entryId hasPrefix:parent.entryId] && parent.deleted) {
        [entries_ setObject:parent forKey:entry.entryId];
        return parent;
    }

    // Otherwise either the undeleted one was never seen, or we've gotten
    // an unrecognized delete format
    [entries_ setObject:entry forKey:entry.entryId];
    if (parent)
        [parent addChild:entry];
    else
        [self.topLevelPosts addObject:entry];
    return entry;
}

- (Entry *)insertEntry:(Entry *)entry withParent:(Entry *)parent {
    BOOL updatePostCount = entry.event < 0 || entry.event > self.lastEvent;

    if (entry.deleted)
        return [self handleDeletion:entry parent:parent updatePostCount:updatePostCount];

    // We might already have this entry, as there's some overlap between the
    // init data and the first page or if we have multiple stream requests at
    // once
    if ([self entryForKey:entry.entryId])
        return nil;

    // Add any children of this node which arrived before it
    NSMutableArray *children = [self.orphans objectForKey:entry.entryId];
    if (children) {
        for (Entry *child in children)
            [entry addChild:child];
        [self.orphans removeObjectForKey:entry.entryId];
    }

    // The replaces ID for edits has a suffix of unknown meaning, so try to
    // find an entry whose ID is the prefix of the target ID
    NSString *replaces = entry.replaces;
    Entry *original = nil;
    while (replaces && !original) {
        original = [self entryForKey:replaces];
        replaces = [self removeEntryIdSuffix:replaces];
    }

    if (original) {
        // what if the visibility changed?
        [original copyFrom:entry];
        [entries_ setObject:original forKey:entry.entryId];
        return original;
    }

    if (![self userCanViewEntry:entry])
        return nil;

    [entries_ setObject:entry forKey:entry.entryId];
    if (updatePostCount && [entry isKindOfClass:[Post class]])
        ++numberVisible_;

    // Register each prefix
    replaces = entry.replaces;
    while (replaces && !original) {
        [entries_ setObject:entry forKey:replaces];
        original = [self entryForKey:replaces];
        replaces = [self removeEntryIdSuffix:replaces];
    }

    if (!parent)
        parent = [self entryForKey:entry.parentId];
    if (parent)
        return [parent addChild:entry];

    if (entry.parentId) {
        // Has a parent but we haven't read the parent yet, so remember it until
        // the parent arrives
        NSMutableArray *siblings = [self.orphans objectForKey:entry.parentId];
        if (!siblings) {
            siblings = [[NSMutableArray alloc] init];
            [self.orphans setObject:siblings forKey:entry.parentId];
        }
        [siblings addObject:entry];
        return nil;
    }

    [self.topLevelPosts addObject:entry];
    return entry;
}

- (Entry *)createEntry:(NSDictionary *)entryData parent:(Entry *)parent {
    if (parent)
        return [Entry entryWithDictionary:entryData
                              authorsFrom:self
                               withParent:parent];

    return [Entry entryWithDictionary:entryData
                          authorsFrom:self
                         inCollection:self];
}

- (Entry *)addEntry:(NSDictionary *)entryData withParent:(Entry *)parent {
    Entry *entry = [self createEntry:entryData parent:parent];
    if (!entry)
        return nil;

    entry = [self insertEntry:entry withParent:parent];
    if (!entry)
        return nil;

    for (NSDictionary *child in [entryData objectForKey:@"childContent"])
        [self addEntry:child withParent:entry];

    return entry;
}

- (BOOL)userCanViewEntry:(Entry *)entry {
    // Unlikes show up as likes with visibility none, so we don't want to filter
    // them out
    if ([entry isKindOfClass:[Like class]])
        return YES;
    if (self.user)
        return [self.user canViewEntry:entry];
    return entry.visibility == ContentVisibilityEveryone;
}

- (Entry *)entryForKey:(NSString *)entryId {
    return entryId ? [entries_ objectForKey:entryId] : nil;
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
        [[self authorForId:authorId] setTo:[authorData objectForKey:authorId]];
    }

    NSMutableArray *newEntries = [[NSMutableArray alloc] initWithCapacity:[postData count]];
    for (NSDictionary *post in postData) {
        Entry *newEntry = [self addEntry:post withParent:nil];
        if (newEntry)
            [newEntries addObject:newEntry];
    }

    if (lastEvent)
        lastEvent_ = lastEvent;

    return newEntries;
}

- (void)addLikeForPost:(Entry *)post visibility:(int)vis {
    struct timeval tp;
    gettimeofday(&tp, 0);
    NSString *likeId = [NSString stringWithFormat:@"%@+%@.%lld%lld", post.entryId, self.user.userId, (int64_t)tp.tv_sec, (int64_t)tp.tv_usec, nil];
    NSDictionary *likeContent = [NSDictionary dictionaryWithObjectsAndKeys:
                                 self.user.userId, @"authorId",
                                 post.entryId, @"targetId",
                                 likeId, @"id",
                                 nil];
    NSDictionary *likeResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:vis], @"vis",
                                  [NSNumber numberWithInt:ContentTypeOpine], @"type",
                                  [NSNumber numberWithInt:0], @"event",
                                  [NSNumber numberWithInt:5], @"source",
                                  likeContent, @"content",
                                  nil];

    [self addEntry:likeResponse withParent:post];
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

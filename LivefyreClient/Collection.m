//
//  CollectionData.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Collection.h"

#import "Author.h"
#import "Content.h"
#import "LFLivefyreViewController.h"
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
    NSMutableDictionary *contents_;
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
    collection->contents_ = [[NSMutableDictionary alloc] init];
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
    if (!authorId)
        return nil;

    if (![self.authors objectForKey:authorId]) {
        [authors_ setObject:[Author authorPlaceholder:authorId]
                     forKey:authorId];

        if ([authorId isEqualToString:self.user.userId])
            [[self.authors objectForKey:authorId] setToUser:self.user];
    }

    return [self.authors objectForKey:authorId];
}

- (NSString *)removeContentIdSuffix:(NSString *)string {
    NSUInteger pos = [string rangeOfString:@"."].location;
    if (pos == NSNotFound)
        return nil;
    return [string substringToIndex:pos];
}

- (Content *)handleDeletion:(Content *)content
                   parent:(Content *)parent
          updatePostCount:(BOOL)updatePostCount
{
    // In stream responses, deleted posts have the same ID as the original
    // post. In bootstrap responses, deleted posts have the original ID,
    // plus a child with the suffixed version of the original ID
    Content *original = [self contentForKey:content.contentId];
    if (original) {
        if (!original.deleted)
            --numberVisible_;
        return [original copyFrom:content];;
    }

    if (parent && [content.contentId hasPrefix:parent.contentId] && parent.deleted) {
        [contents_ setObject:parent forKey:content.contentId];
        return parent;
    }

    // Otherwise either the undeleted one was never seen, or we've gotten
    // an unrecognized delete format
    [contents_ setObject:content forKey:content.contentId];
    if (parent)
        [parent addChild:content];
    else
        [self.topLevelPosts addObject:content];
    return content;
}

- (Content *)insertContent:(Content *)content withParent:(Content *)parent {
    BOOL updatePostCount = content.event < 0 || content.event > self.lastEvent;

    if (content.deleted)
        return [self handleDeletion:content parent:parent updatePostCount:updatePostCount];

    // We might already have this content, either due to overlap between the
    // bootstrap data and the first page, or due to be being content created
    // by this collection. In the first case the new one should be identical to
    // the old one, but in the second the new one might have more data.
    Content *existingContent = [self contentForKey:content.contentId];
    if (existingContent) {
        if ([existingContent isEqual:content])
            return nil;
        return [existingContent copyFrom:content];
    }

    // Add any children of this node which arrived before it
    NSMutableArray *children = [self.orphans objectForKey:content.contentId];
    if (children) {
        for (Content *child in children)
            [content addChild:child];
        [self.orphans removeObjectForKey:content.contentId];
    }

    // The replaces ID for edits has a suffix of unknown meaning, so try to
    // find content whose ID is the prefix of the target ID
    NSString *replaces = content.replaces;
    Content *original = nil;
    while (replaces && !original) {
        original = [self contentForKey:replaces];
        replaces = [self removeContentIdSuffix:replaces];
    }

    if (original) {
        // what if the visibility changed?
        [contents_ setObject:original forKey:content.contentId];
        return [original copyFrom:content];
    }

    if (![self userCanViewContent:content])
        return nil;

    [contents_ setObject:content forKey:content.contentId];
    if (updatePostCount && [content isKindOfClass:[Post class]])
        ++numberVisible_;

    // Register each prefix
    replaces = content.replaces;
    while (replaces && !original) {
        [contents_ setObject:content forKey:replaces];
        original = [self contentForKey:replaces];
        replaces = [self removeContentIdSuffix:replaces];
    }

    if (!parent)
        parent = [self contentForKey:content.parentId];
    if (parent)
        return [parent addChild:content];

    if (content.parentId) {
        // Has a parent but we haven't read the parent yet, so remember it until
        // the parent arrives
        NSMutableArray *siblings = [self.orphans objectForKey:content.parentId];
        if (!siblings) {
            siblings = [[NSMutableArray alloc] init];
            [self.orphans setObject:siblings forKey:content.parentId];
        }
        [siblings addObject:content];
        return nil;
    }

    [self.topLevelPosts addObject:content];
    return content;
}

- (Content *)createContent:(NSDictionary *)contentData parent:(Content *)parent {
    if (parent)
        return [Content contentWithDictionary:contentData
                              authorsFrom:self
                               withParent:parent];

    return [Content contentWithDictionary:contentData
                          authorsFrom:self
                         inCollection:self];
}

- (Content *)addContent:(NSDictionary *)contentData withParent:(Content *)parent {
    Content *content = [self createContent:contentData parent:parent];
    if (!content)
        return nil;

    content = [self insertContent:content withParent:parent];
    if (!content && [[contentData objectForKey:@"childContent"] count])
        content = [self contentForKey:content.contentId];

    if (!content)
        return nil;

    for (NSDictionary *child in [contentData objectForKey:@"childContent"])
        [self addContent:child withParent:content];

    return content;
}

- (BOOL)userCanViewContent:(Content *)content {
    // Unlikes show up as likes with visibility none, so we don't want to filter
    // them out
    if ([content isKindOfClass:[Like class]])
        return YES;
    if (self.user)
        return [self.user canViewContent:content];
    return content.visibility == ContentVisibilityEveryone;
}

- (Content *)contentForKey:(NSString *)contentId {
    return contentId ? [contents_ objectForKey:contentId] : nil;
}

- (NSArray *)addCollectionContent:(NSDictionary *)content
                      erefFetcher:(void (^)(NSString *))erefFetcher
{
    NSArray *contents = [content objectForKey:@"content"];
    if (!contents)
        contents = [content objectForKey:@"messages"];
    if (!contents)
        contents = [[content objectForKey:@"states"] allValues];

    NSDictionary *authors = [content objectForKey:@"authors"];
    NSArray *followers = [content objectForKey:@"followers"];
    int64_t lastEvent = [[content objectForKey:@"maxEventId"] longLongValue];

    NSArray *filteredPosts = [[NSArray alloc] init];

    for (NSDictionary *entry in contents) {
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

    NSMutableArray *newContents = [[NSMutableArray alloc] initWithCapacity:[postData count]];
    for (NSDictionary *post in postData) {
        Content *newContent = [self addContent:post withParent:nil];
        if (newContent)
            [newContents addObject:newContent];
    }

    if (lastEvent)
        lastEvent_ = lastEvent;

    return newContents;
}

- (void)addLikeForPost:(Content *)post visibility:(int)vis {
    struct timeval tp;
    gettimeofday(&tp, 0);
    NSString *likeId = [NSString stringWithFormat:@"%@+%@.%lld%lld", post.contentId, self.user.userId, (int64_t)tp.tv_sec, (int64_t)tp.tv_usec, nil];
    NSDictionary *likeContent = [NSDictionary dictionaryWithObjectsAndKeys:
                                 self.user.userId, @"authorId",
                                 post.contentId, @"targetId",
                                 likeId, @"id",
                                 nil];
    NSDictionary *likeResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:vis], @"vis",
                                  [NSNumber numberWithInt:ContentTypeOpine], @"type",
                                  [NSNumber numberWithInt:0], @"event",
                                  [NSNumber numberWithInt:5], @"source",
                                  likeContent, @"content",
                                  nil];

    [self addContent:likeResponse withParent:post];
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

- (UINavigationController *)newNavigationControllerWithCustomizations:customizations {
    UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"LivefyreStoryboard" bundle:nil] instantiateInitialViewController];
    LFLivefyreViewController *livefyreViewController = (LFLivefyreViewController *)navigationController.topViewController;
    livefyreViewController.collection = self;
    livefyreViewController.client = self.client;
    livefyreViewController.customizations = customizations;
    return navigationController;
}

- (UIViewController *)newViewControllerWithCustomizations:customizations {
    LFLivefyreViewController *livefyreViewController = [[UIStoryboard storyboardWithName:@"LivefyreStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"LFLivefyreViewController"];
    livefyreViewController.collection = self;
    livefyreViewController.client = self.client;
    livefyreViewController.customizations = customizations;
    return livefyreViewController;
}
@end

//
//  Event.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Entry.h"

#import "Author.h"
#import "NSArray+BlocksKit.h"

@interface Entry ()
@property (strong, nonatomic) NSString *entryId;
@property (weak, nonatomic) Author *author;
@property (nonatomic) int createdAt;
@property (nonatomic) int editedAt;
@property (nonatomic) int source;
@property (nonatomic) enum ContentType contentType;
@property (nonatomic) enum ContentVisibility visibility;
@property (strong, nonatomic) NSString *replaces;
@property (strong, nonatomic) NSString *parentId;
@property (weak, nonatomic) Entry *parent;
@property (strong, nonatomic) NSArray *children;
@property (strong, nonatomic) NSArray *embed;
@property (strong, nonatomic) NSArray *likes;
@property (nonatomic) BOOL deleted;
@property (weak, nonatomic) Collection *collection;
@property (nonatomic) int64_t event;

- (Entry *)addToParent:(Entry *)parent;
@end

@interface Post ()
@property (strong, nonatomic) NSString *body;
@property (nonatomic) enum Permissions authorPermissions;
@property (nonatomic) enum PermissionScope permissionScope;
@end

@interface Embed ()
@property (strong, nonatomic) NSString *link;
@property (strong, nonatomic) NSString *providerUrl;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *authorName;
@property (strong, nonatomic) NSString *html;
@property (strong, nonatomic) NSString *version;
@property (strong, nonatomic) NSString *authorUrl;
@property (strong, nonatomic) NSString *providerName;
@property (strong, nonatomic) NSString *thumbnailUrl;
@property (nonatomic) int height;
@property (nonatomic) int width;
@property (nonatomic) int thumbnailHeight;
@property (nonatomic) int thumbnailWidth;
@property (nonatomic) int position;
@end

@implementation Entry
@synthesize author = author_;
@synthesize children = children_;
@synthesize collection = collection_;
@synthesize contentType = contentType_;
@synthesize createdAt = createdAt_;
@synthesize deleted = deleted_;
@synthesize editedAt = editedAt_;
@synthesize embed = embed_;
@synthesize entryId = entryId_;
@synthesize event = event_;
@synthesize likes = likes_;
@synthesize parent = parent_;
@synthesize parentId = parentId_;
@synthesize replaces = replaces_;
@synthesize source = source_;
@synthesize visibility = visibility_;

+ (Entry *)entryWithDictionary:(NSDictionary *)eventData
                   authorsFrom:(id <AuthorLookup>)authorData
                  inCollection:(Collection *)collection
{
    Entry *newEntry = [self entryWithDictionary:eventData
                                    authorsFrom:authorData
                                     withParent:nil];
    newEntry.collection = collection;
    return newEntry;
}

+ (Entry *)entryWithDictionary:(NSDictionary *)eventData
                   authorsFrom:(id <AuthorLookup>)authorData
                    withParent:(Entry *)parent
{
    Entry *newEntry = nil;
    switch ([[eventData objectForKey:@"type"] intValue]) {
        case ContentTypeOpine:
            newEntry = [[Like alloc] initWithDictionary:eventData
                                            authorsFrom:authorData];
            break;
        case ContentTypeEmbed:
            newEntry = [[Embed alloc] initWithDictionary:eventData];
            break;
        case ContentTypeMessage: {
            newEntry = [[Post alloc] initWithDictionary:eventData authorsFrom:authorData];
            if (newEntry.deleted)
                newEntry.parentId = parent.entryId;
            break;
        }
        default:
            NSLog(@"Unrecognized content type: %d", [[eventData objectForKey:@"type"] intValue]);
            return nil;
    }
    newEntry.collection = parent.collection;
    return newEntry;
}

- (Entry *)initWithDictionary:(NSDictionary *)eventData {
    self = [super init];
    if (self) {
        NSDictionary *content = [eventData objectForKey:@"content"];
        self.children = [[NSArray alloc] init];
        self.contentType = [[eventData objectForKey:@"type"] intValue];
        self.createdAt = [[content objectForKey:@"createdAt"] intValue];
        self.editedAt = self.createdAt;
        self.embed = [[NSArray alloc] init];
        self.entryId = [content objectForKey:@"id"];
        self.likes = [[NSArray alloc] init];
        self.replaces = [self fixNull:[content objectForKey:@"replaces"]];
        self.source = [[eventData objectForKey:@"source"] intValue];
        self.visibility = [[eventData objectForKey:@"vis"] intValue];

        id event = [eventData objectForKey:@"event"];
        if ([event respondsToSelector:@selector(longLongValue)])
            self.event = [event longLongValue];
        else
            self.event = -1;

        if (self.source > 8) {
            NSLog(@"Unrecognized source: %d", self.source);
            self.source = 0;
        }
        if (self.visibility > ContentVisibilityGroup) {
            NSLog(@"Unrecognized visibility: %d", self.visibility);
            self.visibility = ContentVisibilityNone;
        }
    }
    return self;
}

- (NSString *)fixNull:(id) value {
    if (![value isKindOfClass:[NSString class]])
        return nil;
    if ([value isEqualToString:@""])
        return nil;
    if ([value isEqualToString:@"None"])
        return nil;

    return value;
}

- (Entry *)addToParent:(Entry *)parent {
    parent.children = [parent.children arrayByAddingObject:self];
    return self;
}

- (Entry *)addChild:(Entry *)child {
    child.parent = self;
    return [child addToParent:self];
}

- (Entry *)copyFrom:(Entry *)entry {
    if (entry.deleted)
        self.deleted = YES;

    if ([self.entryId hasPrefix:entry.entryId])
        self.entryId = entry.entryId;

    if (entry.editedAt > self.editedAt) {
        self.source = entry.source;
        self.visibility = entry.visibility;
    }
    if (!self.createdAt || !entry.createdAt)
        self.createdAt = MAX(self.createdAt, entry.createdAt);
    else
        self.createdAt = MIN(self.createdAt, entry.createdAt);

    self.editedAt = MAX(self.editedAt, entry.editedAt);

    for (Entry *child in entry.children)
        [self addChild:child];
    for (Entry *child in entry.embed)
        [self addChild:child];
    for (Entry *child in entry.likes)
        [self addChild:child];

    return self;
}

static inline BOOL areEqual(id a1, id a2) {
    return a1 == a2 || [a1 isEqual:a2];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    if (!areEqual(self.entryId, [object entryId])) return NO;
    if (self.parent != [object parent]) return NO;
    if (self.collection != [object collection]) return NO;
    if (self.author  != [object author]) return NO;
    if (self.createdAt != [object createdAt]) return NO;
    if (self.editedAt != [object editedAt]) return NO;
    if (self.source != [object source]) return NO;
    if (self.contentType != [object contentType]) return NO;
    if (self.visibility != [object visibility]) return NO;
    if (self.deleted != [object deleted]) return NO;
    if (!areEqual(self.children, [object children])) return NO;
    if (!areEqual(self.embed, [object embed])) return NO;
    if (!areEqual(self.likes, [object likes])) return NO;
    if (!areEqual(self.parentId, [object parentId])) return NO;
    if (self.event != [object event]) return NO;
    return YES;
}
@end

@implementation Post
@synthesize body = body_;
@synthesize authorPermissions = authorPermissions_;
@synthesize permissionScope = permissionScope_;

- (Post *)initWithDictionary:(NSDictionary *)eventData
                 authorsFrom:(id <AuthorLookup>)authorData
{
    self = [super initWithDictionary:eventData];
    if (self) {
        NSDictionary *content = [eventData objectForKey:@"content"];
        if ([content count] == 1u && [content objectForKey:@"id"]) {
            self.deleted = YES;
        }
        else {
            self.body = [content objectForKey:@"bodyHtml"];
            self.authorPermissions = [[content objectForKey:@"authorPermission"] intValue];
            self.permissionScope = [[content objectForKey:@"permissionScope"] intValue];
            self.author = [authorData authorForId:[content objectForKey:@"authorId"]];
            self.parentId = [self fixNull:[content objectForKey:@"parentId"]];

            if (self.authorPermissions > PermissionsModerator) {
                NSLog(@"Unrecognized permission level: %d", self.authorPermissions);
                self.authorPermissions = PermissionsNone;
            }
            if (self.permissionScope > PermissionScopeCollectionRule) {
                NSLog(@"Unrecognized permission scope: %d", self.permissionScope);
                self.permissionScope = PermissionScopeCollectionRule;
            }
        }
    }
    return self;
}

- (Entry *)copyFrom:(Entry *)entry {
    if ([entry isKindOfClass:[self class]] && entry.editedAt > self.editedAt)
        self.body = [(Post *)entry body];
    return [super copyFrom:entry];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    if (![self.body isEqual:[object body]]) return NO;
    return [super isEqual:object];
}
@end

@implementation Like
- (Like *)initWithDictionary:(NSDictionary *)eventData
                 authorsFrom:(id <AuthorLookup>)authorData
{
    self = [super initWithDictionary:eventData];
    if (self) {
        NSDictionary *content = [eventData objectForKey:@"content"];
        self.author = [authorData authorForId:[content objectForKey:@"authorId"]];
        self.parentId = [self fixNull:[content objectForKey:@"targetId"]];
    }
    return self;
}

- (Entry *)addToParent:(Entry *)parent {
    BOOL (^matchesAuthor)(id) = ^BOOL(id obj) {
        return [[obj author] authorId] == self.author.authorId;
    };

    if (self.visibility == ContentVisibilityNone) {
        parent.likes = [parent.likes reject:matchesAuthor];
    }
    else {
        if (![parent.likes match:matchesAuthor])
            parent.likes = [parent.likes arrayByAddingObject:self];
    }
    return parent;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    return [super isEqual:object];
}

- (Entry *)copyFrom:(Entry *)entry {
    [super copyFrom:entry];
    if (!entry.visibility) {
        self.visibility = ContentVisibilityNone;
        self.parent.likes = [self.parent.likes reject:^BOOL(id obj) { return [[obj entryId] isEqual:self.entryId]; }];
    }
    return self.parent;
}
@end

@implementation Embed
@synthesize link = link_;
@synthesize providerUrl = providerUrl_;
@synthesize title = title_;
@synthesize url = url_;
@synthesize type = type_;
@synthesize authorName = authorName_;
@synthesize html = html_;
@synthesize version = version_;
@synthesize authorUrl = authorUrl_;
@synthesize providerName = providerName_;
@synthesize thumbnailUrl = thumbnailUrl_;
@synthesize height = height_;
@synthesize width = width_;
@synthesize thumbnailHeight = thumbnailHeight_;
@synthesize thumbnailWidth = thumbnailWidth_;
@synthesize position = position_;

- (Embed *)initWithDictionary:(NSDictionary *)eventData {
    self = [super initWithDictionary:eventData];
    if (self) {
        NSDictionary *content = [eventData objectForKey:@"content"];
        NSDictionary *oembed = [content objectForKey:@"oembed"];

        self.link = [content objectForKey:@"link"];
        self.providerUrl = [oembed objectForKey:@"provider_url"];
        self.title = [oembed objectForKey:@"title"];
        self.url = [oembed objectForKey:@"url"];
        self.type = [oembed objectForKey:@"type"];
        self.authorName = [oembed objectForKey:@"author_name"];
        self.html = [oembed objectForKey:@"html"];
        self.version = [oembed objectForKey:@"version"];
        self.authorUrl = [oembed objectForKey:@"author_url"];
        self.providerName = [oembed objectForKey:@"provider_name"];
        self.thumbnailUrl = [oembed objectForKey:@"thumbnail_url"];
        self.height = [[oembed objectForKey:@"height"] intValue];
        self.width = [[oembed objectForKey:@"width"] intValue];
        self.thumbnailHeight = [[oembed objectForKey:@"thumbnail_height"] intValue];
        self.thumbnailWidth = [[oembed objectForKey:@"thumbnail_width"] intValue];
        self.position = [[content objectForKey:@"position"] intValue];
        self.parentId = [self fixNull:[content objectForKey:@"targetId"]];
        self.createdAt = (int)([[eventData objectForKey:@"event"] longLongValue] / 1000000);
        self.editedAt = self.createdAt;
    }
    return self;
}

- (Entry *)addToParent:(Entry *)parent {
    self.author = parent.author;
    parent.embed = [parent.embed arrayByAddingObject:self];
    return self;
}

- (Entry *)copyFrom:(Entry *)entry {
    if ([entry isKindOfClass:[self class]] && entry.editedAt > self.editedAt) {
        Embed *embed = (Embed *)entry;
        self.link = embed.link;
        self.providerUrl = embed.providerUrl;
        self.title = embed.title;
        self.url = embed.url;
        self.type = embed.type;
        self.authorName = embed.authorName;
        self.html = embed.html;
        self.version = embed.version;
        self.authorUrl = embed.authorUrl;
        self.providerName = embed.providerName;
        self.thumbnailUrl = embed.thumbnailUrl;
        self.height = embed.height;
        self.width = embed.width;
        self.thumbnailHeight = embed.thumbnailHeight;
        self.thumbnailWidth = embed.thumbnailWidth;
        self.position = embed.position;
    }

    return [super copyFrom:entry];
}

- (BOOL)isEqual:(id)object {
    Embed *embed = object;
    if (![object isKindOfClass:[self class]]) return NO;
    if (!areEqual(self.link, [embed link])) return NO;
    if (!areEqual(self.url, [embed url])) return NO;
    if (!areEqual(self.title, [embed title])) return NO;
    if (!areEqual(self.type, [embed type])) return NO;
    if (!areEqual(self.authorName, [embed authorName])) return NO;
    if (!areEqual(self.authorUrl, [embed authorUrl])) return NO;
    if (!areEqual(self.html, [embed html])) return NO;
    if (!areEqual(self.version, [embed version])) return NO;
    if (!areEqual(self.providerName, [embed providerName])) return NO;
    if (!areEqual(self.providerUrl, [embed providerUrl])) return NO;
    if (self.height != [embed height]) return NO;
    if (self.width != [embed width]) return NO;
    if (!areEqual(self.thumbnailUrl, [embed thumbnailUrl])) return NO;
    if (self.thumbnailHeight != [embed thumbnailHeight]) return NO;
    if (self.thumbnailWidth != [embed thumbnailWidth]) return NO;
    if (self.position != [embed position]) return NO;
    return [super isEqual:object];
}
@end

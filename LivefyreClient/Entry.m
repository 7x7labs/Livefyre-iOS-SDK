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
@synthesize entryId = entryId_;
@synthesize author = author_;
@synthesize createdAt = createdAt_;
@synthesize editedAt = editedAt_;
@synthesize source = source_;
@synthesize contentType = contentType_;
@synthesize visibility = visibility_;
@synthesize replaces = replaces_;
@synthesize parentId = parentId_;
@synthesize parent = parent_;
@synthesize children = children_;
@synthesize embed = embed_;
@synthesize likes = likes_;
@synthesize deleted = deleted_;
@synthesize collection = collection_;

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
        self.entryId = [content objectForKey:@"id"];
        self.createdAt = [[content objectForKey:@"createdAt"] intValue];
        self.editedAt = self.createdAt;
        self.source = [[eventData objectForKey:@"source"] intValue];
        self.contentType = [[eventData objectForKey:@"type"] intValue];
        self.visibility = [[eventData objectForKey:@"vis"] intValue];
        self.replaces = [self fixNull:[content objectForKey:@"replaces"]];
        self.children = [[NSArray alloc] init];
        self.embed = [[NSArray alloc] init];
        self.likes = [[NSArray alloc] init];

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

- (void)copyFrom:(Entry *)entry {
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

- (void)copyFrom:(Entry *)entry {
    if ([entry isKindOfClass:[self class]] && entry.editedAt > self.editedAt)
        self.body = [(Post *)entry body];
    [super copyFrom:entry];
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
    if (self.visibility == ContentVisibilityNone) {
        parent.likes = [parent.likes reject:^BOOL(id obj) {
            return [[obj author] authorId] == self.author.authorId;
        }];
    }
    else {
        parent.likes = [parent.likes arrayByAddingObject:self];
    }
    return parent;
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

- (void)copyFrom:(Entry *)entry {
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

    [super copyFrom:entry];
}

@end

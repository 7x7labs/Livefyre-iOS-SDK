//
//  Content.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Content.h"

#import "Author.h"
#import "NSArray+BlocksKit.h"

@interface Content ()
@property (strong, nonatomic) NSString *contentId;
@property (weak, nonatomic) Author *author;
@property (nonatomic) int createdAt;
@property (nonatomic) int editedAt;
@property (nonatomic) int source;
@property (nonatomic) enum ContentType contentType;
@property (nonatomic) enum ContentVisibility visibility;
@property (strong, nonatomic) NSString *replaces;
@property (strong, nonatomic) NSString *parentId;
@property (weak, nonatomic) Content *parent;
@property (strong, nonatomic) NSArray *children;
@property (strong, nonatomic) NSArray *embed;
@property (strong, nonatomic) NSArray *likes;
@property (nonatomic) BOOL deleted;
@property (weak, nonatomic) Collection *collection;
@property (nonatomic) int64_t event;

- (Content *)addToParent:(Content *)parent;
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

@implementation Content
@synthesize author = author_;
@synthesize children = children_;
@synthesize collection = collection_;
@synthesize contentType = contentType_;
@synthesize createdAt = createdAt_;
@synthesize deleted = deleted_;
@synthesize editedAt = editedAt_;
@synthesize embed = embed_;
@synthesize contentId = contentId_;
@synthesize event = event_;
@synthesize likes = likes_;
@synthesize parent = parent_;
@synthesize parentId = parentId_;
@synthesize replaces = replaces_;
@synthesize source = source_;
@synthesize visibility = visibility_;

+ (Content *)contentWithDictionary:(NSDictionary *)contentData
                   authorsFrom:(id <AuthorLookup>)authorData
                  inCollection:(Collection *)collection
{
    Content *newContent = [self contentWithDictionary:contentData
                                    authorsFrom:authorData
                                     withParent:nil];
    newContent.collection = collection;
    return newContent;
}

+ (Content *)contentWithDictionary:(NSDictionary *)contentData
                   authorsFrom:(id <AuthorLookup>)authorData
                    withParent:(Content *)parent
{
    Content *newContent = nil;
    switch ([[contentData objectForKey:@"type"] intValue]) {
        case ContentTypeOpine:
            newContent = [[Like alloc] initWithDictionary:contentData
                                            authorsFrom:authorData];
            break;
        case ContentTypeEmbed:
            newContent = [[Embed alloc] initWithDictionary:contentData];
            break;
        case ContentTypeMessage: {
            newContent = [[Post alloc] initWithDictionary:contentData authorsFrom:authorData];
            if (newContent.deleted)
                newContent.parentId = parent.contentId;
            break;
        }
        default:
            NSLog(@"Unrecognized content type: %d", [[contentData objectForKey:@"type"] intValue]);
            return nil;
    }
    newContent.collection = parent.collection;
    return newContent;
}

- (Content *)initWithDictionary:(NSDictionary *)contentData {
    self = [super init];
    if (self) {
        NSDictionary *content = [contentData objectForKey:@"content"];
        self.children = [[NSArray alloc] init];
        self.contentType = [[contentData objectForKey:@"type"] intValue];
        self.createdAt = [[content objectForKey:@"createdAt"] intValue];
        self.editedAt = self.createdAt;
        self.embed = [[NSArray alloc] init];
        self.contentId = [content objectForKey:@"id"];
        self.likes = [[NSArray alloc] init];
        self.replaces = [self fixNull:[content objectForKey:@"replaces"]];
        self.source = [[contentData objectForKey:@"source"] intValue];
        self.visibility = [[contentData objectForKey:@"vis"] intValue];

        id event = [contentData objectForKey:@"event"];
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

- (Content *)addToParent:(Content *)parent {
    parent.children = [parent.children arrayByAddingObject:self];
    return self;
}

- (Content *)addChild:(Content *)child {
    child.parent = self;
    return [child addToParent:self];
}

- (Content *)copyFrom:(Content *)content {
    if (content.deleted)
        self.deleted = YES;

    if ([self.contentId hasPrefix:content.contentId])
        self.contentId = content.contentId;

    if (content.editedAt > self.editedAt) {
        self.source = content.source;
        self.visibility = content.visibility;
    }
    if (!self.createdAt || !content.createdAt)
        self.createdAt = MAX(self.createdAt, content.createdAt);
    else
        self.createdAt = MIN(self.createdAt, content.createdAt);

    self.editedAt = MAX(self.editedAt, content.editedAt);

    for (Content *child in content.children)
        [self addChild:child];
    for (Content *child in content.embed)
        [self addChild:child];
    for (Content *child in content.likes)
        [self addChild:child];

    return self;
}

static inline BOOL areEqual(id a1, id a2) {
    return a1 == a2 || [a1 isEqual:a2];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    if (!areEqual(self.contentId, [object contentId])) return NO;
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

- (Post *)initWithDictionary:(NSDictionary *)contentData
                 authorsFrom:(id <AuthorLookup>)authorData
{
    self = [super initWithDictionary:contentData];
    if (self) {
        NSDictionary *content = [contentData objectForKey:@"content"];
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

- (Content *)copyFrom:(Content *)content {
    if ([content isKindOfClass:[self class]] && content.editedAt > self.editedAt)
        self.body = [(Post *)content body];
    return [super copyFrom:content];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    if (![self.body isEqual:[object body]]) return NO;
    return [super isEqual:object];
}
@end

@implementation Like
- (Like *)initWithDictionary:(NSDictionary *)contentData
                 authorsFrom:(id <AuthorLookup>)authorData
{
    self = [super initWithDictionary:contentData];
    if (self) {
        NSDictionary *content = [contentData objectForKey:@"content"];
        self.author = [authorData authorForId:[content objectForKey:@"authorId"]];
        self.parentId = [self fixNull:[content objectForKey:@"targetId"]];
    }
    return self;
}

- (Content *)addToParent:(Content *)parent {
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

- (Content *)copyFrom:(Content *)content {
    [super copyFrom:content];
    if (!content.visibility) {
        self.visibility = ContentVisibilityNone;
        self.parent.likes = [self.parent.likes reject:^BOOL(id obj) { return [[obj contentId] isEqual:self.contentId]; }];
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

- (Embed *)initWithDictionary:(NSDictionary *)contentData {
    self = [super initWithDictionary:contentData];
    if (self) {
        NSDictionary *content = [contentData objectForKey:@"content"];
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
        self.createdAt = (int)([[contentData objectForKey:@"event"] longLongValue] / 1000000);
        self.editedAt = self.createdAt;
    }
    return self;
}

- (Content *)addToParent:(Content *)parent {
    self.author = parent.author;
    parent.embed = [parent.embed arrayByAddingObject:self];
    return self;
}

- (Content *)copyFrom:(Content *)content {
    if ([content isKindOfClass:[self class]] && content.editedAt > self.editedAt) {
        Embed *embed = (Embed *)content;
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

    return [super copyFrom:content];
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

//
//  Event.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "Entry.h"

static NSArray *replaceEntryInArray(NSArray *array, NSString *key, id newValue) {
    NSUInteger index = [array indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj entryId] isEqualToString:key];
    }];
    if (index == NSNotFound)
        return array;

    NSMutableArray *mutable = [NSMutableArray arrayWithArray:array];
    if (newValue)
        [mutable replaceObjectAtIndex:index withObject:newValue];
    else
        [mutable removeObjectAtIndex:index];
    return mutable;
}

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

- (void)addToParent:(Entry *)parent;
- (void)replaceInParent:(Entry *)parent;
- (void)removeFromParent;
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

+ (Entry *)entryWithDictionary:(NSDictionary *)eventData
                   authorsFrom:(id <AuthorLookup>)authorData
{
    return [self entryWithDictionary:eventData authorsFrom:authorData withParent:nil];
}

+ (Entry *)entryWithDictionary:(NSDictionary *)eventData
                   authorsFrom:(id <AuthorLookup>)authorData
                    withParent:(Entry *)parent
{
    NSDictionary *content = [eventData objectForKey:@"content"];
    if ([content objectForKey:@"oembed"])
        return [[Embed alloc] initWithDictionary:eventData];

    if ([content objectForKey:@"bodyHtml"])
        return [[Post alloc] initWithDictionary:eventData authorsFrom:authorData];

    if ([[eventData objectForKey:@"type"] intValue] == ContentTypeOpine)
        return [[Like alloc] initWithDictionary:eventData authorsFrom:authorData];

    Entry *entry = [[Entry alloc] initWithDictionary:eventData];
    entry.deleted = YES;
    entry.parentId = parent.entryId;
    return entry;
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
        if (self.contentType > ContentTypeEmbed || self.contentType == 2) {
            NSLog(@"Unrecognized content type: %d", self.contentType);
            self.contentType = ContentTypeMessage;
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

- (void)addToParent:(Entry *)parent {
    parent.children = [parent.children arrayByAddingObject:self];
}

- (void)replaceInParent:(Entry *)parent {
    parent.children = replaceEntryInArray(parent.children, self.replaces, self);
}

- (void)removeFromParent {
    self.parent.children = replaceEntryInArray(self.parent.children, self.entryId, nil);
}

- (void)addChild:(Entry *)child {
    if (child.parent)
        [child removeFromParent];
    child.parent = self;
    [child addToParent:self];
}

- (void)replaceChild:(Entry *)child {
    if (child.parent)
        [child removeFromParent];
    child.parent = self;
    [child replaceInParent:self];
}

- (void)moveChildrenTo:(Entry *)newParent {
    newParent.createdAt = MIN(self.createdAt, newParent.createdAt);
    newParent.editedAt = MAX(self.editedAt, newParent.editedAt);

    for (NSUInteger i = [self.children count]; i > 0; --i) {
        [newParent addChild:[self.children objectAtIndex:(i - 1)]];
    }
    for (NSUInteger i = [self.embed count]; i > 0; --i) {
        [newParent addChild:[self.embed objectAtIndex:(i - 1)]];
    }
    for (NSUInteger i = [self.likes count]; i > 0; --i) {
        [newParent addChild:[self.likes objectAtIndex:(i - 1)]];
    }
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

- (void)addToParent:(Entry *)parent {
    parent.likes = [parent.likes arrayByAddingObject:self];
}

- (void)replaceInParent:(Entry *)parent {
    parent.likes = replaceEntryInArray(parent.likes, self.replaces, self);
}

- (void)removeFromParent {
    self.parent.likes = replaceEntryInArray(self.parent.likes, self.entryId, nil);
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
    }
    return self;
}

- (void)addToParent:(Entry *)parent {
    self.author = parent.author;
    parent.embed = [parent.embed arrayByAddingObject:self];
}

- (void)replaceInParent:(Entry *)parent {
    self.author = parent.author;
    parent.embed = replaceEntryInArray(parent.embed, self.replaces, self);
}

- (void)removeFromParent {
    self.parent.embed = replaceEntryInArray(self.parent.embed, self.entryId, nil);
}
@end

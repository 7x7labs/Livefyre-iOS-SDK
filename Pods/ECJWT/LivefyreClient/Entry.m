//
//  Event.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Entry.h"

@interface Entry ()
@property (strong, nonatomic) NSString *entryId;
@property (weak, nonatomic) Author *author;
@property (nonatomic) int createdAt;
@property (nonatomic) int source;
@property (nonatomic) enum ContentType contentType;
@property (nonatomic) enum ContentVisibility visibility;
@property (strong, nonatomic) NSString *replaces;
@property (strong, nonatomic) NSString *parentId;

- (void)addToParent:(Post *)parent;
- (void)replaceInParent:(Post *)parent;
@end

@interface Post ()
@property (strong, nonatomic) NSString *body;
@property (nonatomic) enum Permissions authorPermissions;
@property (nonatomic) enum PermissionScope permissionScope;
@property (strong, nonatomic) NSArray *children;
@property (strong, nonatomic) NSArray *embed;
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
@synthesize source = source_;
@synthesize contentType = contentType_;
@synthesize visibility = visibility_;
@synthesize replaces = replaces_;
@synthesize parentId = parentId_;

+ (Entry *)entryWithDictionary:(NSDictionary *)eventData
                   authorsFrom:(id <AuthorLookup>)authorData
{
    NSDictionary *content = [eventData objectForKey:@"content"];
    if ([content objectForKey:@"oembed"])
        return [[Embed alloc] initWithDictionary:eventData];

    if ([content objectForKey:@"bodyHtml"])
        return [[Post alloc] initWithDictionary:eventData authorsFrom:authorData];

    return nil;
}

- (Entry *)initWithDictionary:(NSDictionary *)eventData {
    self = [super init];
    if (self) {
        NSDictionary *content = [eventData objectForKey:@"content"];
        self.entryId = [content objectForKey:@"id"];
        self.createdAt = [[eventData objectForKey:@"event"] intValue];
        self.source = [[eventData objectForKey:@"source"] intValue];
        self.contentType = [[eventData objectForKey:@"type"] intValue];
        self.visibility = [[eventData objectForKey:@"vis"] intValue];
    }
    return self;
}

- (void)addToParent:(Post *)parent { }
- (void)replaceInParent:(Post *)parent { }
- (void)addChild:(Entry *)child { }
- (void)replaceChild:(Entry *)child { }

- (NSArray *)replaceEntryInArray:(NSArray *)array {
    NSUInteger index = [array indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj entryId] isEqualToString:self.replaces];
    }];
    if (index == NSNotFound)
        return array;

    NSMutableArray *mutable = [NSMutableArray arrayWithArray:array];
    [mutable replaceObjectAtIndex:index withObject:self];
    return mutable;
}
@end

@implementation Post
@synthesize body = body_;
@synthesize authorPermissions = authorPermissions_;
@synthesize permissionScope = permissionScope_;
@synthesize children = children_;
@synthesize embed = embed_;

- (Post *)initWithDictionary:(NSDictionary *)eventData
                 authorsFrom:(id <AuthorLookup>)authorData
{
    self = [super initWithDictionary:eventData];
    if (self) {
        NSDictionary *content = [eventData objectForKey:@"content"];
        self.body = [content objectForKey:@"bodyHtml"];
        self.authorPermissions = [[content objectForKey:@"authorPermission"] intValue];
        self.permissionScope = [[content objectForKey:@"permissionScope"] intValue];
        self.children = [[NSArray alloc] init];
        self.embed = [[NSArray alloc] init];
        self.author = [authorData authorForId:[content objectForKey:@"authorId"]];
        self.replaces = [content objectForKey:@"replaces"];
        self.parentId = [content objectForKey:@"parentId"];

        if (self.replaces.length == 0)
            self.replaces = nil;
        if (self.parentId.length == 0)
            self.parentId = nil;
    }
    return self;
}

- (void)addToParent:(Post *)parent {
    parent.children = [parent.children arrayByAddingObject:self];
}

- (void)replaceInParent:(Post *)parent {
    parent.children = [self replaceEntryInArray:parent.children];
}

- (void)addChild:(Entry *)child {
    [child addToParent:self];
}

- (void)replaceChild:(Entry *)child {
    [child replaceInParent:self];
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
        self.providerUrl = [oembed objectForKey:@"providerUrl"];
        self.title = [oembed objectForKey:@"title"];
        self.url = [oembed objectForKey:@"url"];
        self.type = [oembed objectForKey:@"type"];
        self.authorName = [oembed objectForKey:@"authorName"];
        self.html = [oembed objectForKey:@"html"];
        self.version = [oembed objectForKey:@"version"];
        self.authorUrl = [oembed objectForKey:@"authorUrl"];
        self.providerName = [oembed objectForKey:@"providerName"];
        self.thumbnailUrl = [oembed objectForKey:@"thumbnailUrl"];
        self.height = [[oembed objectForKey:@"height"] intValue];
        self.width = [[oembed objectForKey:@"width"] intValue];
        self.thumbnailHeight = [[oembed objectForKey:@"thumbnailHeight"] intValue];
        self.thumbnailWidth = [[oembed objectForKey:@"thumbnailWidth"] intValue];
        self.position = [[content objectForKey:@"position"] intValue];
        self.parentId = [content objectForKey:@"targetId"];

        if (self.parentId.length == 0)
            self.parentId = nil;
    }
    return self;
}

- (void)addToParent:(Post *)parent {
    self.author = parent.author;
    parent.embed = [parent.embed arrayByAddingObject:self];
}

- (void)replaceInParent:(Post *)parent {
    self.author = parent.author;
    parent.embed = [self replaceEntryInArray:parent.embed];

}
@end

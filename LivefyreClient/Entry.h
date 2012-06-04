//
//  Event.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Author;
@class Collection;
@class Post;

enum ContentType {
    ContentTypeMessage = 0,
    ContentTypeOpine = 1,
    ContentTypeEmbed = 3
};

enum ContentVisibility {
    ContentVisibilityNone = 0,
    ContentVisibilityEveryone = 1,
    ContentVisibilityOwner = 2,
    ContentVisibilityGroup = 3
};

enum Permissions {
    PermissionsNone = 0,
    PermissionsWhitelist = 1,
    PermissionsBlacklist = 2,
    PermissionsGraylist = 3,
    PermissionsModerator = 4
};

enum PermissionScope {
    PermissionScopeGlobal = 0,
    PermissionScopeNetwork = 1,
    PermissionScopeSite = 2,
    PermissionScopeCollection = 3,
    PermissionScopeCollectionRule = 4
};

@protocol AuthorLookup <NSObject>
- (Author *)authorForId:(NSString *)authorId;
@end

@interface Entry : NSObject
@property (strong, nonatomic, readonly) NSString *entryId;
@property (weak, nonatomic, readonly) Entry *parent;
@property (weak, nonatomic, readonly) Collection *collection;
@property (weak, nonatomic, readonly) Author *author;

@property (nonatomic, readonly) int createdAt;
@property (nonatomic, readonly) int editedAt;
@property (nonatomic, readonly) int source;
@property (nonatomic, readonly) enum ContentType contentType;
@property (nonatomic, readonly) enum ContentVisibility visibility;
@property (strong, nonatomic, readonly) NSString *replaces;
@property (strong, nonatomic, readonly) NSString *parentId;
@property (nonatomic, readonly) BOOL deleted;

@property (strong, nonatomic, readonly) NSArray *children;
@property (strong, nonatomic, readonly) NSArray *embed;
@property (strong, nonatomic, readonly) NSArray *likes;

+ (Entry *)entryWithDictionary:(NSDictionary *)eventData
                   authorsFrom:(id <AuthorLookup>)authorData
                  inCollection:(Collection *)collection;

+ (Entry *)entryWithDictionary:(NSDictionary *)eventData
                   authorsFrom:(id <AuthorLookup>)authorData
                    withParent:(Entry *)parent;

- (Entry *)initWithDictionary:(NSDictionary *)eventData;

- (void)addChild:(Entry *)child;
- (void)copyFrom:(Entry *)entry;
@end

@interface Like : Entry
- (Like *)initWithDictionary:(NSDictionary *)eventData
                 authorsFrom:(id <AuthorLookup>)authorData;
@end

@interface Post : Entry
@property (strong, nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) enum Permissions authorPermissions;
@property (nonatomic, readonly) enum PermissionScope permissionScope;

- (Post *)initWithDictionary:(NSDictionary *)eventData
                 authorsFrom:(id <AuthorLookup>)authorData;
@end

@interface Embed : Entry
@property (strong, nonatomic, readonly) NSString *link;
@property (strong, nonatomic, readonly) NSString *providerUrl;
@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *url;
@property (strong, nonatomic, readonly) NSString *type;
@property (strong, nonatomic, readonly) NSString *authorName;
@property (strong, nonatomic, readonly) NSString *html;
@property (strong, nonatomic, readonly) NSString *version;
@property (strong, nonatomic, readonly) NSString *authorUrl;
@property (strong, nonatomic, readonly) NSString *providerName;
@property (strong, nonatomic, readonly) NSString *thumbnailUrl;
@property (nonatomic, readonly) int height;
@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int thumbnailHeight;
@property (nonatomic, readonly) int thumbnailWidth;
@property (nonatomic, readonly) int position;

- (Embed *)initWithDictionary:(NSDictionary *)eventData;
@end

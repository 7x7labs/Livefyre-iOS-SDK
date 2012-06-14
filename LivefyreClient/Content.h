//
//  Content.h
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
    /// A message posted by a user in reply to an article or another comment.
    ContentTypeMessage = 0,
    /// An opinion from a user indicating that they like a comment or an embed.
    ContentTypeOpine = 1,
    /// An embedded image which is part of a comment.
    ContentTypeEmbed = 3
};

enum ContentVisibility {
    /// The content is visible to no one, usually due to being deleted.
    ContentVisibilityNone = 0,
    /// The content is visible to everyone.
    ContentVisibilityEveryone = 1,
    /// The content is visible to only the author due to hellbanning.
    ContentVisibilityOwner = 2,
    /// The content is visible to the author and any moderators for the
    /// collection, usually meaning that it's waiting for approval.
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

/// A author ID -> author data mapping.
@protocol AuthorLookup <NSObject>
- (Author *)authorForId:(NSString *)authorId;
@end

/// Content in a collection, such as a comment or an image embedded in a comment.
@interface Content : NSObject
/// The unique Livefyre ID of this content.
///
/// This is not guaranteed to remain unchanged over the life of a Content instance.
@property (strong, nonatomic, readonly) NSString *contentId;

/// The parent of this content.
///
/// Posts with this set are replies to the given Post, and are a top-level
/// comment on the article if this is `nil`. Likes and Embeds should always
/// have this set to a Post as they make little sense on their own.
@property (weak, nonatomic, readonly) Content *parent;

/// The Collection containing this Content.
@property (weak, nonatomic, readonly) Collection *collection;

/// The author of this Content.
@property (weak, nonatomic, readonly) Author *author;

/// When this Content was first created, in epoch time.
@property (nonatomic, readonly) int createdAt;
/// When this Content was last edited, in epoch time.
@property (nonatomic, readonly) int editedAt;

/// Livefyre collections can contain data from external social networks. This
/// field indicates where this specific Content came from.
///
/// 0, 4, 5, 8: Livefyre
/// 1, 2, 7: Twitter
/// 3, 6: Facebook
@property (nonatomic, readonly) int source;

/// The type of this Content.
///
/// This property should always match the result of checking the content type
/// based on the subclass.
@property (nonatomic, readonly) enum ContentType contentType;

/// The visibility of this Content.
///
/// ContentVisibilityOwner indicates that the Content can only be seen by the
/// posting user. This normally should not be revealed in the UI.
///
/// ContentTypeGroup indicates that the Content is currently waiting for
/// moderation and so it only visible to the posting user and any moderators
/// for the Livefyre collection.
///
/// Content which cannot be seen by the current user are automatically filtered
/// out, so ContentVisibilityNone will normally not be seen.
@property (nonatomic, readonly) enum ContentVisibility visibility;

/// Has this content been deleted?
///
/// If this is YES, all other fields other than contentId will either be 0/nil or
/// have stale data which should not be used.
@property (nonatomic, readonly) BOOL deleted;

/// Replies to this content. Generally only populated for Posts.
@property (strong, nonatomic, readonly) NSArray *children;

/// Images or videos embedded in this content. Generally only populated for
/// Posts.
@property (strong, nonatomic, readonly) NSArray *embed;

/// Likes for this content.
@property (strong, nonatomic, readonly) NSArray *likes;

// Implementation details follow
@property (strong, nonatomic, readonly) NSString *replaces;
@property (strong, nonatomic, readonly) NSString *parentId;
@property (nonatomic, readonly) int64_t event;

+ (Content *)contentWithDictionary:(NSDictionary *)contentData
                   authorsFrom:(id <AuthorLookup>)authorData
                  inCollection:(Collection *)collection;

+ (Content *)contentWithDictionary:(NSDictionary *)contentData
                   authorsFrom:(id <AuthorLookup>)authorData
                    withParent:(Content *)parent;

- (Content *)initWithDictionary:(NSDictionary *)contentData;

- (Content *)addChild:(Content *)child;
- (Content *)copyFrom:(Content *)content;
@end

/// An opinion of approval expressed by the author about its parent.
///
/// Likes add no additional data above what Content already has, and the `author`
/// is typically the only interesting property.
@interface Like : Content
- (Like *)initWithDictionary:(NSDictionary *)contentData
                 authorsFrom:(id <AuthorLookup>)authorData;
@end

/// A comment in reply to an article or another comment.
@interface Post : Content
/// The body of the comment, in HTML.
@property (strong, nonatomic, readonly) NSString *body;

/// The comment's author's local permissions level.
///
/// This can be used to mark posts by moderators and such.
@property (nonatomic, readonly) enum Permissions authorPermissions;

/// The scope of the author's local permissions.
@property (nonatomic, readonly) enum PermissionScope permissionScope;

- (Post *)initWithDictionary:(NSDictionary *)contentData
                 authorsFrom:(id <AuthorLookup>)authorData;
@end

/// An image or video embedded in a Post.
@interface Embed : Content
/// The URL of the page containing the embedded content, which may not be
/// distinct from url.
@property (strong, nonatomic, readonly) NSString *link;
/// URL of the actual embed data.
@property (strong, nonatomic, readonly) NSString *url;
/// Title of the embedded content.
@property (strong, nonatomic, readonly) NSString *title;
/// Unknown.
@property (strong, nonatomic, readonly) NSString *type;
/// Name of the author of the embedded content.
///
/// Note that this is the name of the creator of the content being embedded,
/// not the author of the post.
@property (strong, nonatomic, readonly) NSString *authorName;
/// URL of the author's site.
@property (strong, nonatomic, readonly) NSString *authorUrl;
/// HTML which includes the embedded content, which may be used instead of
/// using url directly.
@property (strong, nonatomic, readonly) NSString *html;
/// Unknown.
@property (strong, nonatomic, readonly) NSString *version;
/// Name of the source of the embedded content.
@property (strong, nonatomic, readonly) NSString *providerName;
/// Site of the source of the embedded content.
@property (strong, nonatomic, readonly) NSString *providerUrl;
/// Height in pixels of the content.
@property (nonatomic, readonly) int height;
/// Width in pixels of the content.
@property (nonatomic, readonly) int width;
/// URL for a thumbnail of the embedded content.
@property (strong, nonatomic, readonly) NSString *thumbnailUrl;
/// Height of the thumbnail in pixels.
@property (nonatomic, readonly) int thumbnailHeight;
/// Width of the thumbnail in pixels.
@property (nonatomic, readonly) int thumbnailWidth;
/// Unknown.
@property (nonatomic, readonly) int position;

- (Embed *)initWithDictionary:(NSDictionary *)contentData;
@end

//
//  LivefyreViewController.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 8/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFLivefyreViewController.h"

#import <LivefyreClient/LivefyreClient.h>
#import <BlocksKit/BlocksKit.h>
#import <JSONKit/JSONKit.h>

#import "LFAvatarCache.h"
#import "LFCommentTableViewCell.h"
#import "LFReplyViewController.h"

@interface LFLivefyreViewController () <LFReplyDelegate, UITableViewDataSource, UITableViewDelegate, LFCommentTableViewCellDelegate>
@property (weak, nonatomic) IBOutlet UINavigationItem *closeButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *replyButton;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *rowHeights;
@property (nonatomic, strong) NSMutableDictionary *postHeights;
@property (nonatomic, strong) NSMutableDictionary *postIndex;
@property (nonatomic, strong) UIFont *bodyFont;

@property (nonatomic, strong) LFAvatarCache *imageCache;
@property (nonatomic, weak) Post *replyParent;

@property (nonatomic) NSUInteger pagesFetched;
@property (nonatomic) BOOL isLoading;
@end

@implementation LFLivefyreViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    UIBarButtonItem *backButton = [UIBarButtonItem new];
    backButton.title = @"Close";
    self.navigationItem.backBarButtonItem = backButton;

    _imageCache = [LFAvatarCache new];
    _posts = [NSMutableArray new];
    _rowHeights = [NSMutableArray new];
    _postHeights = [NSMutableDictionary new];
    _postIndex = [NSMutableDictionary new];
    _bodyFont = [UIFont fontWithName:@"HelveticaNeue" size:14];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self.collection fetchBootstrap:^(BOOL bootstrapError, id bootstrapResult) {
        if (bootstrapError) {
            NSLog(@"error getting bootstrap: %@", bootstrapResult);
            [self error:@"Could not open the collection"];
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }

        [self rebuildPosts];
        [self.client startPollingForUpdates:self.collection
                              pollFrequency:30
                             requestTimeout:30
                                gotNewPosts:^(BOOL pollError, id pollResult)
         {
             if (pollError) {
                 NSLog(@"Error polling collection: %@", pollResult);
                 return;
             }

             // Set the height of new posts to 0 so that their
             // appearance is animated, but only if they're recent; the
             // bootstrap head is not updated immediately so the first stream
             // response may include some fairly old posts that shouldn't be
             // animated in.
             NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
             for (Post *newPost in pollResult) {
                 if (!self.postHeights[newPost.contentId] && now - newPost.createdAt < 60) {
                     self.postHeights[newPost.contentId] = @(0);
                 }
             }

             // This could be optimized by only inserting the new posts rather
             // than rebuilding the entire list of posts, but in practice even
             // with a few thousand loaded posts rebuilding the list is trivial
             [self rebuildPosts];
         }];
    }];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self.client stopPollingForUpdates:self.collection];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LFReplyViewController *targetController = segue.destinationViewController;
    targetController.delegate = self;
    targetController.user = self.collection.user;
}

- (void)rebuildPosts {
    [self.posts removeAllObjects];
    [self.rowHeights removeAllObjects];

    NSArray *posts = [self.collection.posts sortedArrayUsingComparator:^(id obj1, id obj2) {
        int lft = [obj1 createdAt];
        int rgt = [obj2 createdAt];
        if (lft > rgt)
            return NSOrderedAscending;
        if (lft < rgt)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];

    for (Post *post in posts) {
        [self addPost:post depth:0];
    }
    [self.tableView reloadData];
}

- (void)addPost:(Post *)post depth:(NSInteger)depth {
    if (post.deleted) return;

    self.postIndex[post.contentId] = @([self.posts count]);
    [self.posts addObject:post];

    NSNumber *height = self.postHeights[post.contentId];
    if (!height) {
        height = @([self getHeight:post.body indent:depth]);
        self.postHeights[post.contentId] = height;
    }
    [self.rowHeights addObject:height];

    for (Post *child in post.children) {
        if ([child contentType] == ContentTypeMessage) {
            [self addPost:child depth:depth + 1];
        }
    }
}

- (void)fetchNextPage {
    if (!self.isLoading && self.pagesFetched < self.collection.numberOfPages) {
        self.isLoading = YES;
        [self.collection fetchPage:self.collection.numberOfPages - self.pagesFetched - 1
                           gotPage:^(BOOL error, id resultOrError)
        {
            self.isLoading = NO;
            self.pagesFetched += 1;
            [self rebuildPosts];
        }];
    }
}

- (CGFloat)getHeight:(NSString *)string indent:(NSInteger)indent {
    // Try to calculate the height of the string without loading it into a
    // webview, as resizing UITableView cells is slow and ugly, and preloading
    // everything into webviews uses unacceptable amounts of memory
    string = [self stripHtml:string];
    CGSize size = [string sizeWithFont:self.bodyFont
                     constrainedToSize:CGSizeMake(285 - 8 * indent, 200)
                         lineBreakMode:UILineBreakModeWordWrap];
    int lines = (int)size.height / 18;
    // webview is set to 17px line-height, origin.y = 34, 7px top/bottom padding,
    // and 1 px border under it
    return lines * 17 + 34 + 1 + 7 * 2;
}

- (NSString*)stripHtml:(NSString *)string {
    string = [NSString stringWithFormat:@"<r>%@</r>", string];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[string dataUsingEncoding:[string fastestEncoding]]];

    NSMutableArray *chunks = [NSMutableArray new];
    A2DynamicDelegate *delegate = [parser dynamicDelegate];
    [delegate implementMethod:@selector(parser:foundCharacters:) withBlock:^(NSXMLParser *xmlParser, NSString *chunk) {
        [chunks addObject:chunk];
    }];
    parser.delegate = (id)delegate;

    [parser parse];
    return [chunks componentsJoinedByString:@""];
}

- (void)error:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - ReplyDelegate
- (void)postReply:(NSString *)body {
    void (^complete)(BOOL error, id resultOrError) = ^(BOOL error, id resultOrError) {
        if (error) {
            NSLog(@"error creating post: %@", resultOrError);
            [self error:resultOrError];
        }
        else {
            self.postHeights[[resultOrError contentId]] = @(0);
            [self rebuildPosts];
        }
        [self.navigationController popViewControllerAnimated:YES];
    };


    if (self.replyParent) {
        [self.client createPost:body inReplyTo:self.replyParent onComplete:complete];
    }
    else {
        [self.client createPost:body inCollection:self.collection onComplete:complete];
    }
}

- (void)setImageView:(UIImageView *)view toImageAtURL:(NSString *)url {
    [self.imageCache setImageView:view toImageAtURL:url];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Post *post = self.posts[indexPath.row];
    LFCommentTableViewCell *cell = (LFCommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"comment"];

    cell.delegate = self;
    [cell setToPost:post];

    CGRect frame = cell.frame;
    frame.size.height = [self.rowHeights[indexPath.row] floatValue];
    cell.frame = frame;

    // Fetch the next page if we're near the bottom for infinite-scroll
    if ([self.posts count] - indexPath.row < 10) {
        [self fetchNextPage];
    }

    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.rowHeights[indexPath.row] floatValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.replyParent = self.posts[indexPath.row];
    [self performSegueWithIdentifier:@"reply" sender:self];
}

#pragma mark - CmmentTableViewCellDelegate
- (void)postWithId:(NSString *)contentId hasHeight:(CGFloat)height {
    CGFloat oldHeight = [self.postHeights[contentId] floatValue];
    if (oldHeight == height) return;

    NSUInteger index = [self.postIndex[contentId] unsignedIntegerValue];
    self.postHeights[contentId] = @(height);
    self.rowHeights[index] = @(height);

    // The combination of Helvetica Neue Medium and Regular in the body
    // occasionally results in the estimate being off by one pixel, and it's
    // not worth updating the cell height for that
    if (oldHeight + 1 >= height && oldHeight - 1 <= height) return;

    NSTimeInterval age = [[NSDate date] timeIntervalSince1970] - [self.posts[index] editedAt];
    UITableViewRowAnimation animation = age > 60 ? UITableViewRowAnimationNone : UITableViewRowAnimationAutomatic;

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                          withRowAnimation:animation];
}
@end

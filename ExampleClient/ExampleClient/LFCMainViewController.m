//
//  LFCMainViewController.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFCMainViewController.h"

#import "CommentList.h"
#import "CommentView.h"

@interface LFCMainViewController ()
@property (strong, nonatomic) LivefyreClient *client;
@property (strong, nonatomic) Collection *collection;
@property (strong, nonatomic) RequestComplete gotData;
@property (nonatomic) NSUInteger pagesFetched;

@property (weak, nonatomic) IBOutlet CommentList *commentList;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *commentBox;
@property (weak, nonatomic) IBOutlet UITextView *commentBody;
@property (weak, nonatomic) IBOutlet UIButton *nextPage;
@end

@implementation LFCMainViewController
@synthesize client = _client;
@synthesize collection = _collection;
@synthesize gotData = _gotData;
@synthesize commentList = _commentList;
@synthesize scrollView = _scrollView;
@synthesize commentBox = _commentBox;
@synthesize commentBody = _commentBody;
@synthesize nextPage = _nextPage;
@synthesize pagesFetched = _pagesFetched;

// General request completion handler which either displays the error message
// in an alert view or sends the changed posts to the CommentList
- (RequestComplete)gotData {
    if (!_gotData) {
        __weak LFCMainViewController *weakSelf = self;
        _gotData = ^(BOOL error, id resultOrError) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:resultOrError
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil,
                  nil] show];
                return;
            }

            if ([resultOrError conformsToProtocol:@protocol(NSFastEnumeration)]) {
                for (Content *changedContent in resultOrError) {
                    if (changedContent.contentType == ContentTypeMessage)
                        [weakSelf.commentList addComment:(Post *)changedContent];
                }
            }
            else if ([resultOrError isKindOfClass:[Post class]]) {
                if ([resultOrError contentType] == ContentTypeMessage)
                    [weakSelf.commentList addComment:resultOrError];
            }

            [weakSelf updateNextPageButton];
        };
    }

    return _gotData;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.commentList addObserver:self forKeyPath:@"frame" options:0 context:nil];
    [CommentView addBordersAndShadow:self.commentBox];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Switch to the config screen if we don't have a valid client yet
    if (!self.client)
        [self performSegueWithIdentifier:@"showAlternate" sender:self];
}

- (void)flipsideViewControllerDidFinish:(LFCFlipsideViewController *)controller {
    [self dismissModalViewControllerAnimated:YES];

    if (!controller.client)
        return;

    if (self.client) {
        [self.client stopPollingForUpdates:self.collection];
        [self.commentList clear];
    }

    self.pagesFetched = 0;
    self.client = controller.client;
    self.collection = controller.collection;
    [self.collection fetchBootstrap:self.gotData];
    [self.client startPollingForUpdates:self.collection
                          pollFrequency:30
                         requestTimeout:30
                            gotNewPosts:self.gotData];
    [self updateNextPageButton];
    [self showCommentBox:!!self.collection.user];
}

- (void)updateNextPageButton {
    if (self.pagesFetched >= self.collection.numberOfPages) {
        [self.nextPage setHidden:YES];
   }
    else {
        [self.nextPage setHidden:NO];
        [self.nextPage setEnabled:YES];
        [self.nextPage setAlpha:1.0];
    }
}

- (IBAction)nextPageTouched {
    [self.nextPage setEnabled:NO];
    [self.nextPage setAlpha:0.5];

    [self.collection fetchPage:self.pagesFetched++
                       gotPage:self.gotData];
}

- (IBAction)postComment {
    [self.client createPost:self.commentBody.text
               inCollection:self.collection
                 onComplete:self.gotData];

    self.commentBody.text = @"";
}

// Update the position of the Show More button and the content size of the
// scroll view whenever the comment list height changes
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    CGFloat y = self.commentList.frame.size.height + self.commentList.frame.origin.y;

    if (!self.nextPage.hidden) {
        CGRect frame = self.nextPage.frame;
        frame.origin.y = y;
        self.nextPage.frame = frame;
        y += frame.size.height + 8;
    }

    self.scrollView.contentSize = CGSizeMake(self.commentList.frame.size.width, y);
}

- (void)showCommentBox:(BOOL)show {
    CGRect frame = self.commentList.frame;
    frame.origin.y = show ? 250 : 20;
    self.commentList.frame = frame;
    self.commentBox.hidden = !show;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [[segue destinationViewController] setDelegate:self];
}

@end

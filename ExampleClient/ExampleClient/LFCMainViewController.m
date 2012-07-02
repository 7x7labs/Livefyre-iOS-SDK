//
//  LFCMainViewController.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFCMainViewController.h"

#import "CommentList.h"

@interface LFCMainViewController ()
@property (strong, nonatomic) LivefyreClient *client;
@property (strong, nonatomic) Collection *collection;
@property (strong, nonatomic) RequestComplete gotData;
@property (nonatomic) NSUInteger pagesFetched;

@property (weak, nonatomic) IBOutlet CommentList *commentList;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *nextPage;
@end

@implementation LFCMainViewController
@synthesize client = _client;
@synthesize collection = _collection;
@synthesize gotData = _gotData;
@synthesize commentList = _commentList;
@synthesize scrollView = _scrollView;
@synthesize pagesFetched = _pagesFetched;
@synthesize nextPage = _nextPage;

- (void)viewDidLoad {
    [super viewDidLoad];

    __weak LFCMainViewController *weakSelf = self;
    self.gotData = ^(BOOL error, id resultOrError) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:resultOrError
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil,
              nil] show];
            return;
        }

        for (Content *changedContent in resultOrError) {
            // Only process top-level comments for now
            if (!changedContent.parent && changedContent.contentType == ContentTypeMessage)
                [weakSelf.commentList addComment:(Post *)changedContent];
        }

        [weakSelf updateNextPageButton];
    };

    [self.commentList addObserver:self
                       forKeyPath:@"frame"
                          options:0
                          context:nil];
}

- (void)flipsideViewControllerDidFinish:(LFCFlipsideViewController *)controller {
    [self dismissModalViewControllerAnimated:YES];

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
}

- (void)updateNextPageButton {
    if (self.pagesFetched >= self.collection.numberOfPages) {
        [self.nextPage removeFromSuperview];
        self.nextPage = nil;
   }
    else if (!self.nextPage) {
        self.nextPage = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.nextPage addTarget:self
                          action:@selector(nextPageTouched:)
                forControlEvents:UIControlEventTouchUpInside];
        [self.nextPage setTitle:@"Show More" forState:UIControlStateNormal];
        self.nextPage.frame = CGRectMake(90, 0, 100, 37);
        [self.scrollView addSubview:self.nextPage];
    }
    else {
        [self.nextPage setEnabled:YES];
        [self.nextPage setAlpha:1.0];
    }
}

- (void)nextPageTouched:(id)sender {
    [self.nextPage setEnabled:NO];
    [self.nextPage setAlpha:0.5];

    [self.collection fetchPage:self.pagesFetched++
                       gotPage:self.gotData];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    CGFloat y = self.commentList.frame.size.height + self.commentList.frame.origin.y;

    if (self.nextPage) {
        self.nextPage.frame = CGRectMake(90, y, self.nextPage.frame.size.width, self.nextPage.frame.size.height);
        y += self.nextPage.frame.size.height + 8;
    }

    self.scrollView.contentSize = CGSizeMake(self.commentList.frame.size.width, y);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)viewDidUnload {
    [self setCommentList:nil];
    [self setScrollView:nil];
    [super viewDidUnload];
}
@end

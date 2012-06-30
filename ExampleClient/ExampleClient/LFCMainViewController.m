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
@end

@implementation LFCMainViewController
@synthesize client = _client;
@synthesize collection = _collection;
@synthesize gotData = _gotData;
@synthesize commentList = _commentList;
@synthesize pagesFetched = _pagesFetched;

- (void)viewDidLoad {
    [super viewDidLoad];

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
                [self.commentList addComment:(Post *)changedContent];
        }

    };
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
        [self.commentList showNextPageButton:nil];
    }
    else {
        [self.commentList showNextPageButton:^{
            [self.collection fetchPage:self.pagesFetched
                               gotPage:self.gotData];
            ++self.pagesFetched;
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)viewDidUnload {
    [self setCommentList:nil];
    [super viewDidUnload];
}
@end

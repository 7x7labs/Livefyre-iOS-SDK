//
//  LFCMainViewController.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFCMainViewController.h"

@interface LFCMainViewController ()
@property (strong, nonatomic) LivefyreClient *client;
@property (strong, nonatomic) Collection *collection;
@property (strong, nonatomic) RequestComplete gotData;
@end

@implementation LFCMainViewController
@synthesize client = _client;
@synthesize collection = _collection;
@synthesize gotData = _gotData;

- (id)init {
    self = [super init];
    if (self) {
        self.gotData = ^(BOOL error, id resultOrError) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:resultOrError
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil,
                  nil] show];
            }
        };
    }
    return self;
}

- (void)flipsideViewControllerDidFinish:(LFCFlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];

    if (self.client) {
        [self.client stopPollingForUpdates:self.collection];
    }

    self.client = controller.client;
    self.collection = controller.collection;
    [self.collection fetchBootstrap:self.gotData];
    [self.client startPollingForUpdates:self.collection
                          pollFrequency:30
                         requestTimeout:30
                            gotNewPosts:self.gotData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

@end

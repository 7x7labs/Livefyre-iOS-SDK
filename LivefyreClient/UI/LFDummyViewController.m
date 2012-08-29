//
//  LFDummyViewController.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 9/20/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFDummyViewController.h"

#import "LFLivefyreViewController.h"

@interface LFDummyViewController ()
@property (nonatomic) BOOL hasSegued;
@end

@implementation LFDummyViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self performSegueWithIdentifier:@"initial" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LFLivefyreViewController *targetController = segue.destinationViewController;
    targetController.client = self.client;
    targetController.collection = self.collection;
    self.hasSegued = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.hasSegued) {
        [self dismissModalViewControllerAnimated:YES];
    }
}
@end

@implementation LFNonAnimatedPush
- (void)perform{
    [[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:NO];
}
@end

//
//  LFCFlipsideViewController.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFCFlipsideViewController.h"

@interface LFCFlipsideViewController ()
@property (weak, nonatomic) IBOutlet UITextField *bootstrapHost;
@property (weak, nonatomic) IBOutlet UITextField *environment;
@property (weak, nonatomic) IBOutlet UITextField *network;
@property (weak, nonatomic) IBOutlet UITextField *siteId;
@property (weak, nonatomic) IBOutlet UITextField *articleId;
@property (weak, nonatomic) IBOutlet UITextField *userToken;

@property (weak, nonatomic) IBOutlet UILabel *bootstrapHostLabel;
@property (weak, nonatomic) IBOutlet UILabel *networkLabel;
@property (weak, nonatomic) IBOutlet UILabel *siteLabel;
@property (weak, nonatomic) IBOutlet UILabel *articleLabel;

@property (nonatomic) BOOL allValid;
@end

@implementation LFCFlipsideViewController
@synthesize articleId = _articleId;
@synthesize articleLabel = _articleLabel;
@synthesize bootstrapHost = _bootstrapHost;
@synthesize bootstrapHostLabel = _bootstrapHostLabel;
@synthesize environment = _environment;
@synthesize network = _network;
@synthesize networkLabel = _networkLabel;
@synthesize siteId = _siteId;
@synthesize siteLabel = _siteLabel;
@synthesize userToken = _userToken;

@synthesize delegate = _delegate;
@synthesize client = _client;
@synthesize collection = _collection;

@synthesize allValid = _allValid;

- (void)validate:(UITextField *)textField label:(UILabel *)label {
    if ([textField.text length] == 0) {
        label.textColor = [UIColor redColor];
        self.allValid = NO;
    }
    else {
        label.textColor = [UIColor blackColor];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)cancel:(id)sender {
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (IBAction)save {
    self.allValid = YES;
    [self validate:self.bootstrapHost label:self.bootstrapHostLabel];
    [self validate:self.network label:self.networkLabel];
    [self validate:self.siteId label:self.siteLabel];
    [self validate:self.articleId label:self.articleLabel];
    if (!self.allValid) return;

    self.client = [LivefyreClient clientWithDomain:self.network.text
                                       environment:self.environment.text
                                     bootstrapHost:self.bootstrapHost.text
                                         domainKey:nil];

    void (^gotCollection)(BOOL, id) = ^(BOOL error, id collectionOrError) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:collectionOrError
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil,
              nil] show];
        }
        else {
            self.collection = collectionOrError;
            [self.delegate flipsideViewControllerDidFinish:self];
       }
    };

    if ([self.userToken.text length]) {
        [self.client getCollectionForArticle:self.articleId.text
                                      inSite:self.siteId.text
                                forUserToken:self.userToken.text
                               gotCollection:gotCollection];
    }
    else {
        [self.client getCollectionForArticle:self.articleId.text
                                      inSite:self.siteId.text
                                     forUser:nil
                               gotCollection:gotCollection];
    }
}

@end

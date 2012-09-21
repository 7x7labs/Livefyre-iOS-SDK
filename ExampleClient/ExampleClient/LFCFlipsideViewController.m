//
//  LFCFlipsideViewController.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFCFlipsideViewController.h"

@interface LFCFlipsideViewController () <UITextFieldDelegate>
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
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic) BOOL allValid;
@end

@implementation LFCFlipsideViewController
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
    self.scrollView.contentSize = self.scrollView.frame.size;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
                                     bootstrapHost:self.bootstrapHost.text];

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

- (IBAction)openDefaultUI:(id)sender {
    self.allValid = YES;
    [self validate:self.bootstrapHost label:self.bootstrapHostLabel];
    [self validate:self.network label:self.networkLabel];
    [self validate:self.siteId label:self.siteLabel];
    [self validate:self.articleId label:self.articleLabel];
    if (!self.allValid) return;

    [LivefyreClient showModalUIInViewController:self
                                        article:self.articleId.text
                                           site:self.siteId.text
                                         domain:self.network.text
                                    environment:self.environment.text
                                  bootstrapHost:self.bootstrapHost.text
                                      userToken:self.userToken.text
                                 customizations:nil];
}

#pragma mark - UITextFieldDelegate
-(void)keyboardDidShow:(NSNotification *)notification  {
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize size = self.view.frame.size;

    self.scrollView.contentSize = CGSizeMake(size.width, size.height + keyboardFrame.size.height);
    self.scrollView.bounces = YES;

    for (UIView *subView in self.scrollView.subviews) {
        if ([subView isFirstResponder]) {
            if (CGRectIntersectsRect(subView.frame, keyboardFrame)) {
                [self.scrollView setContentOffset:CGPointMake(0, keyboardFrame.size.height) animated:YES];
            }
            break;
        }
    }
}

-(void)keyboardDidHide:(NSNotification *)notification  {
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    self.scrollView.contentSize = self.scrollView.frame.size;
    self.scrollView.bounces = NO;
}
@end

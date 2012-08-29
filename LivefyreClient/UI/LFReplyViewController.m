//
//  ReplyViewController.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 9/14/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFReplyViewController.h"

#import <LivefyreClient/LivefyreClient.h>

@interface LFReplyViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UITableView *backgroundView;
@end

@implementation LFReplyViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    [self.textView becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    self.userName.text = self.user.displayName;
    self.avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.user.avatarUrl]]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)keyboardDidShow:(NSNotification *)notification  {
    CGRect keyboardFrame = [[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.backgroundView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - keyboardFrame.size.height);
}

- (IBAction)postTouched:(id)sender {
    [self.delegate postReply:self.textView.text];
}
@end

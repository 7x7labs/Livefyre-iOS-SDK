//
//  CommentView.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "CommentView.h"

#import <QuartzCore/QuartzCore.h>

@interface CommentView () <UIWebViewDelegate>
@property (strong, nonatomic) UILabel *authorName;
@property (strong, nonatomic) UILabel *timestamp;
@property (strong, nonatomic) UIWebView *body;
@property (strong, nonatomic) UIImageView *avatar;

@property (weak, nonatomic) Post *comment;

- (void)webViewDidFinishLoad:(UIWebView *)webView;
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
@end

@implementation CommentView
@synthesize authorName = _authorName;
@synthesize timestamp = _timestamp;
@synthesize body = _body;
@synthesize avatar = _avatar;
@synthesize comment = _comment;

+ (CommentView *)viewForPost:(Post *)post width:(CGFloat)width {
    CGRect frame = CGRectMake(8, 0, width - 16, 100);
    CommentView *view = [[self alloc] initWithFrame:frame];
    [view loadFromPost:post];
    return view;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return self;

    self.authorName = [[UILabel alloc] initWithFrame:CGRectMake(66, 8, 190, 21)];
    self.authorName.backgroundColor = [UIColor clearColor];
    [self addSubview:self.authorName];

    self.timestamp = [[UILabel alloc] initWithFrame:CGRectMake(66, 37, 190, 21)];
    self.timestamp.backgroundColor = [UIColor clearColor];
    [self addSubview:self.timestamp];

    self.body = [[UIWebView alloc] initWithFrame:CGRectMake(8, 66, 246, 66)];
    self.body.backgroundColor = [UIColor clearColor];
    self.body.opaque = NO;
    self.body.delegate = self;
    [self addSubview:self.body];

    self.avatar = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 50, 50)];
    [self addSubview:self.avatar];

    self.backgroundColor =
    [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
    self.layer.cornerRadius = 8.0;
    self.layer.shadowColor = [UIColor colorWithWhite:0.12 alpha:1].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 0.5);
    self.layer.shadowRadius = 2.5;
    self.layer.shadowOpacity = 1;
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;

    return self;
}

- (NSString *)formatTime:(time_t)time {
    struct tm timeStruct;
    localtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, "%Y-%m-%d %H:%M:%S", &timeStruct);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    CGRect frame = webView.frame;
    frame.size.height = 1;
    webView.frame = frame;

    CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    webView.frame = frame;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                            self.frame.size.width,
                            self.body.frame.origin.y + self.body.frame.size.height + 8);

    [[self superview] setNeedsLayout];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeOther)
        return YES;

    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
}

- (void)loadFromPost:(Post *)post {
    self.comment = post;

    self.authorName.text = post.author.displayName;
    [self.body loadHTMLString:post.body baseURL:nil];
    self.timestamp.text = [self formatTime:post.editedAt];

    [post addObserver:self forKeyPath:@"body"     options:0 context:nil];
    [post addObserver:self forKeyPath:@"editedAt" options:0 context:nil];
    [post addObserver:self forKeyPath:@"deleted"  options:0 context:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:post.author.avatarUrl]]];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.avatar.image = image;
        });
	});
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (self.comment.deleted) {
        [self destroy];
    }
    else {
	    [self.body loadHTMLString:self.comment.body baseURL:nil];
        self.timestamp.text = [self formatTime:self.comment.editedAt];
    }
}

- (void)destroy {
    [self.comment removeObserver:self forKeyPath:@"body"];
    [self.comment removeObserver:self forKeyPath:@"editedAt"];
    [self.comment removeObserver:self forKeyPath:@"deleted"];
    [self removeFromSuperview];
}

@end

//
//  CommentView.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "CommentView.h"

#import <QuartzCore/QuartzCore.h>

static const int AvatarSize = 50;
static const int PaddingWidth = 8;
static const int TextBoxHeight = 21;

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

+ (void)addBordersAndShadow:(UIView *)view {
    view.layer.cornerRadius = 8.0;
    view.layer.shadowColor = [UIColor colorWithWhite:0.12 alpha:1].CGColor;
    view.layer.shadowOffset = CGSizeMake(0, 0.5);
    view.layer.shadowRadius = 2.5;
    view.layer.shadowOpacity = 1;
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return self;

    const int topBoxesX = AvatarSize + PaddingWidth * 2;
    const int topBoxesWidth = frame.size.width - topBoxesX - PaddingWidth;

    self.authorName = [[UILabel alloc] initWithFrame:CGRectMake(topBoxesX, PaddingWidth, topBoxesWidth, TextBoxHeight)];
    self.authorName.backgroundColor = [UIColor clearColor];
    [self addSubview:self.authorName];

    self.timestamp = [[UILabel alloc] initWithFrame:CGRectMake(topBoxesX, TextBoxHeight + PaddingWidth * 2, topBoxesWidth, TextBoxHeight)];
    self.timestamp.backgroundColor = [UIColor clearColor];
    [self addSubview:self.timestamp];

    self.body = [[UIWebView alloc] initWithFrame:CGRectMake(PaddingWidth, AvatarSize + PaddingWidth * 2, frame.size.width, 66)];
    self.body.backgroundColor = [UIColor clearColor];
    self.body.opaque = NO;
    self.body.delegate = self;
    [self addSubview:self.body];

    self.avatar = [[UIImageView alloc] initWithFrame:CGRectMake(PaddingWidth, PaddingWidth, AvatarSize, AvatarSize)];
    [self addSubview:self.avatar];

    self.backgroundColor =
    [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
    [CommentView addBordersAndShadow:self];

    return self;
}

// Update the size of the view to fit the contents
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // sizeThatFits never returns a size smaller than the current size
    CGRect frame = webView.frame;
    frame.size.height = 1;
    webView.frame = frame;

    CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    webView.frame = frame;

    frame = self.frame;
    frame.size.height = self.body.frame.origin.y + self.body.frame.size.height + PaddingWidth;
    self.frame = frame;

    [[self superview] setNeedsLayout];
}

// Make any links clicked open in Safari rather than in the comment view
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeOther)
        return YES;

    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
}

- (NSString *)formatTime:(time_t)time {
    struct tm timeStruct;
    localtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, "%Y-%m-%d %H:%M:%S", &timeStruct);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}

- (void)loadFromPost:(Post *)post {
    self.comment = post;

    self.authorName.text = post.author.displayName;
    [self.body loadHTMLString:post.body baseURL:nil];
    self.timestamp.text = [self formatTime:post.editedAt];

    [post addObserver:self forKeyPath:@"body"     options:0 context:nil];
    [post addObserver:self forKeyPath:@"editedAt" options:0 context:nil];
    [post addObserver:self forKeyPath:@"deleted"  options:0 context:nil];

    // Fetch the avatar on a background thread to avoid blocking the UI
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *avatarUrl = [NSURL URLWithString:post.author.avatarUrl];
        NSData *imageData = [NSData dataWithContentsOfURL:avatarUrl];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.avatar.image = [UIImage imageWithData:imageData];
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

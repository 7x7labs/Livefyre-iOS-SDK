//
//  CommentList.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "CommentList.h"

#import "CommentView.h"

#define COMMENT_PADDING_HEIGHT 10

@interface CommentList ()
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) void (^nextPageCallback)();

@property (nonatomic, strong) UIButton *nextPage;
@end

@implementation CommentList
@synthesize comments = _comments;
@synthesize nextPageCallback = _nextPageCallback;
@synthesize nextPage = _nextPage;

- (void)addComment:(Post *)post {
    if (!self.comments)
        self.comments = [NSMutableArray array];

    NSUInteger idx = 0;
    for (CommentView *cv in self.comments) {
        if (cv.comment == post)
            return;

        if (cv.comment.createdAt < post.createdAt)
            break;
        ++idx;
    }

    CommentView *newPost = [CommentView viewForPost:post width:self.bounds.size.width];
    [self.comments insertObject:newPost atIndex:idx];
    [self addSubview:newPost];
}

- (void)layoutSubviews {
    CGFloat y = 0;
    for (CommentView *cv in self.comments) {
        cv.frame = CGRectMake(0, y, cv.frame.size.width, cv.frame.size.height);
        y += cv.frame.size.height + COMMENT_PADDING_HEIGHT;
    }

    if (self.nextPage) {
        self.nextPage.frame = CGRectMake(90, y, self.nextPage.frame.size.width, self.nextPage.frame.size.height);
        y += self.nextPage.frame.size.height + COMMENT_PADDING_HEIGHT;
    }

    self.contentSize = CGSizeMake(self.frame.size.width, y);
}

- (void)clear {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.comments = nil;
}

- (void)showNextPageButton:(void (^)())callback {
    self.nextPageCallback = callback;
    if (!callback) {
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
        [self addSubview:self.nextPage];
    }
    else {
        [self.nextPage setEnabled:YES];
        [self.nextPage setAlpha:1.0];
    }
}

- (void)nextPageTouched:(id)sender {
    void (^callback)() = self.nextPageCallback;
    self.nextPageCallback = nil;
    [self.nextPage setEnabled:NO];
    [self.nextPage setAlpha:0.5];

    if (callback)
        callback();
}

@end

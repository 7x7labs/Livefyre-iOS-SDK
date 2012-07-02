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
@end

@implementation CommentList
@synthesize comments = _comments;

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
    CGFloat y = COMMENT_PADDING_HEIGHT;
    for (CommentView *cv in self.comments) {
        cv.frame = CGRectMake(0, y, cv.frame.size.width, cv.frame.size.height);
        y += cv.frame.size.height + COMMENT_PADDING_HEIGHT;
    }

    CGRect frame = self.frame;
    frame.size.height = y;
    self.frame = frame;
}

- (void)clear {
    [self.subviews makeObjectsPerformSelector:@selector(destroy)];
    self.comments = nil;
}

@end

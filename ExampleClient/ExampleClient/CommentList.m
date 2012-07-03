//
//  CommentList.m
//  ExampleClient
//
//  Created by Thomas Goyne on 6/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "CommentList.h"

#import "CommentView.h"

static const int CommentPaddingHeight = 10;

@implementation CommentList
- (void)addComment:(Post *)post {
    if (post.deleted || post.parent)
        return;

    NSUInteger idx = 0;
    for (CommentView *cv in self.subviews) {
        // Don't need to do anything if it's a change to an existing comment as
        // the view handles that itself
        if (cv.comment == post)
            return;

        if (cv.comment.createdAt < post.createdAt)
            break;
        ++idx;
    }

    [self insertSubview:[CommentView viewForPost:post width:self.bounds.size.width]
                atIndex:idx];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    CGFloat y = CommentPaddingHeight;
    for (CommentView *cv in self.subviews) {
        cv.frame = CGRectMake(0, y, cv.frame.size.width, cv.frame.size.height);
        y += cv.frame.size.height + CommentPaddingHeight;
    }

    CGRect frame = self.frame;
    frame.size.height = y;
    self.frame = frame;
}

- (void)clear {
    [self.subviews makeObjectsPerformSelector:@selector(destroy)];
}

@end

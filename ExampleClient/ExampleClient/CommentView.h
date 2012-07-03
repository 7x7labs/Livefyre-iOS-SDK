//
//  CommentView.h
//  ExampleClient
//
//  Created by Thomas Goyne on 6/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentView : UIView
@property (weak, nonatomic, readonly) Post *comment;

+ (CommentView *)viewForPost:(Post *)post width:(CGFloat)width;
+ (void)addBordersAndShadow:(UIView *)view;

- (void)loadFromPost:(Post *)post;
- (void)destroy;
@end

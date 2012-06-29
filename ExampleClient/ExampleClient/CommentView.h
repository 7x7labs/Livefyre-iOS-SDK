//
//  CommentView.h
//  ExampleClient
//
//  Created by Thomas Goyne on 6/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentView : UIView
+ (CommentView *)viewForPost:(Post *)post width:(CGFloat)width;

@property (weak, nonatomic, readonly) Post *comment;

- (void)loadFromPost:(Post *)post;
@end

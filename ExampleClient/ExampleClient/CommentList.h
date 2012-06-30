//
//  CommentList.h
//  ExampleClient
//
//  Created by Thomas Goyne on 6/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentList : UIScrollView
- (void)addComment:(Post *)post;
- (void)clear;
- (void)showNextPageButton:(void (^)())callback;
@end

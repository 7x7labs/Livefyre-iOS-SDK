//
//  ReplyViewController.h
//  LivefyreClient
//
//  Created by Thomas Goyne on 9/14/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Collection;
@class LivefyreClient;
@class Post;
@class User;

@protocol LFReplyDelegate <NSObject>
- (void)postReply:(NSString *)body;
@end

@interface LFReplyViewController : UITableViewController
@property (nonatomic, strong) User *user;
@property (nonatomic, weak) id<LFReplyDelegate> delegate;
@end

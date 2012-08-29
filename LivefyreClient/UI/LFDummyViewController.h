//
//  LFDummyViewController.h
//  LivefyreClient
//
//  Created by Thomas Goyne on 9/20/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Collection;
@class LivefyreClient;

@interface LFDummyViewController : UIViewController
@property (nonatomic, strong) LivefyreClient *client;
@property (nonatomic, strong) Collection *collection;
@end

@interface LFNonAnimatedPush : UIStoryboardSegue
@end

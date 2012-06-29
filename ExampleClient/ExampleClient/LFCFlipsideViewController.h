//
//  LFCFlipsideViewController.h
//  ExampleClient
//
//  Created by Thomas Goyne on 6/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LFCFlipsideViewController;

@protocol LFCFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(LFCFlipsideViewController *)controller;
@end

@interface LFCFlipsideViewController : UIViewController
@property (weak, nonatomic) id <LFCFlipsideViewControllerDelegate> delegate;
@property (strong, nonatomic) LivefyreClient *client;
@property (strong, nonatomic) Collection *collection;
@end

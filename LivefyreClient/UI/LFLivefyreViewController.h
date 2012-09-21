//
//  LivefyreViewController.h
//  LivefyreClient
//
//  Created by Thomas Goyne on 8/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Collection;
@class LivefyreClient;

@interface LFLivefyreViewController : UIViewController
@property (nonatomic, strong) LivefyreClient *client;
@property (nonatomic, strong) Collection *collection;
@property (nonatomic, strong) NSDictionary *customizations;
@end

//
//  ClientBase.h
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <LivefyreClient/LivefyreClient.h>
#import <SenTestingKit/SenTestingKit.h>

@interface AsyncTestBase : SenTestCase
@property (strong, nonatomic) id client;

- (void)waitForTests;
- (void)completedTest;
@end

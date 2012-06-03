//
//  ClientBase.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "AsyncTestBase.h"

#import "Config.h"

@implementation AsyncTestBase
@synthesize client;

- (void)setUp {
    self.client = [LivefyreClient clientWithDomain:[Config objectForKey:@"domain"]
                                         domainKey:[Config objectForKey:@"domain key"]];
}

- (void)waitForTests {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:60];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while ([self.client pendingAsyncRequests]);
}

@end

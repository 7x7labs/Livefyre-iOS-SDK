//
//  ClientBase.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "AsyncTestBase.h"

#import "Config.h"

@interface ClientWrapper : NSObject {
    LivefyreClient *client;
    int pendingRequests;
}

- (id)init;
- (id)forwardingTargetForSelector:(SEL)aSelector;

- (BOOL)testsRunning;
- (void)testComplete;
@end

@implementation ClientWrapper
- (id)init {
    self = [super init];
    if (self) {
        client = [LivefyreClient clientWithDomain:[Config objectForKey:@"domain"]
                                        domainKey:[Config objectForKey:@"domain key"]];
        pendingRequests = 0;
    }
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    // this only works because LivefyreClient has no synchronous methods not
    // from NSObject
    if ([client respondsToSelector:aSelector]) {
        ++pendingRequests;
        return client;
    }
    return nil;
}

- (BOOL)testsRunning {
    return pendingRequests > 0;
}

- (void)testComplete {
    --pendingRequests;
}
@end


@implementation AsyncTestBase
@synthesize client;

- (void)setUp {
    self.client = [[ClientWrapper alloc] init];
}

- (void)completedTest {
    [self.client testComplete];
}

- (void)waitForTests {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:60];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while ([self.client testsRunning]);
}

@end

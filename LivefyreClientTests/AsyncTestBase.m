//
//  ClientBase.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "AsyncTestBase.h"

#import "Config.h"
#import "MEJWT.h"

@implementation AsyncTestBase
@synthesize client;

static NSString *authToken(NSString *userName, NSString *domain, NSString *key) {
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:domain, @"domain",
                          userName, @"user_id",
                          [NSNumber numberWithInt:(time(0) + 360000)], @"expires",
                          @"test", @"display_name",
                          nil];

    return [ECJWT encodePayload:data secret:key];
}

- (void)setUp {
    NSString *environment = [Config objectForKey:@"environment"];
    if ([environment length]) {
        self.client = [LivefyreClient clientWithDomain:[Config objectForKey:@"domain"]
                                           environment:environment
                                         bootstrapHost:[Config objectForKey:@"bootstrap host"]];
    }
    else {
        self.client = [LivefyreClient clientWithDomain:[Config objectForKey:@"domain"]
                                         bootstrapHost:[Config objectForKey:@"bootstrap host"]];
    }
}

- (void)waitForTests {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:60];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while ([self.client pendingAsyncRequests]);
}

- (NSString *)userToken:(NSString *)userName {
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:[Config objectForKey:@"domain"], @"domain",
                          userName, @"user_id",
                          [NSNumber numberWithInt:(time(0) + 360000)], @"expires",
                          @"test", @"display_name",
                          nil];

    return [ECJWT encodePayload:data secret:[Config objectForKey:@"domain key"]];
}

@end

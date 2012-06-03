//
//  AuthTest.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/28/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "AuthTest.h"

#import <LivefyreClient/LivefyreClient.h>

#import "Config.h"

@implementation AuthTest
- (void)testAuth
{
    [self.client authenticateUser:[Config objectForKey:@"moderator user"]
                          forSite:[Config objectForKey:@"site"]
                       forArticle:[Config objectForKey:@"existing article"]
                          gotUser:^(BOOL error, id result)
     {
         if (error) {
             STFail(result);
         }
         else {
             STAssertNotNil(result, @"User is nil");
             STAssertTrue([result isKindOfClass:[User class]], @"Did not get a User object");
             STAssertTrue([result isModerator], @"User should be a moderator");
             STAssertEqualObjects([result userId],
                                  ([NSString stringWithFormat:@"%@@%@",
                                    [Config objectForKey:@"moderator user"],
                                    [Config objectForKey:@"domain"]]),
                                  nil);
         }
     }];

    [self.client authenticateUser:[Config objectForKey:@"non-moderator user"]
                          forSite:[Config objectForKey:@"site"]
                       forArticle:[Config objectForKey:@"existing article"]
                          gotUser:^(BOOL error, id result)
     {
         if (error) {
             STFail(result);
         }
         else {
             STAssertNotNil(result, @"User is nil");
             STAssertTrue([result isKindOfClass:[User class]], @"Did not get a User object");
             STAssertFalse([result isModerator], @"User should not be a moderator");
             STAssertEqualObjects([result userId],
                                  ([NSString stringWithFormat:@"%@@%@",
                                    [Config objectForKey:@"non-moderator user"],
                                    [Config objectForKey:@"domain"]]),
                                  nil);
         }
     }];

    [self waitForTests];
}
@end

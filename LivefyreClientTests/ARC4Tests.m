//
//  ARC4Tests.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "ARC4Tests.h"

#import "ARC4.h"

@implementation ARC4Tests
- (void)testDecrypt {
    const char rawKey[] = "secret key"; // 736563726574206B6579
    NSString *cipherText = @"0DC9D79D144D7B0C491F2ACF8F8B9B";
    NSString *plainText = @"a sample string";

    NSMutableString *key = [NSMutableString stringWithCapacity:(sizeof(rawKey) * 2)];
    for (size_t i = 0; i < sizeof(rawKey) - 1; ++i) {
        [key appendFormat:@"%02X", (unsigned char)rawKey[i]];
    }

    NSString *decrypted = [ARC4 decrypt:cipherText withKey:key];
    STAssertEqualObjects(decrypted, plainText, nil);
}
@end

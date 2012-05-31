//
//  ARC4.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ARC4.h"

#import <CommonCrypto/CommonCryptor.h>

@implementation ARC4

+ (NSString *)decrypt:(NSString *)string withKey:(NSString *)key {
    const char *inString = [string UTF8String];
    size_t inLength = strlen(inString);
    char *outString = malloc(inLength);
    const char *keyString = [key UTF8String];
    size_t keyLength = strlen(keyString);
    size_t dataOutMoved = 0;

    CCCryptorStatus ccStatus = CCCrypt(kCCDecrypt,
                                       kCCAlgorithmRC4,
                                       0,
                                       keyString,
                                       keyLength,
                                       NULL, // iv
                                       inString,
                                       inLength,
                                       outString,
                                       inLength,
                                       &dataOutMoved);

    NSString *decrypted = [NSString stringWithUTF8String:outString];
    free(outString);

    if (ccStatus == kCCSuccess) {
        return decrypted;
    }

    return string;
}
@end

//
//  ARC4.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 5/17/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "ARC4.h"

#import <CommonCrypto/CommonCryptor.h>

static NSData *hexStringToBytes(NSString *string) {
    NSMutableData *data = [NSMutableData data];
    for (NSUInteger i = 0; i + 2 <= string.length; i += 2) {
        uint8_t value = (uint8_t)strtol([[string substringWithRange:NSMakeRange(i, 2)] UTF8String], 0, 16);
        [data appendBytes:&value length:1];
    }
    return data;
}

@implementation ARC4

+ (NSString *)decrypt:(NSString *)string withKey:(NSString *)key {
    NSData *inBytes = hexStringToBytes(string);
    NSData *keyBytes = hexStringToBytes(key);

    NSMutableData *outBytes = [NSMutableData dataWithLength:[inBytes length]];
    size_t dataOutMoved = 0;

    CCCryptorStatus ccStatus = CCCrypt(kCCDecrypt,
                                       kCCAlgorithmRC4,
                                       0,
                                       [keyBytes bytes],
                                       [keyBytes length],
                                       NULL, // iv
                                       [inBytes bytes],
                                       [inBytes length],
                                       [outBytes mutableBytes],
                                       [outBytes length],
                                       &dataOutMoved);

    NSString *decrypted = [[NSString alloc] initWithData:outBytes encoding:NSUTF8StringEncoding];

    if (ccStatus == kCCSuccess) {
        return decrypted;
    }

    return string;
}
@end

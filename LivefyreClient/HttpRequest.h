//
//  HttpRequest.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/16/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ResponseBlock)(NSString *message, int statusCode);

@interface HttpRequest : NSObject
+ (void)getRequest:(NSString *)url
           onError:(ResponseBlock)onError
         onSuccess:(ResponseBlock)onSuccess;

+ (void)getRequest:(NSString *)url
         withQuery:(NSDictionary *)queryParameters
           onError:(ResponseBlock)onError
         onSuccess:(ResponseBlock)onSuccess;

+ (void)getRequest:(NSString *)url
         withQuery:(NSDictionary *)queryParameters
           timeout:(NSTimeInterval)timeout
           onError:(ResponseBlock)onError
         onSuccess:(ResponseBlock)onSuccess;

+ (void)postRequest:(NSString *)url
            onError:(ResponseBlock)onError
          onSuccess:(ResponseBlock)onSuccess;

+ (void)postRequest:(NSString *)url
           withBody:(NSData *)body
            onError:(ResponseBlock)onError
          onSuccess:(ResponseBlock)onSuccess;

+ (void)postRequest:(NSString *)url
       withFormData:(NSDictionary *)data
            onError:(ResponseBlock)onError
          onSuccess:(ResponseBlock)onSuccess;

+ (NSString *)urlEscape:(NSString *)string;

+ (BOOL)hasPendingRequests;
@end

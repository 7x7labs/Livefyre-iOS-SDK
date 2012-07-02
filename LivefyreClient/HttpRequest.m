//
//  HttpRequest.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/16/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "HttpRequest.h"

#import "ASIFormDataRequest.h"

static int pendingRequests = 0;

@implementation HttpRequest
+ (NSString*)urlEscape:(NSString *)string {
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (__bridge CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 kCFStringEncodingUTF8);
}

+ (BOOL)hasPendingRequests {
    return pendingRequests > 0;
}

+ (NSString *)buildQueryString:(NSString *)url withParamters:(NSDictionary *)parameters {
    BOOL first = YES;
    for (NSString *key in parameters) {
        url = [url stringByAppendingFormat:@"%@%@=%@",
               first ? @"?" : @"&",
               key,
               [self urlEscape:[parameters objectForKey:key]]];
        first = NO;
    }
    return url;
}

+ (void)getRequest:(NSString *)url
           timeout:(NSTimeInterval)timeout
           onError:(ResponseBlock)onError
         onSuccess:(ResponseBlock)onSuccess
{
    ++pendingRequests;
    NSLog(@"GET %@", url);
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    __weak ASIHTTPRequest *weakReq = request;
    [request setRequestMethod:@"GET"];
    [request setCompletionBlock:^{
        --pendingRequests;
        onSuccess(weakReq.responseString, weakReq.responseStatusCode);
    }];
    [request setFailedBlock:^{
        --pendingRequests;
        NSLog(@"ERROR %d %@", weakReq.responseStatusCode, weakReq.error.description);
        onError(weakReq.error.description, weakReq.responseStatusCode);
    }];
    [request setNumberOfTimesToRetryOnTimeout:2];
    [request setTimeOutSeconds:timeout];
    [request startAsynchronous];
}

+ (void)getRequest:(NSString *)url
           onError:(ResponseBlock)onError
         onSuccess:(ResponseBlock)onSuccess
{
    [self getRequest:url timeout:10 onError:onError onSuccess:onSuccess];
}

+ (void)getRequest:(NSString *)url
         withQuery:(NSDictionary *)queryParameters
           onError:(ResponseBlock)onError
         onSuccess:(ResponseBlock)onSuccess
{
    [self getRequest:[self buildQueryString:url withParamters:queryParameters]
             onError:onError
           onSuccess:onSuccess];
}

+ (void)getRequest:(NSString *)url
         withQuery:(NSDictionary *)queryParameters
           timeout:(NSTimeInterval)timeout
           onError:(ResponseBlock)onError
         onSuccess:(ResponseBlock)onSuccess
{
    [self getRequest:[self buildQueryString:url withParamters:queryParameters]
             timeout:timeout
             onError:onError
           onSuccess:onSuccess];
}

+ (ASIFormDataRequest *)createPostRequest:(NSString *)url
                                  onError:(ResponseBlock)onError
                                onSuccess:(ResponseBlock)onSuccess
{
    ++pendingRequests;
    NSLog(@"POST %@", url);
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
    __weak ASIHTTPRequest *weakReq = request;
    [request setCompletionBlock:^{
        --pendingRequests;
        onSuccess(weakReq.responseString, weakReq.responseStatusCode);
    }];
    [request setFailedBlock:^{
        --pendingRequests;
        NSLog(@"ERROR %d %@", weakReq.responseStatusCode, weakReq.error.description);
        onError(weakReq.error.description, weakReq.responseStatusCode);
    }];
    [request setRequestMethod:@"POST"];
    return request;
}

+ (void)postRequest:(NSString *)url
            onError:(ResponseBlock)onError
          onSuccess:(ResponseBlock)onSuccess
{
    [[self createPostRequest:url onError:onError onSuccess:onSuccess] startAsynchronous];
}

+ (void)postRequest:(NSString *)url
           withBody:(NSData *)body
            onError:(ResponseBlock)onError
          onSuccess:(ResponseBlock)onSuccess
{
    ASIFormDataRequest *request = [self createPostRequest:url onError:onError onSuccess:onSuccess];
    [request appendPostData:body];
    [request startAsynchronous];
}

+ (void)postRequest:(NSString *)url
       withFormData:(NSDictionary *)data
            onError:(ResponseBlock)onError
          onSuccess:(ResponseBlock)onSuccess
{
    ASIFormDataRequest *request = [self createPostRequest:url onError:onError onSuccess:onSuccess];
    for (NSString *key in data) {
        [request addPostValue:[data objectForKey:key] forKey:key];
    }
    [request startAsynchronous];
}
@end

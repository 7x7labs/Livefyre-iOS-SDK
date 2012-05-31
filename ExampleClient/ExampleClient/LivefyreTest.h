//
//  LivefyreTest.h
//  jwt-test
//
//  Created by Thomas Goyne on 5/14/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LogSink
- (void)clear;
- (void)log:(NSString *)message;
- (void)logWithFormat:(NSString *)format, ...;
@end

@interface LivefyreTest : NSObject
- (id)initWithLogger:(id <LogSink>)logger;

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *articleId;

- (void)createCollection;
- (void)createPost;
- (void)authenticate;
- (void)getCollectionData;
- (void)startPolling;
- (void)stopPolling;
@end

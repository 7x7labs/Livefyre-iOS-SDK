//
//  LivefyreClient.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/18/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LivefyreClient.h"

#import "HttpRequest.h"
#import "JSONKit.h"
#import "MEJWT.h"
#import "NSString+Base64StringFromData.h"

static NSString *authToken(NSString *userName, NSString *domain, NSString *key) {
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:domain, @"domain",
                          userName, @"user_id",
                          [NSNumber numberWithInt:(time(0) + 360000)], @"expires",
                          @"test", @"display_name",
                          nil];

    return [ECJWT encodePayload:data secret:key];
}

static NSDictionary *tryToParseJSON(NSString *jsonString, RequestComplete callback) {
    id parsedObject = [jsonString objectFromJSONString];
    if (!parsedObject) {
        callback(YES, [@"Could not parse JSON: " stringByAppendingString:jsonString]);
        return nil;
    }

    if (![parsedObject isKindOfClass:[NSDictionary class]]) {
        callback(YES, [@"Got unexpected response: " stringByAppendingString:jsonString]);
        return nil;
    }

    if ([[parsedObject objectForKey:@"status"] isEqualToString:@"error"]) {
        callback(YES, [NSString stringWithFormat:@"%@ %@: %@",
                       [parsedObject objectForKey:@"code"],
                       [parsedObject objectForKey:@"error_type"],
                       [parsedObject objectForKey:@"msg"]]);
        return nil;
    }

    // Not an error, but maybe it should be reported somehow?
    if ([parsedObject objectForKey:@"timeout"])
        return nil;

    NSDictionary *data = [parsedObject objectForKey:@"data"];
    if (!data) {
        callback(YES, [NSString stringWithFormat:@"Data not found in response: %@", jsonString]);
        return nil;
    }

    return data;
}

static void(^errorHandler(RequestComplete callback))(NSString *, int) {
    return ^(NSString *responseString, int statusCode) {
        callback(YES, [NSString stringWithFormat:@"HTTP error %d: %@", statusCode, responseString]);
    };
}

static NSString *bootstrapRoot = @"https://bootstrap-v2-json.s3.amazonaws.com";

@implementation LivefyreClient {
    NSString *domain;
    NSString *key;
    NSMutableDictionary *pollingCollections;
    NSString *uuid;
}

+ (LivefyreClient *)clientWithDomain:(NSString *)domain domainKey:(NSString *)key {
    LivefyreClient *client = [[LivefyreClient alloc] init];
    client->domain = domain;
    client->key = key;
    client->pollingCollections = [[NSMutableDictionary alloc] init];

    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    if (uuid) {
        client->uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
        CFRelease(uuid);
    }

    return client;
}

- (BOOL)pendingAsyncRequests {
    return [HttpRequest hasPendingRequests];
}

- (void)authenticateUser:(NSDictionary *)parameters gotUser:(RequestComplete)callback {
    [HttpRequest getRequest:[NSString stringWithFormat:@"http://admin.%@/api/v3.0/auth/", domain]
                  withQuery:parameters
                    onError:errorHandler(callback)
                  onSuccess:^(NSString *responseString, int statusCode) {
                      NSDictionary *data = tryToParseJSON(responseString, callback);
                      if (!data) return;
                      User *user = [User userWithDictionary:data];
                      if (!user)
                          callback(YES, @"Did not get any user data");
                      else
                          callback(NO, user);
                  }];
}

- (void)authenticateUser:(NSString *)userName
           forCollection:(NSString *)collectionId
                 gotUser:(RequestComplete)callback
{
    [self authenticateUser:[NSDictionary dictionaryWithObjectsAndKeys:authToken(userName, domain, key), @"lftoken",
                            collectionId, @"collectionId",
                            nil]
                   gotUser:callback];
}

- (void)authenticateUser:(NSString *)userName
                 forSite:(NSString *)siteId
              forArticle:(NSString *)articleId
                 gotUser:(RequestComplete)callback
{
    [self authenticateUser:[NSDictionary dictionaryWithObjectsAndKeys:authToken(userName, domain, key), @"lftoken",
                            siteId, @"siteId",
                            [NSString base64StringFromData:[articleId dataUsingEncoding:NSUTF8StringEncoding]], @"articleId",
                            nil]
                   gotUser:callback];
}

- (void)modifyCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionCreated:(RequestComplete)callback
                endpoint:(NSString *)endpoint
{
    NSDictionary *requestData =
    [NSDictionary dictionaryWithObjectsAndKeys:articleId, @"articleId",
     title, @"title",
     url, @"url",
     tags, @"tags",
     nil];

    NSString *encoded = [ECJWT encodePayload:requestData secret:siteKey];
    NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:encoded, @"collectionMeta", nil];

    NSString *postUrl = [NSString stringWithFormat:@"http://quill.%@/api/v3.0/site/%@/collection/%@",
                         domain, siteId, endpoint];

    [HttpRequest postRequest:postUrl
                    withBody:[wrapper JSONData]
                     onError:errorHandler(callback)
                   onSuccess:^(NSString *responseString, int statusCode) {
                       NSDictionary *data = tryToParseJSON(responseString, callback);
                       if (data)
                           callback(NO, [data objectForKey:@"collectionId"]);
                   }];
}

- (void)createCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionCreated:(RequestComplete)callback
{
    [self modifyCollection:title
                forArticle:articleId
                     atUrl:url
                   forSite:siteId
                   withKey:siteKey
                  withTags:tags
         collectionCreated:callback
                  endpoint:@"create"];
}

- (void)updateCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionUpdated:(RequestComplete)callback
{
    [self modifyCollection:title
                forArticle:articleId
                     atUrl:url
                   forSite:siteId
                   withKey:siteKey
                  withTags:tags
         collectionCreated:callback
                  endpoint:@"update"];
}

- (void)getCollectionForArticle:(NSString *)articleId
                         inSite:(NSString *)siteId
                        forUser:(User *)user
                  gotCollection:(RequestComplete)callback
{
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@/%@/init.json",
                     bootstrapRoot,
                     domain,
                     siteId,
                     [NSString base64StringFromData:[articleId dataUsingEncoding:NSUTF8StringEncoding]]];

    [HttpRequest getRequest:url
                    onError:errorHandler(callback)
                  onSuccess:^(NSString *responseString, int statusCode)
     {
         NSDictionary *responseData = [responseString objectFromJSONString];
         if (!responseData) {
             callback(YES,
                      [NSString stringWithFormat:@"Error %d fetching collection data: %@",
                       statusCode,
                       responseString]);
             return;
         }

         NSMutableArray *additionalPages = [self dataRanges:[responseData objectForKey:@"data"]
                                                       user:user];
         callback(NO,
                  [Collection collectionWithId:[responseData objectForKey:@"collectionId"]
                                          user:user
                                     nestLevel:[[responseData objectForKey:@"nestLevel"] intValue]
                                 numberVisible:[[responseData objectForKey:@"numVisible"] intValue]
                             numberOfFollowers:[[responseData objectForKey:@"followers"] intValue]
                                     lastEvent:[[responseData objectForKey:@"event"] longLongValue]
                                     bootstrap:[self pageRequest:[responseData objectForKey:@"bootstrapUrl"]]
                               additionalPages:additionalPages]);
     }];
}

- (void (^)(Collection *collection, RequestComplete callback))pageRequest:(NSString *)url {
    url = [NSString stringWithFormat:@"%@%@", bootstrapRoot, url];
    __weak LivefyreClient *weakSelf = self;
    return ^(Collection *collection, RequestComplete callback) {
        [HttpRequest getRequest:url
                        onError:errorHandler(callback)
                      onSuccess:^(NSString *responseString, int statusCode) {
                          [weakSelf gotCollectionData:responseString
                                        forCollection:collection
                                             callback:callback];
                      }];
    };
}

- (NSMutableArray *)dataRanges:(NSArray *)data
                          user:(User *)user
{
    NSMutableArray *pages = [NSMutableArray arrayWithCapacity:[data count]];

    for (NSDictionary *dataChunk in data) {
        DateRange *range = [DateRange dateRangeWithStart:[[dataChunk objectForKey:@"first"] intValue]
                                                     end:[[dataChunk objectForKey:@"last"] intValue]];

        [pages addObject:[NSDictionary dictionaryWithObjectsAndKeys:range, @"range",
                          [self pageRequest:[dataChunk objectForKey:@"url"]], @"callback",
                          nil]];
    }

    return pages;
}

- (void)gotCollectionData:(NSString *)responseString
            forCollection:(Collection *)collection
                 callback:(RequestComplete)callback
{
    responseString = [self fixAstralPlane:responseString];
    NSDictionary *response = [responseString objectFromJSONString];

    __weak Collection *weakCollection = collection;
    __weak LivefyreClient *weakSelf = self;
    void (^erefFetcher)(NSString *) = ^(NSString *eref) {
        [weakSelf tryToGetErefContent:eref forCollection:weakCollection callback:callback];
    };

    callback(NO, [collection addCollectionContent:response
                                      erefFetcher:erefFetcher]);
}

- (void)tryToGetErefContent:(NSString *)eref
              forCollection:(Collection *)collection
                   callback:(RequestComplete)callback
{
    NSString *decryptedPath = [collection.user tryToDecodeEref:eref];
    if (!decryptedPath) return;

    __weak LivefyreClient *weakSelf = self;
    [HttpRequest getRequest:[NSString stringWithFormat:@"http://bootstrap.%@/api/v3.0/content/eref/", domain]
                  withQuery:[NSDictionary dictionaryWithObject:decryptedPath forKey:@"ref"]
                    onError:errorHandler(callback)
                  onSuccess:^(NSString *responseString, int statusCode) {
                      [weakSelf gotCollectionData:responseString
                                    forCollection:collection
                                         callback:callback];
                  }];
}

- (NSString *)fixAstralPlane:(NSString *)string {
    NSError *error;
    NSRegularExpression *findAstralPlane = [NSRegularExpression regularExpressionWithPattern:@"\\\\U([0-9a-f]{8})" options:0 error:&error];

    NSMutableString *ret = [NSMutableString stringWithCapacity:[string length]];
    __block NSUInteger pos = 0;

    // JSONKit doesn't support the non-standard \Uxxxxxxxx syntax, so convert
    // them to UTF-16 surrogate pairs
    [findAstralPlane enumerateMatchesInString:string
                                      options:0
                                        range:NSMakeRange(0, [string length])
                                   usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
     {
         if (match.range.location > pos)
             [ret appendString:[string substringWithRange:NSMakeRange(pos, match.range.location - pos)]];
         pos = match.range.location + match.range.length;

         unsigned value = (unsigned)strtol([[string substringWithRange:[match rangeAtIndex:1]] UTF8String], 0, 16);
         if (value <= 0xFFFF)
             [ret appendFormat:@"\\u%04x", value];
         else {
             value -= 0x10000;
             [ret appendFormat:@"\\u%04x\\u%04x", 0xD800 + (value >> 10), 0xDC00 + (value & 0x3FF)];
         }
     }];

    if (string.length > pos)
        [ret appendString:[string substringFromIndex:pos]];
    return [NSString stringWithString:ret];
}

- (void)startPollingForUpdates:(Collection *)collection
                 pollFrequency:(NSTimeInterval)frequency
                requestTimeout:(NSTimeInterval)timeout
                   gotNewPosts:(RequestComplete)callback
{
    __weak LivefyreClient *weakSelf = self;
    void (^poll)() = ^{
        NSString *url = [NSString stringWithFormat:@"http://stream.%@/api/v3.0/collection/%@/%lld/",
                         domain, collection.collectionId, collection.lastEvent];

        NSDictionary *query = nil;
        if (uuid)
            query = [NSDictionary dictionaryWithObject:uuid forKey:@"_bi"];

        [HttpRequest getRequest:url
                      withQuery:query
                        onError:errorHandler(callback)
                      onSuccess:^(NSString *responseString, int statusCode)
         {
             NSDictionary *data = tryToParseJSON(responseString, callback);
             if (!data) return;

             __weak Collection *weakCollection = collection;
             void (^erefFetcher)(NSString *) = ^(NSString *eref) {
                 [weakSelf tryToGetErefContent:eref forCollection:weakCollection callback:callback];
             };

             callback(NO, [collection addCollectionContent:data
                                               erefFetcher:erefFetcher]);
         }];
    };

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:frequency
                                                      target:self
                                                    selector:@selector(pollCollection:)
                                                    userInfo:poll
                                                     repeats:YES];

    [[pollingCollections objectForKey:collection.collectionId] invalidate];
    [pollingCollections setObject:timer forKey:collection.collectionId];
    poll();
}

- (void)stopPollingForUpdates:(Collection *)collection {
    [[pollingCollections objectForKey:collection.collectionId] invalidate];
    [pollingCollections removeObjectForKey:collection.collectionId];
}

- (void)pollCollection:(NSTimer *)timer {
    ((void (^)())[timer userInfo])();
}

- (void)likeOrUnlikeContent:(Entry *)entry
                 onComplete:(RequestComplete)callback
                   endpoint:(NSString *)endpoint
{
    Collection *collection = entry.collection;

    if (!collection.user) {
        callback(YES, [NSString stringWithFormat:@"Must be logged in to %@ postsß", endpoint, nil]);
        return;
    }

    NSString *url = [NSString stringWithFormat:@"http://quill.%@/api/v3.0/message/%@/%@/",
                     domain,
                     [HttpRequest urlEscape:entry.entryId],
                     endpoint];

    NSDictionary *formParameters = [NSDictionary dictionaryWithObjectsAndKeys:collection.collectionId, @"collection_id",
                                    collection.user.token, @"lftoken",
                                    nil];

    [HttpRequest postRequest:url
                withFormData:formParameters
                     onError:errorHandler(callback)
                   onSuccess:^(NSString *responseString, int statusCode) {
                       NSLog(@"%d\n%@\n", statusCode, responseString);

                       NSDictionary *data = tryToParseJSON(responseString, callback);
                       if (data)
                           callback(NO, [data objectForKey:@"messageId"]);
                   }];
}

- (void)likeContent:(Entry *)entry
         onComplete:(RequestComplete)callback
{
    [self likeOrUnlikeContent:entry
                   onComplete:callback
                     endpoint:@"like"];
}

- (void)unlikeContent:(Entry *)entry
           onComplete:(RequestComplete)callback
{
    [self likeOrUnlikeContent:entry
                   onComplete:callback
                     endpoint:@"unlike"];
}

- (void)createPost:(NSString *)body
      inCollection:(Collection *)collection
        onComplete:(RequestComplete)callback
{
    [self createPost:body inReplyTo:nil inCollection:collection onComplete:callback];
}

- (void)createPost:(NSString *)body
      inReplyTo:(Post *)parent
        onComplete:(RequestComplete)callback
{
    [self createPost:body inReplyTo:parent inCollection:parent.collection onComplete:callback];
}

- (void)createPost:(NSString *)body
         inReplyTo:(Post *)parent
      inCollection:(Collection *)collection
        onComplete:(RequestComplete)callback
{
    if (!collection.user) {
        callback(YES, @"Must be logged in to create a new post");
        return;
    }

    NSString *url = [NSString stringWithFormat:@"http://quill.%@/api/v3.0/collection/%@/post/",
                     domain, collection.collectionId];

    NSDictionary *postBody;
    if (parent) {
        postBody = [NSDictionary dictionaryWithObjectsAndKeys:body, @"body",
                    collection.user.token, @"lftoken",
                    parent.entryId, @"parent_id",
                    uuid, @"_bi",
                    nil];
    }
    else {
        postBody = [NSDictionary dictionaryWithObjectsAndKeys:body, @"body",
                    collection.user.token, @"lftoken",
                    uuid, @"_bi",
                    nil];
    }

    [HttpRequest postRequest:url
                withFormData:postBody
                     onError:errorHandler(callback)
                   onSuccess:^(NSString *message, int statusCode)
     {
         NSDictionary *data = tryToParseJSON(message, callback);
         if (!data)
             return;

         NSArray *newPosts = [collection addCollectionContent:data erefFetcher:nil];

         for (Post *entry in newPosts) {
             callback(NO, (Post *)entry);
         }
     }];
}

@end

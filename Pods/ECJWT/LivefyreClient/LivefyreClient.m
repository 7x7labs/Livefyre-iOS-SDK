//
//  LivefyreClient.m
//  jwt-test
//
//  Created by Thomas Goyne on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LivefyreClient.h"

#import "CollectionData.h"
#import "Entry.h"
#import "HttpRequest.h"
#import "JSONKit.h"
#import "MEJWT.h"
#import "NSString+Base64StringFromData.h"
#import "User.h"

NSString *authToken(NSString *userName, NSString *domain, NSString *key) {
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:domain, @"domain",
                          userName, @"user_id",
                          [NSNumber numberWithInt:(time(0) + 360000)], @"expires",
                          @"test", @"display_name",
                          nil];

    return [ECJWT encodePayload:data secret:key];
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

- (void)authenticateUser:(NSDictionary *)parameters gotUser:(UserCallback)callback {
    [HttpRequest getRequest:[NSString stringWithFormat:@"http://admin.%@/api/v3.0/auth/", domain]
                  withQuery:parameters
                    onError:^(NSString *responseString, int statusCode) {
                        callback(nil);
                    }
                  onSuccess:^(NSString *responseString, int statusCode) {
                      callback([User userWithDictionary:[[responseString objectFromJSONString] objectForKey:@"data"]]);
                  }];
}

- (void)authenticateUser:(NSString *)userName
           forCollection:(NSString *)collectionId
                 gotUser:(UserCallback)callback
{
    [self authenticateUser:[NSDictionary dictionaryWithObjectsAndKeys:authToken(userName, domain, key), @"lftoken",
                            collectionId, @"collectionId",
                            nil]
                   gotUser:callback];
}

- (void)authenticateUser:(NSString *)userName
                 forSite:(NSString *)siteId
              forArticle:(NSString *)articleId
                 gotUser:(UserCallback)callback
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
       collectionCreated:(CreateCollectionCallback)callback
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

    NSString *postUrl = [NSString stringWithFormat:@"http://quill.%@/api/v3.0/site/%@/collection/%@", domain, siteId, endpoint];

    [HttpRequest postRequest:postUrl
                    withBody:[wrapper JSONData]
                     onError:^(NSString *responseString, int statusCode) {
                         callback(responseString, nil);
                     }
                   onSuccess:^(NSString *responseString, int statusCode) {
                       NSDictionary *responseObject = [responseString objectFromJSONString];
                       NSDictionary *data = [responseObject objectForKey:@"data"];
                       if (data)
                           callback([data objectForKey:@"collectionId"], [data objectForKey:@"checksum"]);
                       else
                           callback([responseObject objectForKey:@"msg"], nil);
                   }];
}

- (void)createCollection:(NSString *)title
              forArticle:(NSString *)articleId
                   atUrl:(NSString *)url
                 forSite:(NSString *)siteId
                 withKey:(NSString *)siteKey
                withTags:(NSString *)tags
       collectionCreated:(CreateCollectionCallback)callback
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
       collectionUpdated:(CreateCollectionCallback)callback
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

- (CollectionData *)getCollectionForArticle:(NSString *)articleId
                                     inSite:(NSString *)siteId
                                    forUser:(User *)user
{
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@/%@/init.json", bootstrapRoot, domain, siteId, [NSString base64StringFromData:[articleId dataUsingEncoding:NSUTF8StringEncoding]]];

    CollectionData *collection = [[CollectionData alloc] init];

    [HttpRequest getRequest:url
                    onError:^(NSString *responseString, int statusCode) { }
                  onSuccess:^(NSString *responseString, int statusCode) {
                      [self gotInit:responseString forCollection:collection forUser:user];
                  }];

    return collection;
}

- (void (^)(CollectionData *collection))pageRequest:(NSString *)url {
    url = [NSString stringWithFormat:@"%@%@", bootstrapRoot, url];
    return ^(CollectionData *collection) {
        [HttpRequest getRequest:url
                        onError:^(NSString *responseString, int statusCode) { }
                      onSuccess:^(NSString *responseString, int statusCode) {
                          [self gotCollectionData:responseString forCollection:collection];
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

- (void)gotInit:(NSString *)response
  forCollection:(CollectionData *)collection
        forUser:(User *)user
{
    NSDictionary *responseData = [response objectFromJSONString];
    if (!responseData)
        return;

    NSMutableArray *additionalPages = [self dataRanges:[responseData objectForKey:@"data"]
                                                  user:user];

    [collection setCollectionId:[responseData objectForKey:@"collectionId"]
                           user:user
                      nestLevel:[[responseData objectForKey:@"nestLevel"] intValue]
                  numberVisible:[[responseData objectForKey:@"numVisible"] intValue]
              numberOfFollowers:[[responseData objectForKey:@"followers"] intValue]
                      lastEvent:[[responseData objectForKey:@"event"] longLongValue]
                additionalPages:additionalPages];

    [self pageRequest:[responseData objectForKey:@"bootstrapUrl"]](collection);
}

- (void)gotCollectionData:(NSString *)responseString
            forCollection:(CollectionData *)collection
{
    responseString = [self fixAstralPlane:responseString];

    NSDictionary *response = [responseString objectFromJSONString];
    NSDictionary *authors = [response objectForKey:@"authors"];
    NSDictionary *contents = [response objectForKey:@"content"];
    NSArray *followers = [response objectForKey:@"followers"];

    NSArray *posts = [[NSArray alloc] init];

    for (NSDictionary *event in contents) {
        NSArray *erefs = [event objectForKey:@"erefs"];
        if (erefs) {
            for (NSString *eref in erefs) {
                [self tryToGetErefContent:eref forCollection:collection];
            }
        }
        else {
            posts = [posts arrayByAddingObject:event];
        }
    }

    [collection addAuthors:authors andPosts:posts andFollowers:followers];
}

- (void)tryToGetErefContent:(NSString *)eref
              forCollection:(CollectionData *)collection
{
    NSString *decryptedPath = [collection.user tryToDecodeEref:eref];
    if (decryptedPath) {
        [HttpRequest getRequest:[NSString stringWithFormat:@"http://bootstrap.%@/api/v3.0/content/eref/", domain]
                      withQuery:[NSDictionary dictionaryWithObject:decryptedPath forKey:@"ref"]
                        onError:^(NSString *responseString, int statusCode) { }
                      onSuccess:^(NSString *responseString, int statusCode) {
                          [self gotCollectionData:responseString
                                    forCollection:collection];
                      }];
    }
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

- (void)startPollingForUpdates:(CollectionData *)collection
                 pollFrequency:(NSTimeInterval)frequency
                requestTimeout:(NSTimeInterval)timeout
{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:frequency
                                                      target:self
                                                    selector:@selector(pollCollection:)
                                                    userInfo:collection
                                                     repeats:YES];

    [[pollingCollections objectForKey:collection.collectionId] invalidate];
    [pollingCollections setObject:timer forKey:collection.collectionId];
}

- (void)stopPollingForUpdates:(CollectionData *)collection {
    [[pollingCollections objectForKey:collection.collectionId] invalidate];
    [pollingCollections removeObjectForKey:collection.collectionId];
}

- (void)pollCollection:(NSTimer *)timer {
    CollectionData *collection = [timer userInfo];

    NSString *url = [NSString stringWithFormat:@"http://stream.%@/api/v3.0/collection/%@/%lld/",
                     domain, collection.collectionId, collection.lastEvent];

    NSDictionary *query = nil;
    if (uuid)
        query = [NSDictionary dictionaryWithObject:query forKey:@"_bi"];

    [HttpRequest getRequest:url
                  withQuery:query
                     onError:^(NSString *responseString, int statusCode) {
                         NSLog(@"%d\n%@\n", statusCode, responseString);
                     }
                   onSuccess:^(NSString *responseString, int statusCode) {
                       NSLog(@"%d\n%@\n", statusCode, responseString);
                       [self gotStreamData:responseString collection:collection];
                   }];
}

- (void)gotStreamData:(NSString *)responseString collection:(CollectionData *)collection {
    responseString = [self fixAstralPlane:responseString];

    NSDictionary *responseObject = [responseString objectFromJSONString];
    if (![[responseObject objectForKey:@"status"] isEqualToString:@"ok"]) {
        NSLog(@"Stream response error: %@\n", [responseObject objectForKey:@"msg"]);
        return;
    }

    NSDictionary *response = [responseString objectFromJSONString];
    NSDictionary *authors = [response objectForKey:@"authors"];
    NSDictionary *contents = [response objectForKey:@"states"];

    NSArray *posts = [[NSArray alloc] init];

    for (NSDictionary *event in [contents allValues]) {
        NSArray *erefs = [event objectForKey:@"erefs"];
        if (erefs) {
            for (NSString *eref in erefs) {
                [self tryToGetErefContent:eref forCollection:collection];
            }
        }
        else {
            posts = [posts arrayByAddingObject:event];
        }
    }


    [collection addAuthors:authors
                  andPosts:posts
                 lastEvent:[[response objectForKey:@"maxEventId"] longLongValue]];
}

- (void)likeOrUnlikeContent:(Entry *)entry
               inCollection:(CollectionData *)collection
                 onComplete:(LikeCallback)callback
                   endpoint:(NSString *)endpoint
{
    NSString *url = [NSString stringWithFormat:@"http://quill.%@/v3.0/message/%@/%@/",
                     domain,
                     [HttpRequest urlEscape:entry.entryId],
                     endpoint];

    NSDictionary *formParameters = [NSDictionary dictionaryWithObjectsAndKeys:collection.collectionId, @"collection_id",
                                    collection.user.token, @"lftoken",
                                    nil];

    [HttpRequest postRequest:url
                withFormData:formParameters
                     onError:^(NSString *responseString, int statusCode) {
                         NSLog(@"%d\n%@\n", statusCode, responseString);
                         callback(responseString);
                     }
                   onSuccess:^(NSString *responseString, int statusCode) {
                       NSLog(@"%d\n%@\n", statusCode, responseString);

                       NSDictionary *data = [responseString objectFromJSONString];
                       if (!data) {
                           callback(responseString);
                           return;
                       }

                       if ([[data objectForKey:@"status"] isEqualToString:@"ok"])
                           callback([[data objectForKey:@"data"] objectForKey:@"messageId"]);
                       else
                           callback([data objectForKey:@"msg"]);
                   }];
}

- (void)likeContent:(Entry *)entry
       inCollection:(CollectionData *)collection
         onComplete:(LikeCallback)callback
{
    [self likeOrUnlikeContent:entry inCollection:collection onComplete:callback endpoint:@"like"];
}

- (void)unlikeContent:(Entry *)entry
         inCollection:(CollectionData *)collection
           onComplete:(LikeCallback)callback
{
    [self likeOrUnlikeContent:entry inCollection:collection onComplete:callback endpoint:@"unlike"];
}

@end

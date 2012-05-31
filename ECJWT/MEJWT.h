//
//  ECJWT.h
//

#import <Foundation/Foundation.h>

@interface ECJWT : NSObject
+ (NSString *)encodePayload:(NSDictionary *)payload secret:(NSString *)secret;
@end

//
//  AvatarCache.h
//  LivefyreClient
//
//  Created by Thomas Goyne on 8/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFAvatarCache : NSObject
- (void)setImageView:(UIImageView *)view toImageAtURL:(NSString *)url;
@end

//
//  AvatarCache.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 8/29/12.
//  Copyright (c) 2012 7x7 Labs. All rights reserved.
//

#import "LFAvatarCache.h"

@interface LFAvatarCache ()
@property (nonatomic, strong) NSMutableDictionary *downloadedImages;
@property (nonatomic, strong) NSMutableDictionary *downloading;
@end

@implementation LFAvatarCache
- (LFAvatarCache *)init {
    self = [super init];
    if (self) {
        _downloadedImages = [NSMutableDictionary new];
        _downloading = [NSMutableDictionary new];
    }
    return self;
}

- (void)setImageView:(UIImageView *)view toImageAtURL:(NSString *)url {
    if (self.downloadedImages[url]) {
        view.image = self.downloadedImages[url];
        return;
    }

    NSInteger hash = [url hash];
    view.tag = hash;

    if (self.downloading[url]) {
        [self.downloading[url] addObject:view];
        return;
    }

    self.downloading[url] = [NSMutableArray arrayWithObject:view];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *avatarUrl = [NSURL URLWithString:url];
        NSData *imageData = [NSData dataWithContentsOfURL:avatarUrl];

        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                self.downloadedImages[url] = image;
            }
            for (UIImageView *imageView in self.downloading[url]) {
                // Don't set the image view if it's already been switched to a
                // different url
                if (imageView.tag == hash) {
                    imageView.image = image;
                }
            }
            [self.downloading removeObjectForKey:url];
        });
	});
}
@end

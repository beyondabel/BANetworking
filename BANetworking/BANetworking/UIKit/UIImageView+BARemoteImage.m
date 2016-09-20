//
//  UIImageView+BARemoteImage.m
//  BANetworking
//
//  Created by BeyondAbel on 16/7/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "UIImageView+BARemoteImage.h"
#import "BAImageCacheManager.h"
#import "BAImageCache.h"

@interface UIImageView () <BAImageCacheManagerDelegate>

@end

@implementation UIImageView (BARemoteImage)

- (void) setImageWithURL:(NSURL *)url{
    [self setImageWithURL:url placeholderImage:nil];
}

- (void) setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder{
    BAImageCacheManager * manager = [BAImageCacheManager sharedInstance];
    [manager cancelForDelegate:self];
    
    if (url) {
        NSData * imageData = [[BAImageCache sharedInstance] queryDiskCacheForKey:url.absoluteString];
        if (imageData) {
            UIImage *image = [UIImage imageWithData:imageData];
            if (image.size.width > 0) {
                self.image = [UIImage imageWithData:imageData];
                return;
            }
        }
        
        self.image = placeholder;
        [manager imageRequestURL:url delegate:self withKey:url.absoluteString];
        
    } else {
        self.image = placeholder;
    }
    
}


/**
 *  取消加载
 */
- (void) cancelCurrentImageLoad
{
    [[BAImageCacheManager sharedInstance] cancelForDelegate:self];
}

#pragma mark - ABELWebImageCacheManagerDelegate
- (void)webImageManagerDidFinishWithImageData:(NSData *)imageData withKey:(NSString *)key
{
    self.alpha = 0;
    self.image = [UIImage imageWithData:imageData];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1;
    }];
}

- (void)cancelURL {
    [[BAImageCacheManager sharedInstance] cancelForDelegate:self];
}


@end

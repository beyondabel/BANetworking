//
//  UIImageView+BARemoteImage.h
//  BANetworking
//
//  Created by BeyondAbel on 16/7/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (BARemoteImage)

- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;
- (void)cancelCurrentImageLoad;

- (void)cancelURL;

@end

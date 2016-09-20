//
//  BAImageCacheManager.h
//  BANetworking
//
//  Created by BeyondAbel on 16/9/20.
//  Copyright © 2016年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BAImageCacheManagerDelegate;
@interface BAImageCacheManager : NSObject

+ (id) sharedInstance;
/**
 *  取消代理
 *
 *  @param delegate 代理对象
 */
- (void) cancelForDelegate:(id<BAImageCacheManagerDelegate>) delegate;

/**
 *  图片请求
 *
 *  @param url      图片的url
 *  @param delegate 代理对象
 */
- (void) imageRequestURL:(NSURL *)url delegate:(id<BAImageCacheManagerDelegate>)delegate withKey:(NSString *)key;

@end

@protocol BAImageCacheManagerDelegate <NSObject>
@optional
/**
 *  得到图片时将会调用
 *
 *  @param imageManager
 *  @param image
 */
- (void)webImageManagerDidFinishWithImageData:(NSData *)imageData withKey:(NSString *)key;
@end

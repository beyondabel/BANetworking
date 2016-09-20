//
//  BAImageCache.h
//  BANetworking
//
//  Created by BeyondAbel on 16/7/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BAImageCache : NSObject

/**
 *
 *
 *  @return ABELWebImageCache
 */
+ (BAImageCache *) sharedInstance;

/**
 *
 *
 *  @param image 图片的NSData
 *  @param key   图片保存的key
 */
- (void) storeImage:(NSData *) image forKey:(NSString *) key;

- (NSData *) queryDiskCacheForKey:(NSString *) key;

/**
 *
 *
 *  @param image  图片二进制流
 *  @param key    图片保存的key
 *  @param toDisk 是否把图片保存到磁盘上
 */
- (void) storeImageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 *
 *
 *  @param key
 */
- (void) removeImageForKey:(NSString *) key;


/**
 *  从内存或磁盘上找图片
 *
 *  @param key      取图片的关键字
 *  @param cacheImageBlock
 */
- (void) queryDiskCacheForKeyAndDelegate:(NSDictionary *)keyAndDelegate queryCacheImageBlock:(void (^)(NSDictionary *, NSData *))cacheImageBlock;

- (void) modificationDate:(NSDate *)date withPath:(NSString *)key;

@end

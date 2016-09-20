//
//  BAImageCacheManager.m
//  BANetworking
//
//  Created by BeyondAbel on 16/9/20.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "BAImageCacheManager.h"
#import "BAImageDownloader.h"
#import "BAImageCache.h"

static BAImageCacheManager * sharedSingleton = nil;

@interface BAImageCacheManager()
{
    NSMutableDictionary * _imageRequestDictionary;
    NSMutableDictionary * _imageDelegateDictionary;
}
@property (atomic, strong) NSMutableDictionary * imageRequestDictionary;
@property (atomic, strong) NSMutableDictionary * imageDelegateDictionary;
@end

@implementation BAImageCacheManager

#pragma mark - singleton
+ (id) sharedInstance {
    if (sharedSingleton == nil) {
        sharedSingleton = [[super allocWithZone:NULL] init];
    }
    return sharedSingleton;
}

+ (id) allocWithZone:(struct _NSZone *)zone {
    return nil;
}

+ (id) alloc {
    return nil;
}

- (id) init {
    if (self = [super init]) {
        _imageRequestDictionary = [[NSMutableDictionary alloc] init];
        _imageDelegateDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#if !__has_feature(objc_arc)
- (id) retain {
    return self;
}

- (NSUInteger) retainCount {
    return NSUIntegerMax;
}

- (id) autorelease {
    return self;
}
#endif

#pragma mark - singleton end

#pragma mark -
- (void) cancelForDelegate:(id<BAImageCacheManagerDelegate>) delegate
{
    NSArray * keys = [self.imageRequestDictionary allKeys];
    for (NSString * key in keys) {
        NSMutableArray * delegates = [self.imageDelegateDictionary objectForKey:key];
        for (NSInteger index = delegates.count - 1; index >= 0; index--) {
            NSDictionary * delegateAndKey = [delegates objectAtIndex:index];
            id<BAImageCacheManagerDelegate> delegateTemp = [delegateAndKey objectForKey:@"delegate"];
            
            if (delegateTemp == delegate) {
                [delegates removeObjectAtIndex:index];
            }
        }
    }
}


- (void) imageRequestURL:(NSURL *)url delegate:(id<BAImageCacheManagerDelegate>)delegate withKey:(NSString *)key {
    if (!url ) {
        return;
    }
    
    BAImageDownloader * imageRequest = [self.imageRequestDictionary objectForKey:url.absoluteString];
    if (imageRequest) {
        if (delegate) {
            NSMutableArray * imageRequestDelegates = [self.imageDelegateDictionary objectForKey:url.absoluteString];
            NSUInteger index = [imageRequestDelegates indexOfObjectIdenticalTo:delegate];
            if (index == NSNotFound) {
                [imageRequestDelegates addObject:[NSDictionary dictionaryWithObjectsAndKeys:key,@"imageKey",delegate,@"delegate", nil]];
            }
            [self.imageDelegateDictionary setObject:imageRequestDelegates forKey:url.absoluteString];
        }
    } else {
        imageRequest = [BAImageDownloader requestWithURL:url imageRequestDelegate:self];
        if (delegate) {
            NSMutableArray * imageRequestDelegates = [[NSMutableArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:key,@"imageKey",delegate,@"delegate", nil], nil];
            [self.imageDelegateDictionary setObject:imageRequestDelegates forKey:url.absoluteString];
#if !__has_feature(objc_arc)
            [imageRequestDelegates release];
#endif
        }
        
        
        [self.imageRequestDictionary setObject:imageRequest forKey:url.absoluteString];
    }
}

// #pragma mark ABELWebImageRequestDelegate
- (void) imageRequest:(BAImageDownloader *)imageRequest didFinishWithImageData:(NSData *)imageData {
    NSMutableArray * delegates = [self.imageDelegateDictionary objectForKey:imageRequest.url.absoluteString];
    for (NSInteger index = delegates.count - 1; index >= 0; index--) {
        NSDictionary * delegateAndKey = [delegates objectAtIndex:index];
        id<BAImageCacheManagerDelegate> delegate = [delegateAndKey objectForKey:@"delegate"];
        if (imageData && [delegate respondsToSelector:@selector(webImageManagerDidFinishWithImageData: withKey:)]) {
            [delegate webImageManagerDidFinishWithImageData:imageData withKey:[delegateAndKey objectForKey:@"imageKey"]];
        }
        [delegates removeObjectAtIndex:index];
    }
    
    if (imageData) {
        // 保存图片
        [self performSelectorInBackground:@selector(savaImageFile:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:imageData,@"imageData",[imageRequest.url absoluteString],@"key", nil]];
    }
    
    [self.imageRequestDictionary removeObjectForKey:imageRequest.url.absoluteString];
    [self.imageDelegateDictionary removeObjectForKey:imageRequest.url.absoluteString];
}

- (void)savaImageFile:(NSDictionary *)dic {
    NSData * imageData = [dic objectForKey:@"imageData"];
    [[BAImageCache sharedInstance] storeImageData:imageData forKey:[dic objectForKey:@"key"] toDisk:YES];
}


@end

//
//  BAImageCache.m
//  BANetworking
//
//  Created by BeyondAbel on 16/7/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "BAImageCache.h"
#import <CommonCrypto/CommonDigest.h>

#define OVERDUE_TIME 604800   // 图片过期时间为7天

static BAImageCache * sharedSingleton = nil;

@interface BAImageCache()
{
    NSMutableDictionary * _memCache;
    NSString * _diskCachePath;
    NSOperationQueue * _cacheInQueue, * _cacheOutQueue;
    
    void (^findImageCache)(NSDictionary * info,NSData * imageData);
}

@property (nonatomic, strong) NSMutableDictionary * memCache;
@property (nonatomic, copy) NSString * diskCachePath;
@property (nonatomic, strong) NSOperationQueue * cacheInQueue;
@property (nonatomic, strong) NSOperationQueue * cacheOutQueue;

@end

@implementation BAImageCache
@synthesize memCache = _memCache,diskCachePath = _diskCachePath,cacheInQueue = _cacheInQueue,cacheOutQueue = _cacheOutQueue;

#pragma mark - Singleton
+ (BAImageCache *) sharedInstance
{
    if (sharedSingleton == nil) {
        sharedSingleton = [[super allocWithZone:NULL] init];
    }
    return sharedSingleton;
}

+ (id) alloc
{
    return nil;
}

- (id)init {
    if (self = [super init]) {
        // 内存缓存
        self.memCache = [[NSMutableDictionary alloc] init];
        
        // 硬盘缓存
//        self.diskCachePath = imagePath;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.diskCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        // operation队列
        self.cacheInQueue = [[NSOperationQueue alloc] init];
        self.cacheInQueue.maxConcurrentOperationCount = 1;
        self.cacheOutQueue = [[NSOperationQueue alloc] init];
        self.cacheOutQueue.maxConcurrentOperationCount = 1;
        
        // 用户手动清除缓存
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearAllDisk) name:@"clearCache" object:nil];
        
        // 收到内存警告时清除缓存
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        //  程序退出时清除缓存
        //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanDisk) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

#pragma mark - ABELWebImageCache(private)
- (NSString *) cachePathForKey:(NSString *) key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString * fileName = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    return [self.diskCachePath stringByAppendingPathComponent:fileName];
}

#pragma mark - 保存图片
/**
 *  保存图片到磁盘上
 *
 *  @param keyAndData 图片imageData和图片的关键字key
 */
- (void) storeKeyWithDataToDiskForKey:(NSString *) key
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSData *data = [self imageDataFromKey:key fromDisk:YES];
    
    if (data){
        [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
    }
#if !__has_feature(objc_arc)
    [data release];
    [fileManager release];
#endif
}

- (void) storeImageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    if (!imageData || !key || !toDisk) {
        return;
    }
    
    [self.memCache setObject:imageData forKey:key];
    
    if (toDisk) {
        NSInvocationOperation * operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(storeKeyWithDataToDiskForKey:) object:key];
        [self.cacheInQueue addOperation:operation];
        
#if !__has_feature(objc_arc)
        [operation release];
#endif
    }
}

- (void) storeImage:(NSData *)image forKey:(NSString *)key
{
    [self storeImageData:image forKey:key toDisk:YES];
}



#pragma mark - 查找图片
- (NSData *) imageFromKey:(NSString *)key
{
    return [self imageDataFromKey:key fromDisk:YES];
}

/**
 *  通过key从memCache或者磁盘中查询图片
 *
 *  @param key      查询图片的关键字
 *  @param fromDisk 是否从磁盘上查询
 *
 *  @return 查询图片结果
 */
- (NSData *) imageDataFromKey:(NSString *)key fromDisk:(BOOL)fromDisk
{
    if (key == nil){
        return nil;
    }
    
    // 如果过期的话，就先删除图片
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-OVERDUE_TIME];
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[self cachePathForKey:key] error:nil];
    if ([[attrs fileModificationDate] compare:expirationDate] == NSOrderedAscending){
        [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
    }
    
    NSData *data=[self.memCache objectForKey:key];
    
    if (!data && fromDisk){
        data=[[NSData alloc] initWithContentsOfFile:[self cachePathForKey:key]];
        if (data){
            [self.memCache setObject:data forKey:key];
        }
    }
    return data;
}

/**
 *  通过关键字key查询图片
 *
 *  @param key             查询图片时用的关键字
 *  @param cacheImageBlock 查询图片结束时被调用的block
 */
- (void) queryDiskCacheForKeyAndDelegate:(NSDictionary *)keyAndDelegate queryCacheImageBlock:(void (^)(NSDictionary * , NSData *))cacheImageBlock
{
#if !__has_feature(objc_arc)
    [findImageCache release];
#endif
    
    findImageCache = [cacheImageBlock copy];
    if (![keyAndDelegate objectForKey:@"key"]) {
        findImageCache(keyAndDelegate,nil);
        return;
    }
    
    NSData * image = [self.memCache objectForKey:[keyAndDelegate objectForKey:@"key"]];
    if (image) {
        findImageCache(keyAndDelegate,image);
        return;
    }
    
    NSMutableDictionary * arguments = [NSMutableDictionary dictionaryWithCapacity:3];
    [arguments setObject:[keyAndDelegate objectForKey:@"key"] forKey:@"key"];
    
    NSInvocationOperation * operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(queryDiskCacheOperation:) object:keyAndDelegate];
    [self.cacheOutQueue addOperation:operation];
}

- (void) queryDiskCacheOperation:(NSDictionary *) keyAndDelegate
{
    NSData * imageData = [[NSData alloc] initWithContentsOfFile:[self cachePathForKey:[keyAndDelegate objectForKey:@"key"]]];
    
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithObject:[keyAndDelegate objectForKey:@"delegate"] forKey:@"delegate"];
    [dic setObject:[keyAndDelegate objectForKey:@"key"] forKey:@"key"];
    if (imageData) {
        [dic setObject:imageData forKey:@"imageData"];
    }
    [self performSelectorOnMainThread:@selector(finishedFindImageCache:) withObject:dic waitUntilDone:NO];
}


- (void) finishedFindImageCache:(NSDictionary *) dic
{
    if (findImageCache ) {
        findImageCache(dic,[dic objectForKey:@"imageData"]);
    }
}


- (NSData *) queryDiskCacheForKey:(NSString *) key
{
    if (key == nil) {
        return nil;
    }
    NSData * image = [self.memCache objectForKey:key];
    if (image) {
        return image;
    }
    return [[NSData alloc] initWithContentsOfFile:[self cachePathForKey:key]];
}

#pragma mark -
- (void) removeImageForKey:(NSString *)key
{
    if (key == nil) {
        return;
    }
    
    [self.memCache removeObjectForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
}

#pragma mark- 清空缓存
- (void) clearMemory
{
    // 清内存
    [self.cacheInQueue cancelAllOperations];
    [self.memCache removeAllObjects];
    //    [self cleanDisk];
}

- (void) cleanDisk
{
    // 清硬盘
    NSDate * expirationData = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString * fileName in fileEnumerator) {
        NSString * filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary * attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[[attrs fileModificationDate] laterDate:expirationData] isEqualToDate:expirationData]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

- (void) clearAllDisk
{
    [self.cacheInQueue cancelAllOperations];
    [self.memCache removeAllObjects];
    
    NSDirectoryEnumerator * fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString * fileName in fileEnumerator) {
        NSString * filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (NSDate *)queryDiskCacheModificationDateForKey:(NSString *)key
{
    NSDictionary *fileAttributes = [self fileAttributesForKey:key];
    if (fileAttributes) {
        return [fileAttributes objectForKey:NSFileModificationDate];
    }
    return nil;
}

- (void) modificationDate:(NSDate *)date withPath:(NSString *)key{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSMutableDictionary * attributes = [NSMutableDictionary dictionaryWithDictionary:[self fileAttributesForKey:key]];
    [attributes setObject:date forKey:NSFileModificationDate];
    
    [fileManager setAttributes:attributes ofItemAtPath:[self cachePathForKey:key] error:nil];
}

- (NSDictionary *) fileAttributesForKey:(NSString *)key{
    return [[NSFileManager defaultManager] attributesOfItemAtPath:[self cachePathForKey:key] error:nil];
}

- (void)dealloc
{
    self.memCache = nil;
    self.diskCachePath = nil;
    self.cacheInQueue = nil;
    self.cacheOutQueue = nil;
#if !__has_feature(objc_arc)
    [findImageCache release];
    [super dealloc];
#endif
}


@end

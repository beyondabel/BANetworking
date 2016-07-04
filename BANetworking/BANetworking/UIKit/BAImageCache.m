//
//  BAImageCache.m
//  BANetworking
//
//  Created by BeyondAbel on 16/7/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "BAImageCache.h"

@implementation BAImageCache

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#pragma mark - Public

+ (instancetype)sharedCache {
    static id sharedCache;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        sharedCache = [[self alloc] init];
    });
    
    return sharedCache;
}



@end

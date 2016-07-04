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

+ (instancetype)sharedCache;

- (void)clearCache;

@end

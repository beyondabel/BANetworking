//
//  BACommonConfig.h
//  BANetworking
//
//  Created by abel on 16/3/29.
//  Copyright © 2016年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BACommonConfigProtocol <NSObject>

/**
 *  Setting HTTP URL/Body parameters
 */
+ (NSDictionary *)commonParameters;

/**
 *  Setting HTTP Header parameters
 */
+ (NSDictionary *)headerCommonParameters;

/**
 *  Setting HTTP Cookie parameters
 */
+ (NSDictionary *)cookieCommonParameters;

@end

//
//  BAAuthenticationAPI.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BABaseAPI.h"

@interface BAAuthenticationAPI : BABaseAPI

+ (BARequest *)requestForAuthenticationWithEmail:(NSString *)email password:(NSString *)password;

+ (BARequest *)requestForAuthenticationWithTransferToken:(NSString *)transferToken;

+ (BARequest *)requestToRefreshToken:(NSString *)refreshToken;

@end

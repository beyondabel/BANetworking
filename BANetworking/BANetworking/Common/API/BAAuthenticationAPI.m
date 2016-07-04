//
//  BAAuthenticationAPI.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAAuthenticationAPI.h"

@implementation BAAuthenticationAPI

+ (BARequest *)requestForAuthenticationWithEmail:(NSString *)email password:(NSString *)password {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (email) {
        [parameters setObject:email forKey:@"email"];
    }
    
    if (password) {
        [parameters setObject:password forKey:@"password"];
    }
    return [BARequest POSTRequestWithPath:@"/login" parameters:parameters];
}


+ (BARequest *)requestForAuthenticationWithTransferToken:(NSString *)transferToken {
    return nil;
}

+ (BARequest *)requestToRefreshToken:(NSString *)refreshToken {
    return nil;
}

+ (BARequest *)requestForAuthenticateLogout {
    return nil;
}

@end

//
//  NSMutableURLRequest+BAHeaders.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSMutableURLRequest+BAHeaders.h"
#import "NSString+BAAdditions.h"

static NSString * const kHeaderAuthorization = @"Authorization";
static NSString * const kAuthorizationOAuth2AccessTokenFormat = @"OAuth2 %@";

@implementation NSMutableURLRequest (BAHeaders)

- (void)ba_setAuthorizationHeaderWithOAuth2AccessToken:(NSString *)accessToken {
    NSString *value = [NSString stringWithFormat:kAuthorizationOAuth2AccessTokenFormat, accessToken];
    [self setValue:value forHTTPHeaderField:kHeaderAuthorization];
}

- (void)ba_setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
    NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
    [self setValue:[NSString stringWithFormat:@"Basic %@", [authString ba_base64String]] forHTTPHeaderField:@"Authorization"];
}

@end

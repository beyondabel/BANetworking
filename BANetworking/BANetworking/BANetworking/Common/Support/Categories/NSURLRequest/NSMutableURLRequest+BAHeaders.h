//
//  NSMutableURLRequest+BAHeaders.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (BAHeaders)

- (void)ba_setAuthorizationHeaderWithOAuth2AccessToken:(NSString *)accessToken;
- (void)ba_setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password;

@end

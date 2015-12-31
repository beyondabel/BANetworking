//
//  BARequestSerializer.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BARequest;

@class BAMultipartFormData;

extern NSString * const BARequestSerializerHTTPHeaderKeyAuthorization;
extern NSString * const BARequestSerializerHTTPHeaderKeyUserAgent;
extern NSString * const BARequestSerializerHTTPHeaderKeyContentType;
extern NSString * const BARequestSerializerHTTPHeaderKeyContentLength;

@interface BARequestSerializer : NSObject

- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request relativeToURL:(NSURL *)baseURL;
- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request multipartData:(BAMultipartFormData *)multipartData relativeToURL:(NSURL *)baseURL;

- (id)valueForHTTPHeader:(NSString *)header;

- (void)setValue:(NSString *)value forHTTPHeader:(NSString *)header;
- (void)setAuthorizationHeaderWithOAuth2AccessToken:(NSString *)accessToken;
- (void)setAuthorizationHeaderWithAPIKey:(NSString *)key secret:(NSString *)secret;
- (void)setUserAgentHeader:(NSString *)userAgent;

- (BAMultipartFormData *)multipartFormDataFromRequest:(BARequest *)request;

@end

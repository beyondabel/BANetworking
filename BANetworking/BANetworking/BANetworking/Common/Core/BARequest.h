//
//  BARequest.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BARequestFileData.h"

#define BARequestPath(fmt, ...) [NSString stringWithFormat:fmt, ##__VA_ARGS__]

typedef NSURLRequest * (^BAURLRequestConfigurationBlock) (NSURLRequest *request);

typedef NS_ENUM(NSUInteger, BARequestMethod) {
    BARequestMethodGET = 0,
    BARequestMethodPOST,
    BARequestMethodPUT,
    BARequestMethodDELETE,
    BARequestMethodHEAD,
};

typedef NS_ENUM(NSUInteger, BARequestContentType) {
    BARequestContentTypeJSON = 0,
    BARequestContentTypeFormURLEncoded,
    BARequestContentTypeMultipart
};

@interface BARequest : NSObject

@property (nonatomic, assign, readonly) BARequestMethod method;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSDictionary *parameters;
@property (nonatomic, strong) BARequestFileData *fileData;
@property (nonatomic, assign, readwrite) BARequestContentType contentType;
@property (nonatomic, copy, readwrite) BAURLRequestConfigurationBlock URLRequestConfigurationBlock;

+ (instancetype)GETRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters;
+ (instancetype)POSTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters;
+ (instancetype)PUTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters;
+ (instancetype)DELETERequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters;

+ (instancetype)GETRequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters;
+ (instancetype)POSTRequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters;
+ (instancetype)PUTRequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters;
+ (instancetype)DELETERequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters;

@end

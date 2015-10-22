//
//  BARequest.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BARequest.h"

@implementation BARequest

- (instancetype)initWithPath:(NSString *)path url:(NSURL *)url parameters:(NSDictionary *)parameters method:(BARequestMethod)method {
    self = [super init];
    if (!self) return nil;
    
    _path = [path copy];
    _URL = [url copy];
    _parameters = [parameters copy];
    _method = method;
    
    return self;
}

+ (instancetype)requestWithPath:(NSString *)path parameters:(NSDictionary *)parameters method:(BARequestMethod)method {
    return [[self alloc] initWithPath:path url:nil parameters:parameters method:method];
}

+ (instancetype)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(BARequestMethod)method {
    return [[self alloc] initWithPath:nil url:url parameters:parameters method:method];
}

+ (instancetype)GETRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters {
    return [self requestWithPath:path parameters:parameters method:BARequestMethodGET];
}

+ (instancetype)POSTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters {
    return [self requestWithPath:path parameters:parameters method:BARequestMethodPOST];
}

+ (instancetype)PUTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters {
    return [self requestWithPath:path parameters:parameters method:BARequestMethodPUT];
}

+ (instancetype)DELETERequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters {
    return [self requestWithPath:path parameters:parameters method:BARequestMethodDELETE];
}

+ (instancetype)GETRequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters {
    return [self requestWithURL:url parameters:parameters method:BARequestMethodGET];
}

+ (instancetype)POSTRequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters {
    return [self requestWithURL:url parameters:parameters method:BARequestMethodPOST];
}

+ (instancetype)PUTRequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters {
    return [self requestWithURL:url parameters:parameters method:BARequestMethodPUT];
}

+ (instancetype)DELETERequestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters {
    return [self requestWithURL:url parameters:parameters method:BARequestMethodDELETE];
}


@end

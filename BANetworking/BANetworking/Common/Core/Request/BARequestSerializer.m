//
//  BARequestSerializer.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BARequestSerializer.h"
#import "BARequest.h"
#import "BAMultipartFormData.h"
#import "NSString+BAAdditions.h"
#import "NSURL+BAAdditions.h"
#import "NSDictionary+BAQueryParameters.h"
#import "NSURLRequest+BADescription.h"

static NSString * const kHTTPMethodGET = @"GET";
static NSString * const kHTTPMethodPOST = @"POST";
static NSString * const kHTTPMethodPUT = @"PUT";
static NSString * const kHTTPMethodDELETE = @"DELETE";
static NSString * const kHTTPMethodHEAD = @"HEAD";

NSString * const BARequestSerializerHTTPHeaderKeyAuthorization = @"Authorization";
NSString * const BARequestSerializerHTTPHeaderKeyUserAgent = @"User-Agent";
NSString * const BARequestSerializerHTTPHeaderKeyContentType = @"Content-Type";
NSString * const BARequestSerializerHTTPHeaderKeyContentLength = @"Content-Length";


static NSString * const kAuthorizationOAuth2AccessTokenFormat = @"OAuth2 %@";

static NSString * const kHeaderTimeZone = @"X-Time-Zone";

static NSString * const kBoundaryPrefix = @"----------------------";
static NSUInteger const kBoundaryLength = 20;


@interface BARequestSerializer ()

@property (nonatomic, assign) BARequestContentType requestContentType;
@property (nonatomic, copy, readonly) NSString *boundary;
@property (nonatomic, strong, readonly) NSMutableDictionary *mutAdditionalHTTPHeaders;

@end

@implementation BARequestSerializer

@synthesize boundary = _boundary;
@synthesize mutAdditionalHTTPHeaders = _mutAdditionalHTTPHeaders;

- (NSString *)boundary {
    if (!_boundary) {
        _boundary = [NSString stringWithFormat:@"%@%@", kBoundaryPrefix, [NSString ba_randomHexStringOfLength:kBoundaryLength]];
    }
    
    return _boundary;
}

- (NSMutableDictionary *)mutAdditionalHTTPHeaders {
    if (!_mutAdditionalHTTPHeaders) {
        _mutAdditionalHTTPHeaders = [NSMutableDictionary new];
    }
    
    return _mutAdditionalHTTPHeaders;
}

- (NSDictionary *)additionalHTTPHeaders {
    return [self.mutAdditionalHTTPHeaders copy];
}

#pragma mark Public

- (id)valueForHTTPHeader:(NSString *)header {
    return [self additionalHTTPHeaders][header];
}

- (void)setValue:(NSString *)value forHTTPHeader:(NSString *)header {
    NSParameterAssert(header);
    
    if (value) {
        self.mutAdditionalHTTPHeaders[header] = value;
    } else {
        [self.mutAdditionalHTTPHeaders removeObjectForKey:header];
    }
}

- (void)setAuthorizationHeaderWithOAuth2AccessToken:(NSString *)accessToken {
    NSParameterAssert(accessToken);
    [self setValue:[NSString stringWithFormat:kAuthorizationOAuth2AccessTokenFormat, accessToken] forHTTPHeader:BARequestSerializerHTTPHeaderKeyAuthorization];
}

- (void)setAuthorizationHeaderWithAPIKey:(NSString *)key secret:(NSString *)secret {
    NSParameterAssert(key);
    NSParameterAssert(secret);
    
    NSString *credentials = [NSString stringWithFormat:@"%@:%@", key, secret];
    [self setValue:[NSString stringWithFormat:@"Basic %@", [credentials ba_base64String]] forHTTPHeader:BARequestSerializerHTTPHeaderKeyAuthorization];
}

- (void)setUserAgentHeader:(NSString *)userAgent {
    NSParameterAssert(userAgent);
    [self setValue:userAgent forHTTPHeader:BARequestSerializerHTTPHeaderKeyUserAgent];
}

#pragma mark - URL request

- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request relativeToURL:(NSURL *)baseURL {
    return [self URLRequestForRequest:request multipartData:nil relativeToURL:baseURL];
}

- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request multipartData:(BAMultipartFormData *)multipartData relativeToURL:(NSURL *)baseURL {
    NSParameterAssert(request);
    NSParameterAssert(baseURL);
    
    NSURL *url = nil;
    if (request.URL) {
        url = request.URL;
    } else {
        NSParameterAssert(request.path);
        url = [NSURL URLWithString:request.path relativeToURL:baseURL];
    }
    
    if (request.parameters && [[self class] supportsQueryParametersForRequestMethod:request.method]) {
        url = [url ba_URLByAppendingQueryParameters:request.parameters];
    }
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    urlRequest.HTTPMethod = [[self class] HTTPMethodForMethod:request.method];
    [urlRequest setValue:[self contentTypeForRequest:request] forHTTPHeaderField:BARequestSerializerHTTPHeaderKeyContentType];
    [urlRequest setValue:[[NSTimeZone localTimeZone] name] forHTTPHeaderField:kHeaderTimeZone];
    
    if (multipartData) {
        NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)multipartData.finalizedData.length];
        [urlRequest setValue:contentLength forHTTPHeaderField:BARequestSerializerHTTPHeaderKeyContentLength];
    }
    
    [self.additionalHTTPHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *header, NSString *value, BOOL *stop) {
        [urlRequest setValue:value forHTTPHeaderField:header];
    }];
    
    urlRequest.HTTPBody = [[self class] bodyDataForRequest:request];
    
    if (request.URLRequestConfigurationBlock) {
        urlRequest = [request.URLRequestConfigurationBlock(urlRequest) mutableCopy];
    }
    
    return urlRequest;
}

- (BAMultipartFormData *)multipartFormDataFromRequest:(BARequest *)request {
    BAMultipartFormData *multiPartData = [BAMultipartFormData multipartFormDataWithBoundary:self.boundary encoding:NSUTF8StringEncoding];
    
    if (request.fileData.data) {
        [multiPartData appendFileData:request.fileData.data fileName:request.fileData.fileName mimeType:nil name:request.fileData.name];
    } else if (request.fileData.filePath) {
        [multiPartData appendContentsOfFileAtPath:request.fileData.filePath name:request.fileData.name];
    }
    
    for (BARequestFileData *fileData in request.fileDatas) {
        if (fileData.data) {
            [multiPartData appendFileData:fileData.data fileName:fileData.fileName mimeType:nil name:fileData.name];
        } else if (fileData.filePath) {
            [multiPartData appendContentsOfFileAtPath:fileData.filePath name:fileData.name];
        }
    }
    
    if ([request.parameters count] > 0) {
        [multiPartData appendFormDataParameters:request.parameters];
    }
    
    [multiPartData finalizeData];
    
    return multiPartData;
}

#pragma mark - Private
+ (NSString *)HTTPMethodForMethod:(BARequestMethod)method {
    NSString *string = nil;
    
    switch (method) {
        case BARequestMethodGET:
            string = kHTTPMethodGET;
            break;
        case BARequestMethodPOST:
            string = kHTTPMethodPOST;
            break;
        case BARequestMethodPUT:
            string = kHTTPMethodPUT;
            break;
        case BARequestMethodDELETE:
            string = kHTTPMethodDELETE;
            break;
        case BARequestMethodHEAD:
            string = kHTTPMethodHEAD;
            break;
        default:
            break;
    }
    
    return string;
}

+ (NSData *)bodyDataForRequest:(BARequest *)request {
    NSData *data = nil;
    
    if (request.parameters && ![self supportsQueryParametersForRequestMethod:request.method]) {
        if (request.contentType == BARequestContentTypeJSON) {
            data = [NSJSONSerialization dataWithJSONObject:request.parameters options:0 error:nil];
        } else if (request.contentType == BARequestContentTypeFormURLEncoded) {
            data = [[request.parameters ba_escapedQueryString] dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    return data;
}

+ (BOOL)supportsQueryParametersForRequestMethod:(BARequestMethod)method {
    return method == BARequestMethodGET || method == BARequestMethodDELETE || method == BARequestMethodHEAD;
}

- (NSString *)contentTypeForRequest:(BARequest *)request {
    NSString *contentType = nil;
    
    static NSString *charset = nil;
    static dispatch_once_t charsetToken;
    dispatch_once(&charsetToken, ^{
        charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    });
    
    switch (request.contentType) {
        case BARequestContentTypeMultipart:
            contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
            break;
        case BARequestContentTypeFormURLEncoded:
            contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset];
            break;
        case BARequestContentTypeJSON:
            contentType = [NSString stringWithFormat:@"application/json; charset=%@", charset];
        default:
            
            break;
    }
    
    return contentType;
}

@end

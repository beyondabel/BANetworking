//
//  NSError+BAErrors.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSError+BAErrors.h"
#import "NSDictionary+BAAdditions.h"

NSString * const ServerErrorDomain = @"ErrorDomain";

NSString * const BAErrorKey = @"BAError";
NSString * const BAErrorDescriptionKey = @"BAErrorDescription";
NSString * const BAErrorDetailKey = @"BAErrorDetail";
NSString * const BAErrorParametersKey = @"BAErrorParameters";
NSString * const BAErrorPropagateKey = @"BAErrorPropagate";

@implementation NSError (BAErrors)

#pragma mark - Public

+ (NSError *)ba_serverErrorWithStatusCode:(NSUInteger)statusCode body:(id)body {
    return [NSError errorWithDomain:ServerErrorDomain code:statusCode userInfo:[self ba_userInfoFromBody:body]];
}

- (BOOL)ba_isServerError {
    return [self.domain isEqualToString:ServerErrorDomain] && self.code > 0;
}

- (NSString *)ba_localizedServerSideDescription {
    return [self ba_shouldPropagate] ? self.userInfo[ServerErrorDomain] : nil;
}

#pragma mark - Private

- (BOOL)ba_shouldPropagate {
    return [self ba_isServerError] && [self.userInfo[ServerErrorDomain] boolValue] == YES;
}

+ (NSDictionary *)ba_userInfoFromBody:(id)body {
    if (![body isKindOfClass:[NSDictionary class]]) return nil;
    
    NSDictionary *errorDict = body;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    
    NSString *error = [errorDict ba_nonNullObjectForKey:@"error"];
    NSString *errorDescription = [errorDict ba_nonNullObjectForKey:@"error_description"];
    NSString *errorDetail = [errorDict ba_nonNullObjectForKey:@"error_detail"];
    NSDictionary *errorParameters = [errorDict ba_nonNullObjectForKey:@"error_parameters"];
    NSNumber *errorPropagate = [errorDict ba_nonNullObjectForKey:@"error_propagate"];
    
    if (errorDescription && [errorPropagate boolValue]) userInfo[NSLocalizedDescriptionKey] = errorDescription;
    if (error) userInfo[BAErrorKey] = error;
    if (errorDescription) userInfo[BAErrorDescriptionKey] = errorDescription;
    if (errorDetail) userInfo[BAErrorDetailKey] = errorDetail;
    if (errorParameters) userInfo[BAErrorParametersKey] = errorParameters;
    if (errorPropagate) userInfo[BAErrorPropagateKey] = errorPropagate;
    
    return [userInfo copy];
}

@end

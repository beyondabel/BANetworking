//
//  NSError+BAErrors.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ServerErrorDomain;

extern NSString * const BAErrorKey;
extern NSString * const BAErrorDescriptionKey;
extern NSString * const BAErrorDetailKey;
extern NSString * const BAErrorParametersKey;
extern NSString * const BAErrorPropagateKey;

@interface NSError (BAErrors)

+ (NSError *)ba_serverErrorWithStatusCode:(NSUInteger)statusCode body:(id)body;

- (BOOL)ba_isServerError;

- (NSString *)ba_localizedServerSideDescription;

@end

//
//  BAResponse.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAResponse.h"

@implementation BAResponse

- (instancetype)initWithStatusCode:(NSInteger)statusCode body:(id)body {
    self = [super init];
    if (!self) return nil;
    
    _statusCode = statusCode;
    _body = body;
    
    return self;
}

@end

//
//  BAResponseSerializer.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAResponseSerializer.h"
#import "NSString+BAAdditions.h"

@implementation BAResponseSerializer

- (id)responseObjectForURLResponse:(NSURLResponse *)response data:(NSData *)data {
    if (data == nil || ![response isKindOfClass:[NSHTTPURLResponse class]]) return nil;
    
    id object = nil;
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    if ([HTTPResponse.allHeaderFields[@"Content-Type"] ba_containsString:@"application/json"]) {
        object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    } else {
        object = data;
    }
    
    return object;
}

@end

//
//  NSURLRequest+HBDescription.m
//  HuoBan
//
//  Created by abel on 14/10/14.
//  Copyright (c) 2014年 Huoban inc. All rights reserved.
//

#import "NSURLRequest+BADescription.h"

@implementation NSURLRequest (BADescription)

- (NSString *)ba_description {
    NSMutableString *mutString = [[NSMutableString alloc] init];
    
    [mutString appendString:@"--------------------------------------------------\n"];
    
    [mutString appendFormat:@"%@ %@\n", self.HTTPMethod, [self.URL absoluteString]];
    [mutString appendString:@"Headers:\n"];
    [self.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id name, id value, BOOL *stop) {
        [mutString appendFormat:@"  %@=%@\n", name, value];
    }];
    
    if ([self.HTTPBody length] > 0) {
        [mutString appendString:@"Body:\n"];
        [mutString appendFormat:@"  %@\n", [[NSString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding]];
    }
    
    [mutString appendString:@"--------------------------------------------------"];
    
    return [mutString copy];
}

@end

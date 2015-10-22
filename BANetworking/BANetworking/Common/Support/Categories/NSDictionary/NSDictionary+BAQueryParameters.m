//
//  NSDictionary+BAQueryParameters.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSDictionary+BAQueryParameters.h"
#import "NSString+BAURLEncode.h"
#import "NSArray+BAAdditions.h"

@implementation NSDictionary (BAQueryParameters)

- (NSString *)ba_queryString {
    return [self ba_queryStringByEscapingValues:NO];
}

- (NSString *)ba_escapedQueryString {
    return [self ba_queryStringByEscapingValues:YES];
}

- (NSDictionary *)ba_queryParametersPairs {
    return [self ba_flattenedKeysAndValuesWithKeyMappingBlock:nil];
}

- (NSDictionary *)ba_escapedQueryParametersPairs {
    NSMutableDictionary *escapedPairs = [NSMutableDictionary new];
    
    NSDictionary *pairs = [self ba_queryParametersPairs];
    [pairs enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *stringValue = [value isKindOfClass:[NSString class]] ? value : [NSString stringWithFormat:@"%@", value];
        escapedPairs[key] = [stringValue ba_encodeString];
    }];
    
    return [escapedPairs copy];
}

#pragma mark - Private

- (NSDictionary *)ba_flattenedKeysAndValuesWithKeyMappingBlock:(NSString * (^)(id key))keyMappingBlock {
    NSMutableDictionary *pairs = [NSMutableDictionary new];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *currentKey = keyMappingBlock ? keyMappingBlock(key) : key;
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *subKeysAndValues = [value ba_flattenedKeysAndValuesWithKeyMappingBlock:^NSString *(id subKey) {
                // Sub-keys should appear in brackets
                return [NSString stringWithFormat:@"[%@]", subKey];
            }];
            
            [subKeysAndValues enumerateKeysAndObjectsUsingBlock:^(id subKey, id subValue, BOOL *stop) {
                NSString *fullKey = [currentKey stringByAppendingString:subKey];
                pairs[fullKey] = subValue;
            }];
        } else {
            pairs[currentKey] = value;
        }
    }];
    
    return [pairs copy];
}

- (NSString *)ba_queryStringByEscapingValues:(BOOL)escapeValues {
    NSMutableArray *pairs = [NSMutableArray new];
    
    NSDictionary *escapedPairs = escapeValues ? [self ba_escapedQueryParametersPairs] : [self ba_queryParametersPairs];
    [escapedPairs enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *pair = [NSString stringWithFormat:@"%@=%@", key, value];
        [pairs addObject:pair];
    }];
    
    return [pairs componentsJoinedByString:@"&"];
}

@end

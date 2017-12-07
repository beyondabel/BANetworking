//
//  NSURL+BAAdditions.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSURL+BAAdditions.h"
#import "NSString+BAAdditions.h"
#import "NSDictionary+BAQueryParameters.h"

@implementation NSURL (BAAdditions)

- (NSURL *)ba_URLByAppendingQueryParameters:(NSDictionary *)parameters {
    if ([parameters count] == 0) return self;
    
    NSMutableString *query = [NSMutableString stringWithString:self.absoluteString];
    
    if (![query ba_containsString:@"?"]) {
        [query appendString:@"?"];
    } else {
        [query appendString:@"&"];
    }
    
    [query appendString:[parameters ba_escapedQueryString]];
    
    return [NSURL URLWithString:[query copy]];
}

@end

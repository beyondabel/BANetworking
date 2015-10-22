//
//  NSDictionary+BAAdditions.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSDictionary+BAAdditions.h"

@implementation NSDictionary (BAAdditions)

- (id)ba_nonNullObjectForKey:(id)key {
    id value = self[key];
    if (value == [NSNull null]) {
        value = nil;
    }
    
    return value;
}

@end

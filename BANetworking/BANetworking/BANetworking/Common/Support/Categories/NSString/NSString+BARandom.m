//
//  NSString+BARandom.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSString+BARandom.h"

@implementation NSString (BARandom)

+ (instancetype)ba_randomHexStringOfLength:(NSUInteger)length {
    char data[length];
    
    for (NSUInteger i = 0; i < length; ++i) {
        u_int32_t rand = arc4random_uniform(36);
        data[i] = rand < 10 ? '0' + rand : 'a' + (rand - 10);
    }
    
    return [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
}

@end

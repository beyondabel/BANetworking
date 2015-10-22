//
//  NSString+BAAdditions.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSString+BAAdditions.h"

@implementation NSString (BAAdditions)

- (BOOL)ba_containsString:(NSString *)string {
    return [self rangeOfString:string].location != NSNotFound;
}

@end

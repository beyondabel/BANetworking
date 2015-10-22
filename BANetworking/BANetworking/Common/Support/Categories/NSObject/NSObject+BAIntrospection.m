//
//  NSObject+BAIntrospection.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+BAIntrospection.h"

@implementation NSObject (BAIntrospection)

+ (id)ba_valueByPerformingSelectorWithName:(NSString *)selectorName {
    return [self ba_valueByPerformingSelectorWithName:selectorName withObject:nil];
}

+ (id)ba_valueByPerformingSelectorWithName:(NSString *)selectorName withObject:(id)object {
    id value = nil;
    
    SEL selector = NSSelectorFromString(selectorName);
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        value = [self performSelector:selector withObject:object];
#pragma clang diagnostic pop
    }
    
    return value;
}

@end

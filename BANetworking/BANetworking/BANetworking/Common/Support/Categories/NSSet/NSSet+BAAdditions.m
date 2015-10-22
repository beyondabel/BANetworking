//
//  NSSet+BAAdditions.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSSet+BAAdditions.h"

@implementation NSSet (BAAdditions)

- (instancetype)ba_mappedSetWithBlock:(id (^)(id obj))block {
    NSParameterAssert(block);
    
    NSMutableSet *mutSet = [[NSMutableSet alloc] initWithCapacity:[self count]];
    for (id object in self) {
        id mappedObject = block(object);
        if (mappedObject) {
            [mutSet addObject:mappedObject];
        }
    }
    
    return [mutSet copy];
}

- (instancetype)ba_filteredSetWithBlock:(BOOL (^)(id obj))block {
    NSParameterAssert(block);
    
    return [self ba_mappedSetWithBlock:^id(id obj) {
        return block(obj) ? obj : nil;
    }];
}

@end

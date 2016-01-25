//
//  NSArray+BAAdditions.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSArray+BAAdditions.h"

@implementation NSArray (BAAdditions)

- (instancetype)ba_mappedArrayWithBlock:(id (^)(id obj))block {
    NSParameterAssert(block);
    
    NSMutableArray *mutArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
    for (id object in self) {
        id mappedObject = block(object);
        if (mappedObject) {
            [mutArray addObject:mappedObject];
        }
    }
    
    return [mutArray copy];
}

- (instancetype)ba_filteredArrayWithBlock:(BOOL (^)(id obj))block {
    NSParameterAssert(block);
    
    return [self ba_mappedArrayWithBlock:^id(id obj) {
        return block(obj) ? obj : nil;
    }];
}

- (id)ba_reducedValueWithInitialValue:(id)initialValue block:(id (^)(id reduced, id obj))block {
    NSParameterAssert(initialValue);
    NSParameterAssert(block);
    
    id result = initialValue;
    
    for (id element in self) {
        result = block(result, element);
    }
    
    return result;
}

- (id)ba_reducedValueWithBlock:(id (^)(id reduced, id obj))block {
    NSParameterAssert(block);
    
    id result = [self firstObject];
    
    for (NSUInteger i = 1; i < [self count]; ++i) {
        result = block(result, self[i]);
    }
    
    return result;
}

- (id)ba_firstObjectPassingTest:(BOOL (^)(id obj))block {
    NSParameterAssert(block);
    
    __block id object = nil;
    [self enumerateObjectsUsingBlock:^(id currentObject, NSUInteger idx, BOOL *stop) {
        if (block(currentObject)) {
            object = currentObject;
            *stop = YES;
        }
    }];
    
    return object;
}

+ (instancetype)ba_arrayFromRange:(NSRange)range {
    NSUInteger min = range.location;
    NSUInteger max = range.location + range.length;
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:range.length];
    for (NSUInteger i = min; i < max; ++i) {
        [array addObject:@(i)];
    }
    
    return [array copy];
}

@end

//
//  NSValueTransformer+BATransformers.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSValueTransformer+BATransformers.h"
#import "BAConstants.h"
#import "BANumberValueTransformer.h"
#import "BAURLValueTransformer.h"
#import "BAModelValueTransformer.h"

@implementation NSValueTransformer (BATransformers)

+ (NSValueTransformer *)ba_transformerWithBlock:(BAValueTransformationBlock)block {
    return [BABlockValueTransformer transformerWithBlock:block];
}

+ (NSValueTransformer *)ba_transformerWithModelClass:(Class)modelClass {
    return [BAModelValueTransformer transformerWithModelClass:modelClass];
}

+ (NSValueTransformer *)ba_URLTransformer {
    return [BAURLValueTransformer new];
}


+ (NSValueTransformer *)ba_numberValueTransformer {
    return [BANumberValueTransformer new];
}

@end

//
//  NSValueTransformer+BATransformers.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BABlockValueTransformer.h"

@interface NSValueTransformer (BATransformers)

+ (NSValueTransformer *)ba_transformerWithBlock:(BAValueTransformationBlock)block;

+ (NSValueTransformer *)ba_transformerWithModelClass:(Class)modelClass;

@end

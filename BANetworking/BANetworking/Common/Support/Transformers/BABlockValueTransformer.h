//
//  BABlockValueTransformer.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^BAValueTransformationBlock) (id value);

@interface BABlockValueTransformer : NSValueTransformer

- (instancetype)initWithBlock:(BAValueTransformationBlock)block;

+ (instancetype)transformerWithBlock:(BAValueTransformationBlock)block;

@end

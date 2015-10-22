//
//  BABlockValueTransformer.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BABlockValueTransformer.h"

@interface BABlockValueTransformer ()

@property (nonatomic, copy) BAValueTransformationBlock transformBlock;

@end

@implementation BABlockValueTransformer

- (instancetype)init {
  return [self initWithBlock:nil];
}

- (instancetype)initWithBlock:(BAValueTransformationBlock)block {
  self = [super init];
  if (!self) return nil;
  
  _transformBlock = [block copy];
  
  return self;
}

+ (instancetype)transformerWithBlock:(BAValueTransformationBlock)block {
  return [[self alloc] initWithBlock:block];
}

#pragma mark - NSValueTransformer

+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  return self.transformBlock ? self.transformBlock(value) : nil;
}

@end

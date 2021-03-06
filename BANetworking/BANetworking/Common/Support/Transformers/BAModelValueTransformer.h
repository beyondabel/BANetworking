//
//  BAModelValueTransformer.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAModelValueTransformer : NSValueTransformer

- (instancetype)initWithModelClass:(Class)modelClass;

+ (instancetype)transformerWithModelClass:(Class)modelClass;

@end

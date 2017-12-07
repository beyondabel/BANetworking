//
//  AutoModel.m
//  BANetworking
//
//  Created by abel on 16/4/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "AutoModel.h"
#import "NSValueTransformer+BATransformers.h"

@implementation AutoModel

+ (NSDictionary *)dictionaryClassForPropertyNames {
    return @{
             @"array" : AutoModel.class
             };
}

@end

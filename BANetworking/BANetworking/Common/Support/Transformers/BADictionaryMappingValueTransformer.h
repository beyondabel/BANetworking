//
//  BADictionaryMappingValueTransformer.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BADictionaryMappingValueTransformer : NSValueTransformer

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

+ (instancetype)transformerWithDictionary:(NSDictionary *)dictionary;

@end

//
//  BADictionaryMappingValueTransformer.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BADictionaryMappingValueTransformer.h"

@interface BADictionaryMappingValueTransformer ()

@property (nonatomic, copy) NSDictionary *mappingDictionary;
@property (nonatomic, copy, readonly) NSDictionary *reverseMappingDictionary;

@end

@implementation BADictionaryMappingValueTransformer

@synthesize reverseMappingDictionary = _reverseMappingDictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return nil;
    
    _mappingDictionary = [dictionary copy];
    
    return self;
}

+ (instancetype)transformerWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

#pragma mark - Properties

- (NSDictionary *)reverseMappingDictionary {
    if (!_reverseMappingDictionary) {
        NSMutableDictionary *mutReverseDictionary = [NSMutableDictionary dictionary];
        [self.mappingDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(NSCopying)]) {
                mutReverseDictionary[obj] = key;
            }
        }];
        
        _reverseMappingDictionary = [mutReverseDictionary copy];
    }
    
    return _reverseMappingDictionary;
}

#pragma mark - NSValueTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    return self.mappingDictionary[value];
}

- (id)reverseTransformedValue:(id)value {
    return self.reverseMappingDictionary[value];
}

@end

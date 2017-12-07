//
//  BAModel.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <objc/runtime.h>
#import "BAModel.h"
#import "NSObject+BAIntrospection.h"

@interface BAModel ()

@property (nonatomic, copy, readonly) NSArray *codablePropertyNames;

@end

@implementation BAModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return nil;
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        [self updateFromDictionary:dictionary];
    }
    
    return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (!self) return nil;
    
    for (NSString *propertyName in self.codablePropertyNames) {
        id value = [coder decodeObjectForKey:propertyName];
        [self setValue:value forKey:propertyName];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    for (NSString *propertyName in self.codablePropertyNames) {
        id value = [self valueForKey:propertyName];
        [coder encodeObject:value forKey:propertyName];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] init];
    
    for (NSString *key in [self codablePropertyNames]) {
        id value = [self valueForKey:key];
        [copy setValue:value forKey:key];
    }
    
    return copy;
}

#pragma mark - Public

+ (NSDictionary *)dictionaryKeyPathsForPropertyNames {
    return nil;
}

+ (NSDictionary *)dictionaryClassForPropertyNames {
    return nil;
}

#pragma mark - Mapping

+ (NSDictionary *)dictionaryKeyPathsForPropertyNamesForClassAndSuperClasses {
    NSMutableDictionary *keyPathsMapping = [NSMutableDictionary new];
    
    Class klass = self;
    while (klass != [BAModel class]) {
        NSDictionary *klassKeyPaths = [klass dictionaryKeyPathsForPropertyNames];
        if (klass) {
            [keyPathsMapping addEntriesFromDictionary:klassKeyPaths];
        }
        
        klass = [klass superclass];
    }
    
    return [keyPathsMapping copy];
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    NSDictionary *keyPathMapping = [[self class] dictionaryKeyPathsForPropertyNamesForClassAndSuperClasses];
    
    NSDictionary *proertyDictionary = [[self class] propertyTypeDictionary];
    
    for (NSString *propertyName in self.codablePropertyNames) {
        // Should this property be mapped?
        NSString *keyPath = [keyPathMapping objectForKey:propertyName];
        if (!keyPath) {
            keyPath = propertyName;
        }
        
        id value = [dictionary valueForKeyPath:keyPath];
        if (value && value == NSNull.null) {
            // NSNull should be treated as nil
            value = nil;
        }
        
        NSLog(@"propertyName = %@  :  proertyDictionary = %@", propertyName, proertyDictionary[propertyName]);
        if (value) {
            if ([proertyDictionary[propertyName] isEqualToString:@"NSString"]) {
                [self setValue:[NSString stringWithFormat:@"%@", value] forKey:propertyName];
            } else if ([proertyDictionary[propertyName] isEqualToString:@"NSNumber"]) {
                if ([value isKindOfClass:[NSString class]]) {
                    value = [NSNumber numberWithInteger:[value integerValue]];
                }
                if ([value isKindOfClass:[NSNumber class]]) {
                    [self setValue:value forKey:propertyName];
                }
            } else if ([proertyDictionary[propertyName] isEqualToString:@"q"] || [proertyDictionary[propertyName] isEqualToString:@"i"] || [proertyDictionary[propertyName] isEqualToString:@"s"]) {
                if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
                    [self setValue:value forKey:propertyName];
                }
            } else if ([proertyDictionary[propertyName] isEqualToString:@"f"] || [proertyDictionary[propertyName] isEqualToString:@"d"]) {
                if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
                    [self setValue:value forKey:propertyName];
                }
            } else if ([proertyDictionary[propertyName] isEqualToString:@"b"] || [proertyDictionary[propertyName] isEqualToString:@"B"]) {
                if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
                    [self setValue:value forKey:propertyName];
                }
            } else if ([proertyDictionary[propertyName] isEqualToString:@"NSDictionary"] || [proertyDictionary[propertyName] isEqualToString:@"NSMutableDictionary"] ) {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    [self setValue:value forKey:propertyName];
                }
            } else if ([proertyDictionary[propertyName] isEqualToString:@"NSArray"] || [proertyDictionary[propertyName] isEqualToString:@"NSMutableArray"]) {
                if ([value isKindOfClass:[NSArray class]]) {
                    Class className = [[self class] dictionaryClassForPropertyNames][propertyName];
                    if (className) {
                        [self setValue:[self mapTransforForArray:value className:className] forKey:propertyName];
                    } else {
                        [self setValue:value forKey:propertyName];
                    }
                }
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                NSString *className = proertyDictionary[propertyName];
                BAModel *model = [[NSClassFromString(className) alloc] init];
                if (model) {
                    [model updateFromDictionary:value];
                    [self setValue:model forKey:propertyName];
                }
            }
        }
    }
}

- (void)setNilValueForKey:(NSString *)key {
    [self setValue:@0 forKey:key];
}

#pragma mark - Introspection

+ (NSArray *)codablePropertyNames {
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(self, &propertyCount);
    
    NSMutableArray *mutPropertyNames = [NSMutableArray arrayWithCapacity:propertyCount];
    
    for (int i = 0; i < propertyCount; ++i) {
        // Find all properties, backed by an ivar and with a KVC-compliant name
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        NSString *propertyName = @(name);
        
        // Check if there is a backing ivar
        char *ivar = property_copyAttributeValue(property, "V");
        if (ivar) {
            // Check if ivar has KVC-compliant name, i.e. either propertyName or _propertyName
            NSString *ivarName = @(ivar);
            if ([ivarName isEqualToString:propertyName] ||
                [ivarName isEqualToString:[@"_" stringByAppendingString:propertyName]]) {
                // setValue:forKey: will work
                [mutPropertyNames addObject:propertyName];
            }
            
            free(ivar);
        }
    }
    
    free(properties);
    
    return [mutPropertyNames copy];
}

- (NSArray *)codablePropertyNames {
    NSArray *propertyNames = objc_getAssociatedObject([self class], _cmd);
    if (propertyNames) {
        return propertyNames;
    }
    
    NSMutableArray *mutPropertyNames = [NSMutableArray array];
    
    Class klass = [self class];
    while (klass != [NSObject class]) {
        NSArray *classPropertyNames = [klass codablePropertyNames];
        [mutPropertyNames addObjectsFromArray:classPropertyNames];
        
        klass = [klass superclass];
    }
    
    propertyNames = [mutPropertyNames copy];
    objc_setAssociatedObject([self class], _cmd, propertyNames, OBJC_ASSOCIATION_COPY);
    
    return propertyNames;
}

+ (NSDictionary *)propertyTypeDictionary {
    NSMutableDictionary *propertyDictionary = [NSMutableDictionary dictionary];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    if (properties) {
        for (unsigned int i = 0; i < propertyCount; i++) {
            if (!properties[i]) break;
            
            const char *name = property_getName(properties[i]);
            unsigned int attrCount;
            objc_property_attribute_t *attrs = property_copyAttributeList(properties[i], &attrCount);
            for (unsigned int i = 0; i < attrCount; i++) {
                if (attrs[i].name[0] == 'T') {
                    if (attrs[i].value) {
                        NSString *typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                        typeEncoding = [[typeEncoding stringByReplacingOccurrencesOfString:@"@\"" withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        if (name && typeEncoding) {
                            [propertyDictionary setObject:typeEncoding forKey:[NSString stringWithUTF8String:name]];
                        }
                        
                        break;
                    }
                }
            }
            
            if (attrs) {
                free(attrs);
                attrs = NULL;
            }
        }
        free(properties);
    }
    
    if (class_getSuperclass([self class]) != [NSObject class]) {
        // 加上父类的属性描述器
        [propertyDictionary addEntriesFromDictionary:[class_getSuperclass([self class]) propertyTypeDictionary]];
    }
    
    return propertyDictionary;
}

- (BOOL)typeMatchingWithType:(NSString *)type value:(id)value {
        NSLog(@"type = %@ value = %@", type, value);
    if ([value isKindOfClass:[NSString class]]) {
        if ([type isEqualToString:@"NSString"] || [type isEqualToString:@"i"]  || [type isEqualToString:@"d"] || [type isEqualToString:@"q"] || [type isEqualToString:@"B"]|| [type isEqualToString:@"f"]) {
            return YES;
        }
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if ([type isEqualToString:@"NSNumber"] || [type isEqualToString:@"i"] || [type isEqualToString:@"d"] || [type isEqualToString:@"q"] || [type isEqualToString:@"B"]) {
            return YES;
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        if ([type isEqualToString:@"NSArray"]) {
            return YES;
        }
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        if ([type isEqualToString:@"NSDictionary"]  || [[NSClassFromString(type) alloc] isKindOfClass:[BAModel class]]) {
            return YES;
            
        }
    } else if ([[NSString stringWithUTF8String:object_getClassName(value)] isEqualToString:type]) {
        return YES;
    }
    
    return NO;
}

- (NSArray *)mapTransforForArray:(NSArray *)array className:(Class)className {
    NSMutableArray *mapObjectArray = [NSMutableArray array];
    for (NSInteger index = 0; index < array.count; index ++) {
        NSObject *object = array[index];
        if ([object isKindOfClass:[NSDictionary class]]) {
            BAModel *model = [[className alloc] init];
            [model updateFromDictionary:(NSDictionary *)object];
            [mapObjectArray addObject:model];
        } else if ([object isKindOfClass:[NSArray class]]) {
            [mapObjectArray addObject:[self mapTransforForArray:(NSArray *)object className:className]];
        }
    }
    return mapObjectArray;
}

#pragma mark - Value transformation

+ (NSValueTransformer *)valueTransformerForKey:(NSString *)key dictionary:(NSDictionary *)dictionary {
    // Try the <propertyName>ValueTransformerWithDictionary: selector
    NSString *transformerSelectorName = [key stringByAppendingString:@"ValueTransformerWithDictionary:"];
    NSValueTransformer *transformer = [self ba_valueByPerformingSelectorWithName:transformerSelectorName withObject:dictionary];
    
    // Try the <propertyName>ValueTransformer selector
    if (!transformer) {
        transformerSelectorName = [key stringByAppendingString:@"ValueTransformer"];
        transformer = [self ba_valueByPerformingSelectorWithName:transformerSelectorName];
    }
    
    return transformer;
}

#pragma mark - NSObject

- (NSUInteger)hash {
    NSUInteger value = 0;
    
    for (NSString *key in self.codablePropertyNames) {
        value ^= [[self valueForKey:key] hash];
    }
    
    return value;
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isMemberOfClass:self.class]) return NO;
    
    for (NSString *key in self.codablePropertyNames) {
        id selfValue = [self valueForKey:key];
        id objectValue = [object valueForKey:key];
        
        BOOL valuesEqual = ((selfValue == nil && objectValue == nil) || [selfValue isEqual:objectValue]);
        if (!valuesEqual) return NO;
    }
    
    return YES;
}


@end

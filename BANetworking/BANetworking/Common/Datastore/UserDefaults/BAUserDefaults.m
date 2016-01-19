//
//  BAUserDefaults.m
//  PersonToPerson
//
//  Created by abel on 15/9/17.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAUserDefaults.h"

@implementation BAUserDefaults

- (instancetype)init {
    return [self initWithService:nil accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service {
    return [self initWithService:service accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup {
    NSParameterAssert(service);
    
    self = [super init];
    if (!self) return nil;
    
//    _service = [service copy];
//    _accessGroup = [accessGroup copy];
//    
    return self;
}

+ (instancetype)keychainForService:(NSString *)service accessGroup:(NSString *)accessGroup {
    return [[self alloc] initWithService:service accessGroup:accessGroup];
}

#pragma mark - Keychain access

+ (id)objectForKey:(id)key {
    NSParameterAssert(key);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [userDefaults objectForKey:key];
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return object;
}


+ (BOOL)setObject:(id<NSCoding>)object ForKey:(id)key {
    NSParameterAssert(key);
    
    BOOL success = YES;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:data forKey:key];
    
    return success;
}

+ (void)removeObjectForKey:(id)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:key];
}

@end

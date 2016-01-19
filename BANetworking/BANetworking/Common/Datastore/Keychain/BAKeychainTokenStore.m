//
//  BAKeychainTokenStore.m
//  BAbelKit
//
//  Created by Abel on 10/06/14.
//  Copyright (c) 2014 Abel, Inc. All rights reserved.
//

#import "BAKeychainTokenStore.h"
#import "BAKeychain.h"

static NSString * const kTokenKeychainKey = @"BAbelKitOAuthToken";

@interface BAKeychainTokenStore ()

@end

@implementation BAKeychainTokenStore

- (instancetype)initWithService:(NSString *)service {
    return [self initWithService:service accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup {
    BAKeychain *keychain = [BAKeychain keychainForService:service accessGroup:accessGroup];
    return [self initWithKeychain:keychain];
}

- (instancetype)initWithKeychain:(BAKeychain *)keychain {
    self = [super init];
    if (!self) return nil;
    
    _keychain = keychain;
    
    return self;
}

#pragma mark - BATokenStore

- (void)storeToken:(BAOAuth2Token *)token {
    [self.keychain setObject:token ForKey:kTokenKeychainKey];
}

- (void)deleteStoredToken {
    [self.keychain removeObjectForKey:kTokenKeychainKey];
}

- (BAOAuth2Token *)storedToken {
    return [self.keychain objectForKey:kTokenKeychainKey];
}

@end

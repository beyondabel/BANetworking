//
//  BANetworking.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BANetworking.h"
#import "BAClient.h"

@implementation BANetworking

+ (void)setupWithAPIKey:(NSString *)key secret:(NSString *)secret {
    [[BAClient currentClient] setupWithAPIKey:key secret:secret];
}

+ (BAAsyncTask *)authenticateAsUserWithAccount:(NSString *)account password:(NSString *)password {
    return [[BAClient currentClient] authenticateAsUserWithEmail:account password:password];
}

+ (BOOL)isAuthenticated {
    return [[BAClient currentClient] isAuthenticated];
}


+ (void)automaticallyStoreTokenInKeychainForServiceWithName:(NSString *)name {
//    [BAClient currentClient].tokenStore = [[BAKeychainTokenStore alloc] initWithService:name];
    [[BAClient currentClient] restoreTokenIfNeeded];
}

+ (void)automaticallyStoreTokenInKeychainForCurrentApp {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge id)kCFBundleIdentifierKey];
    [self automaticallyStoreTokenInKeychainForServiceWithName:name];
}


+ (void)automaticallyStoreTokenInUserDefaultsForServiceWithName:(NSString *)name {

}

+ (void)automaticallyStoreTokenInUserDefaultsForCurrentApp {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge id)kCFBundleIdentifierKey];
    [self automaticallyStoreTokenInUserDefaultsForServiceWithName:name];
}

@end

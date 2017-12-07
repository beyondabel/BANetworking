//
//  BANetworking.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAAsyncTask;

@interface BANetworking : NSObject

/** Informs the caller whether the default client is authenticated or not, i.e. has an active OAuth token.
 *
 * @return YES if the default client is authenticated, otherwise NO.
 */
+ (BOOL)isAuthenticated;

/*
 * Configure the default client with http header userAgent.
 */
+ (void)setupUserAgent:(NSString *)userAgent;

/**
 *  Configure the default Debug to NO
 *  set the debug request.
 */
+ (void)setDebugEnabled:(BOOL)value;

/** Configure the default client to store the OAuth token in the user Keychain.
 *
 * @param name The Service name to use when storing the token in the keychain.
 */
+ (void)automaticallyStoreTokenInKeychainForServiceWithName:(NSString *)name;

/** Configure the default client to store the OAuth token in the user Keychain. The bundle identifier will be used as the Service name for this Keychain item.
 */
+ (void)automaticallyStoreTokenInKeychainForCurrentApp;

/** Configure the default client to store the OAuth token in the user UserDefaults.
 *
 * @param name The Service name to use when storing the token in the UserDefaults.
 */
+ (void)automaticallyStoreTokenInUserDefaultsForServiceWithName:(NSString *)name;

/** Configure the default client to store the OAuth token in the user UserDefaults. The bundle identifier will be used as the Service name for this UserDefaults item.
 */
+ (void)automaticallyStoreTokenInUserDefaultsForCurrentApp;

@end

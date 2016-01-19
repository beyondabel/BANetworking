//
//  BAKeychainTokenStore.h
//  BAbelKit
//
//  Created by Abel on 10/06/14.
//  Copyright (c) 2014 Abel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BATokenStore.h"

@class BAKeychain;

@interface BAKeychainTokenStore : NSObject <BATokenStore>

@property (nonatomic, strong, readonly) BAKeychain *keychain;

- (instancetype)initWithService:(NSString *)service;

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup;

- (instancetype)initWithKeychain:(BAKeychain *)keychain;

@end

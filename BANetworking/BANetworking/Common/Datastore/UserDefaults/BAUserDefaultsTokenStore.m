//
//  BAUserDefaultsTokenStore.m
//  PersonToPerson
//
//  Created by abel on 15/9/18.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAUserDefaultsTokenStore.h"
#import "BAOAuth2Token.h"

static NSString * const kUserDefaultsTokenKey = @"BAbelKitOAuthToken";

@implementation BAUserDefaultsTokenStore

- (instancetype)initWithService:(NSString *)service {
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - BATokenStore

- (void)storeToken:(BAOAuth2Token *)token {
    [BAUserDefaults setObject:token ForKey:kUserDefaultsTokenKey];
}

- (void)deleteStoredToken {
    [BAUserDefaults removeObjectForKey:kUserDefaultsTokenKey];
}

- (BAOAuth2Token *)storedToken {
    return [BAUserDefaults objectForKey:kUserDefaultsTokenKey];
}

@end

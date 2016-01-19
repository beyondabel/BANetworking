//
//  BAUserDefaultsTokenStore.h
//  PersonToPerson
//
//  Created by abel on 15/9/18.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAUserDefaults.h"
#import "BATokenStore.h"

@interface BAUserDefaultsTokenStore : NSObject <BATokenStore>

@property (nonatomic, strong, readonly) BAUserDefaults *keychain;

- (instancetype)initWithService:(NSString *)service;

@end

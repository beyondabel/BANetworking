//
//  BAUserDefaults.h
//  PersonToPerson
//
//  Created by abel on 15/9/17.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAUserDefaults : NSObject

+ (id)objectForKey:(id)key;

+ (BOOL)setObject:(id<NSCoding>)object ForKey:(id)key;

+ (void)removeObjectForKey:(id)key;

- (instancetype)initWithService:(NSString *)service;

@end

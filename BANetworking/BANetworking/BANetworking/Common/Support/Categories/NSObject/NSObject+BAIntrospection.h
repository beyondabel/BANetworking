//
//  NSObject+BAIntrospection.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BAIntrospection)

+ (id)ba_valueByPerformingSelectorWithName:(NSString *)selectorName;

+ (id)ba_valueByPerformingSelectorWithName:(NSString *)selectorName withObject:(id)object;

@end

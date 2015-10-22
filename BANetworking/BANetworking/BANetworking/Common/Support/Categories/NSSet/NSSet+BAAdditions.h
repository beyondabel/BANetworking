//
//  NSSet+BAAdditions.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSSet (BAAdditions)

- (instancetype)ba_mappedSetWithBlock:(id (^)(id obj))block;

- (instancetype)ba_filteredSetWithBlock:(BOOL (^)(id obj))block;

@end

//
//  BAURLValueTransformer.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAURLValueTransformer.h"

@implementation BAURLValueTransformer

- (instancetype)init {
  return [super initWithBlock:^id(NSString *URLString) {
    return [NSURL URLWithString:URLString];
  }];
}

@end

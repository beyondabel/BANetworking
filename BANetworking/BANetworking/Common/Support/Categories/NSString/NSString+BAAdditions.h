//
//  NSString+BAAdditions.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BAAdditions)

+ (instancetype)ba_randomHexStringOfLength:(NSUInteger)length;

- (BOOL)ba_containsString:(NSString *)string;

- (NSString *)ba_base64String;



@end

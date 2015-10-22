//
//  NSNumber(BAAdditions) 
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface NSNumber (BAAdditions)

+ (NSNumber *)ba_numberFromUSNumberString:(NSString *)numberString;
- (NSString *)ba_USNumberString;

@end
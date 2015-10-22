//
//  NSNumberFormatter(BAAdditions) 
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//


#import "NSNumberFormatter+BAAdditions.h"

@implementation NSNumberFormatter (BAAdditions)

+ (NSNumberFormatter *)ba_USNumberFormatter {
  NSNumberFormatter *formatter = [NSNumberFormatter new];
  formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  formatter.numberStyle = NSNumberFormatterDecimalStyle;
  formatter.usesGroupingSeparator = NO;

  return formatter;
}

@end
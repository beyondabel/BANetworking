//
//  NSNumber(BAAdditions) 
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//


#import "NSNumber+BAAdditions.h"
#import "NSNumberFormatter+BAAdditions.h"

static NSNumberFormatter *sNumberFormatter = nil;

@implementation NSNumber (BAAdditions)

+ (NSNumber *)ba_numberFromUSNumberString:(NSString *)numberString {
  return [[self ba_USNumberFormatter] numberFromString:numberString];
}

- (NSString *)ba_USNumberString {
  return [[[self class] ba_USNumberFormatter] stringFromNumber:self];
}

+ (NSNumberFormatter *)ba_USNumberFormatter {
  if (!sNumberFormatter) {
    sNumberFormatter = [NSNumberFormatter ba_USNumberFormatter];
  }

  return sNumberFormatter;
}

@end
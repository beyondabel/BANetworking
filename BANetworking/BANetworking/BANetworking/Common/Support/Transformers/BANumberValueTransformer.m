//
//  BANumberValueTransformer 
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BANumberValueTransformer.h"
#import "NSNumber+BAAdditions.h"


@implementation BANumberValueTransformer

#pragma mark - NSValueTransformer

+ (BOOL)allowsReverseTransformation {
  return YES;
}

- (id)reverseTransformedValue:(id)value {
  if (![value isKindOfClass:[NSNumber class]]) {
       return nil;
  }

  return [(NSNumber *)value ba_USNumberString];
}

- (id)transformedValue:(id)value {
  if (![value isKindOfClass:[NSString class]]) {
    return nil;
  }

  return [NSNumber ba_numberFromUSNumberString:value];
}


@end
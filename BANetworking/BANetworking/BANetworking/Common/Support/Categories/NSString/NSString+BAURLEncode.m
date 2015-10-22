//
//  NSString+BAURLEncode.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "NSString+BAURLEncode.h"

@implementation NSString (BAURLEncode)

- (NSString *)ba_encodeString {
  NSString *escapedString = (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                                   (__bridge CFStringRef)self,
                                                                                                   NULL,
                                                                                                   (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                                                   kCFStringEncodingUTF8);
  return escapedString;
}

- (NSString *)ba_decodeString {
  NSString *escapedString = (__bridge_transfer NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                                   (__bridge CFStringRef)self,
                                                                                                                   CFSTR(""),
                                                                                                                   kCFStringEncodingUTF8);
  return escapedString;
}

@end

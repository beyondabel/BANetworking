//
//  NSDate+BAAdditions.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (BAAdditions)

+ (NSDate *)ba_dateFromUTCDateString:(NSString *)dateString;
+ (NSDate *)ba_dateFromUTCDateTimeString:(NSString *)dateTimeString;

- (NSString *)ba_UTCDateString;
- (NSString *)ba_UTCDateTimeString;

@end

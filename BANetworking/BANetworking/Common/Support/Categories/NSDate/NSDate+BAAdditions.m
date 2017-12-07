//
//  NSDate+BAAdditions.m
//  PodioKit
//
//  Created by Sebastian Rehnby on 08/05/14.
//  Copyright (c) 2014 Citrix Systems, Inc. All rights reserved.
//

#import "NSDate+BAAdditions.h"
#import "NSDateFormatter+BAAdditions.h"

static NSDateFormatter *sUTCDateFormatter = nil;
static NSDateFormatter *sUTCDateTimeFormatter = nil;

@implementation NSDate (BAAdditions)

#pragma mark - Public

+ (NSDate *)ba_dateFromUTCDateString:(NSString *)dateString {
    return [[self UTCDateFormatter] dateFromString:dateString];
}

+ (NSDate *)ba_dateFromUTCDateTimeString:(NSString *)dateTimeString {
    return [[self UTCDateTimeFormatter] dateFromString:dateTimeString];
}

- (NSString *)ba_UTCDateString {
    return [[[self class] UTCDateFormatter] stringFromDate:self];
}

- (NSString *)ba_UTCDateTimeString {
    return [[[self class] UTCDateTimeFormatter] stringFromDate:self];
}

#pragma mark - Private

+ (NSDateFormatter *)UTCDateFormatter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sUTCDateFormatter = [NSDateFormatter ba_UTCDateFormatter];
    });
    
    return sUTCDateFormatter;
}

+ (NSDateFormatter *)UTCDateTimeFormatter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sUTCDateTimeFormatter = [NSDateFormatter ba_UTCDateTimeFormatter];
    });
    
    return sUTCDateTimeFormatter;
}

@end

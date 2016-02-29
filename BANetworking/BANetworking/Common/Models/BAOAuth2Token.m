//
//  BAOAuth2Token.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAOAuth2Token.h"
#import "NSValueTransformer+BATransformers.h"

@implementation BAOAuth2Token


- (instancetype)initWithAccessToken:(NSString *)accessToken
                       refreshToken:(NSString *)refreshToken
                      transferToken:(NSString *)transferToken
                          expiresOn:(NSDate *)expiresOn
                            refData:(NSDictionary *)refData {
    self = [super init];
    if (!self) return nil;
    
    _accessToken = [accessToken copy];
    _refreshToken = [refreshToken copy];
    _transferToken = [transferToken copy];
    _expiresOn = [expiresOn copy];
    _refData = [refData copy];
    
    return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    
    return [self.accessToken isEqualToString:[object accessToken]];
}

- (NSUInteger)hash {
    return [self.accessToken hash];
}

#pragma mark - BAModel

+ (NSDictionary *)dictionaryKeyPathsForPropertyNames {
    return @{
             @"accessToken": @"token",
             };
}

+ (NSValueTransformer *)expiresOnValueTransformer {
    return [NSValueTransformer ba_transformerWithBlock:^id(NSNumber *expiresIn) {
        return [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
    }];
}

#pragma mark - Public

- (BOOL)willExpireWithinIntervalFromNow:(NSTimeInterval)expireInterval {
    return NO;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:expireInterval];
    return [self.expiresOn earlierDate:date] == self.expiresOn;
}

@end

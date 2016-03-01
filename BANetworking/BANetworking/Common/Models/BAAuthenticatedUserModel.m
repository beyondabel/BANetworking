//
//  BAOAuth2Token.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAAuthenticatedUserModel.h"
#import "NSValueTransformer+BATransformers.h"

@implementation BAAuthenticatedUserModel

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
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:expireInterval];
    return [self.expiresOn earlierDate:date] == self.expiresOn;
}

@end

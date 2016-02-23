//
//  BAUserModel.m
//  BANetworking
//
//  Created by abel on 16/1/21.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "BAUserModel.h"
#import "NSValueTransformer+BATransformers.h"

@implementation BAUserModel

+ (NSDictionary *)dictionaryKeyPathsForPropertyNames {
    return @{
             @"userID" : @"user_id",
             @"userName" : @"user_name",
             @"sex" : @"sex",
             @"appModel" : @"app",
             };
}

+ (NSValueTransformer *)appModelValueTransformer {
    return [NSValueTransformer ba_transformerWithModelClass:[BAAppModel class]];
}

@end


@implementation BAAppModel

+ (NSDictionary *)dictionaryKeyPathsForPropertyNames {
    return @{
             @"appID" : @"app_id",
             @"appName" : @"app_name",
             @"link" : @"link",
             };
}



@end
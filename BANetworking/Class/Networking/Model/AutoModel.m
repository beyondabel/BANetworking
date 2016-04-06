//
//  AutoModel.m
//  BANetworking
//
//  Created by abel on 16/4/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "AutoModel.h"

@implementation AutoModel

+ (NSDictionary *)dictionaryKeyPathsForPropertyNames {
    return @{
                @"accessToken": @"token",
             };
}

@end

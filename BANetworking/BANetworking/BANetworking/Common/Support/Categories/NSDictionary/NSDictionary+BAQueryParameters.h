//
//  NSDictionary+BAQueryParameters.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (BAQueryParameters)

- (NSString *)ba_queryString;
- (NSString *)ba_escapedQueryString;
- (NSDictionary *)ba_queryParametersPairs;
- (NSDictionary *)ba_escapedQueryParametersPairs;

@end

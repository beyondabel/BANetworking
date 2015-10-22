//
//  BAResponse.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAResponse : NSObject

@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, copy, readonly) id body;

- (instancetype)initWithStatusCode:(NSInteger)statusCode body:(id)body;

@end

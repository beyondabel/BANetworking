//
//  BAUserModel.h
//  BANetworking
//
//  Created by abel on 16/1/21.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "BAModel.h"

@class BAAppModel;

@interface BAUserModel : BAModel

@property (nonatomic, assign, readonly) NSInteger userID;
@property (nonatomic, strong, readonly) NSString *userName;
@property (nonatomic, strong, readonly) NSString *sex;
@property (nonatomic, strong, readonly) BAAppModel *appModel;

@end



@interface BAAppModel : BAModel

@property (nonatomic, assign, readonly) NSInteger appID;
@property (nonatomic, strong, readonly) NSString *appName;
@property (nonatomic, strong, readonly) NSString *link;

@end
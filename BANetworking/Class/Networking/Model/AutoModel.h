//
//  AutoModel.h
//  BANetworking
//
//  Created by abel on 16/4/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "BAAuthenticatedModel.h"

@interface AutoModel : BAAuthenticatedModel

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSNumber *age;
@property (nonatomic, strong) AutoModel *autoModel;
@property (nonatomic, strong) NSArray *array;

@property (nonatomic, assign) long sex;
@property (nonatomic, assign) BOOL week;



//NSLog(@"The size of a char is: %lu bytes.",sizeof(char));
//NSLog(@"The size of a bool is: %lu bytes.",sizeof(bool));   // Do any additional setup after loading the view,
//4、 NSUInteger


@end

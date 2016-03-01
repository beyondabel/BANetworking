//
//  BATokenStore.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAAuthenticatedUserModel.h"

@protocol BATokenStore <NSObject>

- (void)storeToken:(BAAuthenticatedUserModel *)token;

- (void)deleteStoredToken;

- (BAAuthenticatedUserModel *)storedToken;

@end

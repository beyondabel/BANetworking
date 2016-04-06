//
//  BATokenStore.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAAuthenticatedModel.h"

@protocol BATokenStore <NSObject>

- (void)storeToken:(BAAuthenticatedModel *)token;

- (void)deleteStoredToken;

- (BAAuthenticatedModel *)storedToken;

@end

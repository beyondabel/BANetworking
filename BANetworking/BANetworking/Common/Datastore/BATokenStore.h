//
//  BATokenStore.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAOAuth2Token.h"

@protocol BATokenStore <NSObject>

- (void)storeToken:(BAOAuth2Token *)token;

- (void)deleteStoredToken;

- (BAOAuth2Token *)storedToken;

@end

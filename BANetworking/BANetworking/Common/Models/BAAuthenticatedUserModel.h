//
//  BAOAuth2Token.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAModel.h"

@interface BAAuthenticatedUserModel : BAModel

/**
 *  The access token used for API access.
 */
@property (nonatomic, copy, readonly) NSString *accessToken;



/**
 *  The date representing the point in time at which the token will expire.
 */
@property (nonatomic, copy, readonly) NSDate *expiresOn;

/**
 *  Convenience method to check whether or not the token will expire within the provided interval.
 *
 *  @param expireInterval A time interval from now.
 *
 *  @return YES if the token will expire within the provided time interval, otherwise NO.
 */
- (BOOL)willExpireWithinIntervalFromNow:(NSTimeInterval)expireInterval;

@end

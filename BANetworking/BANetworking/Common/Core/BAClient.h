//
//  BAClient.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAHTTPClient.h"
#import "BAAsyncTask.h"

extern NSString * const BAClientAuthenticationStateDidChangeNotification;

@class BAAuthenticatedModel, BARequest;
@protocol BATokenStore;

@interface BAClient : NSObject

/**
 *  The HTTP client responsible for creating HTTP request.
 */
@property (nonatomic, strong, readonly) BAHTTPClient *HTTPClient;

/**
 *  The current Authenticated token used by the client. When not nil, the client is considered to be authenticated.
 */
@property (nonatomic, strong, readwrite) BAAuthenticatedModel *authenticatedUser;

/**
 *  A boolean indicating whether the client is currently authenticated, i.e. the oauthToken is non-nil.
 */
@property (nonatomic, assign, readonly) BOOL isAuthenticated;

/**
 *  A boolean indicating whether the debug request.
 */
@property (nonatomic, assign) BOOL debugEnabled;

/**
 *  An optional token store. A token store is an abstraction on top of any kind of storage to which the OAuth token
 *  can be persisted, e.g. the Keychain. A token store implementation for the iOS and OS X keychain is provided
 *  by the BAKeychainTokenStore class.
 *
 *  @see BAKeychainTokenStore
 */
@property (nonatomic, strong) id<BATokenStore> tokenStore;

/**
 *  The default API client.
 *
 *  @return The default client.
 */
+ (instancetype)defaultClient;

/**
 *  The current API client. The current client for a give scope can be changed by
 *  using the performBlock: method.
 *
 *  @see performBlock:
 *
 *  @return The current client.
 */
+ (instancetype)currentClient;

/**
 *  The designated initializer. Calling the default init method will instantiate a new HTTP client
 *  instance and pass it to this method.
 *
 *  @param client The HTTP client for the client to use for creating HTTP requests.
 *
 *  @return The initialized client.
 */
- (instancetype)initWithHTTPClient:(BAHTTPClient *)client;

/**
 *  Execute a block for which the current client is self. This is useful to force the use
 *  of a client instead of the default client for a certain scope, and enabled multiple clients to
 *  work in parallel.
 *
 *  @see currentClient
 *
 *  @param block The block for which the current client should be self.
 */
- (void)performBlock:(void (^)(void))block;

/** Authenticate the client as a user with an email and password.
 *
 *  @param email The user's email address
 *  @param password The user's password
 *
 *  @return The resulting task.
 */
- (BAAsyncTask *)authenticateAsUserWithEmail:(NSString *)email password:(NSString *)password;


- (void)setupAuthenticatedAnalysisClass:(Class)authenticatedClass authenticatedAPIClass:(Class)apiClass;

- (void)setupCommonParametersClass:(Class)commonClass;

- (void)setupUserAgent:(NSString *)userAgent;

/**
 *  Authenticate using a transfer token.
 *
 *  @param transferToken The transfer token.
 *
 *  @return The resulting task.
 */
- (BAAsyncTask *)authenticateWithTransferToken:(NSString *)transferToken;

/**
 *  Dispatches an HTTP request task for the provided request.
 *
 *  @param request    The request to perform.
 *
 *  @return The resulting task.
 */
- (BAAsyncTask *)performRequest:(BARequest *)request;

/**
 *  Dispatches an HTTP request task for the provided request.
 *
 *  @param request The request to perform.
 *
 *  @return The URL Request.
 */
- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request;

/**
 *  Will attempt to restore the OAuth token from the current tokenStore if one has been configured.
 *
 *  @see tokenStore
 */
- (void)restoreTokenIfNeeded;

@end

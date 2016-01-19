//
//  BAClient.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAClient.h"
#import "BAOAuth2Token.h"
#import "BATokenStore.h"
#import "BAAuthenticationAPI.h"
#import "BAMacros.h"
#import "NSMutableURLRequest+BAHeaders.h"
#import "NSError+BAErrors.h"

NSString * const BAClientAuthenticationStateDidChangeNotification = @"BAClientAuthenticationStateDidChangeNotification";

static void * kIsAuthenticatedContext = &kIsAuthenticatedContext;
static NSUInteger const kTokenExpirationLimit = 10 * 60; // 10 minutes

typedef NS_ENUM(NSUInteger, BAClientAuthRequestPolicy) {
    BAClientAuthRequestPolicyCancelPrevious = 0,
    BAClientAuthRequestPolicyIgnore,
};

/**
 *  A pending task represents a request that has been requested to be performed but not yet started.
 *  It might be started immediately or enqueued until the token has been successfully refreshed if expired.
 */
@interface BAPendingRequest : NSObject

@property (nonatomic, strong, readonly) BARequest *request;
@property (nonatomic, copy) BARequestCompletionBlock completionBlock;
@property (nonatomic, copy) BARequestProgressBlock progressBlock;
@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation BAPendingRequest {
    
    dispatch_once_t _startedOnceToken;
    dispatch_once_t _cancelledOnceToken;
}

- (instancetype)initWithRequest:(BARequest *)request progress:(BARequestProgressBlock)progress completion:(BARequestCompletionBlock)completion {
    self = [super init];
    if (!self) return nil;
    
    _request = request;
    _completionBlock = [completion copy];
    _progressBlock = [progress copy];
    
    return self;
}

/**
 *  Starts the pending task by requesting an NSURLSessionTask from the HTTP client and then
 *  resuming it.
 *
 *  @param client The HTTP client from which to request the NSURLSessionTask.
 */
- (void)startWithHTTPClient:(BAHTTPClient *)client {
    dispatch_once(&_startedOnceToken, ^{
        self.task = [client taskForRequest:self.request progress:self.progressBlock completion:self.completionBlock];
        self.completionBlock = nil;
        
        [self.task resume];
    });
}

/**
 *  Cancels the pending task by requesting an NSURLSessionTask from the HTTP client and then
 *  immediately cancel it.
 *
 *  @param client The HTTP client from which to request the NSURLSessionTask.
 */
- (void)cancelWithHTTPClient:(BAHTTPClient *)client {
    dispatch_once(&_cancelledOnceToken, ^{
        if (!self.task) {
            self.task = [client taskForRequest:self.request progress:self.progressBlock completion:self.completionBlock];
            self.completionBlock = nil;
        }
        
        [self.task cancel];
    });
}

@end

@interface BAClient ()

@property (nonatomic, copy, readwrite) NSString *apiKey;
@property (nonatomic, copy, readwrite) NSString *apiSecret;
@property (nonatomic, weak, readwrite) BAAsyncTask *authenticationTask;
@property (nonatomic, strong, readwrite) BARequest *savedAuthenticationRequest;
@property (nonatomic, strong, readonly) NSMutableOrderedSet *pendingRequests;

@end


@implementation BAClient

@synthesize pendingRequests = _pendingRequests;

+ (instancetype)defaultClient {
    static BAClient *defaultClient;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        defaultClient = [self new];
    });
    
    return defaultClient;
}

- (id)init {
    BAHTTPClient *httpClient = [BAHTTPClient new];
    BAClient *client = [self initWithHTTPClient:httpClient];
    
    return client;
}

- (instancetype)initWithHTTPClient:(BAHTTPClient *)client {
    @synchronized(self) {
        self = [super init];
        if (!self) return nil;
        
        _HTTPClient = client;
        
        [self updateAuthorizationHeader:self.isAuthenticated];
        
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(isAuthenticated)) options:NSKeyValueObservingOptionNew context:kIsAuthenticatedContext];
        
        return self;
    }
}

- (instancetype)initWithAPIKey:(NSString *)key secret:(NSString *)secret {
    BAClient *client = [self init];
    [client setupWithAPIKey:key secret:secret];
    
    return client;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(isAuthenticated)) context:kIsAuthenticatedContext];
}

#pragma mark - Properties

- (BOOL)isAuthenticated {
    return self.oauthToken != nil;
}

- (void)setOauthToken:(BAOAuth2Token *)oauthToken {
    if (oauthToken == _oauthToken) return;
    
    NSString *isAuthenticatedKey = NSStringFromSelector(@selector(isAuthenticated));
    [self willChangeValueForKey:isAuthenticatedKey];
    
    _oauthToken = oauthToken;
    
    [self didChangeValueForKey:isAuthenticatedKey];
}

- (NSMutableOrderedSet *)pendingRequests {
    if (!_pendingRequests) {
        _pendingRequests = [[NSMutableOrderedSet alloc] init];
    }
    
    return _pendingRequests;
}

#pragma mark - Clients

+ (void)pushClient:(BAClient *)client {
    [[self clientStack] addObject:client];
}

+ (void)popClient {
    [[self clientStack] removeLastObject];
}

+ (instancetype)currentClient {
    return [[self clientStack] lastObject] ?: [self defaultClient];
}

+ (NSMutableArray *)clientStack {
    static NSMutableArray *clientStack = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clientStack = [NSMutableArray new];
    });
    
    return clientStack;
}

- (void)performBlock:(void (^)(void))block {
    NSParameterAssert(block);
    
    [[self class] pushClient:self];
    block();
    [[self class] popClient];
}

#pragma mark - Configuration

- (void)setupWithAPIKey:(NSString *)key secret:(NSString *)secret {
    NSParameterAssert(key);
    NSParameterAssert(secret);
    
    self.apiKey = key;
    self.apiSecret = secret;
    
    [self updateAuthorizationHeader:self.isAuthenticated];
}

#pragma mark - Authentication

- (BAAsyncTask *)authenticateAsUserWithEmail:(NSString *)email password:(NSString *)password {
    NSParameterAssert(email);
    NSParameterAssert(password);
    
    BARequest *request = [BAAuthenticationAPI requestForAuthenticationWithEmail:email password:password];
    return [self authenticateWithRequest:request requestPolicy:BAClientAuthRequestPolicyCancelPrevious];
}

- (BAAsyncTask *)authenticateWithTransferToken:(NSString *)transferToken {
    NSParameterAssert(transferToken);
    
    BARequest *request = [BAAuthenticationAPI requestForAuthenticationWithTransferToken:transferToken];
    return [self authenticateWithRequest:request requestPolicy:BAClientAuthRequestPolicyCancelPrevious];
}

- (BAAsyncTask *)authenticateWithRequest:(BARequest *)request requestPolicy:(BAClientAuthRequestPolicy)requestPolicy {
    if (requestPolicy == BAClientAuthRequestPolicyIgnore) {
        if (self.authenticationTask) {
            // Ignore this new authentation request, let the old one finish
            return nil;
        }
    } else if (requestPolicy == BAClientAuthRequestPolicyCancelPrevious) {
        // Cancel any pending authentication task
        [self.authenticationTask cancel];
    }
    
    BA_WEAK_SELF weakSelf = self;
    
    // Always use basic authentication for authentication requests
    request.URLRequestConfigurationBlock = ^NSURLRequest *(NSURLRequest *urlRequest) {
        BA_STRONG(weakSelf) strongSelf = weakSelf;
        
        NSMutableURLRequest *mutURLRequest = [urlRequest mutableCopy];
        [mutURLRequest ba_setAuthorizationHeaderWithUsername:strongSelf.apiKey password:strongSelf.apiSecret];
        
        return [mutURLRequest copy];
    };
    
    self.authenticationTask = [[self performTaskWithRequest:request] then:^(BAResponse *response, NSError *error) {
        BA_STRONG(weakSelf) strongSelf = weakSelf;
        
        if (!error) {
            strongSelf.oauthToken = [[BAOAuth2Token alloc] initWithDictionary:response.body];
        } else if ([error ba_isServerError]) {
            // If authentication failed server side, reset the token since it isn't likely
            // to be successful next time either. If it is NOT a server side error, it might
            // just be networking so we should not reset the token.
            strongSelf.oauthToken = nil;
        }
        
        strongSelf.authenticationTask = nil;
    }];
    
    return self.authenticationTask;
}

- (BAAsyncTask *)authenticateWithSavedRequest:(BARequest *)request {
    BAAsyncTask *task = [self authenticateWithRequest:request requestPolicy:BAClientAuthRequestPolicyIgnore];
    
    BA_WEAK_SELF weakSelf = self;
    
    task = [task then:^(id result, NSError *error) {
        BA_STRONG(weakSelf) strongSelf = weakSelf;
        
        if (!error) {
            [strongSelf processPendingRequests];
        } else {
            [strongSelf clearPendingRequests];
        }
    }];
    
    return task;
}

#pragma mark - Requests

- (BAAsyncTask *)performRequest:(BARequest *)request {
    BAAsyncTask *task = nil;
    
    if (self.isAuthenticated) {
        // Authenticated request, might need token refresh
        if (![self.oauthToken willExpireWithinIntervalFromNow:kTokenExpirationLimit]) {
            task = [self performTaskWithRequest:request];
        } else {
            task = [self enqueueTaskWithRequest:request];
            [self refreshToken];
        }
    } else if (self.savedAuthenticationRequest) {
        // Can self-authenticate, authenticate before performing request
        task = [self enqueueTaskWithRequest:request];
        [self authenticateWithSavedRequest:self.savedAuthenticationRequest];
    } else {
        // Unauthenticated request
        task = [self performTaskWithRequest:request];
    }
    
    return task;
}

- (BAAsyncTask *)performTaskWithRequest:(BARequest *)request {
    __block BAPendingRequest *pendingRequest = nil;
    
    BA_WEAK_SELF weakSelf = self;
    
    BAAsyncTask *task = [BAAsyncTask taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        pendingRequest = [self pendingRequestForRequest:request taskResolver:resolver];
        
        return ^{
            [pendingRequest cancelWithHTTPClient:weakSelf.HTTPClient];
        };
    }];
    
    [pendingRequest startWithHTTPClient:self.HTTPClient];
    
    return task;
}

- (BAAsyncTask *)enqueueTaskWithRequest:(BARequest *)request {
    __block BAPendingRequest *pendingRequest = nil;
    
    BA_WEAK_SELF weakSelf = self;
    
    BAAsyncTask *task = [BAAsyncTask taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        pendingRequest = [self pendingRequestForRequest:request taskResolver:resolver];
        
        return ^{
            [pendingRequest cancelWithHTTPClient:weakSelf.HTTPClient];
        };
    }];
    
    [self.pendingRequests addObject:pendingRequest];
    
    return task;
}

- (BAPendingRequest *)pendingRequestForRequest:(BARequest *)request taskResolver:(BAAsyncTaskResolver *)taskResolver {
    BA_WEAK_SELF weakSelf = self;
    BA_WEAK(taskResolver) weakResolver = taskResolver;
    
    BAPendingRequest *pendingRequest = [[BAPendingRequest alloc] initWithRequest:request progress:^(float progress, int64_t totalBytesExpected, int64_t totalBytesReceived) {
        // The task made progress
        [weakResolver notifyProgress:progress];
    }  completion:^(BAResponse *response, NSError *error) {
        // The task completed
        BA_STRONG(weakSelf) strongSelf = weakSelf;
        
        if (!error) {
            [taskResolver succeedWithResult:response];
        } else {
            if (response.statusCode == 401) {
                // The token we are using is not valid anymore. Reset it.
                strongSelf.oauthToken = nil;
            }
            
            [taskResolver failWithError:error];
        }
    }];
    
    return pendingRequest;
}

- (void)processPendingRequests {
    for (BAPendingRequest *request in self.pendingRequests) {
        [request startWithHTTPClient:self.HTTPClient];
    }
    
    [self.pendingRequests removeAllObjects];
}

- (void)clearPendingRequests {
    for (BAPendingRequest *request in self.pendingRequests) {
        [request cancelWithHTTPClient:self.HTTPClient];
    }
    
    [self.pendingRequests removeAllObjects];
}

#pragma mark - State

- (void)authenticationStateDidChange:(BOOL)isAuthenticated {
    [self updateAuthorizationHeader:isAuthenticated];
    [self updateStoredToken];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BAClientAuthenticationStateDidChangeNotification object:self];
}

- (void)updateAuthorizationHeader:(BOOL)isAuthenticated {
    if (isAuthenticated) {
        [self.HTTPClient.requestSerializer setAuthorizationHeaderWithOAuth2AccessToken:self.oauthToken.accessToken];
    } else if (self.apiKey && self.apiSecret) {
        [self.HTTPClient.requestSerializer setAuthorizationHeaderWithAPIKey:self.apiKey secret:self.apiSecret];
    }
}

- (void)updateStoredToken {
    if (!self.tokenStore) return;
    
    BAOAuth2Token *token = self.oauthToken;
    if (token) {
        [self.tokenStore storeToken:token];
    } else {
        [self.tokenStore deleteStoredToken];
    }
}

- (void)restoreTokenIfNeeded {
    if (!self.tokenStore) return;
    
    if (!self.isAuthenticated) {
        self.oauthToken = [self.tokenStore storedToken];
    }
}

#pragma mark - Refresh token

- (BAAsyncTask *)refreshTokenWithRefreshToken:(NSString *)refreshToken {
    NSParameterAssert(refreshToken);
    
    BARequest *request = [BAAuthenticationAPI requestToRefreshToken:refreshToken];
    return [self authenticateWithRequest:request requestPolicy:BAClientAuthRequestPolicyIgnore];
}

- (BAAsyncTask *)refreshToken {
    NSAssert([self.oauthToken.refreshToken length] > 0, @"Can't refresh session, refresh token is missing.");
    
    BAAsyncTask *task = [self refreshTokenWithRefreshToken:self.oauthToken.refreshToken];
    
    BA_WEAK_SELF weakSelf = self;
    
    task = [task then:^(id result, NSError *error) {
        BA_STRONG(weakSelf) strongSelf = weakSelf;
        
        if (!error) {
            [strongSelf processPendingRequests];
        } else {
            [strongSelf clearPendingRequests];
        }
    }];
    
    return task;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kIsAuthenticatedContext) {
        BOOL isAuthenticated = [change[NSKeyValueChangeNewKey] boolValue];
        [self authenticationStateDidChange:isAuthenticated];
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;
    
    NSString *isAuthenticatedKey = NSStringFromSelector(@selector(isAuthenticated));
    if ([theKey isEqualToString:isAuthenticatedKey]) {
        // The "isAuthentication" KVO event is managed manually using willChangeValueForKey:/didChangeValueForKey:
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    
    return automatic;
}

@end

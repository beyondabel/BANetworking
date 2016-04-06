//
//  BAClient.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAClient.h"
#import "BAAuthenticatedModel.h"
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

@interface BAClient () {
}

@property (nonatomic, weak, readwrite) BAAsyncTask *authenticationTask;
@property (nonatomic, strong, readwrite) BARequest *savedAuthenticationRequest;
@property (nonatomic, strong, readonly) NSMutableOrderedSet *pendingRequests;

@property (nonatomic, strong, readonly) Class authenticatedClass;
@property (nonatomic, strong, readonly) Class apiClass;

@end


@implementation BAClient

@synthesize pendingRequests = _pendingRequests, authenticatedClass = _authenticatedClass, apiClass = _apiClass;

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

- (void)dealloc {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(isAuthenticated)) context:kIsAuthenticatedContext];
}

#pragma mark - Properties

- (BOOL)isAuthenticated {
    return self.authenticatedUser != nil;
}

- (void)setAuthenticatedUser:(BAAuthenticatedModel *)authenticatedUser {
    if (authenticatedUser == _authenticatedUser) {
        return;
    }
    
    NSString *isAuthenticatedKey = NSStringFromSelector(@selector(isAuthenticated));
    [self willChangeValueForKey:isAuthenticatedKey];
    
    _authenticatedUser = authenticatedUser;
    
    [self didChangeValueForKey:isAuthenticatedKey];
    
}

- (NSMutableOrderedSet *)pendingRequests {
    if (!_pendingRequests) {
        _pendingRequests = [[NSMutableOrderedSet alloc] init];
    }
    
    return _pendingRequests;
}

- (Class)authenticatedClass {
    if (_authenticatedClass) {
        return _authenticatedClass;
    }
    return [BAAuthenticatedModel class];
}

- (Class)apiClass {
    if (_apiClass) {
        return _apiClass;
    }
    return [BAAuthenticationAPI class];
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
- (void)setDebugEnabled:(BOOL)debugEnabled {
    self.HTTPClient.debugEnabled = debugEnabled;
}

- (void)setupAuthenticatedAnalysisClass:(Class)authenticatedClass authenticatedAPIClass:(Class)apiClass {
    if(authenticatedClass) {
        _authenticatedClass = authenticatedClass;
    }
    
    if (apiClass) {
        _apiClass = apiClass;
    }
}

- (void)setupCommonParametersClass:(Class)commonClass {
    _HTTPClient.commonParametersClass = commonClass;
}

- (void)setupUserAgent:(NSString *)userAgent {
    _HTTPClient.userAgent = userAgent;
}

#pragma mark - Authentication

- (BAAsyncTask *)authenticateAsUserWithEmail:(NSString *)email password:(NSString *)password {
    NSParameterAssert(email);
    NSParameterAssert(password);
    BARequest *request = [[self apiClass] requestForAuthenticationWithEmail:email password:password];
    return [self authenticateWithRequest:request requestPolicy:BAClientAuthRequestPolicyCancelPrevious];
}

- (BAAsyncTask *)authenticateWithTransferToken:(NSString *)transferToken {
    NSParameterAssert(transferToken);
    
    BARequest *request = [[self apiClass] requestForAuthenticationWithTransferToken:transferToken];
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
    
    self.authenticationTask = [[self performTaskWithRequest:request] then:^(BAResponse *response, NSError *error) {
        BA_STRONG(weakSelf) strongSelf = weakSelf;
        if (!error) {
            strongSelf.authenticatedUser = [[[self authenticatedClass] alloc] initWithDictionary:response.body];
        } else if ([error ba_isServerError]) {
            // If authentication failed server side, reset the token since it isn't likely
            // to be successful next time either. If it is NOT a server side error, it might
            // just be networking so we should not reset the token.
            strongSelf.authenticatedUser = nil;
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

- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request {
    return [self.HTTPClient URLRequestForRequest:request];
}

- (BAAsyncTask *)performRequest:(BARequest *)request {
    BAAsyncTask *task = nil;
    
    if (self.isAuthenticated) {
        // Authenticated request, might need token refresh
        if (![self.authenticatedUser willExpireWithinIntervalFromNow:kTokenExpirationLimit]) {
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
                strongSelf.authenticatedUser = nil;
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
        [self.HTTPClient.requestSerializer setAuthorizationHeaderWithOAuth2AccessToken:self.authenticatedUser.accessToken];
    }
}

- (void)updateHTTPHeader:(NSDictionary *)HTTPHeaderDictionary {
    for (NSString *key in HTTPHeaderDictionary) {
        [self.HTTPClient.requestSerializer setValue:HTTPHeaderDictionary[key] forKey:key];
    }
}

- (void)updateStoredToken {
    if (!self.tokenStore) return;
    
    BAAuthenticatedModel *token = self.authenticatedUser;
    if (token) {
        [self.tokenStore storeToken:token];
    } else {
        [self.tokenStore deleteStoredToken];
    }
}

- (void)restoreTokenIfNeeded {
    if (!self.tokenStore) return;
    
    if (!self.isAuthenticated) {
        self.authenticatedUser = [self.tokenStore storedToken];
    }
}

#pragma mark - Refresh token

- (BAAsyncTask *)refreshTokenWithRefreshToken:(NSString *)refreshToken {
    NSParameterAssert(refreshToken);
    
    BARequest *request = [BAAuthenticationAPI requestToRefreshToken:refreshToken];
    return [self authenticateWithRequest:request requestPolicy:BAClientAuthRequestPolicyIgnore];
}

- (BAAsyncTask *)refreshToken {
    BAAsyncTask *task = [self refreshTokenWithRefreshToken:self.authenticatedUser.accessToken];
    
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

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

typedef NS_ENUM(NSUInteger, BAClientAuthRequestPolicy) {
    BAClientAuthRequestPolicyCancelPrevious = 0,
    BAClientAuthRequestPolicyIgnore,
};

/**
 *  A pending task represents a request that has been requested to be performed but not yet started.
 *  It might be started immediately or enqueued until the token has been successfully refreshed if expired.
 */
@interface BAPendingRequest : NSObject {
    dispatch_once_t _performedOnceToken;
}

@property (nonatomic, strong, readonly) BARequest *request;
@property (nonatomic, copy) BARequestCompletionBlock completionBlock;
@property (nonatomic, copy) BARequestProgressBlock progressBlock;
@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation BAPendingRequest

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
    dispatch_once(&_performedOnceToken, ^{
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
    dispatch_once(&_performedOnceToken, ^{
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

- (void)setupUserAgent:(NSString *)userAgent {
    _HTTPClient.userAgent = userAgent;
}

- (void)setHeaderValue:(NSString *)value forKey:(NSString *)key {
    if (value && key) {
        [self.HTTPClient setHeaderValue:value forKey:key];
    }
}

#pragma mark - Requests

- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request {
    return [self.HTTPClient URLRequestForRequest:request];
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

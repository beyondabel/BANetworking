//
//  BAHTTPClient.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAHTTPClient.h"
#import "BAURLSessionTaskDelegate.h"
#import "BAMultipartFormData.h"
#import "BASecurity.h"
#import "BAMacros.h"
#import "NSURLRequest+BADescription.h"


#ifndef kDefaultBaseURL
#define kDefaultBaseURL

static NSString * const kDefaultBaseURLString = @"http://192.168.31.200/";
static NSString * const kDefaultCookieURLString = @".jindanlicai.com/";

#endif

static char * const kRequestProcessingQueueLabel = "com.jindanlicai.networingkit.httpclient.response_processing_queue";

@interface BAHTTPClient () <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, strong, readonly) dispatch_queue_t responseProcessingQueue;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@property (nonatomic, strong) NSMutableDictionary *taskDelegates;
@property (nonatomic, strong) NSLock *taskDelegatesLock;
@property (nonatomic, copy, readonly) BASecurity *security;

@end

@implementation BAHTTPClient

@synthesize session = _session;
@synthesize requestSerializer = _requestSerializer;
@synthesize responseSerializer = _responseSerializer;
@synthesize security = _security;

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    _baseURL = [[NSURL alloc] initWithString:kDefaultBaseURLString];
    _responseProcessingQueue = dispatch_queue_create(kRequestProcessingQueueLabel, DISPATCH_QUEUE_CONCURRENT);
    _requestSerializer = [BARequestSerializer new];
    _responseSerializer = [BAResponseSerializer new];
    _taskDelegates = [NSMutableDictionary new];
    _taskDelegatesLock = [NSLock new];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.HTTPShouldUsePipelining = YES;
    
    self.delegateQueue = [NSOperationQueue new];
    self.delegateQueue.maxConcurrentOperationCount = 1;
    
    _session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:self.delegateQueue];
    
    return self;
}

#pragma mark - Properties

- (NSString *)userAgent {
    return [self.requestSerializer valueForHTTPHeader:BARequestSerializerHTTPHeaderKeyUserAgent];
}

- (void)setUserAgent:(NSString *)userAgent {
    [self.requestSerializer setUserAgentHeader:userAgent];
}

- (void)setHeaderValue:(NSString *)value forKey:(NSString *)key {
    [self.requestSerializer setValue:value forHTTPHeader:key];
}

#pragma mark - Private

- (BASecurity *)security {
    if (!_security) {
        _security = [BASecurity new];
    }
    
    return _security;
}

- (void)addTaskDelegate:(BAURLSessionTaskDelegate *)delegate forTask:(NSURLSessionTask *)task {
    NSParameterAssert(delegate);
    [self.taskDelegatesLock lock];
    self.taskDelegates[@(task.taskIdentifier)] = delegate;
    [self.taskDelegatesLock unlock];
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    [self.taskDelegatesLock lock];
    [self.taskDelegates removeObjectForKey:@(task.taskIdentifier)];
    [self.taskDelegatesLock unlock];
}

- (BAURLSessionTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
    return self.taskDelegates[@(task.taskIdentifier)];
}

#pragma mark - Public

- (NSURLSessionTask *)taskForRequest:(BARequest *)request progress:(BARequestProgressBlock)progress completion:(BARequestCompletionBlock)completion {
    NSURLSessionTask *task = nil;
    
    BAHTTPResponseProcessBlock responseProcessBlock = nil;
    
    if ((request.fileData || request.fileDatas) && (request.method == BARequestMethodPOST || request.method == BARequestMethodPUT)) {
        // Upload task
        BAMultipartFormData *multipartData = [self.requestSerializer multipartFormDataFromRequest:request];
        NSData *data = [multipartData finalizedData];
        
        NSMutableURLRequest *URLRequest = [self.requestSerializer URLRequestForRequest:request multipartData:multipartData relativeToURL:self.baseURL];
        
        if (self.debugEnabled) {
            debug(@"URLRequest = %@ ", [URLRequest ba_description]);
        }
        
        BA_WEAK(self.responseSerializer) weakResponseSerializer = self.responseSerializer;
        responseProcessBlock = ^(NSURLResponse *URLResponse, NSData *data, BAURLSessionTaskDelegate *delegate) {
            return [weakResponseSerializer responseObjectForURLResponse:URLResponse data:data];
        };
        
        task = [self.session uploadTaskWithRequest:URLRequest fromData:data];
    } else {
        NSMutableURLRequest *URLRequest = [self.requestSerializer URLRequestForRequest:request relativeToURL:self.baseURL];
        
        if (self.debugEnabled) {
            debug(@"URLRequest = %@ ", [URLRequest ba_description]);
        }
        if (request.fileData && request.method == BARequestMethodGET) {
            // Download task
            
            task = [self.session downloadTaskWithRequest:URLRequest];
        } else {
            // Regular data task
            task = [self.session dataTaskWithRequest:URLRequest];
            
            BA_WEAK(self.responseSerializer) weakResponseSerializer = self.responseSerializer;
            responseProcessBlock = ^(NSURLResponse *URLResponse, NSData *data, BAURLSessionTaskDelegate *delegate) {
                return [weakResponseSerializer responseObjectForURLResponse:URLResponse data:data];
            };
        }
    }
    
    BAURLSessionTaskDelegate *taskDelegate = [[BAURLSessionTaskDelegate alloc] initWithRequest:request
                                                                         responseProcessingQueue:self.responseProcessingQueue
                                                                                   progressBlock:progress
                                                                            responseProcessBlock:responseProcessBlock
                                                                                 completionBlock:completion];
    [self addTaskDelegate:taskDelegate forTask:task];
    
    return task;
}

- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request {
    return [self.requestSerializer URLRequestForRequest:request relativeToURL:_baseURL];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    if (self.useSSLPinning && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        BOOL isTrustValid = [self.security evaluateServerTrust:serverTrust];
        
        if (isTrustValid) {
            credential = [NSURLCredential credentialForTrust:serverTrust];
            if (credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    BAURLSessionTaskDelegate *taskDelegate = [self delegateForTask:task];
    [taskDelegate task:task didCompleteWithError:error];
    [self removeDelegateForTask:task];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    BAURLSessionTaskDelegate *taskDelegate = [self delegateForTask:dataTask];
    [taskDelegate task:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    BAURLSessionTaskDelegate *taskDelegate = [self delegateForTask:task];
    [taskDelegate taskDidUpdateProgress:task];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    BAURLSessionTaskDelegate *taskDelegate = self.taskDelegates[@(downloadTask.taskIdentifier)];
    [taskDelegate taskDidUpdateProgress:downloadTask];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    BAURLSessionTaskDelegate *taskDelegate = [self delegateForTask:downloadTask];
    [taskDelegate task:downloadTask didFinishDownloadingToURL:location];
}

@end

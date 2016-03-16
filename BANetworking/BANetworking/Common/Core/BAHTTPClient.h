//
//  BAHTTPClient.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BARequest.h"
#import "BAResponse.h"
#import "BARequestSerializer.h"
#import "BAResponseSerializer.h"

typedef void(^BARequestCompletionBlock)(BAResponse *response, NSError *error);

/**
 *  A progress block to be called whenever a task makes progress.
 *
 *  @param progress           The current progress of the task.
 *  @param totalBytesExpected The total expected number of bytes to be received.
 *  @param totalBytesReceived The current number of bytes received at the time of calling this block.
 */
typedef void(^BARequestProgressBlock)(float progress, int64_t totalBytesExpected, int64_t totalBytesReceived);

@interface BAHTTPClient : NSObject

@property (nonatomic, copy) NSURL *baseURL;

/**
 *  The user agent string of the user agent.
 */
@property (nonatomic, copy) NSString *userAgent;


@property (nonatomic, assign) BOOL debugEnabled;

/**
 *  The serializer of the request.
 */
@property (nonatomic, strong, readonly) BARequestSerializer *requestSerializer;

/**
 *  The serializer of the response.
 */
@property (nonatomic, strong, readonly) BAResponseSerializer *responseSerializer;

/**
 *  Controls whether or not to pin the server public key to that of any .cer certificate included in the app bundle.
 */
@property (nonatomic) BOOL useSSLPinning;

/**
 *  Creates and returns a NSURLSessionTask for the given request, for which the provided completion handler
 *  will be executed upon completion.
 *
 *  @param request    The request
 *  @param completion A block to be called when the task makes progress, or nil.
 *  @param completion A completion handler to be executed on task completion.
 *
 *  @return An NSURLSessionTask
 */
- (NSURLSessionTask *)taskForRequest:(BARequest *)request progress:(BARequestProgressBlock)progress completion:(BARequestCompletionBlock)completion;

- (NSMutableURLRequest *)URLRequestForRequest:(BARequest *)request;

@end

//
//  BAAsyncTask.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#import "BAAsyncTask.h"

#import "BAMacros.h"
#import "NSArray+BAAdditions.h"

typedef NS_ENUM(NSUInteger, BAAsyncTaskState) {
    BAAsyncTaskStatePending = 0,
    BAAsyncTaskStateSucceeded,
    BAAsyncTaskStateErrored,
};

@interface BAAsyncTask ()

@property (readwrite) BAAsyncTaskState state;
@property (strong) id result;
@property (strong, readonly) NSMutableArray *completeCallbacks;
@property (strong, readonly) NSMutableArray *successCallbacks;
@property (strong, readonly) NSMutableArray *errorCallbacks;
@property (strong, readonly) NSMutableArray *progressCallbacks;
@property (copy) BAAsyncTaskCancelBlock cancelBlock;
@property (strong) NSLock *stateLock;

- (void)succeedWithResult:(id)result;
- (void)failWithError:(NSError *)error;

@end

@interface BAAsyncTaskResolver ()

// Make the task reference strong to make sure that if the resolver lives
// on (in a completion handler for example), the task does as well.
@property (strong) BAAsyncTask *task;

- (instancetype)initWithTask:(BAAsyncTask *)task;

@end

@implementation BAAsyncTask {
    
//    dispatch_once_t _resolvedOnceToken;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    _state = BAAsyncTaskStatePending;
    _completeCallbacks = [NSMutableArray new];
    _successCallbacks = [NSMutableArray new];
    _errorCallbacks = [NSMutableArray new];
    _progressCallbacks = [NSMutableArray new];
    _stateLock = [NSLock new];
    
    return self;
}

+ (instancetype)taskForBlock:(BAAsyncTaskResolveBlock)block {
    BAAsyncTask *task = [self new];
    BAAsyncTaskResolver *resolver = [[BAAsyncTaskResolver alloc] initWithTask:task];
    task.cancelBlock = block(resolver);
    
    return task;
}

+ (instancetype)taskWithResult:(id)result {
    return [self taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        [resolver succeedWithResult:result];
        
        return nil;
    }];
}

+ (instancetype)taskWithError:(NSError *)error {
    return [self taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        [resolver failWithError:error];
        
        return nil;
    }];
}

+ (instancetype)when:(NSArray *)tasks {
    return [self taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        NSMutableSet *pendingTasks = [NSMutableSet setWithArray:tasks];
        
        NSUInteger taskCount = [tasks count];
        NSMutableDictionary *results = [NSMutableDictionary new];
        NSMutableDictionary *progresses = [NSMutableDictionary new];
        
        // We need a lock to synchronize access to the results dictionary and remaining tasks set.
        NSLock *lock = [NSLock new];
        
        void (^cancelRemainingBlock) (void) = ^{
            // Clear the backlog of tasks and cancel remaining ones.
            [lock lock];
            
            NSSet *tasksToCancel = [pendingTasks copy];
            [pendingTasks removeAllObjects];
            
            for (BAAsyncTask *task in tasksToCancel) {
                [task cancel];
            }
            
            [lock unlock];
        };
        
        NSUInteger pos = 0;
        for (BAAsyncTask *task in tasks) {
            
            [task onSuccess:^(id result) {
                id res = result ?: [NSNull null];
                
                [lock lock];
                
                // Add the result to the results dictionary at the original position of the task,
                // and remove the task from the list of pending tasks to avoid it from being
                // cancelled if the combined task is cancelled later.
                results[@(pos)] = res;
                [pendingTasks removeObject:task];
                
                [lock unlock];
                
                if (results.count == taskCount) {
                    // All tasks have completed, collect the results and sort them in the
                    // tasks' original ordering
                    NSArray *positions = [NSArray ba_arrayFromRange:NSMakeRange(0, taskCount)];
                    NSArray *orderedResults = [positions ba_mappedArrayWithBlock:^id(NSNumber *pos) {
                        return results[pos];
                    }];
                    
                    [resolver succeedWithResult:orderedResults];
                }
            } onError:^(NSError *error) {
                cancelRemainingBlock();
                
                [resolver failWithError:error];
            }];
            
            [task onProgress:^(float progress) {
                progresses[@(pos)] = @(progress);
                
                // Add together the progress of all tasks
                float completedProgress = [[[progresses allValues] ba_reducedValueWithBlock:^id(NSNumber *reduced, NSNumber *current) {
                    return @(reduced.floatValue + current.floatValue);
                }] floatValue];
                
                // Calculate how much of the total value has been completed. The individual progress between the tasks is not
                // weighted, so if one task includes "more" work, it will still only contribute 1.0 to the total progress.
                float totalProgress = taskCount * 1.f;
                float currentProgress = completedProgress / totalProgress;
                
                [resolver notifyProgress:currentProgress];
            }];
            
            ++pos;
        }
        
        return cancelRemainingBlock;
    }];
}

- (instancetype)then:(BAAsyncTaskThenBlock)thenBlock {
    return [[self class] taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        [self onSuccess:^(id result) {
            thenBlock(result, nil);
            [resolver succeedWithResult:result];
        } onError:^(NSError *error) {
            thenBlock(nil, error);
            [resolver failWithError:error];
        }];
        
        [self onProgress:^(float progress) {
            [resolver notifyProgress:progress];
        }];
        
        BA_WEAK_SELF weakSelf = self;
        
        return ^{
            [weakSelf cancel];
        };
    }];
}

- (instancetype)map:(id (^)(id result))block {
    return [[self class] taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        
        [self onSuccess:^(id result) {
            id mappedResult = block ? block(result) : result;
            [resolver succeedWithResult:mappedResult];
        } onError:^(NSError *error) {
            [resolver failWithError:error];
        }];
        
        [self onProgress:^(float progress) {
            [resolver notifyProgress:progress];
        }];
        
        BA_WEAK_SELF weakSelf = self;
        
        return ^{
            [weakSelf cancel];
        };
    }];
}

- (instancetype)pipe:(BAAsyncTask *(^)(id result))block {
    NSParameterAssert(block);
    
    return [[self class] taskForBlock:^BAAsyncTaskCancelBlock(BAAsyncTaskResolver *resolver) {
        __block BAAsyncTask *pipedTask = nil;
        
        [self onSuccess:^(id result1) {
            pipedTask = block(result1);
            
            [pipedTask onSuccess:^(id result2) {
                [resolver succeedWithResult:result2];
            } onError:^(NSError *error) {
                [resolver failWithError:error];
            }];
        } onError:^(NSError *error) {
            [resolver failWithError:error];
        }];
        
        // Cancel both tasks in the case of the parent task being cancelled.
        BA_WEAK_SELF weakSelf = self;
        BA_WEAK(pipedTask) weakPipedTask = pipedTask;
        
        return ^{
            [weakSelf cancel];
            [weakPipedTask cancel];
        };
    }];
}

#pragma mark - Properties

- (BOOL)completed {
    return self.state != BAAsyncTaskStatePending;
}

- (BOOL)succeeded {
    return self.state == BAAsyncTaskStateSucceeded;
}

- (BOOL)errored {
    return self.state == BAAsyncTaskStateErrored;
}

#pragma mark - KVO

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
    NSMutableSet *keyPaths = [[super keyPathsForValuesAffectingValueForKey:key] mutableCopy];
    
    NSArray *keysAffectedByState = @[
                                     NSStringFromSelector(@selector(completed)),
                                     NSStringFromSelector(@selector(succeeded)),
                                     NSStringFromSelector(@selector(errored))
                                     ];
    
    if ([keysAffectedByState containsObject:key]) {
        [keyPaths addObject:NSStringFromSelector(@selector(state))];
    }
    
    return [keyPaths copy];
}

#pragma mark - Register callbacks

- (instancetype)onComplete:(BAAsyncTaskCompleteBlock)completeBlock {
    NSParameterAssert(completeBlock);
    
    [self performSynchronizedBlock:^{
        if (self.succeeded) {
            completeBlock(self.result, nil);
        } else if (self.errored) {
            completeBlock(nil, self.result);
        } else {
            [self.completeCallbacks addObject:[completeBlock copy]];
        }
    }];
    
    return self;
}

- (instancetype)onSuccess:(void (^)(id x))successBlock {
    NSParameterAssert(successBlock);
    
    [self performSynchronizedBlock:^{
        if (self.completed) {
            if (self.succeeded) {
                successBlock(self.result);
            }
        } else {
            [self.successCallbacks addObject:[successBlock copy]];
        }
    }];
    
    return self;
}

- (instancetype)onError:(void (^)(NSError *error))errorBlock {
    NSParameterAssert(errorBlock);
    
    [self performSynchronizedBlock:^{
        if (self.completed) {
            if (self.errored) {
                errorBlock(self.result);
            }
        } else {
            [self.errorCallbacks addObject:[errorBlock copy]];
        }
    }];
    
    return self;
}

- (instancetype)onSuccess:(BAAsyncTaskSuccessBlock)successBlock onError:(BAAsyncTaskErrorBlock)errorBlock {
    [self onSuccess:successBlock];
    [self onError:errorBlock];
    
    return self;
}

- (instancetype)onProgress:(BAAsyncTaskProgressBlock)progressBlock {
    NSParameterAssert(progressBlock);
    
    [self.progressCallbacks addObject:[progressBlock copy]];
    
    return self;
}

#pragma mark - Resolve

- (void)succeedWithResult:(id)result {
    [self resolveWithState:BAAsyncTaskStateSucceeded result:result];
}

- (void)failWithError:(NSError *)error {
    [self resolveWithState:BAAsyncTaskStateErrored result:error];
}

- (void)notifyProgress:(float)progress {
    for (BAAsyncTaskProgressBlock callback in self.progressCallbacks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(progress);
        });
    }
}

- (void)resolveWithState:(BAAsyncTaskState)state result:(id)result {
    static dispatch_once_t _resolvedOnceToken;
    dispatch_once(&_resolvedOnceToken, ^{
        [self performSynchronizedBlock:^{
            self.state = state;
            self.result = result;
            
            if (state == BAAsyncTaskStateSucceeded) {
                [self performSuccessCallbacksWithResult:result];
                [self performCompleteCallbacksWithResult:result error:nil];
            } else if (state == BAAsyncTaskStateErrored) {
                [self performErrorCallbacksWithError:result];
                [self performCompleteCallbacksWithResult:nil error:result];
            }
            
            [self removeAllCallbacks];
        }];
    });
}

- (void)performSuccessCallbacksWithResult:(id)result {
    for (BAAsyncTaskSuccessBlock callback in self.successCallbacks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(self.result);
        });
    }
}

- (void)performErrorCallbacksWithError:(NSError *)error {
    for (BAAsyncTaskErrorBlock callback in self.errorCallbacks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(self.result);
        });
    }
}

- (void)performCompleteCallbacksWithResult:(id)result error:(NSError *)error {
    for (BAAsyncTaskCompleteBlock callback in self.completeCallbacks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(result, error);
        });
    }
}

- (void)removeAllCallbacks {
    [self.successCallbacks removeAllObjects];
    [self.errorCallbacks removeAllObjects];
    [self.completeCallbacks removeAllObjects];
    self.cancelBlock = nil;
}

- (void)cancel {
    if (self.cancelBlock) {
        self.cancelBlock();
        self.cancelBlock = nil;
    }
}

#pragma mark - Helpers

- (void)performSynchronizedBlock:(void (^)(void))block {
    NSParameterAssert(block);
    
    [self.stateLock lock];
    block();
    [self.stateLock unlock];
}

@end

@implementation BAAsyncTaskResolver

- (instancetype)initWithTask:(BAAsyncTask *)task {
    self = [super init];
    if (!self) return nil;
    
    _task = task;
    
    return self;
}

- (void)succeedWithResult:(id)result {
    [self.task succeedWithResult:result];
    self.task = nil;
}

- (void)failWithError:(NSError *)error {
    [self.task failWithError:error];
    self.task = nil;
}

- (void)notifyProgress:(float)progress {
    [self.task notifyProgress:progress];
}

@end

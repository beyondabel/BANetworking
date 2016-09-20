//
//  BAImageDownloader.m
//  BANetworking
//
//  Created by BeyondAbel on 16/7/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import "BAImageDownloader.h"
#import "BAImageCache.h"

@interface BAImageDownloader()
{
    NSURL *_url;
    id<BAImageDownloaderDelegate> _delegate;
    NSURLConnection *_connection;
    NSMutableData *_imageData;
    NSInteger statusCode;
}

@property (nonatomic) id<BAImageDownloaderDelegate> delegate;
@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, strong) NSMutableData * imageData;
@end

@implementation BAImageDownloader

+ (id) requestWithURL:(NSURL *)url imageRequestDelegate:(id<BAImageDownloaderDelegate>)delegate
{
    BAImageDownloader * imageRequest = [[BAImageDownloader alloc] init];
    imageRequest.url = url;
    imageRequest.delegate = delegate;
    [imageRequest performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    return imageRequest;
}

- (void) start
{
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:self.url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:30];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
    
    if (self.connection) {
        self.imageData = [NSMutableData data];
    } else{
        if ([self.delegate respondsToSelector:@selector(imageRequest:didFailWithError:)]) {
            [self.delegate imageRequest:self didFailWithError:nil];
        }
    }
#if !__has_feature(objc_arc)
    [request release];
#endif
}

- (void) cancel
{
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
}

#pragma mark NSURLConnection (delegate)
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    statusCode = [response statusCode];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([self.delegate respondsToSelector:@selector(imageRequest:didFinishWithImageData:)]) {
        [self.delegate imageRequest:self didFinishWithImageData:self.imageData];
    }
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(imageRequest:didFailWithError:)]) {
        [self.delegate imageRequest:self didFailWithError:error];
    }
    
    self.connection = nil;
    self.imageData = nil;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}


@end

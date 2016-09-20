//
//  BAImageDownloader.h
//  BANetworking
//
//  Created by BeyondAbel on 16/7/4.
//  Copyright © 2016年 abel. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol BAImageDownloaderDelegate;

@interface BAImageDownloader : NSObject

@property (nonatomic, strong) NSURL * url;


+ (id)requestWithURL:(NSURL *)url imageRequestDelegate:(id)delegate;

/*!
 @method start downloader image
 */
- (void)start;

/*!
 @method cancel downloader
 */
- (void)cancel;

@end

@protocol BAImageDownloaderDelegate <NSObject>

- (void)avatarImageRequest:(BAImageDownloader *)imageRequest didFinishWithImageData:(NSData *)imageData;

- (void)imageRequest:(BAImageDownloader *)imageRequest didFinishWithImageData:(NSData *)imageData;
- (void)imageRequest:(BAImageDownloader *)imageRequest didFailWithError:(NSError *) error;

@end
# BANetworking

## How do I get started?

1. Download BANetworking and try out the included Mac and iPhone example apps
2. Check out the documentation for a comprehensive look at all of the APIs available in BANetworking

BANetworking uses ARC and is based on NSURLSession, which means it supports iOS 7.0 and above and Mac OS X 10.9 and above.

If you need a hand, you can contact us by [e-mail](beyondabel@gmail.com).

## Using BANetworking

#### 1. Set up request logs

	[BANetworking setDebugEnabled:YES];
	
#### 2. Creating a Download Task

	BARequest *request = [BARequest GETRequestWithURL:[NSURL URLWithString:@"http://127.0.0.1/avatar"] parameters:nil];
	[[[[BAClient currentClient] performRequest:request] onComplete:^(BAResponse *result, NSError *error) {
   		
	}] onProgress:^(float progress) {
      NSLog(@"download progress = %f",progress);
	}];

#### 3. Creating an Upload Task
	BARequest *request = [BARequest POSTRequestWithPath:path parameters:nil];
	request.contentType = BARequestContentTypeMultipart;
	request.fileData = [BARequestFileData fileDataWithData:data name:fileName fileName:[NSString stringWithFormat:@“%@.png",fileName]];
	[[[BAClient currentClient] performRequest:request] onComplete:^(id result, NSError *error) {
        if (error) {
            NSLog(@"file upload error");
        } else {
            NSLog(@"file upload succeed");
        }
    }];
    
## Adding to your project

If you are using CocoaPods, then, just add this line to your Podfile

	pod 'BANetworking', '~> 1.0.0'
    
## Documentation

You can find a getting started guide and full documentation over at the [BANetworking](https://net.beyondabel.com).

## License

BANetworking is released under the MIT license. 

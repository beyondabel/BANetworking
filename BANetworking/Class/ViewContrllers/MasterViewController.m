//
//  MasterViewController.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright (c) 2015年 abel. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "BAGlobalHeaders.h"
#import "NSArray+BAAdditions.h"


@interface MasterViewController ()

@property NSMutableArray *objects;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;

    [self uploadFiles];
}

// 单文件上传
- (void)uploadFile {
    BARequest *request = [BARequest POSTRequestWithPath:@"avatar" parameters:@{@"type" : @"avatar"}];
    request.fileData = [BARequestFileData fileDataWithData:[NSData data] name:@"fileKey" fileName:@"fileName"];
    [[[BAClient currentClient] performRequest:request] onComplete:^(id result, NSError *error) {
        if (error) {
            NSLog(@"文件上传出错");
        } else {
            NSLog(@"文件上传出错");
        }
    }];
}

// 多文件上传
- (void)uploadFiles {
    NSURL *url = [NSURL URLWithString:@"http://qebaby.nowtime.com.cn/index.php/app/topic/uploads"];
    BARequest *request = [BARequest POSTRequestWithURL:url parameters:nil];
    request.contentType = BARequestContentTypeMultipart;
    BARequestFileData *fileData1 = [BARequestFileData fileDataWithData:UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]) name:@"image1" fileName:@"fileName1"];
    BARequestFileData *fileData2 = [BARequestFileData fileDataWithData:UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]) name:@"image2" fileName:@"fileName2"];
    request.fileDatas = @[fileData1, fileData2];
    [[[BAClient currentClient] performRequest:request] onComplete:^(id result, NSError *error) {
        if (error) {
            NSLog(@"文件上传出错");
        } else {
            NSLog(@"文件上传成功 %@", [result body]);
        }
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = self.objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDate *object = self.objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end

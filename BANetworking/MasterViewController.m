//
//  MasterViewController.m
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright (c) 2015年 abel. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "BARequest.h"
#import "BAClient.h"
#import "BAAsyncTask.h"
#import "BAModel.h"

@interface BAUser : BAModel

@property (nonatomic, assign) NSInteger userID;
@property (nonatomic, strong) NSString *userName;

@end

@implementation BAUser

@end


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

//    BARequest *request = [BARequest GETRequestWithPath:@"help_background" parameters:nil];
    BARequest *request = [BARequest GETRequestWithURL:[NSURL URLWithString:@"http://lx.cdn.baidupcs.com/file/c57dd56cb36d8a290f3544d71d2c3cac?bkt=p2-qd-51&xcode=14028950a00a36c1732763df59e52bf6cbb9029b3648648bed03e924080ece4b&fid=3004343519-250528-1123010459727468&time=1453293802&sign=FDTAXGERLBH-DCb740ccc5511e5e8fedcff06b081203-z8La684JHJED2WAHmc%2B%2BoEi4ObI%3D&to=lc&fm=Nin,B,T,t&sta_dx=220&sta_cs=110&sta_ft=pdf&sta_ct=7&fm2=Ningbo,B,T,t&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=1400c57dd56cb36d8a290f3544d71d2c3cac1265ae4c00000dc153f0&sl=75628622&expires=8h&rt=pr&r=516884902&mlogid=460689475081725023&vuk=3004343519&vbdid=4019177510&fin=%E3%80%8A%E7%99%BD%E5%B8%BD%E5%AD%90%E8%AE%B2Web%E5%AE%89%E5%85%A8%E3%80%8B220MB.pdf&fn=%E3%80%8A%E7%99%BD%E5%B8%BD%E5%AD%90%E8%AE%B2Web%E5%AE%89%E5%85%A8%E3%80%8B220MB.pdf&slt=pm&uta=0&rtype=1&iv=0&isw=0&dp-logid=460689475081725023&dp-callid=0.1.1"] parameters:nil];
    [[[[BAClient currentClient] performRequest:request] onComplete:^(BAResponse *result, NSError *error) {
        NSLog(@"help_background = %@", [[NSString alloc]initWithData:result.body encoding:NSUTF8StringEncoding]);
    }] onProgress:^(float progress) {
        NSLog(@"progress = %f",progress);
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

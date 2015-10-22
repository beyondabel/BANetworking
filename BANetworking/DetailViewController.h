//
//  DetailViewController.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright (c) 2015年 abel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end


//
//  GWVerticalButtonViewController.m
//  GWUtils
//
//  Created by huangqisheng on 15/4/24.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import "GWVerticalButtonViewController.h"
#import "GWVerticalButton.h"

@interface GWVerticalButtonViewController ()

@end

@implementation GWVerticalButtonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [GWVerticalButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"collection_normal.png"] forState:UIControlStateNormal];
    [button setTitle:@"lalalla" forState:UIControlStateNormal];
    [self.view addSubview:button];
    button.frame = CGRectMake(100, 100, 200, 300);
    button.backgroundColor = [UIColor blueColor];
    [button sizeToFit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

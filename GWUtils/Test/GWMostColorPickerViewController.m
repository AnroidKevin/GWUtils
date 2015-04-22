//
//  GWMostColorPickerViewController.m
//  GWUtils
//
//  Created by huangqisheng on 15/4/22.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import "GWMostColorPickerViewController.h"
#import "UIImage+MostColor.h"

@interface GWMostColorPickerViewController ()

@property (nonatomic, weak) UIImageView *imageView;

@end

@implementation GWMostColorPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MostColorPicker";
//    self.extendedLayoutIncludesOpaqueBars = NO;
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(110, 200, 100, 100)];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    btn.frame=CGRectMake(20, 20, 60, 60);
    [btn addTarget:self action:@selector(onBtn:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"1" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor grayColor];
    btn.tag=1;
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn addTarget:self action:@selector(onBtn:) forControlEvents:UIControlEventTouchUpInside];
    btn.frame=CGRectMake(100, 20, 60, 60);
    [btn setTitle:@"2" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor grayColor];
    btn.tag=2;
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn addTarget:self action:@selector(onBtn:) forControlEvents:UIControlEventTouchUpInside];
    btn.frame=CGRectMake(180, 20, 60, 60);
    [btn setTitle:@"3" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor grayColor];
    btn.tag=3;
    [self.view addSubview:btn];
}

-(void)onBtn:(UIButton*)btn{
    UIImage *img=[UIImage imageNamed:[NSString stringWithFormat:@"%ld.jpg",(long)btn.tag]];
    self.imageView.image=img;
    
    UIColor *most=[img mostColor];
    self.view.backgroundColor=most;
    
}

@end

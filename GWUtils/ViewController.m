//
//  ViewController.m
//  GWUtils
//
//  Created by huangqisheng on 15/4/22.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import "ViewController.h"
#import "GWMostColorPickerViewController.h"
#import "GWAdressBookViewController.h"
#import "GWKeyboardScrollViewController.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Home";
    
    UITableView *table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    table.delegate = self;
    table.dataSource = self;
    [self.view addSubview:table];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDatasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"MostColorPicker";
            break;
            
        case 1: {
            
            cell.textLabel.text = @"GWAddressBook";
            break;
        }
            
        case 2: {
            
            cell.textLabel.text = @"GWKeyboardScrollManager";
            break;
        }
            
        default:
            break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0: {
            
            GWMostColorPickerViewController *vc = [[GWMostColorPickerViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
            
        case 1: {
            
            GWAdressBookViewController *vc = [[GWAdressBookViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
            
        case 2: {
            
            GWKeyboardScrollViewController *vc = [[GWKeyboardScrollViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
            
        default:
            break;
    }
}

@end

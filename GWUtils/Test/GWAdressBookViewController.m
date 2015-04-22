//
//  GWAdressBookViewController.m
//  GWUtils
//
//  Created by huangqisheng on 15/4/22.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import "GWAdressBookViewController.h"
#import "GWAddressBook.h"

@interface GWAdressBookViewController ()

@property (nonatomic, strong) NSArray *addressBookArray;

@end

@implementation GWAdressBookViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"GWAdressBook";
    
    [[GWAddressBook instance] fetchAddressBookPeopleWithCompletion:^(BOOL authorized, NSArray *allPeople) {
        
        if (!authorized) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"没有授权" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alert show];
        } else {
            
            self.addressBookArray = allPeople;
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.addressBookArray) {
        
        return [self.addressBookArray count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    GWAddressBookPerson *person = [self.addressBookArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@ %@", person.firstName, person.middleName, person.lastName];
    cell.detailTextLabel.text = [person.phoneNumbers componentsJoinedByString:@","];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

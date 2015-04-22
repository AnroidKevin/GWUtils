//
//  GWAddressBookPerson.h
//  GWUtils
//
//  Created by huangqisheng on 14/12/11.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GWAddressBookPerson : NSObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *middleName;
@property (nonatomic, strong) NSString *organization;

@property (nonatomic, strong) NSArray *phoneNumbers;

- (id)initWithDictionary:(NSDictionary *)dic;

@end

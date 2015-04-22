//
//  GWAddressBookPerson.m
//  GWUtils
//
//  Created by huangqisheng on 14/12/11.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import "GWAddressBookPerson.h"

@implementation GWAddressBookPerson

- (id)initWithDictionary:(NSDictionary *)dic {
    
    if (self = [super init]) {
        
        _firstName = [dic objectForKey:@"firstName"];
        _lastName = [dic objectForKey:@"lastName"];
        _middleName = [dic objectForKey:@"middleName"];
        _organization = [dic objectForKey:@"organization"];
        _phoneNumbers = [dic objectForKey:@"phoneNumbers"];
    }
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"firstName : %@, lastName : %@, middleName : %@, organization : %@, phoneNumbers : %@", self.firstName, self.lastName, self.middleName, self.organization, self.phoneNumbers];
}

@end

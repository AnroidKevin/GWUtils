//
//  GWAddressbook.m
//
//  Created by huangqisheng on 14-8-19.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "GWAddressBook.h"
#import "GWSystemApiHelper.h"

@interface GWAddressBook ()

@property (nonatomic, assign) ABAddressBookRef addressBook;

@end

@implementation GWAddressBook

- (void)dealloc {
    
    if (_addressBook) {
        
        CFRelease(_addressBook);
    }
}

- (id)init {
    
    if (self = [super init]) {
        
        if ([GWSystemApiHelper systemIsIOS6AndLater]) {
            _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        } else {
            
            _addressBook = ABAddressBookCreate();
        }
        
    }
    return self;
}

#pragma mark - 通讯录
- (GWAddressBookAuthorizedStatus)addressBookGetAuthorizationStatus {
    
    GWAddressBookAuthorizedStatus status = GWAddressBookAuthorizedStatusAuthorized;
    
    // iOS6以后，判断是否可以访问地址簿
    if ([GWSystemApiHelper systemIsIOS6AndLater]) {
        
        switch (ABAddressBookGetAuthorizationStatus()) {
            case kABAuthorizationStatusNotDetermined: {
                
                status = GWAddressBookAuthorizedStatusNotDetermine;
                break;
            }
                
            case kABAuthorizationStatusRestricted: {
                
                status = GWAddressBookAuthorizedStatusRestricted;
                break;
            }
                
            case kABAuthorizationStatusDenied: {
                
                status = GWAddressBookAuthorizedStatusDenied;
                break;
            }
                
            case kABAuthorizationStatusAuthorized: {
                
                status = GWAddressBookAuthorizedStatusAuthorized;
                break;
            }
                
            default:
                break;
        }
    }
    
    return status;
}

- (void)requestAddressBookAccessWithCompletion:(void (^)(BOOL granted, NSError *error))completion {
    
    // iOS6以后，请求访问地址簿权限
    if ([GWSystemApiHelper systemIsIOS6AndLater]) {
        
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            
            if (completion) {
                
                completion(granted ? YES : NO, (__bridge NSError *)error);
            }
        });
    } else {
        
        if (completion) {
            
            completion(YES, nil);
        }
    }
    
}

- (NSArray *)fetchAllPeopleInAddressBook {
    
    NSMutableArray *allPeople = [NSMutableArray arrayWithCapacity:0];
    NSArray *allSources = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(self.addressBook);
    
    if (allSources
        && [allSources count] > 0) {
        
        for (id source in allSources) {
            
            ABRecordRef person = (__bridge_retained ABRecordRef)source;
            
            NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
            NSString *middleName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
            NSString *organization = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);

            NSMutableArray *phoneNumbers = [NSMutableArray array];
            
            //处理联系人电话号码
            ABMultiValueRef  phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            CFIndex count = ABMultiValueGetCount(phones);
            for(int i = 0; i < count; i++)
            {
                
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, i);
                NSString * phoneNumber = (__bridge NSString *)phoneNumberRef;
                phoneNumber = [self phoneNumberWithRemovePrefix:phoneNumber];
                phoneNumber = [self phoneNumberWithRemoveMiddleLine:phoneNumber];
                
                if (phoneNumber) {
                    
                    [phoneNumbers addObject:phoneNumber];
                }
                CFRelease(phoneNumberRef);
            }
            
            NSMutableDictionary *dic= [NSMutableDictionary dictionary];
            if (firstName) {
                
                [dic setValue:firstName forKey:@"firstName"];
            }
            if (lastName) {
                
                [dic setValue:lastName forKey:@"lastName"];
            }
            if (middleName) {
                
                [dic setValue:middleName forKey:@"middleName"];
            }
            if (organization) {
                
                [dic setValue:organization forKey:@"organization"];
            }
            if (phoneNumbers) {
                
                [dic setValue:phoneNumbers forKey:@"phoneNumbers"];
            }
            GWAddressBookPerson *personObj = [[GWAddressBookPerson alloc] initWithDictionary:dic];
//            personObj.firstName = (__bridge NSString *)firstName;
//            personObj.lastName = (__bridge NSString *)lastName;
//            personObj.middleName = (__bridge NSString *)middleName;
//            personObj.organization = (__bridge NSString *)organization;
//            personObj.phoneNumbers = phoneNumbers;
            
            [allPeople addObject:personObj];
            
//            if (firstName) {
//                
//                CFRelease(firstName);
//            }
//            if (lastName) {
//                
//                CFRelease(lastName);
//            }
//            if (middleName) {
//                CFRelease(middleName);
//            }
//            if (organization) {
//                CFRelease(organization);
//            }
//            if (phones) {
//                
//                CFRelease(phones);
//            }
            
        }
    }
    
    if (allSources) {
        
        CFRelease((CFArrayRef)allSources);
    }
    
    return allPeople;
}

- (void)fetchAddressBookPeopleWithCompletion:(GWFetchAddressBookPeopleCompletion)completion {
    
    GWAddressBookAuthorizedStatus status = [self addressBookGetAuthorizationStatus];
    switch (status) {
        case GWAddressBookAuthorizedStatusNotDetermine: {
            [self requestAddressBookAccessWithCompletion:^(BOOL granted, NSError *error) {
                
                if (granted) {
                    
                    if (completion) {
                        
                        NSArray *allPeople = [self fetchAllPeopleInAddressBook];
                        completion(YES, allPeople);
                    }
                } else if (completion) {
                    
                    completion(NO, nil);
                }
                
            }];
            break;
        }
            
        case GWAddressBookAuthorizedStatusRestricted: {
            if (completion) {
                
                completion(NO, nil);
            }
            break;
        }
            
        case GWAddressBookAuthorizedStatusDenied: {
            if (completion) {
                
                completion(NO, nil);
            }
            break;
        }
            
        case GWAddressBookAuthorizedStatusAuthorized: {
            if (completion) {
                
                NSArray *allPeople = [self fetchAllPeopleInAddressBook];
                completion(YES, allPeople);
            }
            break;
        }
    }
}

#pragma mark - 处理电话号码
// 检查手机号是否合法
- (BOOL)validateMobile:(NSString *)mobile
{
    if ([mobile length] == 0) {
        return NO;
    }
    // 1开头都可以
    NSString *mobileRegex = @"^1\\d{10}$";
    NSPredicate *mobileTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileRegex];
    return [mobileTest evaluateWithObject:mobile];
}

// 删除电话开头的+86
- (NSString *)phoneNumberWithRemovePrefix:(NSString *)phoneNumber {
    
    if (phoneNumber
        && [phoneNumber hasPrefix:@"+86"]) {
        
        return [phoneNumber substringFromIndex:3];
    }
    return phoneNumber;
}

// 删除电话中的-，(，)，空格
- (NSString *)phoneNumberWithRemoveMiddleLine:(NSString *)phoneNumber {
    
    NSString *phone = phoneNumber;
    if (phone) {
        
        phone = [phone stringByReplacingOccurrencesOfString:@"[-\\(\\)\\s]"
                                                 withString:@""
                                                    options:NSRegularExpressionSearch
                                                      range:NSMakeRange(0, phone.length)];
    }
    return phone;
}

#pragma mark - static
+ (instancetype)instance {
    
    return [[GWAddressBook alloc] init];
}

@end

//
//  GWAddressbook.h
//
//  Created by huangqisheng on 14-8-19.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GWAddressBookPerson.h"

typedef NS_ENUM(NSInteger, GWAddressBookAuthorizedStatus) {
    
    GWAddressBookAuthorizedStatusNotDetermine,      // 未决定
    GWAddressBookAuthorizedStatusRestricted,         // 受限访问
    GWAddressBookAuthorizedStatusDenied,            // 拒绝访问
    GWAddressBookAuthorizedStatusAuthorized,        // 允许访问
};

typedef void (^GWFetchAddressBookIntoDataCompletion)(BOOL success, BOOL authorized, NSData *fileData);
typedef void (^GWFetchAddressBookPeopleCompletion)(BOOL authorized, NSArray *allPeople);

/**
 *  singleton, use + (GWAddressBook *)sharedAdressBook to get the shared instance
 *  must use this class in main thread
 */
@interface GWAddressBook : NSObject

/**
 *  获取地址簿的可访问状态
 *
 *  @return 访问状态
 */
- (GWAddressBookAuthorizedStatus)addressBookGetAuthorizationStatus;

/**
 *  请求地址簿授权访问
 *
 *  @param completion 授权回调
 */
- (void)requestAddressBookAccessWithCompletion:(void (^)(BOOL granted, NSError *error))completion;

/**
 *  获取所有联系人，不检查权限
 *
 *  @return 返回所有联系人
 */
- (NSArray *)fetchAllPeopleInAddressBook;

/**
 *  检查地址簿授权状态，并获取所有联系人
 *
 *  @param completion 回调
 */
- (void)fetchAddressBookPeopleWithCompletion:(GWFetchAddressBookPeopleCompletion)completion;

#pragma mark - static
+ (instancetype)instance;

@end

//
//  GWIAPStoreKitDataManager.h
//  testlib
//
//  Created by huangqisheng on 14-1-15.
//  Copyright (c) 2014年 PerfectWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GWIAPProductInfo;

@interface GWIAPStoreKitDataManager : NSObject

// 返回值：0成功，1用户禁止应用内支付，2参数错误, 3有未完成交易, 4,被封禁
- (int)getSKProductsWithIdentifiers:(NSArray *)identifiers;

/**
 *  @brief  支付接口，检查临时账号
 *
 *  @param payProduct 支付信息
 *
 *  @return 错误信息
 */
- (int)payWithProduct:(GWIAPProductInfo *)payProduct;

#pragma mark -
#pragma mark complete the uncomplete pay
// 不检查未完成的交易是否有效
- (void)completeUncompletePayWithValidateToken:(GWIAPProductInfo *)product;
// 判断是否有未完成交易，同时检查交易的有效性
- (BOOL)haveIAPUncompletePay;

// 支付失败
- (void)IAPPayFailedWithErrorCode:(NSInteger)code
                          message:(NSString *)message
                     deleteCanliu:(BOOL)deleteCanliu;


#pragma mark -
#pragma mark sharedInstance
+ (GWIAPStoreKitDataManager *)sharedManager;

@end

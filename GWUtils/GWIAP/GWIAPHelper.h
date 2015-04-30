//
//  GWIAPHelper.h
//  testlib
//
//  Created by huangqisheng on 15/3/25.
//  Copyright (c) 2015年 PerfectWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct;

typedef void (^GWIAPHelperReceiptCallback)(NSData *receiptData);
typedef void (^GWIAPHelperPurchasingCallback)();
typedef void (^GWIAPHelperProductsCallback)(NSArray *products, NSArray *invalidIdentifiers);
typedef void (^GWIAPHelperErrorCallback)(NSError *error);

typedef NS_ENUM(NSInteger, GWIAPHelperErrorCode) {
    
    GWIAPHelperErrorCodeSuccess = 0,                    // 成功
    GWIAPHelperErrorCodeConcurrent = -32500,            // 并发请求，既之前已经有请求在进行，又进来新的请求
    GWIAPHelperErrorCodeProductFailed = -32501,         // 获取产品请求失败
    GWIAPHelperErrorCodePayFailed = -32502,             // 支付失败
    GWIAPHelperErrorCodePayLoadProductFailed = -32503,  // 通过productIdentifier支付时，获取产品失败
    GWIAPHelperErrorCodeParams = -32504,                // 参数错误
    GWIAPHelperErrorCodeReceiptNotUsed = -32505,        // 有票据未处理
    GWIAPHelperErrorCodeDeviceSettingForbidden = -32506,// 有票据未处理
};


extern NSString *const GWIAPHelperErrorDomain;

@interface GWIAPHelper : NSObject

@property (nonatomic, copy, readonly) GWIAPHelperReceiptCallback uncompleteCallback;

@property (nonatomic, copy, readonly) GWIAPHelperReceiptCallback receiptCallback;
@property (nonatomic, copy, readonly) GWIAPHelperPurchasingCallback purchasingCallback;
@property (nonatomic, copy, readonly) GWIAPHelperProductsCallback productsCallback;
@property (nonatomic, copy, readonly) GWIAPHelperErrorCallback productsErrorCallback;
@property (nonatomic, copy, readonly) GWIAPHelperErrorCallback payErrorCallback;

@property (nonatomic, assign, readonly) BOOL loadingProducts;     // 正在获取产品
@property (nonatomic, assign, readonly) BOOL payProcessing;       // 正在支付

/**
 *  @brief  设置未完成交易回调。在使用GWIAPHelper实例的时候，应该调用此方法，设置未完成交易的回调。已处理以前残留的未完成交易
 *
 *  @param uncomplete 未完成交易的回调
 *
 */
- (void)setupUncompleteCallback:(GWIAPHelperReceiptCallback)uncomplete;

/**
 *  @brief  获取产品
 *
 *  @param identifiers apple产品id集合
 *  @param productsCallback 请求成功回调
 *  @param errorCallback 请求失败回调
 *
 */
- (void)startLoadProductsWithProductIdentifiers:(NSSet *)identifiers
                                     completion:(GWIAPHelperProductsCallback)productsCallback
                                          error:(GWIAPHelperErrorCallback)errorCallback;

/**
 *  @brief  通过SKProduct购买产品
 *
 *  @param product 购买的产品（SKProduct）
 *  @param quantity 购买数量
 *  @param purchasingCallback 支付中回调
 *  @param receiptCallback 支付成功回调
 *  @param errorCallback 请求失败回调
 *
 */
- (void)startPayWithSKProduct:(SKProduct *)product
                     quantity:(NSUInteger)quantity
                   purchasing:(GWIAPHelperPurchasingCallback)purchasingCallback
                   completion:(GWIAPHelperReceiptCallback)receiptCallback
                        error:(GWIAPHelperErrorCallback)errorCallback;

/**
 *  @brief  通过ProductIdentifier购买产品，此方法会先向itunes请求SKProduct，然后调用上面的方法实现购买，错误回调中包含GWIAPHelperErrorCodeReceiptNotUsed错误码，说明当前有未处理的票据，调用
 *
 *  @param product 购买产品的identifier
 *  @param quantity 购买数量
 *  @param purchasingCallback 支付中回调
 *  @param receiptCallback 支付成功回调
 *  @param errorCallback 请求失败回调
 *
 */
- (void)startPayWithProductIdentifier:(NSString *)productIdentifier
                             quantity:(NSUInteger)quantity
                           purchasing:(GWIAPHelperPurchasingCallback)purchasingCallback
                           completion:(GWIAPHelperReceiptCallback)receiptCallback
                                error:(GWIAPHelperErrorCallback)errorCallback;

+ (instancetype)sharedInstance;

@end

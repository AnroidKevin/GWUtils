//
//  GWIAPStoreKitDataManager.m
//  testlib
//
//  Created by huangqisheng on 14-1-15.
//  Copyright (c) 2014年 PerfectWorld. All rights reserved.
//
#import <StoreKit/StoreKit.h>

#import "GWIAPStoreKitDataManager.h"
//#import "GWCPNotifications.h"
//#import "GWNSData+Base64.h"
#import "GWSFHFKeychainUtils.h"
//#import "GWComPlatformAPIResponse.h"
//#import "GWSFHFKeychainUtils.h"
//#import "GWUtil.h"
//#import "GGWessageTipView.h"
//#import "GWJSONKit.h"
//#import "GWRequest.h"

#import "GWComPlatform.h"
#import "GWComPlatform+Extend.h"
#import "GWKeychainInfo.h"
//#import "GWForbidden.h"

#import "GWLHNewApiForbiddenManager.h"
#import "GWLHNewApiIAPPayManager.h"
#import "GWLHNewApiLoginManager.h"
#import "GWSDKGlobalController.h"

#import "GWIAPHelper.h"

//// 统计SDK
//#import "GWSDKAnalysis.h"
//
//static NSString *const kGWAnalysisIAPKey = @"IAP";
//
//static NSString *const kGWAnalysisPayWaiting = @"payWaiting";
//static NSString *const kGWAnalysisPayWaitingTimeout = @"payWaitingTimeOut";
//static NSString *const kGWAnalysisPayWaitingStop = @"payWaitingStop";
//static NSString *const kGWAnalysisGetUncompleteInfo = @"getUncompleteInfo";
//
//static NSString *const kGWAnalysisValidateReceiptStart = @"validateReceiptStart"; //苹果票据验证开始(老虎服务器)
//static NSString *const kGWAnalysisValidateReceiptSuccessed = @"validateReceiptSuccessed"; //苹果票据验证成功(老虎服务器)
//
//static NSString *const kGWAnalysisIAPGetProductStart = @"iapGetProductStart"; //获取苹果商品信息开始
//static NSString *const kGWAnalysisIAPGetProductSuccessed = @"iapGetProductSuccessed"; //获取苹果商品信息成功
//static NSString *const kGWAnalysisIAPGetProductFailed = @"iapGetProductFailed"; //获取苹果商品信息失败
//
//static NSString *const kGWAnalysisIAPPayStart = @"iapPayStart"; //苹果IAP支付开始
//static NSString *const kGWAnalysisIAPPayFailed = @"iapPayPurchaseFailed"; // 苹果IAP支付失败
//static NSString *const kGWAnalysisIAPPayPurchased = @"iapPayPurchased"; //苹果IAP支付成功
//static NSString *const kGWAnalysisIAPPayPurchasing = @"iapPayPurchasing"; //苹果IAP支付中
//static NSString *const kGWAnalysisIAPPayRestored = @"iapPayRestored"; //苹果IAP恢复购买
//static NSString *const kGWAnalysisIAPPayUnknowFinished = @"iapPayUnknowFinished"; //苹果IAP支付流程无状态完成
//
//static NSString *const kGWAnalysisIAPPayUncompleteStart = @"iapPayUncompleteStart"; //苹果IAP残留交易开始
//
//static NSString *const kGWAnalysisIAPPayProcessFailed = @"iapPayFailed"; // 整个IAP支付过程中支付失败
//
//static NSString *const kGWAnalysis<#something#> = @"<#something#>";

#define GW_APPSTORE_IAP_PAY_KEYCHAIN_SERVICE            @"GWAPPStoreIAPPayKeyChainService"
#define GW_APPSTORE_IAP_PAY_CURRENT_PURCHASE_KEY        @"GWAPPStoreIAPPayKeyCurrentPurchase"

//@interface GWIAPProductInfo (JsonExt)
//
//- (NSString *)valueJsonRepresentation;
//- (void)setPayStatus:(GWIAPPayStatus)payStatus;
//
//@end

@interface GWIAPStoreKitDataManager ()

// 支付票据
@property (nonatomic, retain) NSString *receipt;
// 订单号
@property (nonatomic, retain) NSString *orderId;

@property (nonatomic, retain) GWIAPProductInfo *payProduct;
@property (nonatomic, retain) SKProduct *skProduct;

@property (nonatomic, retain) GWLHNewApiIAPPayManager *payManager;

// 残留交易等待计时器
@property (nonatomic, retain) NSTimer *payWaitTimer;

@property (nonatomic, retain) NSMutableDictionary *analysisMuDic; // 老虎SDK统计(该参数可包含:支付用户userId,订单号:orderId,错误码:code)

@end

@implementation GWIAPStoreKitDataManager {
    
    BOOL _isPaying;
    
    // 封禁标识, 共3处进封禁流程
    BOOL _isForbidden;
    
    // 是否正在获取产品
    BOOL _isLoadingProduct;
    
    // 是否有支付等待
    BOOL _isPayWaiting;
    
    // 是否验证过token，并且token有效
    BOOL _isTokenValidated;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        [[GWIAPHelper sharedInstance] setupUncompleteCallback:^(NSData *receiptData) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (receiptData) {
                    
                    [self prePay];
                    if (!self.payProduct) {
                        
                        self.payProduct = [self getIAPUncompletePay];
                    }
                    
                    NSString *receipt = [receiptData base64EncodedStringWithOptions:0];
                    self.receipt = receipt;
                    
                    [self applePaySuccessWithReceipt:receipt];
                }
            });
        }];
    }
    return self;
}

- (GWLHNewApiIAPPayManager *)payManager {
    
    if (!_payManager) {
        
        _payManager = [[GWLHNewApiIAPPayManager alloc] init];
    }
    return _payManager;
}

#pragma mark - Setter, Getter

- (NSMutableDictionary *)analysisMuDic
{
    if (nil == _analysisMuDic) {
        _analysisMuDic = [[NSMutableDictionary alloc] init];
    }
    
    if (self.payProduct
        && 0 < [self.payProduct.userId length]) {
        [_analysisMuDic setObject:self.payProduct.userId forKey:@"userId"];
        
    } else {
        
        NSString *userId = [[GWComPlatform defaultPlatform] loginUin];
        if (nil != userId
            && 0 < [userId length]) {
            [_analysisMuDic setObject:userId forKey:@"userId"];
        }
        
    }
    
    if (nil != self.orderId
        && 0 < [self.orderId length]) {
        [_analysisMuDic setObject:self.orderId forKey:@"orderId"];
    }
    
    return _analysisMuDic;
}


#pragma mark -
#pragma mark sharedInstance
static GWIAPStoreKitDataManager *sharedManager;
+ (GWIAPStoreKitDataManager *)sharedManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedManager) {
            sharedManager = [[GWIAPStoreKitDataManager alloc] init];
//            [[SKPaymentQueue defaultQueue] addTransactionObserver:sharedManager];
            
            //IAP SDK统计相关附加信息
            sharedManager.analysisMuDic = [NSMutableDictionary dictionary];
        }
    });
    return sharedManager;
}

#pragma mark -
#pragma mark complete the uncomplete pay
- (void)completeUncompletePayWithValidateToken:(GWIAPProductInfo *)product {
    
    if (_isPaying) {
        return;
    }
    
    self.payProduct = product;
    if ([self haveIAPUncompletePay]) {
        
        self.payProduct = [self getIAPUncompletePay];
        
        [self prePay];
        [self validateLoginWithCompletion:^(BOOL tokenValid, BOOL isNetworkError) {
            
            if (tokenValid) {
                
                [self completeUncompletePay];
            } else {
                
                if (_isForbidden) {
                    
                    //                    [self IAPPayFailedWithMessage:[NSString GWLocalizedStringWithString:@"IAP支付被封禁"]];
                    [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                            message:[NSString GWLocalizedStringWithString:@"支付被封禁"]
                                       deleteCanliu:NO];
                    return;
                } else if (isNetworkError) {
                    
                    // 网络错误
                    [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_NETWORK_UNAVAILABLE
                                            message:[NSString GWLocalizedStringWithString:@"支付失败"]
                                       deleteCanliu:NO];
                    return;
                }
                
                // 未登录或登录失效
                [self afterPay];
                
                [[GWSDKGlobal sharedInstance] setIsTokenInvalid:YES]; //增加登录界面 Token失效提示
                [[GWComPlatform defaultPlatform] GWLoginEx:0];
                [[GWSDKGlobal sharedInstance] setIsIAPPaymentProcessing:YES];
                [[GWSDKGlobal sharedInstance] setIapProductInfo:self.payProduct];
                if (self.receipt) {
                    
                    [[GWSDKGlobal sharedInstance] setIapProductHasReceipt:YES];
                }
            }
        }];
    }
    
}

- (void)completeUncompletePay {
    
    if (_isPayWaiting) {
        
        return;
    }
    
    // 没有残留交易，不再继续，可能发生在apple先返回失败，然后token校验完成执行此处代码
    if (![self haveIAPUncompletePay]) {
        
        return;
    }
    
//    // FIXME: 统计点, 苹果残留交易开始
//    [GWSDKAnalysis event:kGWAnalysisIAPKey
//                   label:kGWAnalysisIAPPayUncompleteStart
//               attribute:self.analysisMuDic];
    
    // 如果有票据，则直接验证，否则，进入支付等待流程
    if (self.receipt) {
        
        [self validateReceipt:self.receipt];
    } else {
        
        [self startPayWaiting];
    }
}

- (BOOL)haveIAPUncompletePay {
    
    // 检查是否有未完成交易
    GWIAPProductInfo *unComplete = [self getIAPUncompletePay];
    if (unComplete
        && [unComplete isValidPay]) {
        
        return YES;
    }
    
    return NO;
}

// 获取未完成的支付(指IAP支付完成，还没有向服务器确认的支付)，目前只会有一个未完成支付
- (GWIAPProductInfo *)getIAPUncompletePay {
    
    NSString *productValue = [GWSFHFKeychainUtils getPasswordForUsername:GW_APPSTORE_IAP_PAY_CURRENT_PURCHASE_KEY
                                                          andServiceName:GW_APPSTORE_IAP_PAY_KEYCHAIN_SERVICE
                                                                   error:NULL];
    
    GWDLog(@"  pay info : %@", productValue);
    
    if (productValue) {
        
        NSDictionary *dic = [productValue objectFromJSONString];
        if (dic
            && [dic isKindOfClass:[NSDictionary class]]) {
            
            self.receipt = [GWBaseModel GWStringValue:[dic objectForKey:@"receipt"]];
            self.orderId = [GWBaseModel GWStringValue:[dic objectForKey:@"orderId"]];
            
            GWIAPProductInfo *unComplete = [[GWIAPProductInfo alloc] initWithDictionary:dic];
            
            // TODO: 统计点, 获取残留交易信息
            
            return [unComplete autorelease];
        }
    }
    
    return nil;
}

- (void)startPayWaiting {
    
    _isPayWaiting = YES;
    
    if (self.payWaitTimer) {
        
        [self.payWaitTimer invalidate];
    }
    
    [self.payProduct setPayStatus:GWIAPPayStatusWaitingCanliu];
    
    self.payWaitTimer = [NSTimer scheduledTimerWithTimeInterval:5.f
                                                         target:self
                                                       selector:@selector(payWaitTimeout:)
                                                       userInfo:nil
                                                        repeats:NO];
    // TODO: 统计点, 支付等待流程
}

- (void)payWaitTimeout:(id)sender {
    
    [self stopPayWaiting];
    
    [self.payProduct setPayStatus:GWIAPPayStatusWaitCanliuTimeout];
    
    // 删除残留票据
    [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                            message:[NSString GWLocalizedStringWithString:@"支付失败"]
                       deleteCanliu:YES];
    
    // TODO: 统计点,支付超时
}

- (void)stopPayWaiting {
    
    _isPayWaiting = NO;
    if (self.payWaitTimer) {
        
        [self.payWaitTimer invalidate];
        self.payWaitTimer = nil;
    }
    
    // TODO: 统计点, 停止支付
}

#pragma mark - Pay

- (int)getSKProductsWithIdentifiers:(NSArray *)identifiers {
    if (_isLoadingProduct) {
        
        return GW_COM_PLATFORM_ERROR_FAILED;
    }
    
    if (![SKPaymentQueue canMakePayments]) {
        return GW_COM_PLATFORM_ERROR_IAP_PAY_DEVICE_FORBIDDEN;
    }
    
    if (!identifiers
        || [identifiers count] == 0) {
        return GW_COM_PLATFORM_ERROR_PARAM;
    }
    
    _isLoadingProduct = YES;
    
    NSSet *identifiersSet = [NSSet setWithArray:identifiers];
    [[GWIAPHelper sharedInstance] startLoadProductsWithProductIdentifiers:identifiersSet completion:^(NSArray *products, NSArray *invalidIdentifiers) {
        _isLoadingProduct = NO;
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:@"0" forKey:@"result"];
        if (products) {
            [dic setValue:products forKey:@"products"];
        }
        if (invalidIdentifiers) {
            [dic setValue:invalidIdentifiers forKey:@"invalidProductIdentifiers"];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kGWCPIAPProductsNotification
                                                            object:self
                                                          userInfo:dic];
        
        // FIXME: 统计点, 获取苹果商品成功
        NSMutableDictionary *info = self.analysisMuDic;
        [info removeObjectForKey:@"orderId"];
        
//        [GWSDKAnalysis event:kGWAnalysisIAPKey
//                       label:kGWAnalysisIAPGetProductSuccessed
//                   attribute:info];

    } error:^(NSError *error) {
        _isLoadingProduct = NO;
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"result", error, @"error", nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kGWCPIAPProductsNotification
                                                            object:self
                                                          userInfo:userInfo];
        
        // FIXME: 统计点, 获取苹果商品失败
        NSMutableDictionary *info = self.analysisMuDic;
        [info removeObjectForKey:@"orderId"];
//        [GWSDKAnalysis event:kGWAnalysisIAPKey
//                       label:kGWAnalysisIAPGetProductFailed
//                   attribute:info];

    }];
    
    // FIXME: 统计点, 获取苹果商品信息开始
    
    // 取产品不需要订单号
    NSMutableDictionary *info = self.analysisMuDic;
    [info removeObjectForKey:@"orderId"];
//    [GWSDKAnalysis event:kGWAnalysisIAPKey
//                   label:kGWAnalysisIAPGetProductStart
//               attribute:info];
    
    return GW_COM_PLATFORM_NO_ERROR;
}

- (int)payWithProduct:(GWIAPProductInfo *)payProduct {
    
    if (_isPaying) {
        // TODO: 统计点, 正在支付
        
        return GW_COM_PLATFORM_ERROR_IAP_PAY_ORIGIN_PAYING;
    }
    
    if (_isPayWaiting) {
        // TODO: 统计点, 等待支付
        
        return GW_COM_PLATFORM_ERROR_IAP_PAY_HAS_UMCOMPLETE;
    }
    
    if (!payProduct
        || ![payProduct isValidPay]) {
        
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_IAP_PAY_PAYPRODUCTINFO_INVALID
                                message:[NSString GWLocalizedStringWithString:@"支付非法"]
                           deleteCanliu:NO];
        
        // TODO: 统计点, 非法支付
        
        return GW_COM_PLATFORM_ERROR_IAP_PAY_PAYPRODUCTINFO_INVALID;
    }
    
    if ([self haveIAPUncompletePay]) {
        
        // TODO: 统计点, 残留交易
        
        [self completeUncompletePayWithValidateToken:payProduct];
        return GW_COM_PLATFORM_ERROR_IAP_PAY_HAS_UMCOMPLETE;
    }
    
    if (![SKPaymentQueue canMakePayments]) {
        
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_IAP_PAY_DEVICE_FORBIDDEN
                                message:[NSString GWLocalizedStringWithString:@"您的设备禁用了支付功能"]
                           deleteCanliu:NO];
        return GW_COM_PLATFORM_ERROR_IAP_PAY_DEVICE_FORBIDDEN;
    }
    
    // 清空上次支付剩下的信息
    self.orderId = nil;
    self.receipt = nil;
    
    _isPaying = YES;
    self.payProduct = payProduct;
    
    [self prePay];
    [self validateLoginWithCompletion:^(BOOL tokenValid, BOOL isNetworkError) {
        
        if (tokenValid) {
            
            // token验证成功
            [self.payProduct setPayStatus:GWIAPPayStatusTokenValidateSuccess];
            [self continuePayAfterValidToken];
        } else {
            
            // token验证失败
            [self.payProduct setPayStatus:GWIAPPayStatusTokenValidateFailed];
            if (_isForbidden) {
                
                [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                        message:[NSString GWLocalizedStringWithString:@"支付被封禁"]
                                   deleteCanliu:NO];
                return;
            } else if (isNetworkError) {
                
                [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_NETWORK_UNAVAILABLE
                                        message:[NSString GWLocalizedStringWithString:@"支付失败"]
                                   deleteCanliu:NO];
                return;
            }
            
            [self afterPay];
            
            // 未登录或登录失效
            [[GWSDKGlobal sharedInstance] setIsTokenInvalid:YES]; //增加登录界面 Token失效提示
            [[GWComPlatform defaultPlatform] GWLoginEx:0];
            [[GWSDKGlobal sharedInstance] setIsIAPPaymentProcessing:YES];
            [[GWSDKGlobal sharedInstance] setIapProductInfo:payProduct];
            if (self.receipt) {
                
                [[GWSDKGlobal sharedInstance] setIapProductHasReceipt:YES];
            }
        }
    }];
    
    return GW_COM_PLATFORM_NO_ERROR;
}

- (void)continuePayAfterValidToken {
    
    [[GWIAPHelper sharedInstance] startLoadProductsWithProductIdentifiers:[NSSet setWithObject:self.payProduct.goodId] completion:^(NSArray *products, NSArray *invalidIdentifiers) {
        
//        _iapPayGetProduct = NO;
        if ([products count] > 0
            && self.payProduct) {
            
            SKProduct *product = [products lastObject];
            if (product) {
                
                // 停止支付等待，支付继续
                if (_isPayWaiting) {
                    
                    [self stopPayWaiting];
                }
                
                self.skProduct = product;
                // 获取支付产品成功
                [self.payProduct setPayStatus:GWIAPPayStatusGetSKProductSuccess];
                
                NSString *currency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
                NSString *language = [product.priceLocale objectForKey:NSLocaleLanguageCode];
                NSString *country = [product.priceLocale objectForKey:NSLocaleCountryCode];
                
                [self createLaohuOrderWithProductInfo:self.payProduct
                                          payCurrency:currency
                                             language:language
                                              country:country];
                
                // FIXME: 统计点, 获取苹果商品成功
                NSMutableDictionary *info = self.analysisMuDic;
                [info removeObjectForKey:@"orderId"];
                
//                [GWSDKAnalysis event:kGWAnalysisIAPKey
//                               label:kGWAnalysisIAPGetProductSuccessed
//                           attribute:info];
                
            } else {
                
                // 获取支付产品失败
                [self.payProduct setPayStatus:GWIAPPayStatusGetSKProductFailed];
                
                // 停止支付等待，支付失败
                if (_isPayWaiting) {
                    
                    [self stopPayWaiting];
                }
                
                // 支付中失败，删除残留订单信息
                [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                        message:[NSString GWLocalizedStringWithString:@"获取产品失败"]
                                   deleteCanliu:YES];
            }
        } else {
            
            // 停止支付等待，支付失败
            if (_isPayWaiting) {
                
                [self stopPayWaiting];
            }
            
            // 支付中失败，删除残留订单信息
            [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                    message:[NSString GWLocalizedStringWithString:@"获取产品失败"]
                               deleteCanliu:YES];
        }
    } error:^(NSError *error) {
        
//        _iapPayGetProduct = NO;
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                message:[NSString GWLocalizedStringWithString:@"支付失败"]
                           deleteCanliu:YES];
    }];
}

- (void)startIAPPay {
    
//     FIXME: 统计点, IAP支付开始
//    
//    [GWSDKAnalysis event:kGWAnalysisIAPKey
//                   label:kGWAnalysisIAPPayStart
//               attribute:self.analysisMuDic];
    
    if (!self.payProduct) {
        
        //        [self IAPPayFailedWithMessage:[NSString GWLocalizedStringWithString:@"支付失败"]];
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                message:[NSString GWLocalizedStringWithString:@"支付失败"]
                           deleteCanliu:NO];
        return;
    }
    
    // 支付前保存订单信息，没有票据
    [self saveIAPCanliuPurchaseWithReceipt:nil];
    [self.payProduct setPayStatus:GWIAPPayStatusSaveCanliuWithoutReceipt];
    
    // 支付中回调
    GWIAPHelperPurchasingCallback purchasing = ^{
        
        [self.payProduct setPayStatus:GWIAPPayStatusApplePayProcessing];
        
        // 停止支付等待，支付继续
        if (_isPayWaiting) {
            
            [self stopPayWaiting];
        }
        
        // 停止统计
        [GWSDKGlobal sharedInstance].stopStatistics = YES;
        
//        // FIXME: 统计点, 苹果IAP正在支付中
//        [GWSDKAnalysis event:kGWAnalysisIAPKey
//                       label:kGWAnalysisIAPPayPurchasing
//                   attribute:self.analysisMuDic];
    };
    
    // 支付成功回调
    GWIAPHelperReceiptCallback purchased = ^(NSData *receiptData) {
        
        if (_isPayWaiting) {
            // 停止支付等待
            [self stopPayWaiting];
        }
        
        [self.payProduct setPayStatus:GWIAPPayStatusApplePaySuccess];
        
        
//        // FIXME: 统计点, 苹果IAP支付成功
//        [GWSDKAnalysis event:kGWAnalysisIAPKey
//                       label:kGWAnalysisIAPPayPurchased
//                   attribute:self.analysisMuDic];
        
        // 继续支付流程
        NSString *receipt = [receiptData base64EncodedString];
        [self applePaySuccessWithReceipt:receipt];
    };
    
    // 支付失败回调
    GWIAPHelperErrorCallback error = ^(NSError *error) {
        
        [self.payProduct setPayStatus:GWIAPPayStatusApplePayFailed];
        
        if (_isPayWaiting) {
            // 停止支付等待
            [self stopPayWaiting];
        }
        
        // 支付中失败，删除残留订单信息
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                message:[NSString GWLocalizedStringWithString:@"支付失败"]
                           deleteCanliu:YES];
        
        // 开启统计
        [GWSDKGlobal sharedInstance].stopStatistics = NO;
        
//        // FIXME: 统计点, 苹果IAP支付失败
//        [GWSDKAnalysis event:kGWAnalysisIAPKey
//                       label:kGWAnalysisIAPPayFailed
//                   attribute:self.analysisMuDic];
    };
    if (self.skProduct) {
        
//        [self payWithSKProduct:self.skProduct quantity:self.payProduct.goodNum];
        [[GWIAPHelper sharedInstance] startPayWithSKProduct:self.skProduct
                                                   quantity:self.payProduct.goodNum
                                                 purchasing:purchasing
                                                 completion:purchased
                                                      error:error];
    } else {
        
//        [self payWithProductIdentifer:self.payProduct.goodId quantity:self.payProduct.goodNum];
        [[GWIAPHelper sharedInstance] startPayWithProductIdentifier:self.payProduct.goodId
                                                           quantity:self.payProduct.goodNum
                                                         purchasing:purchasing
                                                         completion:purchased
                                                              error:error];
    }
}

- (void)prePay {
    
    _isPaying = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
        if (keyWindow) {
            [GGWessageTipView showHUDAddedTo:keyWindow animated:YES];
        }
    });
    
}

- (void)afterPay {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
        if (keyWindow) {
            [GGWessageTipView hideAllHUDsForView:keyWindow animated:YES];
        }
    });
    _isPaying = NO;
    // 一次支付流程结束，重置token验证
    _isTokenValidated = NO;
    
    self.skProduct = nil;
    
}

#pragma mark -
#pragma mark check token
- (void)validateLoginWithCompletion:(void (^)(BOOL tokenValid, BOOL isNetworkError))completion {
    
    if (![GWComPlatform defaultPlatform].sessionId) {
        //        [self IAPPayFailedWithMessage:[NSString GWLocalizedStringWithString:@"支付失败"]];
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                message:[NSString GWLocalizedStringWithString:@"请先登录"]
                           deleteCanliu:NO];
        if (completion) {
            
            completion(NO, NO);
        }
        return;
    }
    
    [[GWLHNewApiLoginManager sharedManager] startValidateTokenOnlyWithUserId:[GWComPlatform defaultPlatform].loginUin
                                                                       token:[GWComPlatform defaultPlatform].sessionId
                                                                  completion:^(GWLHNewApiRequestResult *result, NSError *error) {
                                                                      
                                                                      BOOL tokenValid = [self handleAuth:result];
                                                                      BOOL isNetworkError = (result == nil ? YES : NO);
                                                                      
                                                                      _isTokenValidated = tokenValid;
                                                                      if (completion) {
                                                                          
                                                                          completion(tokenValid, isNetworkError);
                                                                      }
                                                                  }];
}

- (BOOL)handleAuth:(GWLHNewApiRequestResult *)result
{
    
    if (!result) {
        //        [self IAPPayFailedWithMessage:[NSString GWLocalizedStringWithString:@"支付失败"]];
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                message:[NSString GWLocalizedStringWithString:@"支付失败"]
                           deleteCanliu:NO];
        return NO;
    } else if (result.code != 0) {
        
        GWLHNewApiForbiddenInfo *info = [[[GWLHNewApiForbiddenInfo alloc] init] autorelease];
        info.code = result.code;
        info.message = result.message;
        
        if ([[GWLHNewApiForbiddenManager sharedManager] checkInBlackListToLoginUI:info]) {
            
            _isForbidden = YES;
        } else {
            
            _isForbidden = NO;
        }
        
        [[GWComPlatform defaultPlatform] GWAccountToOffline];
        
        return NO;
    } else {
        
        return YES;
    }
    
}

- (void)applePaySuccessWithReceipt:(NSString *)receipt {
    
    // 如果此处没有product，则取残留交易中的product
    if (!self.payProduct
        && [self haveIAPUncompletePay]) {
        
        self.payProduct = [self getIAPUncompletePay];
    }
    
    if (_isPayWaiting) {
        // 停止支付等待
        [self stopPayWaiting];
    }
    
    if (receipt) {
        
        self.receipt = receipt;
        
        // 存keychain,残留交易使用
        [self saveIAPCanliuPurchaseWithReceipt:receipt];
        [self.payProduct setPayStatus:GWIAPPayStatusCanliuSaved];
        
        // 存documents,手工补单使用
        [self saveDocumentsReceipt:receipt];
        [self.payProduct setPayStatus:GWIAPPayStatusDocumentsSaved];
        
        // 如果未完成token验证，则等待token验证完成。残留交易验证token过程中，apple给返回票据了，需要等待token验证完成，再验证票据
        if (_isTokenValidated) {
            
            // 请求服务器确认支付凭据
            [self validateReceipt:receipt];
        }
        
        // 如果token失效，回到登录界面之后，apple返回票据，则设置全局票据标识为YES，以在登录成功后能够处理此残留交易
        if ([GWSDKGlobal sharedInstance].isTokenInvalid
            && [GWSDKGlobal sharedInstance].isIAPPaymentProcessing) {
            
            [GWSDKGlobal sharedInstance].iapProductHasReceipt = YES;
        }
    } else {
        
        [self.payProduct setPayStatus:GWIAPPayStatusApplePayEnded];
    }
    
    // 开启统计
    [GWSDKGlobal sharedInstance].stopStatistics = NO;
}

#pragma mark -
#pragma mark confirm receipt result
// 支付并验证成功
- (void)IAPPaySuccess {
    
    // TODO: 统计点, 支付成功
    
    [self afterPay];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"result", self.payProduct, @"payProductInfo", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kGWCPAPPStoreIAPBuyResultNotification
                                                            object:self
                                                          userInfo:userInfo];
        //        [self deleteIAPReceipt:self.payProduct];
        [self deleteIAPCanliuPurchase];
        
        if ([GWSDKGlobal sharedInstance].shouldShowIAPTips) {
            
            [GGWessageTipView showInTopWindowWithMessage:@"支付成功"];
        }
        
        [self.payProduct setPayStatus:GWIAPPayStatusPayEndedWithSuccess];
        
        //临时账号充值提示
        [[GWSDKGlobalController sharedInstance] showTempAccountPayAlertIfNeeded];
    });
    
}

- (void)IAPPayFailedWithErrorCode:(NSInteger)code
                          message:(NSString *)message
                     deleteCanliu:(BOOL)deleteCanliu {
    
    // FIXME: 统计点, 支付失败,code
    NSMutableDictionary *failedInfo = [NSMutableDictionary dictionaryWithDictionary:self.analysisMuDic];
    NSString *codeStr = [NSString stringWithFormat:@"%ld", (long)code];
    [failedInfo setObject:codeStr forKey:@"code"];
    
//    [GWSDKAnalysis event:kGWAnalysisIAPKey
//                   label:kGWAnalysisIAPPayProcessFailed
//               attribute:failedInfo];
//    
//    GWDLog(@"IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIAPPayFailedWithErrorCode:%ld message:%@ deleteCanliu:%@",(long)code, message, deleteCanliu ? @"YES":@"NO");
    
    [self afterPay];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld", (long)code], @"result", self.payProduct, @"payProductInfo", message, @"message", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kGWCPAPPStoreIAPBuyResultNotification
                                                            object:self
                                                          userInfo:userInfo];
        
        if (deleteCanliu) {
            
            //            [self deleteIAPReceipt:self.payProduct];
            [self deleteIAPCanliuPurchase];
        }
        
        if (nil != message && message.length > 0) {
            
            // 货币封禁提示
            if (code == 11019) {
                
                GWAlertView *alert = [[[GWAlertView alloc] initWithTitle:nil
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:nil
                                                        otherButtonTitle:[NSString GWLocalizedStringWithString:@"确认"]] autorelease];
                [alert show];
            } else if ([GWSDKGlobal sharedInstance].shouldShowIAPTips) {
                [GGWessageTipView showInTopWindowWithMessage:message];
            }
        }
        
        [self.payProduct setPayStatus:GWIAPPayStatusPayEndedWithFailed];
        
        //临时账号充值提示
        [[GWSDKGlobalController sharedInstance] showTempAccountPayAlertIfNeeded];
    });
}

#pragma mark -
#pragma mark Save Consume Info

// 保存残留交易
- (void)saveIAPCanliuPurchaseWithReceipt:(NSString *)receipt {
    
    if (self.payProduct) {
        
        NSMutableDictionary *saveKeychain = [NSMutableDictionary dictionaryWithDictionary:[self getRequestParamsFromProduct:self.payProduct]];
        if (self.receipt) {
            
            [saveKeychain setValue:self.receipt forKey:@"receipt"];
        }
        if (self.orderId) {
            
            [saveKeychain setValue:self.orderId forKey:@"orderId"];
        }
        
        NSString *saveKeychainString = [saveKeychain JSONString];
        
        GWDLog(@"IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIsave keychain pay info : %@", saveKeychainString);
        
        if (saveKeychainString) {
            
            NSError *error = nil;
            [GWSFHFKeychainUtils storeUsername:GW_APPSTORE_IAP_PAY_CURRENT_PURCHASE_KEY
                                   andPassword:saveKeychainString
                                forServiceName:GW_APPSTORE_IAP_PAY_KEYCHAIN_SERVICE
                                updateExisting:YES
                                         error:&error];
            
            if (error) {
                // error handling
                GWDLog(@"save IAP receipt error : %@", [error localizedDescription]);
            }
        }
    }
}

- (void)saveDocumentsReceipt:(NSString *)receipt {
    
    // 没有票据时，不做处理
    if (!receipt) {
        
        return;
    }
    
    // save to file
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *timeStr = [NSString stringWithFormat:@"%li", lround(floor(time))];
    NSMutableDictionary *receiptDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:receipt, @"receipt",
                                       [[GWComPlatform defaultPlatform] loginUin], @"userId",
                                       [NSString stringWithFormat:@"%ld", (long)[[GWComPlatform defaultPlatform] appId]], @"appId",
                                       timeStr, @"t", nil];
    if (self.payProduct
        && self.payProduct.appOrder) {
        
        [receiptDic setValue:self.payProduct.appOrder forKey:@"appOrder"];
    }
    if (self.orderId) {
        
        [receiptDic setValue:self.orderId forKey:@"orderId"];
    }
    
    GWDLog(@"IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIsave documents pay info : %@", receiptDic);
    
    NSString *appKey = [[GWComPlatform defaultPlatform] appKey];
    
    [self.payManager saveReceipt:receiptDic
                       withAppId:[NSString stringWithFormat:@"%ld", (long)[[GWComPlatform defaultPlatform] appId]]
                             key:[appKey substringFromIndex:(appKey.length - 16)]];
}

// 删除持久化的残留交易
- (void)deleteIAPCanliuPurchase {
    
    // 重置票据
    self.receipt = nil;
    
    NSError *error = nil;
    [GWSFHFKeychainUtils deleteItemForUsername:GW_APPSTORE_IAP_PAY_CURRENT_PURCHASE_KEY
                                andServiceName:GW_APPSTORE_IAP_PAY_KEYCHAIN_SERVICE
                                         error:&error];
    
    if (error) {
        // error handling
        GWDLog(@"delete IAP receipt error : %@", [error localizedDescription]);
    }
    
    // TODO: 统计点, 删除残留交易
}

#pragma mark -
#pragma mark create laohu order
- (void)createLaohuOrderWithProductInfo:(GWIAPProductInfo *)product
                            payCurrency:(NSString *)currency
                               language:(NSString *)language
                                country:(NSString *)country {
    
    NSMutableDictionary *params = [[GWKeychainInfo sharedInstance] requestParametersWithDeviceFrom:[self getRequestParamsFromProduct:self.payProduct] withMac:NO];
    
    [params setValue:[[GWComPlatform defaultPlatform] sessionId] forKey:@"token"];
    [params setValue:@"1" forKey:@"platform"];
    [params setValue:@"8" forKey:@"payType"];  //LAOHU(1), ALIPAY(6), PHONECARD(7), IAP(8)
    
    NSString *time = [NSString stringWithFormat:@"%li", lround(floor([[NSDate date] timeIntervalSince1970]))];
    [params setValue:time forKey:@"t"];
    
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    [params setValue:systemVersion forKey:@"systemType"];
    
    NSString *deviceType = [GWSystemApiHelper GWCurrentDeviceType];
    [params setValue:deviceType forKey:@"deviceType"];
    
    //    [self.payDataManager createIAPOrderWithParams:params];
    [self.payManager startGenerateIAPOrderWithParams:params
                                         payCurrency:currency
                                            language:language
                                             country:country
                                          completion:^(GWLHNewApiRequestResult *result, NSString *stringResult, NSError *error) {
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                                  if (result
                                                      && result.code == 0) {
                                                      
                                                      self.orderId = stringResult;
                                                      
                                                      // 订单创建成功
                                                      [self.payProduct setPayStatus:GWIAPPayStatusCreateLaohuOrderSuccess];
                                                      [self startIAPPay];
                                                      
                                                      // TODO: 统计点, 订单创建成功, 带OrderId, UserId
                                                  } else {
                                                      
                                                      // 订单创建失败
                                                      [self.payProduct setPayStatus:GWIAPPayStatusCreateLaohuOrderFailed];
                                                      
                                                      NSString *msg = [error.userInfo objectForKey:@"msg"];
                                                      
                                                      NSInteger code = GW_COM_PLATFORM_ERROR_FAILED;
                                                      
                                                      if (result) {
                                                          
                                                          code = result.code;
                                                      }
                                                      [self IAPPayFailedWithErrorCode:code
                                                                              message:msg
                                                                         deleteCanliu:NO];
                                                      //                                                      [self IAPPayFailedWithMessage:msg];
                                                      
                                                  }
                                              });
                                          }];
}

#pragma mark -
#pragma mark 验证票据

- (void)validateReceipt:(NSString *)receipt {
    
    if (!receipt) {
        
        //        [self IAPPayFailedWithErrorReceiptMessage:[NSString GWLocalizedStringWithString:@"支付失败"]];
        [self IAPPayFailedWithErrorCode:GW_COM_PLATFORM_ERROR_FAILED
                                message:[NSString GWLocalizedStringWithString:@"支付失败"]
                           deleteCanliu:YES];
        return;
    }
    
    
//    // FIXME: 统计点, 票据验证开始
//    [GWSDKAnalysis event:kGWAnalysisIAPKey
//                   label:kGWAnalysisValidateReceiptStart
//               attribute:self.analysisMuDic];
    
    [self.payManager startValidateIAPTokenWithAppOrder:self.payProduct.appOrder
                                               orderId:self.orderId
                                                ticket:receipt
                                            completion:^(GWLHNewApiRequestResult *result, NSError *error) {
                                                
                                                if (result
                                                    && result.code == 0) {
                                                    
                                                    [self.payProduct setPayStatus:GWIAPPayStatusValidateReceiptSuccess];
                                                    [self IAPPaySuccess];
                                                    
//                                                    [GWSDKAnalysis event:kGWAnalysisIAPKey
//                                                                   label:kGWAnalysisValidateReceiptSuccessed
//                                                               attribute:self.analysisMuDic];
                                                    
                                                } else {
                                                    
                                                    NSInteger code = GW_COM_PLATFORM_ERROR_FAILED;
                                                    if (result) {
                                                        code = result.code;
                                                    }
                                                    
                                                    NSString *msg = [error.userInfo objectForKey:@"msg"];
                                                    
                                                    if (code == 102
                                                        || code == 10011
                                                        || code == 10012
                                                        || code == 10013
                                                        || code == 11003
                                                        || code == 11004) {
                                                        
                                                        // 苹果票据验证失败
                                                        //                                                        [self IAPPayFailedWithErrorReceiptMessage:msg];
                                                        [self.payProduct setPayStatus:GWIAPPayStatusValidateReceiptFailedDeleteCanliu];
                                                        [self IAPPayFailedWithErrorCode:code
                                                                                message:msg
                                                                           deleteCanliu:YES];
                                                    } else {
                                                        
                                                        //                                                        [self IAPPayFailedWithMessage:msg];
                                                        
                                                        [self.payProduct setPayStatus:GWIAPPayStatusValidateReceiptFailedNotDeleteCanliu];
                                                        [self IAPPayFailedWithErrorCode:code
                                                                                message:msg
                                                                           deleteCanliu:NO];
                                                    }
                                                }
                                            }];
}


- (NSDictionary *)getRequestParamsFromProduct:(GWIAPProductInfo *)product {
    
    NSMutableDictionary *dicRepresentation = [NSMutableDictionary dictionaryWithCapacity:12];
    
    [dicRepresentation setObject:[NSString stringWithFormat:@"%ld", (long)product.appId] forKey:@"appId"];
    [dicRepresentation setObject:[NSString stringWithFormat:@"%ld", (long)product.roleId] forKey:@"roleId"];
    
    if (product.goodNum > 0) {
        [dicRepresentation setObject:[NSString stringWithFormat:@"%ld", (long)product.goodNum] forKey:@"goodNum"];
    }
    if (product.amount > 0) {
        [dicRepresentation setObject:[NSString stringWithFormat:@"%ld", (long)product.amount] forKey:@"amount"];
    }
    if (product.serverId != 0) {
        [dicRepresentation setObject:[NSString stringWithFormat:@"%ld", (long)product.serverId] forKey:@"serverId"];
    }
    if (product.areaId != 0) {
        [dicRepresentation setObject:[NSString stringWithFormat:@"%ld", (long)product.areaId] forKey:@"areaId"];
    }
    if (product.goodId) {
        [dicRepresentation setObject:product.goodId forKey:@"goodId"];
    }
    if (product.appOrder) {
        [dicRepresentation setObject:product.appOrder forKey:@"appOrder"];
    }
    if (product.goodInfo) {
        [dicRepresentation setObject:product.goodInfo forKey:@"goodInfo"];
    }
    if (product.channelId) {
        [dicRepresentation setObject:product.channelId forKey:@"channelId"];
    }
    if (product.userId) {
        [dicRepresentation setObject:product.userId forKey:@"userId"];
    }
    
    return dicRepresentation;
}

@end

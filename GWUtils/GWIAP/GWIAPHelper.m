//
//  GWIAPHelper.m
//  testlib
//
//  Created by huangqisheng on 15/3/25.
//  Copyright (c) 2015年 PerfectWorld. All rights reserved.
//

#import "GWIAPHelper.h"
#import <StoreKit/StoreKit.h>

NSString *const GWIAPHelperErrorDomain = @"GWIAPHelperErrorDomain";

@interface GWIAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, copy, readwrite) GWIAPHelperReceiptCallback uncompleteCallback;

@property (nonatomic, copy, readwrite) GWIAPHelperReceiptCallback receiptCallback;
@property (nonatomic, copy, readwrite) GWIAPHelperPurchasingCallback purchasingCallback;
@property (nonatomic, copy, readwrite) GWIAPHelperProductsCallback productsCallback;
@property (nonatomic, copy, readwrite) GWIAPHelperErrorCallback productsErrorCallback;
@property (nonatomic, copy, readwrite) GWIAPHelperErrorCallback payErrorCallback;

@property (nonatomic, assign, readwrite) BOOL loadingProducts;     // 正在获取产品
@property (nonatomic, assign, readwrite) BOOL payProcessing;       // 正在支付

@property (nonatomic, retain) NSData *receipt;                     // 未完成交易的票据

@end

@implementation GWIAPHelper

- (void)dealloc {
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    
    self.uncompleteCallback = nil;
    self.receiptCallback = nil;
    self.purchasingCallback = nil;
    self.payErrorCallback = nil;
    self.productsCallback = nil;
    self.productsErrorCallback = nil;
    
    self.receipt = nil;
}

#pragma mark - products request
- (void)startLoadProductsWithProductIdentifiers:(NSSet *)identifiers
                                     completion:(GWIAPHelperProductsCallback)productsCallback
                                          error:(GWIAPHelperErrorCallback)errorCallback {
    
    // 参数错误
    if (!identifiers
        || [identifiers count] == 0) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeParams
                                             userInfo:nil];
            errorCallback(error);
        }
        return;
    }
    
    // 已经有请求在进行中
    if (self.loadingProducts) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeConcurrent
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:identifiers, @"result", nil]];
            errorCallback(error);
        }
        return;
    }
    
    self.loadingProducts = YES;
    self.productsCallback = productsCallback;
    self.productsErrorCallback = errorCallback;
    
    // 请求产品
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
    request.delegate = self;
    [request start];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSArray *products = response.products;
    NSArray *invalidIdentifiers = response.invalidProductIdentifiers;
    
    if (self.productsCallback) {
        
        self.productsCallback(products, invalidIdentifiers);
        self.productsCallback = nil;
    }
    
    self.loadingProducts = NO;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    if (self.productsErrorCallback) {
        
        NSError *error1 = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                              code:GWIAPHelperErrorCodeProductFailed
                                          userInfo:error.userInfo];
        self.productsErrorCallback(error1);
        self.productsErrorCallback = nil;
    }
    self.loadingProducts = NO;
}

#pragma mark - 处理未完成交易
- (void)setupUncompleteCallback:(GWIAPHelperReceiptCallback)uncomplete {
    
    self.uncompleteCallback = uncomplete;
    if (self.receipt
        && self.uncompleteCallback) {
        
        self.uncompleteCallback(self.receipt);
        self.receipt = nil;
    }
}

#pragma mark - pay request
- (void)startPayWithSKProduct:(SKProduct *)product
                     quantity:(NSUInteger)quantity
                   purchasing:(GWIAPHelperPurchasingCallback)purchasingCallback
                   completion:(GWIAPHelperReceiptCallback)receiptCallback
                        error:(GWIAPHelperErrorCallback)errorCallback {
    
    // 有支付正在进行
    if (self.payProcessing) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeConcurrent
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"支付正在进行", @"msg", nil]];
            errorCallback(error);
        }
        return;
    }
    // 还有票据未处理
    if (self.receipt) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeReceiptNotUsed
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.receipt, @"receipt", nil]];
            errorCallback(error);
        }
        return;
    }
    // 产品不能为空
    if (!product
        || quantity == 0) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeParams
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"支付产品不能为空", @"msg", nil]];
            errorCallback(error);
        }
        return;
    }
    // 设备封禁
    if (![SKPaymentQueue canMakePayments]) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeDeviceSettingForbidden
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"您的设备禁用了支付功能", @"msg", nil]];
            errorCallback(error);
        }
        return;
    }
    self.payProcessing = YES;
    self.purchasingCallback = purchasingCallback;
    self.receiptCallback = receiptCallback;
    self.payErrorCallback = errorCallback;
    
    [self pPayWithSKProduct:product
                   quantity:quantity];
}

- (void)startPayWithProductIdentifier:(NSString *)productIdentifier
                             quantity:(NSUInteger)quantity
                           purchasing:(GWIAPHelperPurchasingCallback)purchasingCallback
                           completion:(GWIAPHelperReceiptCallback)receiptCallback
                                error:(GWIAPHelperErrorCallback)errorCallback {
    
    // 有支付正在进行
    if (self.payProcessing) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeConcurrent
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"支付正在进行", @"msg", nil]];
            errorCallback(error);
        }
        return;
    }
    // 还有票据未处理
    if (self.receipt) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeReceiptNotUsed
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.receipt, @"receipt", nil]];
            errorCallback(error);
        }
        return;
    }
    // 产品不能为空
    if (!productIdentifier
        || quantity == 0) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeParams
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"支付产品不能为空", @"msg", nil]];
            errorCallback(error);
        }
        return;
    }
    
    // 设备封禁
    if (![SKPaymentQueue canMakePayments]) {
        
        if (errorCallback) {
            
            NSError *error = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                                 code:GWIAPHelperErrorCodeDeviceSettingForbidden
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"您的设备禁用了支付功能", @"msg", nil]];
            errorCallback(error);
        }
        return;
    }
    
    self.payProcessing = YES;
    self.purchasingCallback = purchasingCallback;
    self.receiptCallback = receiptCallback;
    self.payErrorCallback = errorCallback;
    
    // 获取产品
    [self startLoadProductsWithProductIdentifiers:[NSSet setWithObject:productIdentifier]
                                       completion:^(NSArray *products, NSArray *invalidIdentifiers) {
                                           
                                           if (products
                                               && [products count] > 0) {
                                               
                                               // 取到产品，继续支付
                                               [self pPayWithSKProduct:[products lastObject]
                                                              quantity:quantity];
                                           } else {
                                               
                                               // 没取到产品回调
                                               NSError *error1 = [NSError errorWithDomain:GWIAPHelperErrorDomain code:GWIAPHelperErrorCodePayLoadProductFailed userInfo:[NSDictionary dictionaryWithObjectsAndKeys:invalidIdentifiers, @"result", nil]];
                                               if (errorCallback) {
                                                   
                                                   errorCallback(error1);
                                               }
                                               self.purchasingCallback = nil;
                                               self.receiptCallback = nil;
                                               self.payErrorCallback = nil;
                                               self.payProcessing = NO;
                                           }
                                       }
                                            error:^(NSError *error) {
                                                
                                                // 没取到产品回调
                                                NSError *error1 = [NSError errorWithDomain:GWIAPHelperErrorDomain code:GWIAPHelperErrorCodePayLoadProductFailed userInfo:error.userInfo];
                                                if (errorCallback) {
                                                    
                                                    errorCallback(error1);
                                                }
                                                self.purchasingCallback = nil;
                                                self.receiptCallback = nil;
                                                self.payErrorCallback = nil;
                                                self.payProcessing = NO;
                                            }];
}

- (void)pPayWithSKProduct:(SKProduct *)product
                 quantity:(NSUInteger)quantity {
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = quantity;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue
        updatedTransactions:(NSArray *)transactions {
    
    if (!transactions
        || [transactions count] == 0) {
        return;
    }
    
    for (SKPaymentTransaction *transaction in transactions) {
        
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateFailed: {
                
                // 购买失败
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self pTransactionFailed:transaction];
                break;
            }
                
            case SKPaymentTransactionStatePurchased: {
                
                // 购买成功
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self pTransactionPurchased:transaction];
                break;
            }
                
            case SKPaymentTransactionStatePurchasing: {
                
                // 支付中
                [self pTransactionPurchasing:transaction];
                break;
            }
                
            case SKPaymentTransactionStateRestored: {
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
                
            default: {
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
                
        }
        
    }
}

// 支付中
- (void)pTransactionPurchasing:(SKPaymentTransaction *)transaction {
    
    if (self.purchasingCallback) {
        
        self.purchasingCallback();
    }
}

// 支付成功，带票据回调
- (void)pTransactionPurchased:(SKPaymentTransaction *)transaction {
    
    NSData *receipt = nil;
    // 保存支付凭据
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        // Test whether the receipt is present at the above URL
        if(![[NSFileManager defaultManager] fileExistsAtPath:[receiptURL path]]) {
            
            receipt = [NSData dataWithContentsOfURL:receiptURL];
        } else {
            
            receipt = transaction.transactionReceipt;
        }
    } else {
        
        receipt = transaction.transactionReceipt;
    }
    
    if (self.receiptCallback) {
        
        self.receiptCallback(receipt);
    } else if (self.uncompleteCallback) {
        
        // 没有支付回调，当做未完成交易回调
        self.uncompleteCallback(receipt);
    } else {
        
        // 没有回调，当做未完成交易
        self.receipt = receipt;
    }
    self.purchasingCallback = nil;
    self.receiptCallback = nil;
    self.payErrorCallback = nil;
    self.payProcessing = NO;
}

// 支付失败回调
- (void)pTransactionFailed:(SKPaymentTransaction *)transaction {
    
    if (self.payErrorCallback) {
        
        NSError *error1 = [NSError errorWithDomain:GWIAPHelperErrorDomain
                                              code:GWIAPHelperErrorCodePayFailed
                                          userInfo:transaction.error.userInfo];
        self.payErrorCallback(error1);
    }
    self.purchasingCallback = nil;
    self.receiptCallback = nil;
    self.payErrorCallback = nil;
    self.payProcessing = NO;
}

#pragma mark - static sharedInstance
+ (instancetype)sharedInstance {
    
    static GWIAPHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[GWIAPHelper alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:sharedInstance];
    });
    return sharedInstance;
}

@end

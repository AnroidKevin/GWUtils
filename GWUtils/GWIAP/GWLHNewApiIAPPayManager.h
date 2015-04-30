//
//  GWLHNewApiIAPPayDataManager.h
//  testlib
//
//  Created by huangqisheng on 14-6-19.
//  Copyright (c) 2014年 PerfectWorld. All rights reserved.
//

#import "GWLHNewApiWithLoginBaseNetManager.h"

@interface GWLHNewApiIAPPayManager : GWLHNewApiWithLoginBaseNetManager

@property (nonatomic, retain) NSString *orderId;

/**
 *  创建IAP支付订单，并获取订单号
 *
 *  @param params     参见服务器接口文档
 *  @param completion 回调
 */
- (void)startGenerateIAPOrderWithParams:(NSDictionary *)params
                            payCurrency:currency
                               language:language
                                country:country
                             completion:(GWLHNewApiRequestWithStringCompletion)completion;

/**
 *  验证IAP票据
 *
 *  @param appOrder   游戏订单号, 可选
 *  @param ticket     IAP票据
 *  @param orderId    老虎订单号，可选
 *  @param completion 回调
 */
- (void)startValidateIAPTokenWithAppOrder:(NSString *)appOrder
                                  orderId:(NSString *)orderId
                                   ticket:(NSString *)ticket
                               completion:(GWLHNewApiRequestCompletion)completion;

#pragma mark - save receipt to file
- (NSString *)getIAPReceiptWithAppId:(NSString *)appId key:(NSString *)key;
- (void)saveReceipt:(NSDictionary *)receiptInfoDic
          withAppId:(NSString *)appId
                key:(NSString *)key;

@end

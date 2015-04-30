//
//  GWLHNewApiIAPPayDataManager.m
//  testlib
//
//  Created by huangqisheng on 14-6-19.
//  Copyright (c) 2014年 PerfectWorld. All rights reserved.
//

#import "GWLHNewApiIAPPayManager.h"

#import "GWUtil.h"
#import "GWFileManager.h"
#import "GWFBEncryptorAES.h"
#import "GWJSONKit.h"

#import "GWLHCenterErrorChecker.h"

@implementation GWLHNewApiIAPPayManager

- (void)dealloc {
    
    self.orderId = nil;
    
    [super dealloc];
}

- (void)startGenerateIAPOrderWithParams:(NSDictionary *)params
                            payCurrency:currency
                               language:language
                                country:country
                             completion:(GWLHNewApiRequestWithStringCompletion)completion {
    
    [self resetDefaultParams];
    
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithCapacity:([params count] + [self.GWRequestParams count])];
    [allParams addEntriesFromDictionary:self.GWRequestParams];
    [allParams addEntriesFromDictionary:params];
    
    allParams = [GWUtil signWithParameter:allParams];
    
    if (currency) {
        [allParams setValue:currency forKey:@"currency"];
    }
    if (language) {
        [allParams setValue:language forKey:@"language"];
    }
    if (country) {
        [allParams setValue:country forKey:@"country"];
    }
    
    [self.GWRequest sendAsynGETRequestWithPath:GW_NEW_API_IAP_GENERATE_IAP_ORDER
                                        params:allParams
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *result) {
                                           
                                            if (result) {
                                                
                                                NSError *error = nil;
                                                [self checkRequestResult:result
                                                                   error:&error
                                                   donothingForForbidden:nil];
                                                
                                                if (self.requestResult.code != 0) {
                                                    
                                                    if (completion) {
                                                        
                                                        completion(self.requestResult, nil, error);
                                                    }
                                                } else {
                                                    
                                                    id resultObject = [result objectForKey:@"result"];
                                                    
                                                    id orderIdObj = nil;
                                                    if ([result isKindOfClass:[NSDictionary class]]) {
                                                        
                                                        orderIdObj = [resultObject objectForKey:@"orderId"];
                                                    }
//                                                    id orderIdObj = [result objectForKey:@"orderId"];
                                                    NSString *orderId = nil;
                                                    if ([orderIdObj isKindOfClass:[NSString class]]) {
                                                        orderId = orderIdObj;
                                                    } else if ([orderIdObj respondsToSelector:@selector(stringValue)]) {
                                                        
                                                        orderId = [orderIdObj stringValue];
                                                    }
                                                    self.orderId = orderId;
                                                    
                                                    if (completion) {
                                                        
                                                        completion(self.requestResult, self.orderId, nil);
                                                    }
                                                }
                                            }
                                        }
                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                            
                                            if (completion) {
                                                
                                                completion(nil, nil, error);
                                            }
                                        }];
}

- (void)startValidateIAPTokenWithAppOrder:(NSString *)appOrder
                                  orderId:(NSString *)orderId
                                   ticket:(NSString *)ticket
                               completion:(GWLHNewApiRequestCompletion)completion {
    [self resetDefaultParams];
    
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithCapacity:([self.GWRequestParams count] + 3)];
    [allParams addEntriesFromDictionary:self.GWRequestParams];
    if (appOrder) {
        [allParams setObject:appOrder forKey:@"appOrder"];
    }
    if (orderId) {
        [allParams setObject:orderId forKey:@"orderId"];
    }
    [allParams setObject:ticket forKey:@"ticket"];
    
    allParams = [GWUtil signWithParameter:allParams];
    
    [self.GWRequest sendAsynPOSTRequestWithPath:GW_NEW_API_IAP_VALIDATE_IAP_TICKET
                                         params:allParams
                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *result) {
                                            
                                            if (result) {
                                                
                                                NSError *error = nil;
                                                [self checkRequestResult:result
                                                                   error:&error
                                                   donothingForForbidden:nil];
                                                
                                                if (self.requestResult.code != 0) {
                                                    
                                                    if (completion) {
                                                        
                                                        completion(self.requestResult, error);
                                                    }
                                                    
                                                } else if (completion) {
                                                    
                                                    completion(self.requestResult, nil);
                                                }
                                            }
                                        }
                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                            
                                            if (completion) {
                                                
                                                completion(nil, error);
                                            }
                                        }];
    
}

#pragma mark - save receipt to file
- (NSString *)getIAPReceiptWithAppId:(NSString *)appId key:(NSString *)key {
    
    NSString *receiptPath = [self getReceiptFilePathWithAppId:appId key:key];
    
    return [[GWFileManager sharedInstance] getStringFromFile:receiptPath error:NULL];
    
}

- (void)saveReceipt:(NSDictionary *)receiptInfoDic
          withAppId:(NSString *)appId
                key:(NSString *)key {
    
    
    if (!receiptInfoDic
        || !appId
        || !key) {
        
        return;
    }
    
    // 取出原来已经有的
    NSString *originString = [self getIAPReceiptWithAppId:appId key:key];
    
    
    NSString *decrypt = nil;
    if (originString) {
        
        decrypt = [GWFBEncryptorAES decryptAES128AndPKCS7AndCBCWithBase64String:originString
                                                                            key:key
                                                                  separateLines:NO];
    }
    
//    GWDLog(@"origin data : %@", decrypt);
    
    // 将原来已存入的和当前需要存入的数据合并
    NSMutableArray *allReceiptInfo = [NSMutableArray array];
    if (decrypt) {
        
        NSArray *originInfo = (NSArray *)[decrypt objectFromJSONString];
        
        if (originInfo
            && [originInfo isKindOfClass:[NSArray class]]) {
            
            [allReceiptInfo addObjectsFromArray:originInfo];
        }
        
    }
    
    [allReceiptInfo addObject:receiptInfoDic];
    
    NSString *allReceiptString = [allReceiptInfo JSONStringWithOptions:GWJKSerializeOptionNone
                                                                 error:NULL];
    
    // 整体加密
    NSString *encrypt = [GWFBEncryptorAES encryptAES128AndPKCS7AndCBCWithBase64String:allReceiptString
                                                                                  key:key
                                                                        separateLines:NO];
    
    // 新数据重新存入
    [[GWFileManager sharedInstance] saveString:encrypt
                                        toFile:[self getReceiptFilePathWithAppId:appId key:key]
                                         error:NULL];
}

- (NSString *)getReceiptFilePathWithAppId:(NSString *)appId key:(NSString *)key {
    
    NSString *receiptFileName = [NSString stringWithFormat:@"%@_GWLaohuSDK_LaohuUsedData_%@.txt", appId, [GWUtil UtilMD5:appId]];
    NSString *receiptPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:receiptFileName];
    
    return receiptPath;
}

@end

//
//  GWSystemInfo.h
//  GWUtils
//
//  Created by huangqisheng on 14/12/11.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GWSystemInfo : NSObject

+ (NSString *)getIPAdress;
+ (NSString *)getMacAddress;

+ (NSString *)getOSVersion;

+ (BOOL)isJailbroken;

@end

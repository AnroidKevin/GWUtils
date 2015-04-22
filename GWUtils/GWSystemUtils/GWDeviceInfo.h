//
//  GWDeviceInfo.h
//  GWUtils
//
//  Created by huangqisheng on 14/12/11.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GWDeviceInfo : NSObject

+ (NSString *)currentDeviceModel;           // e.g. @"iPhone", @"iPod touch"
+ (NSString *)currentDeviceName;            // e.g. @"My iPhone"
+ (NSString *)currentDeviceSystemVersion;   // e.g. @"4.0"
+ (NSString *)currentDevicePlatform;        // e.g. @"iPhone1,1"

+ (BOOL)deviceIsIPad;
+ (BOOL)deviceIsIPhoneOrTouch;

@end

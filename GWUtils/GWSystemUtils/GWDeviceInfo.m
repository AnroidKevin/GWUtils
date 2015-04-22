//
//  GWDeviceInfo.m
//  GWUtils
//
//  Created by huangqisheng on 14/12/11.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <sys/sysctl.h>
#import <UIKit/UIKit.h>

#import "GWDeviceInfo.h"

@implementation GWDeviceInfo

#pragma mark - device info
+ (NSString *)currentDeviceModel {
    
    return [[UIDevice currentDevice] model];
}

+ (NSString *)currentDeviceName {
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    return deviceName;
}

+ (NSString *)currentDeviceSystemVersion {
    
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)currentDevicePlatform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    //    NSString *platform = @(machine);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (BOOL)deviceIsIPad
{
    static BOOL ret = NO;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        ret = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    });
    return ret;
}

+ (BOOL)deviceIsIPhoneOrTouch
{
    static BOOL ret = NO;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        ret = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    });
    return ret;
}

@end

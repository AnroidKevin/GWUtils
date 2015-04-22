//
//  GWSystemApiHelper.m
//  GWUtils
//
//  Created by huangqisheng on 14/12/11.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GWSystemApiHelper.h"

@implementation GWSystemApiHelper

+ (BOOL)systemIsIOS6AndLater {
    static BOOL ret = NO;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        //        ret = [[UIDevice currentDevice].systemVersion floatValue] >= 6.0;
        ret = [[UIDevice currentDevice].systemVersion floatValue] >= 6.0;
    });
    return ret;
}

+ (BOOL)systemIsIOS7AndLater {
    static BOOL ret = NO;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        //        ret = [[UIDevice currentDevice].systemVersion floatValue] >= 6.0;
        ret = [[UIDevice currentDevice].systemVersion floatValue] >= 7.0;
    });
    return ret;
}

+ (BOOL)systemIsIOS8AndLater {
    static BOOL ret = NO;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        //        ret = [[UIDevice currentDevice].systemVersion floatValue] >= 6.0;
        ret = [[UIDevice currentDevice].systemVersion floatValue] >= 8.0;
    });
    return ret;
}

@end

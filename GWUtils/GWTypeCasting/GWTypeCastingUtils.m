//
//  GWTypeCastingUtils.m
//  GWUtils
//
//  Created by huangqisheng on 14/12/18.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "GWTypeCastingUtils.h"

@implementation GWTypeCastingUtils

/**
 * @brief 获取模型属性为NSString类型
 * @param `id` 属性值
 * @return `NSString *` 返回NSString
 */
+ (NSString *)GWStringValue:(id)value {
    
    NSString *ret = nil;
    id valueTmp = [self GWNSNullToNil:value];
    if (!valueTmp) {
        
        // do nothing.
    } else if ([valueTmp isKindOfClass:[NSString class]]) {
        
        ret = valueTmp;
    } else if ([valueTmp respondsToSelector:@selector(stringValue)]) {
        
        ret = [valueTmp stringValue];
    }
    
    return ret;
}

/**
 * @brief 获取模型属性为NSInteger类型
 * @param `id` 属性值
 * @return `NSInteger` 返回NSInteger
 */
+ (NSInteger)GWIntegerValue:(id)value {
    
    NSInteger ret = 0;
    id valueTmp = [self GWNSNullToNil:value];
    
    if (!valueTmp
        && [valueTmp respondsToSelector:@selector(integerValue)]) {
            ret = [valueTmp integerValue];
        }
    return ret;
}

/**
 * @brief 获取模型属性为BOOL类型
 * @param `id` 属性值
 * @return `BOOL` 返回BOOL, 默认返回NO
 */
+ (BOOL)GWBoolValue:(id)value {
    
    BOOL ret = NO;
    id valueTmp = [self GWNSNullToNil:value];
    
    if (!valueTmp
        && [valueTmp respondsToSelector:@selector(boolValue)]) {
        ret = [valueTmp boolValue];
    }
    return ret;
}

/**
 * @brief 获取模型属性为CGFloat类型
 * @param `id` 属性值
 * @return `CGFloat` 返回CGFloat
 */
+ (CGFloat)GWFloatValue:(id)value {
    
    CGFloat ret = 0.f;
    id valueTmp = [self GWNSNullToNil:value];
    
    if (!valueTmp
        && [valueTmp respondsToSelector:@selector(doubleValue)]) {
        ret = [valueTmp doubleValue];
    }
    return ret;
}

/**
 *  @brief  将NSNull对象转化成nil，其他类型的对象不变。
 *
 *  @param object 待转化的对象
 *
 *  @return 如果object为NSNull，返回nil，否则返回原值
 */
+ (id)GWNSNullToNil:(id)object {
    
    if (object == [NSNull null]) {
        return nil;
    }
    return object;
}

@end

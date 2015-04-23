//
//  GWTypeCastingUtils.h
//  GWUtilsPro
//
//  Created by huangqisheng on 14/12/18.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GWTypeCastingUtils : NSObject

/**
 * @brief 获取模型属性为NSString类型
 * @param `id` 属性值
 * @return `NSString *` 返回NSString
 */
+ (NSString *)GWStringValue:(id)value;

/**
 * @brief 获取模型属性为NSInteger类型
 * @param `id` 属性值
 * @return `NSInteger` 返回NSInteger
 */
+ (NSInteger)GWIntegerValue:(id)value;

/**
 * @brief 获取模型属性为BOOL类型
 * @param `id` 属性值
 * @return `BOOL` 返回BOOL, 默认返回NO
 */
+ (BOOL)GWBoolValue:(id)value;

/**
 * @brief 获取模型属性为CGFloat类型
 * @param `id` 属性值
 * @return `CGFloat` 返回CGFloat
 */
+ (CGFloat)GWFloatValue:(id)value;

/**
 *  @brief  将NSNull对象转化成nil，其他类型的对象不变。
 *
 *  @param object 待转化的对象
 *
 *  @return 如果object为NSNull，返回nil，否则返回原值
 */
+ (id)GWNSNullToNil:(id)object;

@end

//
//  NSDictionary+TypeCasting.h
//  GWUtils
//
//  Created by huangqisheng on 15/4/23.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (GWTypeCasting)

- (NSString *)GWStringValueForKey:(id)key;
- (NSInteger)GWIntergerValueForKey:(id)key;
- (CGFloat)GWFloatValueForKey:(id)key;
- (BOOL)GWBoolValueForKey:(id)key;

@end

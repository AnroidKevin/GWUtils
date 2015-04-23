//
//  NSDictionary+TypeCasting.m
//  GWUtils
//
//  Created by huangqisheng on 15/4/23.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "NSDictionary+GWTypeCasting.h"
#import "GWTypeCastingUtils.h"

@implementation NSDictionary (GWTypeCasting)

- (NSString *)GWStringValueForKey:(id)key {
    
    id value = [self objectForKey:key];
    
    return [GWTypeCastingUtils GWStringValue:value];
}

- (NSInteger)GWIntergerValueForKey:(id)key {
    
    id value = [self objectForKey:key];
    return [GWTypeCastingUtils GWIntegerValue:value];
}

- (CGFloat)GWFloatValueForKey:(id)key {
    
    id value = [self objectForKey:key];
    return [GWTypeCastingUtils GWFloatValue:value];
}

- (BOOL)GWBoolValueForKey:(id)key {
    
    id value = [self objectForKey:key];
    return [GWTypeCastingUtils GWBoolValue:value];
}

@end

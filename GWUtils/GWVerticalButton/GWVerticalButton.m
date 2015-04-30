//
//  GWVerticalButton.m
//  GWUtils
//
//  Created by huangqisheng on 15/4/24.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import "GWVerticalButton.h"

@implementation GWVerticalButton

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    
    CGRect originRect = [super imageRectForContentRect:contentRect];
    CGRect imageRect = originRect;
    // 水平居中
    imageRect.origin.x = contentRect.origin.x + (contentRect.size.width - originRect.size.width) / 2.f;
    // 竖直在顶部
    imageRect.origin.y = contentRect.origin.y + 2;
    return imageRect;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    
    CGRect originRect = [super titleRectForContentRect:contentRect];
    CGRect titleRect = originRect;
    titleRect.origin.x = contentRect.origin.x + (contentRect.size.width - originRect.size.width) / 2.f;
    // 竖直在底部
    titleRect.origin.y = contentRect.size.height + contentRect.origin.y - titleRect.size.height - 2;
    return titleRect;
}

- (CGSize)sizeThatFits:(CGSize)size {
    
    CGSize originSize = [super sizeThatFits:size];
    self.titleLabel.backgroundColor = [UIColor redColor];
    CGSize imageSize = [self.imageView sizeThatFits:size];
    CGSize titleSize = [self.titleLabel sizeThatFits:size];
    return CGSizeMake(originSize.width - MIN(imageSize.width, titleSize.width), imageSize.height + titleSize.height + 12.f);
}

@end

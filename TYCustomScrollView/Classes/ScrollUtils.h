//
//  ScrollUtils.h
//  TYCustomScrollView
//
//  Created by BYF on 1/19/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScrollUtils : NSObject

+ (CGFloat)computeVerticalScrollOffset:(UIView *)view;

+ (CGFloat)getScrollBottomOffset:(UIView *)view;

+ (CGFloat)getScrollTopOffset:(UIView *)view;

+ (BOOL)canScrollVertically:(UIView *)view direct:(int)direct;

@end

NS_ASSUME_NONNULL_END

//
//  ScrollUtils.m
//  TYCustomScrollView
//
//  Created by BYF on 1/19/22.
//

#import "ScrollUtils.h"

@implementation ScrollUtils

/**
 * 获取childView的偏移量
 */
+ (CGFloat)computeVerticalScrollOffset:(UIView *)view {
    
    if (view != nil && [view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        return scrollView.contentOffset.y;
    }else {
        return 0;
    }
}

/**
 * 获取View滑动到自身底部的偏移量
 */
+ (CGFloat)getScrollBottomOffset:(UIView *)view {
    
    if (view != nil && [view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        CGFloat offset = scrollView.contentSize.height - scrollView.contentOffset.y - CGRectGetHeight(scrollView.frame);
        NSLog(@"offset:%.2f", offset);
        return offset;
    }else {
        return 0;
    }
}

/**
 * 获取View滑动到自身顶部的偏移量
 */
+ (CGFloat)getScrollTopOffset:(UIView *)view {
    
    if (view != nil && [view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        CGFloat offset = scrollView.contentOffset.y;//CGRectGetMinY(scrollView.bounds);
        NSLog(@"offset:%.2f", offset);
        return -offset;
    }else {
        return 0;
    }
}

// 是否可以垂直滑动 bottom: 1, top: -1
+ (BOOL)canScrollVertically:(UIView *)view direct:(int)direct {
    
    if (view != nil && [view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        if (direct > 0) {
            return scrollView.contentOffset.y < scrollView.contentSize.height - CGRectGetHeight(scrollView.frame);
        }else {
            return scrollView.contentOffset.y > 0;
        }
    }else {
        return NO;
    }
}

@end

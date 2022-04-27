//
//  YFCustomScrollView.m
//  TYCustomScrollView
//
//  Created by BYF on 1/7/22.
//

#import "YFCustomScrollView.h"
// item
#import "TYDynamicItem.h"
// utils
#import "ScrollUtils.h"

/**
 * @param offset 顶部或底部，超出的部分 dimension
 * @param dimension 最大返回范围
 */
static CGFloat rubberBandDistance(CGFloat offset, CGFloat dimension) {

    const CGFloat constant = 0.55f;
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0f ? -result : result;
}

@interface YFCustomScrollView ()

@property CGRect startBounds;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, weak) UIDynamicItemBehavior *decelerationBehavior;
@property (nonatomic, weak) UIAttachmentBehavior *springBehavior;
@property (nonatomic, strong) TYDynamicItem *dynamicItem;
@property (nonatomic) CGPoint lastPointInBounds;

@property (nonatomic, assign) CGFloat mScrollRange;

// 这个值不是真实的布局滑动偏移量 记录模拟的偏移量 用于计算滑动时的距离变化（包含子view是scrollView的contentOffset）
@property (nonatomic, assign) CGFloat offsetY;

// 用于单独计算手指滑动时的偏移量
@property (nonatomic, assign) CGFloat startOffsetY;

@property (nonatomic, assign) CGFloat mContentSizeHeight;

//@property (nonatomic, assign) CGFloat total;

// 需自动计算
@property (nonatomic) CGSize contentSize;

#warning 考虑inset属性计算，方便上、下拉刷新等
@property (nonatomic, assign) UIEdgeInsets contentInset;

@end

@implementation YFCustomScrollView

// TODO: init
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }
    
    [self commonInitForCustomScrollView];
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self == nil) {
        return nil;
    }
    
    [self commonInitForCustomScrollView];
    return self;
}

- (void)commonInitForCustomScrollView
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGestureRecognizer];

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    self.dynamicItem = [[TYDynamicItem alloc] init];
}

// TODO: layout
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.mScrollRange = 0;
    self.mContentSizeHeight = 0;
    __block CGFloat childTop = 0.f;
    CGFloat left = 0.f;
    
    NSArray<UIView *> *children = [self getNonHiddenChildView];
    
    __weak typeof(self)weakSelf = self;
    [children enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        CGFloat bottom = childTop + CGRectGetHeight(obj.frame);
        obj.frame = CGRectMake(left, childTop, CGRectGetWidth(obj.frame), CGRectGetHeight(obj.frame));
        childTop = bottom;
        // 联动容器可滚动最大距离
        strongSelf.mContentSizeHeight += ({
            CGFloat contentHeight = 0.f;
            if (obj != nil && [obj isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView *)obj;
                contentHeight = scrollView.contentSize.height;
            }else {
                contentHeight = CGRectGetHeight(obj.frame);
            }
            contentHeight;
        });
        strongSelf.mScrollRange += CGRectGetHeight(obj.frame);
    }];
    // 联动容器可滚动range
    self.mScrollRange -= CGRectGetHeight(self.frame);
    self.mContentSizeHeight -= CGRectGetHeight(self.frame);
//    self.contentSize = CGSizeMake(CGRectGetWidth(self.frame), self.mScrollRange);
}

// TODO: Override
//- (void)addSubview:(UIView *)view {
//    [super addSubview:view];
//
//
//}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    NSLog(@"fittest->%@",view);
//    if (<#condition#>) {
//        <#statements#>
//    }
    NSLog(@"dddd%@", event.allTouches);
    return view;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL pointInside = [super pointInside:point withEvent:event];
    NSLog(@"xxxx%d", pointInside);
    [self.animator removeAllBehaviors];
    return pointInside;
}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"CustomScrollView %s",__func__);
//}

//- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesMoved:touches withEvent:event];
//    NSLog(@"ddddd");
//}
//responder

// TODO: Gesture
- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    NSLog(@"handlePanGesture");
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.startBounds = self.bounds;
            self.startOffsetY = 0;
            
            [self.animator removeAllBehaviors];
            
        }
            // fall through

        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGestureRecognizer translationInView:self];
            CGPoint touchPoint = [panGestureRecognizer locationInView:self];
            NSLog(@"touchPointX:%.2f   touchPointY:%.2f", touchPoint.x,  touchPoint.y);
            
            
            NSLog(@"translation:%.2f", translation.y);
            CGRect bounds = self.startBounds;
            CGFloat offsetY = self.startOffsetY;

//            if (!self.scrollHorizontal) {
//                translation.x = 0.0;
//            }
//            if (!self.scrollVertical) {
//                translation.y = 0.0;
//            }

//            CGFloat newBoundsOriginX = bounds.origin.x - translation.x;
//            CGFloat minBoundsOriginX = 0.0;
//            CGFloat maxBoundsOriginX = self.contentSize.width - bounds.size.width;
//            CGFloat constrainedBoundsOriginX = fmax(minBoundsOriginX, fmin(newBoundsOriginX, maxBoundsOriginX));
//            CGFloat rubberBandedX = rubberBandDistance(newBoundsOriginX - constrainedBoundsOriginX, CGRectGetWidth(self.bounds));
//            bounds.origin.x = constrainedBoundsOriginX + rubberBandedX;
//
            
            CGFloat newBoundsOriginY = bounds.origin.y - translation.y;
//            CGFloat nnY = newBoundsOriginY - self.bounds.origin.y;
            
            CGFloat newOffsetY = -translation.y;
            CGFloat newOffsetChange = newOffsetY - offsetY;
            
            CGFloat remainder = [self dispatchScroll:newOffsetChange];
            
//            self.offsetY += newOffsetChange;
            
            NSLog(@"self.offsetY:%.2f  newOffsetChange:%.2f self.bounds:%.2f", self.offsetY,  newOffsetChange, newBoundsOriginY);
            self.startOffsetY = newOffsetY;
//
            if (remainder != 0) {
                CGFloat minBoundsOriginY = 0.0;
                CGFloat maxBoundsOriginY = self.mScrollRange;
                CGFloat constrainedBoundsOriginY = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY));
                CGFloat rubberBandedY = rubberBandDistance(newBoundsOriginY - constrainedBoundsOriginY, CGRectGetHeight(self.bounds));
                bounds.origin.y = constrainedBoundsOriginY + rubberBandedY;


                NSLog(@"rubberBandedY:%.2f", bounds.origin.y);
                
                self.offsetY = bounds.origin.y + ([self outsideBoundsMaximum] ? self.mContentSizeHeight - self.mScrollRange : 0);
                if (self.offsetY < 1867) {
                    NSLog(@"dddddd");
                }
                
                self.bounds = bounds;
                
                
                NSLog(@"self.offsetY-rubberBandedY:%.2f", self.offsetY);
            }
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            CGPoint velocity = [panGestureRecognizer velocityInView:self];
            velocity.x = -velocity.x;
            velocity.y = -velocity.y;

            if (![self scrollHorizontal] || [self outsideBoundsMinimum] || [self outsideBoundsMaximum]) {
                velocity.x = 0;
            }
            if (![self scrollVertical] || [self outsideBoundsMinimum] || [self outsideBoundsMaximum]) {
                NSLog(@"scrollVertical：%d, outsideBoundsMinimum: %d, outsideBoundsMaximum: %d", ![self scrollVertical], [self outsideBoundsMinimum], [self outsideBoundsMaximum]);
                velocity.y = 0;
            }

            self.dynamicItem.center = CGPointMake(0, self.offsetY);
            if (self.offsetY < -1000) {
                NSLog(@"dddddd");
            }
            UIDynamicItemBehavior *decelerationBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.dynamicItem]];
            [decelerationBehavior addLinearVelocity:velocity forItem:self.dynamicItem];
            decelerationBehavior.resistance = 2.0;

            __weak typeof(self)weakSelf = self;
            decelerationBehavior.action = ^{
                // IMPORTANT: If the deceleration behavior is removed, the bounds' origin will stop updating. See other possible ways of updating origin in the accompanying blog post.

                if ([self outsideBoundsMinimum] || [self outsideBoundsMaximum]) {

                    CGFloat newOffsetY = weakSelf.dynamicItem.center.y - ([self outsideBoundsMaximum] ? self.mContentSizeHeight - self.mScrollRange : 0);
                    weakSelf.offsetY = weakSelf.dynamicItem.center.y;
                    if (self.offsetY < -1000) {
                        NSLog(@"dddddd");
                    }
                    CGRect bounds = weakSelf.bounds;
                    bounds.origin = CGPointMake(weakSelf.dynamicItem.center.x, newOffsetY);
//                    bounds.origin = weakSelf.dynamicItem.center;
                    weakSelf.bounds = bounds;

                    //weakSelf.dynamicItem 这个值不对！需要反复调整观察
                    NSLog(@"changeOffSetxxxy:%.2f", weakSelf.dynamicItem.center.y);
                    
                }else {
                    CGFloat changeOffSet = weakSelf.dynamicItem.center.y - self.offsetY;
                    NSLog(@"changeOffSetxxx:%.2f -- %.2f", changeOffSet, weakSelf.dynamicItem.center.y);
                    [weakSelf dispatchScroll:changeOffSet];
                    
//                    weakSelf.offsetY += changeOffSet;
                }
                if (self.offsetY < -1000) {
                    NSLog(@"dddddd");
                }
//                weakSelf.offsetY = weakSelf.dynamicItem.center.y;
            };

            [self.animator addBehavior:decelerationBehavior];
            self.decelerationBehavior = decelerationBehavior;
        }
            break;

        default:
            break;
    }
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    if (([self outsideBoundsMinimum] || [self outsideBoundsMaximum]) &&
        (self.decelerationBehavior && !self.springBehavior)) {

        CGPoint target = [self anchor];
//        CGPoint target = CGPointMake(0, 2867);

        UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.dynamicItem attachedToAnchor:target];
        // Has to be equal to zero, because otherwise the bounds.origin wouldn't exactly match the target's position.
        springBehavior.length = 0;
        // These two values were chosen by trial and error.
        springBehavior.damping = 1;
        springBehavior.frequency = 2;

        [self.animator addBehavior:springBehavior];
        self.springBehavior = springBehavior;
    }

    if (![self outsideBoundsMinimum] && ![self outsideBoundsMaximum]) {
        self.lastPointInBounds = CGPointMake(0, self.offsetY);
    }
}

- (BOOL)scrollVertical
{
    return self.mScrollRange > 0;
}

- (BOOL)scrollHorizontal
{
    return self.contentSize.width > CGRectGetWidth(self.bounds);
}

- (CGPoint)maxBoundsOrigin
{
    return CGPointMake(0,
                       self.mScrollRange);
}

- (BOOL)outsideBoundsMinimum
{
    return self.bounds.origin.x < 0.0 || self.bounds.origin.y < 0.0;
}

- (BOOL)outsideBoundsMaximum
{
    CGPoint maxBoundsOrigin = [self maxBoundsOrigin];
    return self.bounds.origin.x > maxBoundsOrigin.x || self.bounds.origin.y > maxBoundsOrigin.y;
}

- (CGPoint)anchor
{
    CGRect bounds = CGRectMake(0, self.offsetY, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    CGPoint maxBoundsOrigin = CGPointMake(0, self.mContentSizeHeight);

    CGFloat deltaX = self.lastPointInBounds.x - bounds.origin.x;
    CGFloat deltaY = self.lastPointInBounds.y - bounds.origin.y;

    // solves a system of equations: y_1 = ax_1 + b and y_2 = ax_2 + b
    CGFloat a = deltaY / deltaX;
    CGFloat b = self.lastPointInBounds.y - self.lastPointInBounds.x * a;

    CGFloat leftBending = -bounds.origin.x;
    CGFloat topBending = -bounds.origin.y;
    CGFloat rightBending = bounds.origin.x - maxBoundsOrigin.x;
    CGFloat bottomBending = bounds.origin.y - maxBoundsOrigin.y;

    // Updates anchor's `y` based on already set `x`, i.e. y = f(x)
    void(^solveForY)(CGPoint*) = ^(CGPoint *anchor) {
        // Updates `y` only if there was a vertical movement. Otherwise `y` based on current `bounds.origin` is already correct.
        if (deltaY != 0) {
            anchor->y = a * anchor->x + b;
        }
    };
    // Updates anchor's `x` based on already set `y`, i.e. x =  f^(-1)(y)
    void(^solveForX)(CGPoint*) = ^(CGPoint *anchor) {
        if (deltaX != 0) {
            anchor->x = (anchor->y - b) / a;
        }
    };

    CGPoint anchor = bounds.origin;

    if (bounds.origin.x < 0.0 && leftBending > topBending && leftBending > bottomBending) {
        anchor.x = 0;
        solveForY(&anchor);
    } else if (bounds.origin.y < 0.0 && topBending > leftBending && topBending > rightBending) {
        anchor.y = 0;
        solveForX(&anchor);
    } else if (bounds.origin.x > maxBoundsOrigin.x && rightBending > topBending && rightBending > bottomBending) {
        anchor.x = maxBoundsOrigin.x;
        solveForY(&anchor);
    } else if (bounds.origin.y > maxBoundsOrigin.y) {
        anchor.y = maxBoundsOrigin.y;
        solveForX(&anchor);
    }

    return anchor;
}

// TODO: Helper
- (NSArray<UIView *> *)getNonHiddenChildView {
    // 之后递归找到所有子view
    return ({
        NSMutableArray<UIView *> *children = [NSMutableArray array];
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (!obj.hidden) {
                [children addObject:obj];
            }
            
        }];
        children;
    });
}

- (UIScrollView *)getChildScrollView {
    return ({
        __block UIScrollView *scrollView;
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([obj isKindOfClass:UIScrollView.class]) {
                scrollView = obj;
                *stop = YES;
            }
            
        }];
        scrollView;
    });
}

/**
 * 滑动距离处理分发
 */
- (CGFloat)dispatchScroll:(CGFloat)offset {
    
    if (offset > 0) {
        // 向上滑动
        return [self scrollUp:offset];
    }else if (offset < 0) {
        // 向下滑动
        return [self scrollDown:offset];
    }
    
    return 0.f;
}

// 向上滑动 offset 容器将要滑动到的偏移位置
- (CGFloat)scrollUp:(CGFloat)offset {
    
    // 消费的滑动记录
    CGFloat scrollOffset = 0;
    // 未消费的滑动距离
    CGFloat remainder = offset;
    do {
        scrollOffset = 0;
        // 是否滑动到底部
        if (![self isScrollBottom]) {
            // 找到当前显示的第一个View
            UIView *firstVisibleView = [self findFirstVisibleView];
            if (firstVisibleView) {
                // 获取View滑动到自身底部的偏移量
                CGFloat bottomOffset = [ScrollUtils getScrollBottomOffset:firstVisibleView];
                NSLog(@"bottomOffset:%.2f", bottomOffset);
                NSLog(@"tag-%ld MaxY:%.2f MinY:%.2f", (long)firstVisibleView.tag, CGRectGetMaxY(firstVisibleView.frame), CGRectGetMinY(self.bounds));
                if (bottomOffset > 0) {
                    // 如果bottomOffset大于0，表示这个view还没有滑动到自身的底部，那么就由这个view来消费这次的滑动距离。
                    // 计算需要滑动的距离
                    scrollOffset = MIN(remainder, bottomOffset);
                    // 滑动子view
                    [self scrollChild:firstVisibleView offset:scrollOffset];
                    NSLog(@"scrollChild-Up:%.2f", scrollOffset);
                    self.offsetY += scrollOffset;
                    if (self.offsetY < -1000) {
                        NSLog(@"dddddd");
                    }
                }else {
                    // 如果子view已经滑动到自身的底部，就由父布局消费滑动距离，直到把这个子view滑出屏幕
                    CGFloat selfOldScrollY = CGRectGetMinY(self.bounds);
                    // 计算需要滑动的距离 求最小值防止子控件是滑动控件时 remainder过大滑动导致子控件不能居顶
                    scrollOffset = MIN(remainder, CGRectGetMaxY(firstVisibleView.frame) - selfOldScrollY);
                    // 滑动父布局
                    self.offsetY += scrollOffset;
                    CGRect bounds = self.bounds;
                    bounds.origin.y = scrollOffset + selfOldScrollY;
                    self.bounds = bounds;
                    if (self.offsetY < -1000) {
                        NSLog(@"dddddd");
                    }
                }
                // 计算消费的滑动距离，如果还没有消费完，就继续循环消费。
//                mOwnScrollY += scrollOffset;
                remainder -= scrollOffset;
                
            }
        }
        
    } while (scrollOffset > 0 && remainder > 0);
    
    return remainder;
}

// 向下滑动
- (CGFloat)scrollDown:(CGFloat)offset {
    
    // 消费的滑动记录
    CGFloat scrollOffset = 0;
    // 未消费的滑动距离
    CGFloat remainder = offset;
    do {
        scrollOffset = 0;
        // 是否滑动到底部
        if (![self isScrollTop]) {
            // 找到当前显示的第最后一个View
            UIView *lastVisibleView = [self findLastVisibleView];
            NSLog(@"lastVisibleView.tag:%ld", (long)lastVisibleView.tag);
            if (lastVisibleView) {
                // 获取View滑动到自身顶部的偏移量
                CGFloat childScrollOffset = [ScrollUtils getScrollTopOffset:lastVisibleView];
                
                if (childScrollOffset < 0) {
                    // 计算需要滑动的距离
                    scrollOffset = MAX(remainder, childScrollOffset);
                    // 滑动子view
                    [self scrollChild:lastVisibleView offset:scrollOffset];
                    NSLog(@"scrollChild-Down:%.2f", scrollOffset);
                    self.offsetY += scrollOffset;
                    if (self.offsetY < -1000) {
                        NSLog(@"dddddd");
                    }
                }else {
                    // 如果子view已经滑动到自身的顶部，就由父布局消费滑动距离，直到把这个子view滑出屏幕
                    CGFloat scrollY = CGRectGetMinY(self.bounds);
                    // 计算需要滑动的距离
                    scrollOffset = MAX(remainder,  CGRectGetMinY(lastVisibleView.frame) - scrollY - CGRectGetHeight(self.frame));
                    // 滑动父布局
                    self.offsetY += scrollOffset;
                    CGRect bounds = self.bounds;
                    bounds.origin.y = scrollOffset + scrollY;
                    self.bounds = bounds;
                    if (self.offsetY < -1000) {
                        NSLog(@"dddddd");
                    }
                }
                // 计算消费的滑动距离，如果还没有消费完，就继续循环消费。
//                mOwnScrollY += scrollOffset;
                remainder = remainder - scrollOffset;
                
            }
        }
        
    } while (scrollOffset < 0 && remainder < 0);
    
    return remainder;
}

- (BOOL)isScrollTop {

    CGFloat contentOffsetY = CGRectGetMinY(self.bounds);
    NSArray<UIView *> *children = [self getNonHiddenChildView];
    
    if (children && children.count > 0) {
        UIView *child = [children objectAtIndex:0];
        
        BOOL isScrollTop = contentOffsetY <= 0 && ![ScrollUtils canScrollVertically:child direct:-1];
        
        if (isScrollTop) {
#warning 后期此处-处理检查所有可滚动控件滑动偏移情况
        }
        
        return isScrollTop;
    }
    
    return YES;
}

- (BOOL)isScrollBottom {

    CGFloat contentOffsetY = CGRectGetMinY(self.bounds);
    NSArray<UIView *> *children = [self getNonHiddenChildView];
    
    if (children && children.count > 0) {
        UIView *child = [children objectAtIndex:children.count - 1];
        
        BOOL isScrollBottom = contentOffsetY >= self.mScrollRange && ![ScrollUtils canScrollVertically:child direct:1];
        
        if (isScrollBottom) {
#warning 后期此处-处理检查所有可滚动控件滑动偏移情况
        }
        
        return isScrollBottom;
    }
    
    return YES;
}


/**
 * 返回顶部第一个childView
 */
- (UIView *)findFirstVisibleView {
    
    CGFloat offset = CGRectGetMinY(self.bounds);
    NSArray<UIView *> *children = [self getNonHiddenChildView];
    
    __block UIView *child;
    
    [children enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat viewTop = CGRectGetMinY(obj.frame);
        CGFloat viewBottom = CGRectGetMaxY(obj.frame);
        if (viewTop <= offset && viewBottom > offset) {
            obj.tag = idx;
            child = obj;
            *stop = YES;
        }
    }];
    
    return child;
}

/**
 * 返回底部第一个childView
 */
- (UIView *)findLastVisibleView {
    
    CGFloat offset = CGRectGetMinY(self.bounds) + CGRectGetHeight(self.frame);
    NSArray<UIView *> *children = [self getNonHiddenChildView];
    
    __block UIView *child;
    
    __block CGFloat lastBottom = 0.f;
    
    [children enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat viewTop = lastBottom;
        CGFloat viewBottom = 0.f;
        viewBottom = lastBottom + CGRectGetHeight(obj.frame);
        lastBottom = viewBottom;
        if (viewTop < offset && viewBottom >= offset) {
            obj.tag = idx;
            child = obj;
            *stop = YES;
        }
    }];
    
    return child;
}

- (void)scrollChild:(UIView *)view offset:(CGFloat)offsetY {
    
    if (view != nil && [view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y + offsetY)];
    }
}


@end

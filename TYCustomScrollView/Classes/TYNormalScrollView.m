//
//  TYNormalScrollView.m
//  FBSnapshotTestCase
//
//  Created by BYF on 12/28/21.
//

#import "TYNormalScrollView.h"
// item
#import "TYDynamicItem.h"

static CGFloat rubberBandDistance(CGFloat offset, CGFloat dimension) {

    const CGFloat constant = 0.55f;
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0f ? -result : result;
}

@interface TYNormalScrollView ()<UITableViewDelegate, UITableViewDataSource>

@property CGRect startBounds;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, weak) UIDynamicItemBehavior *decelerationBehavior;
@property (nonatomic, weak) UIAttachmentBehavior *springBehavior;
@property (nonatomic, strong) TYDynamicItem *dynamicItem;
@property (nonatomic) CGPoint lastPointInBounds;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) CGFloat startY;
@property (nonatomic, assign) CGFloat endY;

@property (nonatomic, assign) CGFloat contentOffSetY;

@end

@implementation TYNormalScrollView

// TODO: init
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self commonInitForCustomScrollView];

    }
    return self;
}

- (void)commonInitForCustomScrollView
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGestureRecognizer];

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    self.dynamicItem = [[TYDynamicItem alloc] init];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 150, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) style:UITableViewStylePlain];
    self.tableView.rowHeight = 44;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = NO;
    [self addSubview:self.tableView];
    [self bringSubviewToFront:self.tableView];
}

// Gesture
- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    
    CGFloat maxBoundsOriginYToSelf = self.contentSize.height - CGRectGetHeight(self.frame);
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            int intY = (int)self.tableView.contentOffset.y;
            if (intY == 0 && CGRectGetMinY(self.bounds) < maxBoundsOriginYToSelf) {
                self.startY = CGRectGetMinY(self.bounds);
            }else {
                self.startY = self.tableView.contentOffset.y + maxBoundsOriginYToSelf;
            }
            self.startBounds = self.bounds;
            [self.animator removeAllBehaviors];
            self.endY = 0.0;
            self.contentOffSetY = 0.f;
        }
            // fall through
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGestureRecognizer translationInView:self];
            CGFloat Y = self.startY;
            CGRect bounds = self.startBounds;

            if (!self.scrollHorizontal) {
                translation.x = 0.0;
            }
            if (!self.scrollVertical) {
                translation.y = 0.0;
            }

            CGFloat newBoundsOriginY = Y - translation.y;
            
            CGFloat minBoundsOriginY = 0.0;
            
            CGFloat maxBoundsOriginY = maxBoundsOriginYToSelf;
            
            CGFloat childMaxBoundsOriginY = self.tableView.contentSize.height - CGRectGetHeight(self.frame);
            
            CGFloat contentMaxBoundsOriginY = maxBoundsOriginY + childMaxBoundsOriginY;
            
            CGFloat constrainedBoundsOriginY = fmax(minBoundsOriginY, fmin(newBoundsOriginY, contentMaxBoundsOriginY));
            
            CGFloat rubberBandedY = rubberBandDistance(newBoundsOriginY - constrainedBoundsOriginY, CGRectGetHeight(self.bounds));
            bounds.origin.y = fmin(maxBoundsOriginYToSelf, constrainedBoundsOriginY) + rubberBandedY;
            self.bounds = bounds;

            self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, fmin(childMaxBoundsOriginY, fmax(0, newBoundsOriginY - maxBoundsOriginYToSelf)));
            self.contentOffSetY = self.tableView.contentOffset.y;
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
                velocity.y = 0;
            }
            
            if ([self scrollVertical] && fabs(velocity.y) < 5 && fabs(velocity.y) > 0) {
                return;
            }
            if ([self scrollHorizontal] && fabs(velocity.x) < 5 && fabs(velocity.x) > 0) {
                return;
            }
            
            if (!self.dynamicItem) return;
            
            int intY = (int)self.tableView.contentOffset.y;
            if (intY == 0 && CGRectGetMinY(self.bounds) < maxBoundsOriginYToSelf) {
                self.dynamicItem.center = CGPointMake(self.dynamicItem.center.x, self.bounds.origin.y);
            }else {
                self.dynamicItem.center = CGPointMake(self.dynamicItem.center.x, self.tableView.contentOffset.y + maxBoundsOriginYToSelf);
            }

            self.dynamicItem.center = self.bounds.origin;
            UIDynamicItemBehavior *decelerationBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.dynamicItem]];
            [decelerationBehavior addLinearVelocity:velocity forItem:self.dynamicItem];
            decelerationBehavior.resistance = 2.0;

            __weak typeof(self)weakSelf = self;
            decelerationBehavior.action = ^{
                // IMPORTANT: If the deceleration behavior is removed, the bounds' origin will stop updating. See other possible ways of updating origin in the accompanying blog post.
                CGRect bounds = weakSelf.bounds;
                bounds.origin.y = fmax((weakSelf.dynamicItem.center.y - (weakSelf.tableView.contentSize.height - CGRectGetHeight(weakSelf.frame))), fmin(maxBoundsOriginYToSelf, weakSelf.dynamicItem.center.y));
                weakSelf.bounds = bounds;
                
                if (weakSelf.tableView.contentOffset.y == (weakSelf.tableView.contentSize.height - CGRectGetHeight(weakSelf.frame))) {
                    weakSelf.endY = weakSelf.tableView.contentSize.height - CGRectGetHeight(weakSelf.frame);
                }
                
                if (weakSelf.endY > 0) {
                    weakSelf.tableView.contentOffset = CGPointMake(weakSelf.tableView.contentOffset.x, weakSelf.endY);
                }else {
                    weakSelf.tableView.contentOffset = CGPointMake(weakSelf.tableView.contentOffset.x, fmin(weakSelf.tableView.contentSize.height - CGRectGetHeight(weakSelf.frame), fmax(0, weakSelf.dynamicItem.center.y - maxBoundsOriginYToSelf)));
                }
            };

            [self.animator addBehavior:decelerationBehavior];
            self.decelerationBehavior = decelerationBehavior;
        }
            break;

        default:
            break;
    }
}

// TODO: Helper
- (BOOL)scrollVertical
{
    return self.contentSize.height > CGRectGetHeight(self.bounds);
}

- (BOOL)scrollHorizontal
{
    return self.contentSize.width > CGRectGetWidth(self.bounds);
}

- (CGPoint)maxBoundsOrigin
{
    return CGPointMake(self.contentSize.width - self.bounds.size.width,
                       self.contentSize.height - self.bounds.size.height);
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

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    if (([self outsideBoundsMinimum] || [self outsideBoundsMaximum]) &&
        (self.decelerationBehavior && !self.springBehavior)) {

        CGPoint target = [self anchor];

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
        self.lastPointInBounds = bounds.origin;
    }
}

- (CGPoint)anchor
{
    CGRect bounds = self.bounds;
    CGPoint maxBoundsOrigin = [self maxBoundsOrigin];

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

// TODO: Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"cell row is %ld", (long)indexPath.row];
    cell.backgroundColor = indexPath.row % 2 == 0 ? [UIColor greenColor] : [UIColor orangeColor];
    
    return cell;
}


@end

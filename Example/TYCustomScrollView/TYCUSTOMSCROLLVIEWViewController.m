//
//  TYCUSTOMSCROLLVIEWViewController.m
//  TYCustomScrollView
//
//  Created by baiyunfei on 12/20/2021.
//  Copyright (c) 2021 baiyunfei. All rights reserved.
//

#import "TYCUSTOMSCROLLVIEWViewController.h"

#import "TYNormalScrollView.h"
#import "YFCustomScrollView.h"

#import "Masonry.h"

#import <WebKit/WebKit.h>

static WKProcessPool *sharedPool;
static dispatch_once_t onceToken;

@interface TYScorllView : UIScrollView<UIScrollViewDelegate>

@end

@implementation TYScorllView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
    }
    return self;
}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    // 将事件传递给下一响应者
//    [self.nextResponder touchesBegan:touches withEvent:event];
//    // 调用父类的touch方法 和上面的方法效果一样 这两句只需要其中一句
////    [super touchesBegan:touches withEvent:event];
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    NSLog(@"1111");
    CGPoint point = [scrollView.panGestureRecognizer translationInView:self];
    if (point.x != 0) {
        // 向滚动
    } else {
        // 向上滚动
    }
}

@end

@interface TYGravityView : UIView<UIDynamicItem>

@end

@implementation TYGravityView

@end

@interface TYCUSTOMSCROLLVIEWViewController ()<UITableViewDelegate, UITableViewDataSource>

// view
@property (nonatomic, strong) UIView *vContainer;

@property (nonatomic, strong) UIDynamicAnimator *animator;

@property (nonatomic, strong) UIGravityBehavior *gBehavior;

@property (nonatomic, strong) UICollisionBehavior *collisionBehavior;

@property (nonatomic, strong, readonly) WKWebView *webView;

@end

@implementation TYCUSTOMSCROLLVIEWViewController

+ (WKProcessPool *)singleWkProcessPool
{
    dispatch_once(&onceToken, ^{
        sharedPool = [[WKProcessPool alloc] init];
    });
    
    return sharedPool;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//    _vContainer = [UIView new];
//    _vContainer.backgroundColor = [UIColor greenColor];
//    [self.view addSubview:_vContainer];
//    [_vContainer mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.mas_equalTo(0);
//    }];
//
//    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:_vContainer];
//
//    UIView *box = [UIView new];
//    box.backgroundColor = [UIColor redColor];
//    [_vContainer addSubview:box];
//    [box mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.centerX.mas_equalTo(0);
//        make.width.height.mas_equalTo(100);
//    }];
//
//    [_vContainer setNeedsLayout];
//    [_vContainer layoutIfNeeded];
//
//    _gBehavior = [[UIGravityBehavior alloc] initWithItems:@[box]];
//    _collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[box]];
//    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
//
//    [_animator addBehavior:_gBehavior];
//    [_animator addBehavior:_collisionBehavior];
//
//    UIButton *btnReplay = [UIButton new];
//    [btnReplay setTitle:@"Replay" forState:UIControlStateNormal];
//    [self.view addSubview:btnReplay];
//    [btnReplay mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(100);
//        make.left.mas_equalTo(20);
//        make.width.mas_equalTo(80);
//        make.height.mas_equalTo(40);
//    }];
//    [btnReplay addTarget:self action:@selector(on_clickReplay) forControlEvents:UIControlEventTouchUpInside];
    
    // TYNormalScrollView
//    TYNormalScrollView *scrollView = [[TYNormalScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
//    scrollView.backgroundColor = [UIColor brownColor];
//    scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) + 150);
//    [self.view addSubview:scrollView];
    
    
    YFCustomScrollView *scrollView = [[YFCustomScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
    [self.view addSubview:scrollView];
    
    // 添加childView
    {
        UIView *view = [UIView new];
        view.tag = 1;
        view.backgroundColor = [UIColor greenColor];
        [scrollView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
            make.height.mas_equalTo(400);
        }];
    }
    {
        TYScorllView *view = [TYScorllView new];
        view.tag = 2;
//        view.scrollEnabled = NO;
        view.backgroundColor = [UIColor yellowColor];
        [scrollView addSubview:view];
        [view setContentSize:CGSizeMake(2000, 1000)];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
            make.height.mas_equalTo(667);
        }];
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"111";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"222";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(100);
                make.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"333";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(200);
                make.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"444";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(300);
                make.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
    }
    {
        UIScrollView *view = [UIScrollView new];
        view.tag = 3;
        view.scrollEnabled = NO;
        view.backgroundColor = [UIColor greenColor];
        [scrollView addSubview:view];
        [view setContentSize:CGSizeMake(200, 667*2)];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
            make.height.mas_equalTo(667);
        }];
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"111";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"222";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(100);
                make.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"333";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(200);
                make.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
        {
            UILabel *lbContent = [UILabel new];
            lbContent.text = @"444";
            [view addSubview:lbContent];
            [lbContent mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(300);
                make.left.mas_equalTo(0);
                make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
                make.height.mas_equalTo(100);
            }];
        }
    }
    {
        UIView *view = [UIView new];
        view.tag = 4;
        view.backgroundColor = [UIColor redColor];
        [scrollView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
            make.height.mas_equalTo(200);
        }];
    }
    {
        UIView *view = [UIView new];
        view.tag = 5;
        view.backgroundColor = [UIColor systemPinkColor];
        [scrollView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
            make.height.mas_equalTo(100);
        }];
    }
    {
        UIView *view = [UIView new];
        view.tag = 6;
        view.backgroundColor = [UIColor greenColor];
        [scrollView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
            make.height.mas_equalTo(200);
        }];
    }
    {
        UIView *view = [UIView new];
        view.tag = 7;
        view.backgroundColor = [UIColor redColor];
        [scrollView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(CGRectGetWidth(self.view.bounds));
            make.height.mas_equalTo(300);
        }];
    }
    
//    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(scrollView.bounds), CGRectGetHeight(scrollView.bounds)) style:UITableViewStylePlain];
//    tableView.rowHeight = 44;
//    tableView.delegate = self;
//    tableView.dataSource = self;
//    tableView.scrollEnabled = NO;
//    [scrollView addSubview:tableView];
//    [scrollView bringSubviewToFront:tableView];
    
//    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
//    config.allowsInlineMediaPlayback = YES;
//    if (@available(iOS 10.0, *)) {
//        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
//    }
//    config.processPool = [[self class] singleWkProcessPool];
////    config.applicationNameForUserAgent = [self hp_YunnanUserAgent];
//    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
//
//    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 375, 667)
//                                   configuration:config];
//    _webView.backgroundColor = [UIColor whiteColor];
////    _webView.scrollView.delegate = self;
////    _webView.navigationDelegate = self;
////    _webView.allowsLinkPreview = NO;
//    [self.view addSubview:_webView];
//
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"321" ofType:@"html"];
//     NSURL *pathURL = [NSURL fileURLWithPath:filePath];
//    [_webView loadRequest:[NSURLRequest requestWithURL:pathURL]];
    
}

// TODO: Event
- (void)on_clickReplay {
    
    [_animator removeBehavior:_gBehavior];
    [_animator removeBehavior:_collisionBehavior];
    [_animator addBehavior:_gBehavior];
    [_animator addBehavior:_collisionBehavior];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"clicked");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

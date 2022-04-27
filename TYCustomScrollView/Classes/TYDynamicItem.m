//
//  TYDynamicItem.m
//  TYCustomScrollView
//
//  Created by BYF on 1/4/22.
//

#import "TYDynamicItem.h"

@implementation TYDynamicItem

- (instancetype)init {
    self = [super init];

    if (self) {
        // Sets non-zero `bounds`, because otherwise Dynamics throws an exception.
        _bounds = CGRectMake(0, 0, 1, 1);
    }

    return self;
}

@end

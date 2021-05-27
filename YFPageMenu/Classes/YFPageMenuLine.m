//
//  YFPageMenuLine.m
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import "YFPageMenuLine.h"

@implementation YFPageMenuLine

// 当外界设置隐藏和alpha值时，让pageMenu重新布局
- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (self.hideBlock) {
        self.hideBlock();
    }
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    if (self.hideBlock) {
        self.hideBlock();
    }
}


@end

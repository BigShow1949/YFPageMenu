//
//  YFPageMenuScrollView.m
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import "YFPageMenuScrollView.h"

@implementation YFPageMenuScrollView

// 重写这个方法的目的是：当手指长按按钮时无法滑动scrollView的问题
- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES;
}
@end

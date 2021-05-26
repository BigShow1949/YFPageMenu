//
//  YFPageMenuTrack.m
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import "YFPageMenuTracker.h"
#import "YFPageMenuButton.h"
#import "YFPageMenuScrollView.h"

@implementation YFPageMenuTracker

- (instancetype)init
{
    self = [super init];
    if (self) {
        _spacing       = 30;
        _trackerHeight = 3.0;
        _segmentBorderColor = [UIColor colorWithRed:187/255.0 green:187/255.0 blue:187/255.0 alpha:1.0];
        self.layer.cornerRadius = _trackerHeight * 0.5;
//        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)setTrackerWidth:(CGFloat)trackerWidth {
    _trackerWidth = trackerWidth;
    CGRect trackerRect = self.frame;
    trackerRect.size.width = trackerWidth;
    self.frame = trackerRect;
    CGPoint trackerCenter = self.center;
    trackerCenter.x = _selectedButton.center.x;
    self.center = trackerCenter;
}

- (void)setTrackerStyle:(YFPageMenuTrackerStyle)trackerStyle {
    _trackerStyle = trackerStyle;
    switch (trackerStyle) {
        case YFPageMenuTrackerStyleLine:
        case YFPageMenuTrackerStyleLineLongerThanItem:
        case YFPageMenuTrackerStyleLineAttachment:
//            self.backgroundColor = _selectedItemTitleColor;
            break;
        case YFPageMenuTrackerStyleRoundedRect:
        case YFPageMenuTrackerStyleRect:
        case YFPageMenuTrackerStyleSegment:
            self.backgroundColor = [UIColor redColor];
            // _trackerHeight是默认有值的，所有样式都会按照事先询问_trackerHeight有没有值，如果有值则采用_trackerHeight，如果矩形或圆角矩形样式下也用_trackerHeight高度太小了，除非外界用户自己设置了_trackerHeight
            _trackerHeight = 0;
            break;
        default:
            break;
    }
}

- (void)resetupTrackerFrameWithSelectedButton:(YFPageMenuButton *)selectedButton {
    CGFloat trackerX;
    CGFloat trackerY;
    CGFloat trackerW;
    CGFloat trackerH;
    CGFloat selectedButtonWidth = selectedButton.frame.size.width;
    CGFloat itemScrollViewH = self.itemScrollView.bounds.size.height;
    switch (self.trackerStyle) {
        case YFPageMenuTrackerStyleLine:
        {
            trackerW = _trackerWidth ? _trackerWidth : selectedButtonWidth;
            trackerH = _trackerHeight;
            trackerX = selectedButton.frame.origin.x;
            trackerY = itemScrollViewH - trackerH;
            self.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
        }
            break;
        case YFPageMenuTrackerStyleLineLongerThanItem:
        {
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+(selectedButtonWidth ? _spacing : 0));
            trackerH = _trackerHeight;
            trackerX = selectedButton.frame.origin.x;
            trackerY = itemScrollViewH - trackerH;
            self.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
        }
            break;
        case YFPageMenuTrackerStyleLineAttachment:
        {
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth ? selectedButton.titleLabel.font.pointSize : 0); // 没有自定义宽度就固定宽度为字体大小
            trackerH = _trackerHeight;
            trackerX = selectedButton.frame.origin.x;
            trackerY = itemScrollViewH - trackerH;
            self.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
        }
            break;
        case YFPageMenuTrackerStyleRect:
        {
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+(selectedButtonWidth ? _spacing : 0));
            trackerH = _trackerHeight ? _trackerHeight : (selectedButton.frame.size.height);
            trackerX = selectedButton.frame.origin.x;
            trackerY = (itemScrollViewH-trackerH)*0.5;
            self.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
            self.layer.cornerRadius = 0;
        }
            break;
        case YFPageMenuTrackerStyleSegment:
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+(selectedButtonWidth ? _spacing : 0));
            trackerH = _trackerHeight ? _trackerHeight : (selectedButton.frame.size.height);
            trackerX = selectedButton.frame.origin.x;
            trackerY = (itemScrollViewH-trackerH)*0.5;
            self.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
            self.layer.cornerRadius = 0;

            self.attachView.layer.cornerRadius = self.frame.size.height/2;
            self.attachView.clipsToBounds = YES;
            self.attachView.layer.borderColor = _segmentBorderColor.CGColor;
            self.attachView.layer.borderWidth = 0.5;
            break;
        case YFPageMenuTrackerStyleRoundedRect:
        {
            trackerH = _trackerHeight ? _trackerHeight : (_selectedButton.titleLabel.font.lineHeight+10);
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+_spacing);
            trackerX = selectedButton.frame.origin.x;
            trackerY = (itemScrollViewH-trackerH)*0.5;
            self.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
            self.layer.cornerRadius = MIN(trackerW, trackerH)*0.5;
            self.layer.masksToBounds = YES;
        }
            break;
        default:
            break;
    }

    CGPoint trackerCenter = self.center;
    trackerCenter.x = selectedButton.center.x;
    self.center = trackerCenter;
//    NSLog(@"height ==== %f", self.frame.size.height);
}

- (void)setTrackerHeight:(CGFloat)trackerHeight {
    _trackerHeight = trackerHeight;
    self.layer.cornerRadius = trackerHeight/2;
    [self setNeedsLayout];
    [self layoutIfNeeded];

}


@end

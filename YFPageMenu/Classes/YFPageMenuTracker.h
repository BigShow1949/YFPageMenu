//
//  YFPageMenuTrack.h
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YFPageMenuButton,YFPageMenuScrollView;
typedef NS_ENUM(NSInteger, YFPageMenuTrackerStyle) {
    YFPageMenuTrackerStyleLine = 0,                  // 下划线,默认与item等宽
    YFPageMenuTrackerStyleLineLongerThanItem,        // 下划线,比item要长(长度为item的宽+间距)
    YFPageMenuTrackerStyleLineAttachment,            // 下划线“依恋”样式，此样式下默认宽度为字体的pointSize，你可以通过trackerWidth自定义宽度
    YFPageMenuTrackerStyleRoundedRect,               // 圆角矩形
    YFPageMenuTrackerStyleRect,                      // 矩形
    YFPageMenuTrackerStyleSegment,                   // segment样式  仅在 YFPageMenuPermutationWayNotScrollEqualWidths 样式下有效
    YFPageMenuTrackerStyleNothing                    // 什么样式都没有
};

typedef NS_ENUM(NSInteger, YFPageMenuTrackerFollowingMode) {
    YFPageMenuTrackerFollowingModeAlways = 0,   // 外界scrollView拖动时，跟踪器时刻跟随外界scrollView移动
    YFPageMenuTrackerFollowingModeEnd,     // 外界scrollVie拖动结束后，跟踪器才开始移动
    YFPageMenuTrackerFollowingModeHalf     // 外界scrollView拖动到一半时，跟踪器开始移动
};


@interface YFPageMenuTracker : UIImageView

#if TARGET_INTERFACE_BUILDER
@property (nonatomic,readonly) IBInspectable NSInteger trackerStyle; // 该枚举属性支持storyBoard/xib,方便在storyBoard/xib中创建时直接设置
#else
@property (nonatomic,assign) YFPageMenuTrackerStyle trackerStyle;
#endif

@property (nonatomic,strong) YFPageMenuButton *selectedButton;

@property (nonatomic,strong) YFPageMenuScrollView *itemScrollView;
/**
 * 跟踪器的跟踪模式
 */
@property (nonatomic,assign) YFPageMenuTrackerFollowingMode trackerFollowingMode;
/**
 *  跟踪器的高度度 默认：3（如果显示圆角，默认是高度的一半）
 */
@property (nonatomic,assign) CGFloat trackerHeight;
/**
 *  跟踪器的宽度 默认：根据selectedButton计算
 */
@property (nonatomic,assign) CGFloat trackerWidth;
/**
 *  依附的view 比如：YFPageMenu的实例对象
 */
@property (nonatomic,weak) UIView *attachView;
/**
 *  item之间的间距 默认：30
 */
@property (nonatomic,assign) CGFloat spacing;
/**
 *  边框颜色 默认：#BBBBBB
 */
@property (nonatomic,strong) UIColor *segmentBorderColor;




- (void)resetupTrackerFrameWithSelectedButton:(YFPageMenuButton *)selectedButton;


@end

NS_ASSUME_NONNULL_END

//
//  YFPageMenu.h
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//


#import <UIKit/UIKit.h>
#import "YFPageMenuButton.h"
#import "YFPageMenuButtonItem.h"
#import "YFPageMenuTracker.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, YFPageMenuPermutationWay) {
    YFPageMenuPermutationWayScrollAdaptContent = 0,  // 自适应内容,可以左右滑动   默认
    YFPageMenuPermutationWayNotScrollEqualWidths,    // 等宽排列,不可以滑动,整个内容被控制在pageMenu的范围之内,等宽是根据pageMenu的总宽度对每个按钮均分
    YFPageMenuPermutationWayNotScrollAdaptContent    // 自适应内容,不可以滑动,整个内容被控制在pageMenu的范围之内,这种排列方式下,自动计算item之间的间距,spacing属性无效
};


@class YFPageMenu;

@protocol YFPageMenuDelegate <NSObject>

@optional
// 点击item的时候会调用
- (void)pageMenu:(YFPageMenu *)pageMenu itemSelectedFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

// 右侧的功能按钮被点击的代理方法
- (void)pageMenu:(YFPageMenu *)pageMenu functionButtonClicked:(UIButton *)functionButton;
@end

@interface YFPageMenu : UIView

// 创建pagMenu
+ (instancetype)pageMenuWithFrame:(CGRect)frame trackerStyle:(YFPageMenuTrackerStyle)trackerStyle;
- (instancetype)initWithFrame:(CGRect)frame trackerStyle:(YFPageMenuTrackerStyle)trackerStyle;

/**
 *  传递数据
 *
 *  @param items    数组 (数组元素可以是NSString、UIImage类型、YFPageMenuButtonItem类型，其中YFPageMenuButtonItem相当于一个模型，可以同时设置图片和文字)
 *  @param selectedItemIndex  默认选中item的下标
 */
- (void)setItems:(nullable NSArray *)items selectedItemIndex:(NSInteger)selectedItemIndex;

@property (nonatomic) NSInteger selectedItemIndex; // 选中的item下标，改变其值可以用于切换选中的item
@property(nonatomic,readonly) NSUInteger numberOfItems; // items的总个数


// 跟踪器
@property (nonatomic,readonly) YFPageMenuTracker *tracker;

@property (nonatomic,assign) YFPageMenuPermutationWay permutationWay; // 排列方式

@property (nonatomic,strong) UIColor *borderColor; //  边框颜色 默认：#BBBBBB

@property (nonatomic,strong)          UIColor *selectedItemTitleColor;   // 选中的item标题颜色
@property (nonatomic,strong)          UIColor *unSelectedItemTitleColor; // 未选中的item标题颜色

@property (nonatomic,strong)          UIFont  *itemTitleFont;  // 设置所有item标题字体，不区分选中的item和未选中的item
@property (nonnull, nonatomic, strong) UIFont  *selectedItemTitleFont;    // 选中的item字体
@property (nonnull, nonatomic, strong) UIFont  *unSelectedItemTitleFont;  // 未选中的item字体

// 外界添加控制器view的srollView，pageMenu会监听该scrollView的滚动状况，让跟踪器时刻跟随此scrollView滑动；所谓的滚动状况，是指手指拖拽滚动，非手指拖拽不算
@property (nonatomic,strong) UIScrollView *bridgeScrollView;


// 分割线
@property (nonatomic,readonly) UIImageView *dividingLine; // 分割线,你可以拿到该对象设置一些自己想要的属性，如颜色、图片等，如果想要隐藏分割线，拿到该对象直接设置hidden为YES或设置alpha<0.01即可(eg：pageMenu.dividingLine.hidden = YES)
@property (nonatomic) CGFloat dividingLineHeight; // 分割线的高度

@property (nonatomic,assign) UIEdgeInsets contentInset; // 内容的四周内边距(内容不包括分割线)，默认UIEdgeInsetsZero

// 选中的item缩放系数，默认为1，为1代表不缩放，[0,1)之间缩小，(1,+∞)之间放大，(-1,0)之间"倒立"缩小，(-∞,-1)之间"倒立"放大，为-1"倒立不缩放",
@property (nonatomic) CGFloat selectedItemZoomScale;

@property (nonatomic,assign) BOOL needTextColorGradients; // 是否需要文字渐变,默认为YES


@property(nonatomic) BOOL bounces; // 边界反弹效果，默认YES
@property(nonatomic) BOOL alwaysBounceHorizontal; // 水平方向上，当内容没有充满scrollView时，滑动scrollView是否有反弹效果，默认NO

@property (nonatomic,weak) id<YFPageMenuDelegate> delegate;

// 插入item,插入和删除操作时,如果itemIndex超过了了items的个数,则不做任何操作
- (void)insertItemWithTitle:(nonnull NSString *)title atIndex:(NSUInteger)itemIndex animated:(BOOL)animated;
- (void)insertItemWithImage:(nonnull UIImage *)image atIndex:(NSUInteger)itemIndex animated:(BOOL)animated;
- (void)insertItem:(nonnull YFPageMenuButtonItem *)item atIndex:(NSUInteger)itemIndex animated:(BOOL)animated;
// 如果移除的正是当前选中的item(当前选中的item下标不为0),删除之后,选中的item会切换为上一个item
- (void)removeItemAtIndex:(NSUInteger)itemIndex animated:(BOOL)animated;
- (void)removeAllItems;

- (void)setTitle:(nonnull NSString *)title forItemAtIndex:(NSUInteger)itemIndex; // 设置指定item的标题,设置后，仅会有文字
- (nullable NSString *)titleForItemAtIndex:(NSUInteger)itemIndex; // 获取指定item的标题

- (void)setImage:(nonnull UIImage *)image forItemAtIndex:(NSUInteger)itemIndex; // 设置指定item的图片,设置后，仅会有图片
- (nullable UIImage *)imageForItemAtIndex:(NSUInteger)itemIndex; // 获取指定item的图片

- (void)setItem:(YFPageMenuButtonItem *)item forItemAtIndex:(NSUInteger)itemIndex; // 同时为指定item设置标题和图片
- (nullable YFPageMenuButtonItem *)itemAtIndex:(NSUInteger)itemIndex; // 获取指定item

- (void)setContent:(id)content forItemAtIndex:(NSUInteger)itemIndex; // 设置指定item的内容，content可以是NSString、UIImage或YFPageMenuButtonItem类型
- (id)contentForItemAtIndex:(NSUInteger)itemIndex; // 获取指定item的内容，该方法返回值可能是NSString、UIImage或YFPageMenuButtonItem类型

- (void)setWidth:(CGFloat)width forItemAtIndex:(NSUInteger)itemIndex; // 设置指定item的宽度(如果width为0,item会根据内容自动计算width)
- (CGFloat)widthForItemAtIndex:(NSUInteger)itemIndex; // 获取指定item的宽度

- (void)setCustomSpacing:(CGFloat)spacing afterItemAtIndex:(NSUInteger)itemIndex; // 设置指定item后面的自定义间距
- (CGFloat)customSpacingAfterItemAtIndex:(NSUInteger)itemIndex; // 获取指定item后面的自定义间距

- (void)setEnabled:(BOOL)enaled forItemAtIndex:(NSUInteger)itemIndex; // 设置指定item的enabled状态
- (BOOL)enabledForItemAtIndex:(NSUInteger)itemIndex; // 获取指定item的enabled状态

- (void)setContentEdgeInsets:(UIEdgeInsets)contentEdgeInsets forItemAtIndex:(NSUInteger)itemIndex; // 设置指定item的四周内边距
- (UIEdgeInsets)contentEdgeInsetsForItemAtIndex:(NSUInteger)itemIndex; // 获取指定item的四周内边距

// 设置背景图片，barMetrics只有为UIBarMetricsDefault时才生效，如果外界传进来的backgroundImage调用过-resizableImageWithCapInsets:且参数capInsets不为UIEdgeInsetsZero，则直接用backgroundImage作为背景图; 否则内部会自动调用-resizableImageWithCapInsets:进行拉伸
- (void)setBackgroundImage:(nullable UIImage *)backgroundImage barMetrics:(UIBarMetrics)barMetrics;
- (nullable UIImage *)backgroundImageForBarMetrics:(UIBarMetrics)barMetrics; // 获取背景图片

- (CGRect)titleRectRelativeToPageMenuForItemAtIndex:(NSUInteger)itemIndex;  // 文字相对pageMenu位置和大小
- (CGRect)imageRectRelativeToPageMenuForItemAtIndex:(NSUInteger)itemIndex;  // 图片相对pageMenu位置和大小
- (CGRect)buttonRectRelativeToPageMenuForItemAtIndex:(NSUInteger)itemIndex; // 按钮相对pageMenu位置和大小

- (void)addComponentViewInScrollView:(UIView *)componentView; // 在内置的scrollView上添加一个view



#pragma mark - function button


@property (nonatomic,assign) BOOL showFunctionButton; // 是否显示功能按钮(功能按钮显示在最右侧),默认为NO

@property (nonatomic,assign) CGFloat functionButtonshadowOpacity; // /**功能按钮左侧的阴影透明度,如果设置小于等于0，则没有阴影

// 设置功能按钮的内容，content可以是NSString、UIImage或YFPageMenuButtonItem类型
- (void)setFunctionButtonContent:(id)content forState:(UIControlState)state;
// 为functionButton配置相关属性，如设置字体、文字颜色等；在此,attributes中,只有NSFontAttributeName、NSForegroundColorAttributeName、NSBackgroundColorAttributeName有效
- (void)setFunctionButtonTitleTextAttributes:(nullable NSDictionary *)attributes forState:(UIControlState)state;


@end



NS_ASSUME_NONNULL_END




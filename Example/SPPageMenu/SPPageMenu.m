//
//  SPPageMenu.m
//  SPPageMenu
//
//  Created by 乐升平 on 17/10/26.
//  Copyright © 2017年 iDress. All rights reserved.
//

#import "SPPageMenu.h"
#import "SPPageMenuScrollView.h"
#import "SPPageMenuLine.h"

#define tagBaseValue 100
#define scrollViewContentOffset @"contentOffset"


@interface SPPageMenu()
@property (nonatomic, assign) SPPageMenuTrackerStyle trackerStyle;
@property (nonatomic, strong) NSArray *items; // 里面装的是字符串或者图片
@property (nonatomic, strong) UIImageView *tracker;
@property (nonatomic, assign) CGFloat trackerHeight;
@property (nonatomic, weak) UIView *backgroundView;
@property (nonatomic, weak) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *dividingLine;
@property (nonatomic, weak) SPPageMenuScrollView *itemScrollView;
@property (nonatomic, weak) SPPageMenuButton *functionButton;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) SPPageMenuButton *selectedButton;
@property (nonatomic, strong) NSMutableDictionary *customWidths;
@property (nonatomic, strong) NSMutableDictionary *customSpacings;
@property (nonatomic, assign) BOOL insert;
// 起始偏移量,为了判断滑动方向
@property (nonatomic, assign) CGFloat beginOffsetX;

/// 开始颜色, 取值范围 0~1
@property (nonatomic, assign) CGFloat startR;
@property (nonatomic, assign) CGFloat startG;
@property (nonatomic, assign) CGFloat startB;
@property (nonatomic, assign) CGFloat startA;
/// 完成颜色, 取值范围 0~1
@property (nonatomic, assign) CGFloat endR;
@property (nonatomic, assign) CGFloat endG;
@property (nonatomic, assign) CGFloat endB;
@property (nonatomic, assign) CGFloat endA;

// 这个高度，是存储itemScrollView的高度
@property (nonatomic, assign) CGFloat itemScrollViewH;
@property (nonatomic, assign) BOOL forceUseSettingSpacing;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation SPPageMenu


#pragma mark - public
+ (instancetype)pageMenuWithFrame:(CGRect)frame trackerStyle:(SPPageMenuTrackerStyle)trackerStyle {
    SPPageMenu *pageMenu = [[SPPageMenu alloc] initWithFrame:frame trackerStyle:trackerStyle];
    return pageMenu;
}

- (instancetype)initWithFrame:(CGRect)frame trackerStyle:(SPPageMenuTrackerStyle)trackerStyle {
    if (self = [super init]) {
        self.frame = frame;
        self.backgroundColor = [UIColor whiteColor];
        self.trackerStyle = trackerStyle;
        [self setupStartColor:_selectedItemTitleColor];
        [self setupEndColor:_unSelectedItemTitleColor];
    }
    return self;
}

- (void)setItems:(NSArray *)items selectedItemIndex:(NSInteger)selectedItemIndex {
    if (selectedItemIndex < 0) selectedItemIndex = 0;
    NSAssert(selectedItemIndex <= items.count-1, @"selectedItemIndex 大于了 %ld",items.count-1);
    _items = items.copy;
    _selectedItemIndex = selectedItemIndex;
    
    self.insert = NO;

    if (self.buttons.count) {
        for (SPPageMenuButton *button in self.buttons) {
            [button removeFromSuperview];
        }
    }
    [self.buttons removeAllObjects];
    
    for (int i = 0; i < items.count; i++) {
        id object = items[i];
        NSAssert([object isKindOfClass:[NSString class]] || [object isKindOfClass:[UIImage class]] || [object isKindOfClass:[SPPageMenuButtonItem class]], @"items中的元素类型只能是NSString、UIImage或SPPageMenuButtonItem");
        [self addButton:i object:object animated:NO];
    }

    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    if (self.buttons.count) {
        // 默认选中selectedItemIndex对应的按钮
        SPPageMenuButton *selectedButton = [self.buttons objectAtIndex:selectedItemIndex];
        [self buttonInPageMenuClicked:selectedButton];

        // SPPageMenuTrackerStyleTextZoom和SPPageMenuTrackerStyleNothing样式跟tracker没有关联
        if ([self haveOrNeedsTracker]) {
            [self.itemScrollView insertSubview:self.tracker atIndex:0];
            // 这里千万不能再去调用setNeedsLayout和layoutIfNeeded，因为如果外界在此之前对selectedButton进行了缩放，调用了layoutSubViews后会重新对selectedButton设置frame,先缩放再重设置frame会导致文字显示不全，所以我们直接跳过layoutSubViews调用resetSetupTrackerFrameWithSelectedButton：只设置tracker的frame
            [self resetupTrackerFrameWithSelectedButton:selectedButton];
        }
    }
}

- (void)insertItemWithTitle:(NSString *)title atIndex:(NSUInteger)itemIndex animated:(BOOL)animated {
    self.insert = YES;
    NSAssert(itemIndex <= self.items.count, @"itemIndex超过了items的总个数“%ld”",self.items.count);
    NSMutableArray *titleArr = self.items.mutableCopy;
    [titleArr insertObject:title atIndex:itemIndex];
    self.items = titleArr;
    [self addButton:itemIndex object:title animated:animated];
    if (itemIndex <= self.selectedItemIndex) {
        _selectedItemIndex += 1;
    }
}

- (void)insertItemWithImage:(UIImage *)image atIndex:(NSUInteger)itemIndex animated:(BOOL)animated {
    self.insert = YES;
    NSAssert(itemIndex <= self.items.count, @"itemIndex超过了items的总个数“%ld”",self.items.count);
    NSMutableArray *objects = self.items.mutableCopy;
    [objects insertObject:image atIndex:itemIndex];
    self.items = objects.copy;
    [self addButton:itemIndex object:image animated:animated];
    if (itemIndex <= self.selectedItemIndex) {
        _selectedItemIndex += 1;
    }
}

- (void)insertItem:(SPPageMenuButtonItem *)item atIndex:(NSUInteger)itemIndex animated:(BOOL)animated {
    self.insert = YES;
    NSAssert(itemIndex <= self.items.count, @"itemIndex超过了items的总个数“%ld”",self.items.count);
    NSMutableArray *objects = self.items.mutableCopy;
    [objects insertObject:item atIndex:itemIndex];
    self.items = objects.copy;
    [self addButton:itemIndex object:item animated:animated];
    if (itemIndex <= self.selectedItemIndex) {
        _selectedItemIndex += 1;
    }
}

- (void)removeItemAtIndex:(NSUInteger)itemIndex animated:(BOOL)animated {
    NSAssert(itemIndex <= self.items.count, @"itemIndex超过了items的总个数“%ld”",self.items.count);
    // 被删除的按钮之后的按钮需要修改tag值
    for (SPPageMenuButton *button in self.buttons) {
        if (button.tag-tagBaseValue > itemIndex) {
            button.tag = button.tag - 1;
        }
    }
    if (self.items.count) {
        NSMutableArray *objects = self.items.mutableCopy;
        // 特别注意的是：不能先通过itemIndex取出对象，然后再将对象删除，因为这样会删除所有相同的对象
        [objects removeObjectAtIndex:itemIndex];
        self.items = objects.copy;
    }
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        if (button == self.selectedButton) { // 如果删除的正是选中的item，删除之后，选中的按钮切换为上一个item
            self.selectedItemIndex = itemIndex > 0 ? itemIndex-1 : itemIndex;
        }
        [self.buttons removeObjectAtIndex:itemIndex];
        [button removeFromSuperview];
        if (self.buttons.count == 0) { // 说明移除了所有
            [self.tracker removeFromSuperview];
            self.selectedButton = nil;
            self.selectedItemIndex = 0;
        }
    }
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }];
    } else {
        [self setNeedsLayout];
    }
}

- (void)removeAllItems {
    NSMutableArray *objects = self.items.mutableCopy;
    [objects removeAllObjects];
    self.items = objects.copy;
    self.items = nil;
    
    for (int i = 0; i < self.buttons.count; i++) {
        SPPageMenuButton *button = self.buttons[i];
        [button removeFromSuperview];
    }
    
    [self.buttons removeAllObjects];
    
    [self.tracker removeFromSuperview];
    
    self.selectedButton = nil;
    self.selectedItemIndex = 0;
    
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title forItemAtIndex:(NSUInteger)itemIndex {
    if (title == nil) return;
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        [button setImage:nil forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateNormal];

        NSMutableArray *items = self.items.mutableCopy;
        [items replaceObjectAtIndex:itemIndex withObject:title];
        self.items = items.copy;
    }
    [self setNeedsLayout];
}

- (NSString *)titleForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.items.count) {
        id object = [self.items objectAtIndex:itemIndex];
        NSAssert([object isKindOfClass:[NSString class]],@"itemIndex对应的item不是NSString类型，请仔细核对");
        return object;
    }
    return nil;
}

- (void)setImage:(UIImage *)image forItemAtIndex:(NSUInteger)itemIndex {
    if (image == nil) return;
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        [button setTitle:nil forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateNormal];

        NSMutableArray *items = self.items.mutableCopy;
        [items replaceObjectAtIndex:itemIndex withObject:image];
        self.items = items.copy;
    }
    [self setNeedsLayout];
}

- (UIImage *)imageForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.items.count) {
        id object = [self.items objectAtIndex:itemIndex];
        NSAssert([object isKindOfClass:[UIImage class]],@"itemIndex对应的item不是UIImage类型，请仔细核对");
        return object;
    }
    return nil;
}

- (void)setItem:(SPPageMenuButtonItem *)item forItemIndex:(NSUInteger)itemIndex {
    if (item == nil) return;
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        [button setTitle:item.title forState:UIControlStateNormal];
        [button setImage:item.image forState:UIControlStateNormal];
        button.imagePosition = item.imagePosition;
        button.imageTitleSpace = item.imageTitleSpace;
        
        if (item != nil) {
            NSMutableArray *items = self.items.mutableCopy;
            [items replaceObjectAtIndex:itemIndex withObject:item];
            self.items = items.copy;
        }
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)setItem:(SPPageMenuButtonItem *)item forItemAtIndex:(NSUInteger)itemIndex {
    [self setItem:item forItemIndex:itemIndex];
}

- (SPPageMenuButtonItem *)itemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.items.count) {
        id object = [self.items objectAtIndex:itemIndex];
        NSAssert([object isKindOfClass:[SPPageMenuButtonItem class]],@"itemIndex对应的item不是SPPageMenuButtonItem类型，请仔细核对");
        return object;
    }
    return nil;
}

- (void)setContent:(id)content forItemIndex:(NSUInteger)itemIndex {
    if (content == nil) return;
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        if ([content isKindOfClass:[NSString class]]) {
            [button setTitle:content forState:UIControlStateNormal];
        } else if ([content isKindOfClass:[UIImage class]]) {
            [button setImage:content forState:UIControlStateNormal];
        } else if ([content isKindOfClass:[SPPageMenuButtonItem class]]) {
            SPPageMenuButtonItem *item = (SPPageMenuButtonItem *)content;
            [button setTitle:item.title forState:UIControlStateNormal];
            [button setImage:item.image forState:UIControlStateNormal];
            button.imagePosition = item.imagePosition;
            button.imageTitleSpace = item.imageTitleSpace;
        }
        NSMutableArray *items = self.items.mutableCopy;
        [items replaceObjectAtIndex:itemIndex withObject:content];
        self.items = items.copy;
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)setContent:(id)content forItemAtIndex:(NSUInteger)itemIndex {
    [self setContent:content forItemIndex:itemIndex];
}

- (id)contentForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.items.count) {
        id content = [self.items objectAtIndex:itemIndex];
        return content;
    }
    return nil;
}

- (id)objectForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.items.count) {
        id object = [self.items objectAtIndex:itemIndex];
        return object;
    }
    return nil;
}

- (void)setEnabled:(BOOL)enaled forItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        [button setEnabled:enaled];
    }
}

- (BOOL)enabledForItemAtIndex:(NSUInteger)itemIndex {
    if (self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        return button.enabled;
    }
    return YES;
}

- (void)setWidth:(CGFloat)width forItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        [self.customWidths setValue:@(width) forKey:[NSString stringWithFormat:@"%lu",(unsigned long)itemIndex]];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (CGFloat)widthForItemAtIndex:(NSUInteger)itemIndex {
    CGFloat customWidth = [[self.customWidths valueForKey:[NSString stringWithFormat:@"%lu",(unsigned long)itemIndex]] floatValue];
    if (customWidth) {
        return customWidth;
    } else {
        if (itemIndex < self.buttons.count) {
            SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
            return button.bounds.size.width;
        }
    }
    return 0;
}

- (void)setCustomSpacing:(CGFloat)spacing afterItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        [self.customSpacings setValue:@(spacing) forKey:[NSString stringWithFormat:@"%lu",(unsigned long)itemIndex]];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (CGFloat)customSpacingAfterItemAtIndex:(NSUInteger)itemIndex {
    if ([self.customSpacings.allKeys containsObject:[NSString stringWithFormat:@"%lu",(unsigned long)itemIndex]]) {
        CGFloat customSpacing = [[self.customSpacings valueForKey:[NSString stringWithFormat:@"%lu",(unsigned long)itemIndex]] floatValue];
        return customSpacing;
    } else {
        return CGFLOAT_MAX;
    }
}

- (void)setContentEdgeInsets:(UIEdgeInsets)contentInset forForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        button.contentEdgeInsets = contentInset;
    }
}

- (void)setContentEdgeInsets:(UIEdgeInsets)contentInset forItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        button.contentEdgeInsets = contentInset;
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (UIEdgeInsets)contentEdgeInsetsForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        return button.contentEdgeInsets;
    }
    return UIEdgeInsetsZero;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage barMetrics:(UIBarMetrics)barMetrics {
    if (barMetrics == UIBarMetricsDefault) {
        if (UIEdgeInsetsEqualToEdgeInsets(backgroundImage.capInsets, UIEdgeInsetsZero)) {
            CGFloat imageWidth = CGImageGetWidth(backgroundImage.CGImage);
            CGFloat imageHeight = CGImageGetHeight(backgroundImage.CGImage);
            [self.backgroundImageView setImage:[backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(imageHeight*0.5, imageWidth*0.5, imageHeight*0.5, imageWidth*0.5) resizingMode:backgroundImage.resizingMode]];
        } else {
            [self.backgroundImageView setImage:backgroundImage];
        }
    }
}

- (UIImage *)backgroundImageForBarMetrics:(UIBarMetrics)barMetrics {
    return self.backgroundImageView.image;
}

- (CGRect)titleRectRelativeToPageMenuForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        CGRect titleRectAtPageMenu = [button.titleLabel convertRect:button.titleLabel.bounds toView:self];
        return titleRectAtPageMenu;
    }
    return CGRectZero;
}

- (CGRect)imageRectRelativeToPageMenuForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        CGRect imageRectAtPageMenu = [button.imageView convertRect:button.imageView.bounds toView:self];
        return imageRectAtPageMenu;
    }
    return CGRectZero;
}

- (CGRect)buttonRectRelativeToPageMenuForItemAtIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        CGRect buttonRectAtPageMenu = [button convertRect:button.bounds toView:self];
        return buttonRectAtPageMenu;
    }
    return CGRectZero;
}

- (void)addComponentViewInScrollView:(UIView *)componentView {
    [self.itemScrollView addSubview:componentView];
}

- (void)setTrackerHeight:(CGFloat)trackerHeight cornerRadius:(CGFloat)cornerRadius {
    _trackerHeight = trackerHeight;
    self.tracker.layer.cornerRadius = cornerRadius;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setFunctionButtonWithItem:(SPPageMenuButtonItem *)item forState:(UIControlState)state {
    [self.functionButton setTitle:item.title forState:state];
    [self.functionButton setImage:item.image forState:state];
    self.functionButton.imagePosition = item.imagePosition;
    self.functionButton.imageTitleSpace = item.imageTitleSpace;
}

- (void)setFunctionButtonContent:(id)content forState:(UIControlState)state {
    if ([content isKindOfClass:[NSString class]]) {
        [self.functionButton setTitle:content forState:state];
    } else if ([content isKindOfClass:[UIImage class]]) {
        [self.functionButton setImage:content forState:state];
    } else if ([content isKindOfClass:[SPPageMenuButtonItem class]]) {
        SPPageMenuButtonItem *item = (SPPageMenuButtonItem *)content;
        [self.functionButton setTitle:item.title forState:state];
        [self.functionButton setImage:item.image forState:state];
        self.functionButton.imagePosition = item.imagePosition;
        self.functionButton.imageTitleSpace = item.imageTitleSpace;
    }
}

- (void)setFunctionButtonTitleTextAttributes:(nullable NSDictionary *)attributes forState:(UIControlState)state {
    if (attributes[NSFontAttributeName]) {
        self.functionButton.titleLabel.font = attributes[NSFontAttributeName];
    }
    if (attributes[NSForegroundColorAttributeName]) {
        [self.functionButton setTitleColor:attributes[NSForegroundColorAttributeName] forState:state];
    }
    if (attributes[NSBackgroundColorAttributeName]) {
        self.functionButton.backgroundColor = attributes[NSBackgroundColorAttributeName];
    }
}

- (void)moveTrackerFollowScrollView:(UIScrollView *)scrollView {
    // 说明外界传进来了一个scrollView,如果外界传进来了，pageMenu会观察该scrollView的contentOffset自动处理跟踪器的跟踪
    if (self.bridgeScrollView == scrollView) { return; }
    [self prepareMoveTrackerFollowScrollView:scrollView];
}

// 以下方法在3.0版本上有升级，可以使用但不推荐
- (void)setTitle:(nullable NSString *)title image:(nullable UIImage *)image imagePosition:(SPItemImagePosition)imagePosition imageRatio:(CGFloat)ratio forItemIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        [button setTitle:title forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateNormal];
        button.imagePosition = imagePosition;
        
        // 文字和图片只能替换其一，因为items数组里不能同时装文字和图片。当文字和图片同时设置时，items里只更新文字
        if (title == nil || title.length == 0 || [title isKindOfClass:[NSNull class]]) {
            NSMutableArray *items = self.items.mutableCopy;
            [items replaceObjectAtIndex:itemIndex withObject:image];
            self.items = items.copy;
        } else if (image == nil) {
            NSMutableArray *items = self.items.mutableCopy;
            [items replaceObjectAtIndex:itemIndex withObject:title];
            self.items = items.copy;
        } else {
            NSMutableArray *items = self.items.mutableCopy;
            [items replaceObjectAtIndex:itemIndex withObject:image];
            self.items = items.copy;
        }
        
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)setTitle:(nullable NSString *)title image:(nullable UIImage *)image imagePosition:(SPItemImagePosition)imagePosition imageRatio:(CGFloat)ratio imageTitleSpace:(CGFloat)imageTitleSpace forItemIndex:(NSUInteger)itemIndex {
    if (itemIndex < self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:itemIndex];
        [button setTitle:title forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateNormal];
        button.imagePosition = imagePosition;
        button.imageTitleSpace = imageTitleSpace;
        
        // 文字和图片只能替换其一，因为items数组里不能同时装文字和图片。当文字和图片同时设置时，items里只更新文字
        if (title == nil || title.length == 0 || [title isKindOfClass:[NSNull class]]) {
            NSMutableArray *items = self.items.mutableCopy;
            [items replaceObjectAtIndex:itemIndex withObject:image];
            self.items = items.copy;
        } else if (image == nil) {
            NSMutableArray *items = self.items.mutableCopy;
            [items replaceObjectAtIndex:itemIndex withObject:title];
            self.items = items.copy;
        } else {
            NSMutableArray *items = self.items.mutableCopy;
            [items replaceObjectAtIndex:itemIndex withObject:image];
            self.items = items.copy;
        }
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)setFunctionButtonTitle:(nullable NSString *)title image:(nullable UIImage *)image imagePosition:(SPItemImagePosition)imagePosition imageRatio:(CGFloat)ratio forState:(UIControlState)state {
    [self.functionButton setTitle:title forState:state];
    [self.functionButton setImage:image forState:state];
    self.functionButton.imagePosition = imagePosition;
}

- (void)setFunctionButtonTitle:(nullable NSString *)title image:(nullable UIImage *)image imagePosition:(SPItemImagePosition)imagePosition imageRatio:(CGFloat)ratio imageTitleSpace:(CGFloat)imageTitleSpace forState:(UIControlState)state {
    [self.functionButton setTitle:title forState:state];
    [self.functionButton setImage:image forState:state];
    self.functionButton.imagePosition = imagePosition;
    self.functionButton.imageTitleSpace = imageTitleSpace;
}

#pragma mark - private

- (void)addButton:(NSInteger)index object:(id)object animated:(BOOL)animated {
    // 如果是插入，需要改变已有button的tag值
    for (SPPageMenuButton *button in self.buttons) {
        if (button.tag-tagBaseValue >= index) {
            button.tag = button.tag + 1; // 由于有新button的加入，新button后面的button的tag值得+1
        }
    }
    SPPageMenuButton *button = [SPPageMenuButton buttonWithType:UIButtonTypeCustom];
    [button setTitleColor:_unSelectedItemTitleColor forState:UIControlStateNormal];
    button.titleLabel.font = _unSelectedItemTitleFont; // 此时必然还没有选中任何按钮，设置_unSelectedItemTitleFont就相是设置所有按钮的文字颜色，这里不能用_itemTitleFont，如果外界先设置_unSelectedItemTitleFont，再创建按钮，假如这里使用_itemTitleFont，那外界设置的_unSelectedItemTitleFont就不生效
    [button addTarget:self action:@selector(buttonInPageMenuClicked:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = tagBaseValue + index;
    if ([object isKindOfClass:[NSString class]]) {
        [button setTitle:object forState:UIControlStateNormal];
    } else if ([object isKindOfClass:[UIImage class]]) {
        [button setImage:object forState:UIControlStateNormal];
    } else {
        SPPageMenuButtonItem *item = (SPPageMenuButtonItem *)object;
        [button setTitle:item.title forState:UIControlStateNormal];
        [button setImage:item.image forState:UIControlStateNormal];
        button.imagePosition = item.imagePosition;
        button.imageTitleSpace = item.imageTitleSpace;
    }
    if (self.insert) {
        if ([self haveOrNeedsTracker]) {
            if (self.buttons.count == 0) { // 如果是第一个插入，需要将跟踪器加上,第一个插入说明itemScrollView上没有任何子控件
                [self.itemScrollView insertSubview:self.tracker atIndex:0];
                [self.itemScrollView insertSubview:button atIndex:index+1];
            } else { // 已经有跟踪器
                [self.itemScrollView insertSubview:button atIndex:index+1]; // +1是因为跟踪器
            }
        } else {
            [self.itemScrollView insertSubview:button atIndex:index];
        }
        if (!self.buttons.count) {
            [self buttonInPageMenuClicked:button];
        }
    } else {
        [self.itemScrollView insertSubview:button atIndex:index];
    }
    [self.buttons insertObject:button atIndex:index];

    if (self.insert && animated) { // 是插入的新按钮,且需要动画
        // 取出上一个按钮
        SPPageMenuButton *lastButton;
        if (index > 0) {
            lastButton = self.buttons[index-1];
        }
        // 先给初始的origin，按钮将会从这个origin开始动画
        button.frame = CGRectMake(CGRectGetMaxX(lastButton.frame)+_itemPadding*0.5, 0, 0, 0);
        button.titleLabel.frame = button.bounds;
        [UIView animateWithDuration:.5 animations:^{
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }];
    }
}

// 是否已经或者即将有跟踪器
- (BOOL)haveOrNeedsTracker {
    if (self.trackerStyle != SPPageMenuTrackerStyleTextZoom && self.trackerStyle != SPPageMenuTrackerStyleNothing) {
        return YES;
    }
    return NO;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _itemPadding = 30.0;
    _selectedItemTitleColor = [UIColor redColor];
    _unSelectedItemTitleColor = [UIColor blackColor];
    _selectedItemTitleFont = [UIFont systemFontOfSize:16];
    _unSelectedItemTitleFont = [UIFont systemFontOfSize:16];
    _itemTitleFont = [UIFont systemFontOfSize:16];
    _trackerHeight = 3.0;
    _dividingLineHeight = 1.0 / [UIScreen mainScreen].scale;
    _contentInset = UIEdgeInsetsZero;
    _selectedItemIndex = 0;
    _showFuntionButton = NO;
    _funtionButtonshadowOpacity = 0.5;
    _selectedItemZoomScale = 1;
    _needTextColorGradients = YES;
    [self setupSubViews];
}

- (void)setupSubViews {
    // 必须先添加分割线
    SPPageMenuLine *dividingLine = [[SPPageMenuLine alloc] init];
    dividingLine.backgroundColor = [UIColor lightGrayColor];
    __weak typeof(self) weakSelf = self;
    dividingLine.hideBlock = ^() {
        [weakSelf setNeedsLayout];
    };
    [self addSubview:dividingLine];
    _dividingLine = dividingLine;
    
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.layer.masksToBounds = YES;
    [self addSubview:backgroundView];
    _backgroundView = backgroundView;
    
    UIImageView *backgroundImageView = [[UIImageView alloc] init];
    [backgroundView addSubview:backgroundImageView];
    _backgroundImageView = backgroundImageView;
    
    SPPageMenuScrollView *itemScrollView = [[SPPageMenuScrollView alloc] init];
    itemScrollView.showsVerticalScrollIndicator = NO;
    itemScrollView.showsHorizontalScrollIndicator = NO;
    itemScrollView.scrollsToTop = NO; // 目的是不要影响到外界的scrollView置顶功能
    itemScrollView.bouncesZoom = NO;
    itemScrollView.bounces = YES;
    if (@available(iOS 11.0, *)) {
        itemScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [backgroundView addSubview:itemScrollView];
    _itemScrollView = itemScrollView;
    
    SPPageMenuButton *functionButton = [SPPageMenuButton buttonWithType:UIButtonTypeCustom];
    functionButton.backgroundColor = [UIColor whiteColor];
    [functionButton setTitle:@"＋" forState:UIControlStateNormal];
    [functionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [functionButton addTarget:self action:@selector(functionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    functionButton.layer.shadowColor = [UIColor blackColor].CGColor;
    functionButton.layer.shadowOffset = CGSizeMake(0, 0);
    functionButton.layer.shadowRadius = 2;
    functionButton.layer.shadowOpacity = _funtionButtonshadowOpacity; // 默认是0,为0的话不会显示阴影
    functionButton.hidden = !_showFuntionButton;
    [backgroundView addSubview:functionButton];
    _functionButton = functionButton;
}

// 按钮点击方法
- (void)buttonInPageMenuClicked:(SPPageMenuButton *)sender {
    NSInteger fromIndex = self.selectedButton ? self.selectedButton.tag-tagBaseValue : sender.tag - tagBaseValue;
    NSInteger toIndex = sender.tag - tagBaseValue;
    // 更新下item对应的下标,必须在代理之前，否则外界在代理方法中拿到的不是最新的
    _selectedItemIndex = toIndex;
    // 如果sender是新的选中的按钮，则上一次的按钮颜色为非选中颜色，当前选中的颜色为选中颜色
    if (self.selectedButton != sender) {
        [self.selectedButton setTitleColor:_unSelectedItemTitleColor forState:UIControlStateNormal];
        [sender setTitleColor:_selectedItemTitleColor forState:UIControlStateNormal];
        self.selectedButton.titleLabel.font = _unSelectedItemTitleFont;
        sender.titleLabel.font = _selectedItemTitleFont;
        
        // 让itemScrollView发生偏移
        [self moveItemScrollViewWithSelectedButton:sender];
        
        if (self.trackerStyle == SPPageMenuTrackerStyleTextZoom || _selectedItemZoomScale != 1) {
            if (labs(toIndex-fromIndex) >= 2) { // 该条件意思是当外界滑动scrollView连续的滑动了超过2页
                for (SPPageMenuButton *button in self.buttons) { // 必须遍历将非选中按钮还原缩放，而不是仅仅只让上一个选中的按钮还原缩放。因为当用户快速滑动外界scrollView时，会频繁的调用-zoomForTitleWithProgress:fromButton:toButton:方法，有可能经过的某一个button还没彻底还原缩放就直接过去了，从而可能会导致该按钮文字会显示不全，所以在这里，将所有非选中的按钮还原缩放
                    if (button != sender && !CGAffineTransformEqualToTransform(button.transform, CGAffineTransformIdentity)) {
                        button.transform = CGAffineTransformIdentity;
                    }
                }
            } else {
                self.selectedButton.transform = CGAffineTransformIdentity;
            }
            sender.transform = CGAffineTransformMakeScale(_selectedItemZoomScale, _selectedItemZoomScale);
        }
        if (fromIndex != toIndex) { // 如果相等，说明是第1次进来或者2次点了同一个，此时不需要动画
            [self moveTrackerWithSelectedButton:sender];
        }
        self.selectedButton = sender;
        if (_selectedItemTitleFont != _unSelectedItemTitleFont) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }
    }
    [self delegatePerformMethodWithFromIndex:fromIndex toIndex:toIndex];
}

// 点击button让itemScrollView发生偏移
- (void)moveItemScrollViewWithSelectedButton:(SPPageMenuButton *)selectedButton {
    if (CGRectEqualToRect(self.backgroundView.frame, CGRectZero)) {
        return;
    }
    // 转换点的坐标位置
    CGPoint centerInPageMenu = [self.backgroundView convertPoint:selectedButton.center toView:self];
    // CGRectGetMidX(self.backgroundView.frame)指的是屏幕水平中心位置，它的值是固定不变的
    CGFloat offSetX = centerInPageMenu.x - CGRectGetMidX(self.backgroundView.frame);
    
    // itemScrollView的容量宽与自身宽之差
    CGFloat maxOffsetX = self.itemScrollView.contentSize.width - self.itemScrollView.frame.size.width;
    // 如果选中的button中心x值小于或者等于itemScrollView的中心x值，或者itemScrollView的容量宽度小于itemScrollView本身，此时点击button时不发生任何偏移，置offSetX为0
    if (offSetX <= 0 || maxOffsetX <= 0) {
        offSetX = 0;
    }
    // 如果offSetX大于maxOffsetX,说明itemScrollView已经滑到尽头，此时button也发生任何偏移了
    else if (offSetX > maxOffsetX){
        offSetX = maxOffsetX;
    }
    [self.itemScrollView setContentOffset:CGPointMake(offSetX, 0) animated:YES];
}

// 移动跟踪器
- (void)moveTrackerWithSelectedButton:(SPPageMenuButton *)selectedButton {
    [UIView animateWithDuration:0.25 animations:^{
        [self resetupTrackerFrameWithSelectedButton:selectedButton];
    }];
}

// 执行代理方法
- (void)delegatePerformMethodWithFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageMenu:itemSelectedFromIndex:toIndex:)]) {
        [self.delegate pageMenu:self itemSelectedFromIndex:fromIndex toIndex:toIndex];
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(pageMenu:itemSelectedAtIndex:)]) {
        [self.delegate pageMenu:self itemSelectedAtIndex:toIndex];
    }
}

// 功能按钮的点击方法
- (void)functionButtonClicked:(SPPageMenuButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageMenu:functionButtonClicked:)]) {
        [self.delegate pageMenu:self functionButtonClicked:sender];
    }
}

- (void)prepareMoveTrackerFollowScrollView:(UIScrollView *)scrollView {

    // 这个if条件的意思是scrollView的滑动不是由手指拖拽产生
    if (!scrollView.isDragging && !scrollView.isDecelerating) {return;}
    // 当滑到边界时，继续通过scrollView的bouces效果滑动时，直接return
    if (scrollView.contentOffset.x < 0 || scrollView.contentOffset.x > scrollView.contentSize.width-scrollView.bounds.size.width) {return;}

    // 当前偏移量
    CGFloat currentOffSetX = scrollView.contentOffset.x;
    // 偏移进度
    CGFloat offsetProgress = currentOffSetX / scrollView.bounds.size.width;
    CGFloat progress = offsetProgress - floor(offsetProgress);

    NSInteger fromIndex = 0;
    NSInteger toIndex = 0;
    // 初始值不要等于scrollView.contentOffset.x,因为第一次进入此方法时，scrollView.contentOffset.x的值已经有一点点偏移了，不是很准确
    _beginOffsetX = scrollView.bounds.size.width * self.selectedItemIndex;

    // 以下注释的“拖拽”一词很准确，不可说成滑动，例如:当手指向右拖拽，还未拖到一半时就松开手，接下来scrollView则会往回滑动，这个往回，就是向左滑动，这也是_beginOffsetX不可时刻纪录的原因，如果时刻纪录，那么往回(向左)滑动时会被视为“向左拖拽”,然而，这个往回却是由“向右拖拽”而导致的
    if (currentOffSetX - _beginOffsetX > 0) { // 向左拖拽了
        // 求商,获取上一个item的下标
        fromIndex = currentOffSetX / scrollView.bounds.size.width;
        // 当前item的下标等于上一个item的下标加1
        toIndex = fromIndex + 1;
        if (toIndex >= self.buttons.count) {
            toIndex = fromIndex;
        }
    } else if (currentOffSetX - _beginOffsetX < 0) {  // 向右拖拽了
        toIndex = currentOffSetX / scrollView.bounds.size.width;
        fromIndex = toIndex + 1;
        progress = 1.0 - progress;

    } else {
        progress = 1.0;
        fromIndex = self.selectedItemIndex;
        toIndex = fromIndex;
    }
    if (currentOffSetX == scrollView.bounds.size.width * fromIndex) {// 滚动停止了
        progress = 1.0;
        toIndex = fromIndex;
    }
    // 如果滚动停止，直接通过点击按钮选中toIndex对应的item
    if (currentOffSetX == scrollView.bounds.size.width*toIndex) { // 这里toIndex==fromIndex
        // 这一次赋值起到2个作用，一是点击toIndex对应的按钮，走一遍代理方法,二是弥补跟踪器的结束跟踪，因为本方法是在scrollViewDidScroll中调用，可能离滚动结束还有一丁点的距离，本方法就不调了,最终导致外界还要在scrollView滚动结束的方法里self.selectedItemIndex进行赋值,直接在这里赋值可以让外界不用做此操作
        if (_selectedItemIndex != toIndex) {
            self.selectedItemIndex = toIndex;
        }
        // 要return，点击了按钮，跟踪器自然会跟着被点击的按钮走
        return;
    }
    switch (self.trackerFollowingMode) {
        case SPPageMenuTrackerFollowingModeAlways:
            // 这个方法才开始移动跟踪器
            [self moveTrackerWithProgress:progress fromIndex:fromIndex toIndex:toIndex currentOffsetX:currentOffSetX beginOffsetX:_beginOffsetX];
            break;
        case SPPageMenuTrackerFollowingModeHalf:{
            SPPageMenuButton *fromButton;
            SPPageMenuButton *toButton;
            if (progress > 0.5) {
                if (toIndex >= 0 && toIndex < self.buttons.count) {
                    toButton = self.buttons[toIndex];
                    fromButton = self.buttons[fromIndex];
                    if (_selectedItemIndex != toIndex) {
                        self.selectedItemIndex = toIndex;
                    }
                }
            } else {
                if (fromIndex >= 0 && fromIndex < self.buttons.count) {
                    toButton = self.buttons[fromIndex];
                    fromButton = self.buttons[toIndex];
                    if (_selectedItemIndex != fromIndex) {
                        self.selectedItemIndex = fromIndex;
                    }
                }
            }
        }
            break;
        default:
            break;
    }
}

// 这个方法才开始真正滑动跟踪器，上面都是做铺垫
- (void)moveTrackerWithProgress:(CGFloat)progress fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex currentOffsetX:(CGFloat)currentOffsetX beginOffsetX:(CGFloat)beginOffsetX {

    UIButton *fromButton = self.buttons[fromIndex];
    UIButton *toButton = self.buttons[toIndex];
    
    // 2个按钮之间的距离
    CGFloat xDistance = toButton.center.x - fromButton.center.x;
    // 2个按钮宽度的差值
    CGFloat wDistance = toButton.frame.size.width - fromButton.frame.size.width;
    
    CGRect newFrame = self.tracker.frame;
    CGPoint newCenter = self.tracker.center;
    if (self.trackerStyle == SPPageMenuTrackerStyleLine) {
        newCenter.x = fromButton.center.x + xDistance * progress;
        newFrame.size.width = _trackerWidth ? _trackerWidth : (fromButton.frame.size.width + wDistance * progress);
        self.tracker.frame = newFrame;
        self.tracker.center = newCenter;
        if (_selectedItemZoomScale != 1) {
            [self zoomForTitleWithProgress:progress fromButton:fromButton toButton:toButton];
        }
    } else if (self.trackerStyle == SPPageMenuTrackerStyleLineAttachment) {
        // 这种样式的计算比较复杂,有个很关键的技巧，就是参考progress分别为0、0.5、1时的临界值
        // 原先的x值
        CGFloat originX = fromButton.frame.origin.x+(fromButton.frame.size.width-(_trackerWidth ? _trackerWidth : fromButton.titleLabel.font.pointSize))*0.5;
        // 原先的宽度
        CGFloat originW = _trackerWidth ? _trackerWidth : fromButton.titleLabel.font.pointSize;
        if (currentOffsetX - _beginOffsetX >= 0) { // 向左拖拽了
            if (progress < 0.5) {
                newFrame.origin.x = originX; // x值保持不变
                newFrame.size.width = originW + xDistance * progress * 2;
            } else {
                newFrame.origin.x = originX + xDistance * (progress-0.5) * 2;
                newFrame.size.width = originW + xDistance - xDistance * (progress-0.5) * 2;
            }
        } else { // 向右拖拽了
            // 此时xDistance为负
            if (progress < 0.5) {
                newFrame.origin.x = originX + xDistance * progress * 2;
                newFrame.size.width = originW - xDistance * progress * 2;
            } else {
                newFrame.origin.x = originX + xDistance;
                newFrame.size.width = originW - xDistance + xDistance * (progress-0.5) * 2;
            }
        }
        self.tracker.frame = newFrame;
        if (_selectedItemZoomScale != 1) {
            [self zoomForTitleWithProgress:progress fromButton:fromButton toButton:toButton];
        }
        
    } else if (self.trackerStyle == SPPageMenuTrackerStyleTextZoom || self.trackerStyle == SPPageMenuTrackerStyleNothing) {
        // 缩放文字
        if (_selectedItemZoomScale != 1) {
            [self zoomForTitleWithProgress:progress fromButton:fromButton toButton:toButton];
        }
    } else if (self.trackerStyle == SPPageMenuTrackerStyleRoundedRect) {
        newCenter.x = fromButton.center.x + xDistance * progress;
        newFrame.size.width = _trackerWidth ? _trackerWidth : (fromButton.frame.size.width + wDistance * progress + _itemPadding);
        self.tracker.frame = newFrame;
        self.tracker.center = newCenter;
        if (_selectedItemZoomScale != 1) {
            [self zoomForTitleWithProgress:progress fromButton:fromButton toButton:toButton];
        }
    } else {
        newCenter.x = fromButton.center.x + xDistance * progress;
        newFrame.size.width = _trackerWidth ? _trackerWidth : (fromButton.frame.size.width + wDistance * progress + _itemPadding);
        self.tracker.frame = newFrame;
        self.tracker.center = newCenter;
        if (_selectedItemZoomScale != 1) {
            [self zoomForTitleWithProgress:progress fromButton:fromButton toButton:toButton];
        }
    }
    // 文字颜色渐变
    if (self.needTextColorGradients) {
        [self colorGradientForTitleWithProgress:progress fromButton:fromButton toButton:toButton];
    }
}

// 颜色渐变方法
- (void)colorGradientForTitleWithProgress:(CGFloat)progress fromButton:(UIButton *)fromButton toButton:(UIButton *)toButton {
    // 获取 targetProgress
    CGFloat fromProgress = progress;
    // 获取 originalProgress
    CGFloat toProgress = 1 - fromProgress;
    
    CGFloat r = self.endR - self.startR;
    CGFloat g = self.endG - self.startG;
    CGFloat b = self.endB - self.startB;
    CGFloat a = self.endA - self.startA;
    UIColor *fromColor = [UIColor colorWithRed:self.startR +  r * fromProgress  green:self.startG +  g * fromProgress  blue:self.startB +  b * fromProgress alpha:self.startA + a * fromProgress];
    UIColor *toColor = [UIColor colorWithRed:self.startR + r * toProgress green:self.startG + g * toProgress blue:self.startB + b * toProgress alpha:self.startA + a * toProgress];
    
    // 设置文字颜色渐变
    [fromButton setTitleColor:fromColor forState:UIControlStateNormal];
    [toButton setTitleColor:toColor forState:UIControlStateNormal];
}

// 获取颜色的RGB值
- (NSArray *)getRGBForColor:(UIColor *)color {
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return @[@(red), @(green), @(blue), @(alpha)];
}

/// 开始颜色设置
- (void)setupStartColor:(UIColor *)color {
    NSArray *components = [self getRGBForColor:color];
    self.startR = [components[0] floatValue];
    self.startG = [components[1] floatValue];
    self.startB = [components[2] floatValue];
    self.startA = [components[3] floatValue];
}

/// 结束颜色设置
- (void)setupEndColor:(UIColor *)color {
    NSArray *components = [self getRGBForColor:color];
    self.endR = [components[0] floatValue];
    self.endG = [components[1] floatValue];
    self.endB = [components[2] floatValue];
    self.endA = [components[3] floatValue];
}

- (void)zoomForTitleWithProgress:(CGFloat)progress fromButton:(UIButton *)fromButton toButton:(UIButton *)toButton {
    CGFloat diff = _selectedItemZoomScale - 1;
    fromButton.transform = CGAffineTransformMakeScale((1 - progress) * diff + 1, (1 - progress) * diff + 1);
    toButton.transform = CGAffineTransformMakeScale(progress * diff + 1, progress * diff + 1);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.bridgeScrollView) {
        if ([keyPath isEqualToString:scrollViewContentOffset]) {
            // 当scrolllView滚动时,让跟踪器跟随scrollView滑动
            [self prepareMoveTrackerFollowScrollView:self.bridgeScrollView];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - setter

- (void)setBridgeScrollView:(UIScrollView *)bridgeScrollView {
    if (bridgeScrollView == _bridgeScrollView) return;
    if (_bridgeScrollView && bridgeScrollView != _bridgeScrollView) {
        [_bridgeScrollView removeObserver:self forKeyPath:scrollViewContentOffset];
    };
    _bridgeScrollView = bridgeScrollView;
    if (bridgeScrollView) {
        [bridgeScrollView addObserver:self forKeyPath:scrollViewContentOffset options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setTrackerColor:(UIColor *)trackerColor {
    _trackerColor = trackerColor;
    self.tracker.backgroundColor = trackerColor;
}

- (void)setTrackerStyle:(SPPageMenuTrackerStyle)trackerStyle {
    _trackerStyle = trackerStyle;
    switch (trackerStyle) {
        case SPPageMenuTrackerStyleLine:
        case SPPageMenuTrackerStyleLineLongerThanItem:
        case SPPageMenuTrackerStyleLineAttachment:
            self.tracker.backgroundColor = _selectedItemTitleColor;
            break;
        case SPPageMenuTrackerStyleRoundedRect:
        case SPPageMenuTrackerStyleRect:
        case SPPageMenuTrackerStyleSegment:
            self.tracker.backgroundColor = [UIColor redColor];
            _selectedItemTitleColor = [UIColor whiteColor];
            // _trackerHeight是默认有值的，所有样式都会按照事先询问_trackerHeight有没有值，如果有值则采用_trackerHeight，如果矩形或圆角矩形样式下也用_trackerHeight高度太小了，除非外界用户自己设置了_trackerHeight
            _trackerHeight = 0;
            break;
        case SPPageMenuTrackerStyleTextZoom:
            // 此样式下默认1.3
            self.selectedItemZoomScale = 1.3;
            break;
        default:
            break;
    }
}

- (void)setBounces:(BOOL)bounces {
    _bounces = bounces;
    self.itemScrollView.bounces = bounces;
}

- (void)setAlwaysBounceHorizontal:(BOOL)alwaysBounceHorizontal {
    _alwaysBounceHorizontal = alwaysBounceHorizontal;
    self.itemScrollView.alwaysBounceHorizontal = alwaysBounceHorizontal;
}

- (void)setTrackerWidth:(CGFloat)trackerWidth {
    _trackerWidth = trackerWidth;
    CGRect trackerRect = self.tracker.frame;
    trackerRect.size.width = trackerWidth;
    self.tracker.frame = trackerRect;
    CGPoint trackerCenter = self.tracker.center;
    trackerCenter.x = _selectedButton.center.x;
    self.tracker.center = trackerCenter;
}

- (void)setDividingLineHeight:(CGFloat)dividingLineHeight {
    _dividingLineHeight = dividingLineHeight;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSelectedItemZoomScale:(CGFloat)selectedItemZoomScale {
    _selectedItemZoomScale = selectedItemZoomScale;
    if (selectedItemZoomScale != 1) {
        _selectedButton.transform = CGAffineTransformMakeScale(_selectedItemZoomScale, _selectedItemZoomScale);
        self.tracker.transform = CGAffineTransformMakeScale(_selectedItemZoomScale, 1);
    } else {
        _selectedButton.transform = CGAffineTransformIdentity;
        self.tracker.transform = CGAffineTransformIdentity;
    }
}

- (void)setShowFuntionButton:(BOOL)showFuntionButton {
    _showFuntionButton = showFuntionButton;
    self.functionButton.hidden = !showFuntionButton;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 修正scrollView偏移
    [self moveItemScrollViewWithSelectedButton:self.selectedButton];
}

- (void)setFuntionButtonshadowOpacity:(CGFloat)funtionButtonshadowOpacity {
    _funtionButtonshadowOpacity = funtionButtonshadowOpacity;
    self.functionButton.layer.shadowOpacity = funtionButtonshadowOpacity;
}

- (void)setItemPadding:(CGFloat)itemPadding {
    _itemPadding = itemPadding;
    _forceUseSettingSpacing = YES;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 修正scrollView偏移
    [self moveItemScrollViewWithSelectedButton:self.selectedButton];
}

- (void)setSpacing:(CGFloat)spacing {
    _spacing = spacing;
    self.itemPadding = spacing;
}

- (void)setItemTitleFont:(UIFont *)itemTitleFont {
    _itemTitleFont = itemTitleFont;
    _selectedItemTitleFont = itemTitleFont;
    _unSelectedItemTitleFont = itemTitleFont;
    for (SPPageMenuButton *button in self.buttons) {
        button.titleLabel.font = itemTitleFont;
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 修正scrollView偏移
    [self moveItemScrollViewWithSelectedButton:self.selectedButton];
}

- (void)setUnSelectedItemTitleFont:(UIFont *)unSelectedItemTitleFont {
    _unSelectedItemTitleFont = unSelectedItemTitleFont;
    for (SPPageMenuButton *button in self.buttons) {
        if (button == _selectedButton) {
            continue;
        }
        button.titleLabel.font = unSelectedItemTitleFont;
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 修正scrollView偏移
    [self moveItemScrollViewWithSelectedButton:self.selectedButton];
}

- (void)setSelectedItemTitleFont:(UIFont *)selectedItemTitleFont {
    _selectedItemTitleFont = selectedItemTitleFont;
    self.selectedButton.titleLabel.font = selectedItemTitleFont;

    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 修正scrollView偏移
    [self moveItemScrollViewWithSelectedButton:self.selectedButton];
}

- (void)setSelectedItemTitleColor:(UIColor *)selectedItemTitleColor {
    _selectedItemTitleColor = selectedItemTitleColor;
    [self setupStartColor:selectedItemTitleColor];
    [self.selectedButton setTitleColor:selectedItemTitleColor forState:UIControlStateNormal];
}

- (void)setUnSelectedItemTitleColor:(UIColor *)unSelectedItemTitleColor {
    _unSelectedItemTitleColor = unSelectedItemTitleColor;
    [self setupEndColor:unSelectedItemTitleColor];
    for (SPPageMenuButton *button in self.buttons) {
        if (button == _selectedButton) {
            continue;  // 跳过选中的那个button
        }
        [button setTitleColor:unSelectedItemTitleColor forState:UIControlStateNormal];
    }
}

- (void)setSelectedItemIndex:(NSInteger)selectedItemIndex {
    _selectedItemIndex = selectedItemIndex;
    if (self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:selectedItemIndex];
        [self buttonInPageMenuClicked:button];
    }
}

- (void)setDelegate:(id<SPPageMenuDelegate>)delegate {
    if (delegate == _delegate) {return;}
    _delegate = delegate;
    if (self.buttons.count) {
        SPPageMenuButton *button = [self.buttons objectAtIndex:_selectedItemIndex];
        [self delegatePerformMethodWithFromIndex:button.tag-tagBaseValue toIndex:button.tag-tagBaseValue];
        [self moveItemScrollViewWithSelectedButton:button];
    }
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 修正scrollView偏移
    [self moveItemScrollViewWithSelectedButton:self.selectedButton];
}

- (void)setPermutationWay:(SPPageMenuPermutationWay)permutationWay {
    _permutationWay = permutationWay;
    if (!_forceUseSettingSpacing) {
        if (_permutationWay == SPPageMenuPermutationWayNotScrollEqualWidths) {
            _spacing = _itemPadding = 0;
        } else {
            _spacing = _itemPadding = 30;
        }
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 修正scrollView偏移
    [self moveItemScrollViewWithSelectedButton:self.selectedButton];
}

- (void)setCloseTrackerFollowingMode:(BOOL)closeTrackerFollowingMode {
    _closeTrackerFollowingMode = closeTrackerFollowingMode;
    if (closeTrackerFollowingMode) {
        self.trackerFollowingMode = SPPageMenuTrackerFollowingModeEnd;
    } else {
        self.trackerFollowingMode = SPPageMenuTrackerFollowingModeAlways;
    }
}
#pragma mark - getter

- (NSArray *)items {
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}

- (NSMutableArray *)buttons {
    
    if (!_buttons) {
        _buttons = [NSMutableArray array];
        
    }
    return _buttons;
}

- (NSMutableDictionary *)customWidths {
    
    if (!_customWidths) {
        _customWidths = [NSMutableDictionary dictionary];
    }
    return _customWidths;
}

- (NSMutableDictionary *)customSpacings {
    if (!_customSpacings) {
        _customSpacings = [[NSMutableDictionary alloc] init];
    }
    return _customSpacings;
}

- (UIImageView *)tracker {
    
    if (!_tracker) {
        _tracker = [[UIImageView alloc] init];
        _tracker.layer.cornerRadius = _trackerHeight * 0.5;
        _tracker.layer.masksToBounds = YES;
    }
    return _tracker;
}

- (NSUInteger)numberOfItems {
    return self.items.count;
}

#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat backgroundViewX = self.bounds.origin.x+_contentInset.left;
    CGFloat backgroundViewY = self.bounds.origin.y+_contentInset.top;
    CGFloat backgroundViewW = self.bounds.size.width-(_contentInset.left+_contentInset.right);
    CGFloat backgroundViewH = self.bounds.size.height-(_contentInset.top+_contentInset.bottom);
    self.backgroundView.frame = CGRectMake(backgroundViewX, backgroundViewY, backgroundViewW, backgroundViewH);
    self.backgroundImageView.frame = self.backgroundView.bounds;
    
    CGFloat dividingLineW = self.bounds.size.width;
    CGFloat dividingLineH = (self.dividingLine.hidden || self.dividingLine.alpha < 0.01) ? 0 : _dividingLineHeight;
    CGFloat dividingLineX = 0;
    CGFloat dividingLineY = self.bounds.size.height-dividingLineH;
    self.dividingLine.frame = CGRectMake(dividingLineX, dividingLineY, dividingLineW, dividingLineH);

    CGFloat functionButtonH = backgroundViewH-dividingLineH;
    CGFloat functionButtonW = functionButtonH;
    CGFloat functionButtonX = backgroundViewW-functionButtonW;
    CGFloat functionButtonY = 0;
    self.functionButton.frame = CGRectMake(functionButtonX, functionButtonY, functionButtonW, functionButtonH);
    // 通过shadowPath设置功能按钮的单边阴影
    if (self.funtionButtonshadowOpacity > 0) {
        self.functionButton.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 2.5, 2, functionButtonH-5)].CGPath;
    }
    CGFloat itemScrollViewX = 0;
    CGFloat itemScrollViewY = 0;
    CGFloat itemScrollViewW = self.showFuntionButton ? backgroundViewW-functionButtonW : backgroundViewW;
    CGFloat itemScrollViewH = backgroundViewH-dividingLineH;
    self.itemScrollView.frame = CGRectMake(itemScrollViewX, itemScrollViewY, itemScrollViewW, itemScrollViewH);
    
    // 存储itemScrollViewH,目的是解决选中按钮缩放后高度变化了的问题，我们要让选中的按钮缩放之后，依然保持原始高度
    _itemScrollViewH = itemScrollViewH;

    __block CGFloat buttonW = 0.0;
    __block CGFloat lastButtonMaxX = 0.0;
    
    CGFloat contentW = 0.0; // 内容宽
    CGFloat contentW_sum = 0.0; // 所有文字宽度之和
    NSMutableArray *buttonWidths = [NSMutableArray array];
    // 提前计算每个按钮的宽度，目的是为了计算间距
    for (int i= 0 ; i < self.buttons.count; i++) {
        SPPageMenuButton *button = self.buttons[i];
        CGFloat textW;
        CGFloat customWidth = [[self.customWidths valueForKey:[NSString stringWithFormat:@"%d",i]] floatValue];
        if (button == _selectedButton) {
            textW = ceil([button.titleLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, itemScrollViewH) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_selectedItemTitleFont} context:nil].size.width);
        } else {
            textW = ceil([button.titleLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, itemScrollViewH) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_unSelectedItemTitleFont} context:nil].size.width);
        }
        CGFloat imageW = button.currentImage.size.width;
        CGFloat imageH = button.currentImage.size.height;
        if (imageH > itemScrollViewH) {
            imageH = itemScrollViewH;
        }
        if (button.currentTitle.length && !button.currentImage) {
            contentW = textW+button.contentEdgeInsets.left+button.contentEdgeInsets.right;
        } else if(button.currentImage && !button.currentTitle) {
            contentW = imageW+button.contentEdgeInsets.left+button.contentEdgeInsets.right;
        } else if (button.currentTitle.length && button.currentImage && (button.imagePosition == SPItemImagePositionRight || button.imagePosition == SPItemImagePositionLeft || button.imagePosition == SPItemImagePositionDefault)) {
            contentW = textW + imageW + button.imageTitleSpace+button.contentEdgeInsets.left+button.contentEdgeInsets.right;
        } else if (button.currentTitle && button.currentImage && (button.imagePosition == SPItemImagePositionTop || button.imagePosition == SPItemImagePositionBottom)) {
            contentW = MAX(textW, imageW)+button.contentEdgeInsets.left+button.contentEdgeInsets.right;
        }
        if (customWidth) {
            contentW_sum += customWidth;
            [buttonWidths addObject:@(customWidth)];
        } else {
            contentW_sum += contentW;
            [buttonWidths addObject:@(contentW)];
        }
    }
    CGFloat diff = itemScrollViewW - contentW_sum;
    if (self.permutationWay == SPPageMenuPermutationWayNotScrollAdaptContent && diff < 0) {
        for (int i = 0; i < buttonWidths.count; i++) {
            CGFloat buttonW = [buttonWidths[i] floatValue];
            buttonW -= fabs(diff)*buttonW/contentW_sum;
            [buttonWidths replaceObjectAtIndex:i withObject:@(buttonW)];
        }
        contentW_sum = [[buttonWidths valueForKeyPath:@"@sum.floatValue"] floatValue];
    }
    
    [self.buttons enumerateObjectsUsingBlock:^(SPPageMenuButton *button, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat customWidth = [[self.customWidths valueForKey:[NSString stringWithFormat:@"%lu",(unsigned long)idx]] floatValue];
        CGFloat customSpacing = 0.0;
        if (idx > 0) {
            NSString *key = [NSString stringWithFormat:@"%lu",(unsigned long)(idx-1)];
            if ([self.customSpacings.allKeys containsObject:key]) {
                customSpacing = [[self.customSpacings valueForKey:key] floatValue];
            } else {
                customSpacing = self->_itemPadding;
            }
        }
        CGFloat totalCustomSpacing = [[self.customSpacings.allValues valueForKeyPath:@"@sum.floatValue"] floatValue];
        CGFloat totalSpacing = totalCustomSpacing + (self.buttons.count-self.customSpacings.count)*self->_itemPadding;
        if (self.permutationWay == SPPageMenuPermutationWayScrollAdaptContent) {
            buttonW = [buttonWidths[idx] floatValue];
            if (idx == 0) {
                button.frame = CGRectMake(self->_itemPadding*0.5+lastButtonMaxX, 0, buttonW, itemScrollViewH);
            } else {
                button.frame = CGRectMake(customSpacing+lastButtonMaxX, 0, buttonW, itemScrollViewH);
            }
        } else if (self.permutationWay == SPPageMenuPermutationWayNotScrollEqualWidths) {
            // 求出外界设置的按钮宽度之和
            CGFloat totalCustomWidth = [[self.customWidths.allValues valueForKeyPath:@"@sum.floatValue"] floatValue];
            // 如果该按钮外界设置了宽，则取外界设置的，如果外界没设置，则其余按钮等宽
            buttonW = customWidth ? customWidth : (itemScrollViewW-totalSpacing-totalCustomWidth)/(self.buttons.count-self.customWidths.count);
            if (buttonW < 0) { // 按钮过多时,有可能会为负数
                buttonW = 0;
            }
            if (idx == 0) {
                button.frame = CGRectMake(self->_itemPadding*0.5+lastButtonMaxX, 0, buttonW, itemScrollViewH);
            } else {
                button.frame = CGRectMake(customSpacing+lastButtonMaxX, 0, buttonW, itemScrollViewH);
            }
            
        } else {
            buttonW = [buttonWidths[idx] floatValue];
            if (_forceUseSettingSpacing) { // 如果强制使用外界设置的间距
                CGFloat paddingDiff = diff - totalSpacing; // 自动间距之和与外界设置的间距之和的差
                buttonW += paddingDiff * buttonW/contentW_sum; // 用上面计算出来的差值乘以原按钮宽度相对总按钮宽度的比例,得到的结果就是每个按钮宽度应该增减的值,这样可以保证各个按钮之间的宽度之比不变
            } else { // 否则使用自己计算的间距
                CGFloat autoPadding = diff/self.buttons.count;
                if (autoPadding < 0) {autoPadding = 0.0;}
                if (totalCustomSpacing > 0) {
                    CGFloat paddingDiff = totalCustomSpacing - autoPadding*self.customSpacings.count;
                    buttonW -= paddingDiff * buttonW/contentW_sum;
                }
                self->_itemPadding = autoPadding;
                NSString *key = [NSString stringWithFormat:@"%lu",(unsigned long)(idx-1)];
                if (![self.customSpacings.allKeys containsObject:key]) {
                    customSpacing = self->_itemPadding;
                }
            }
            if (buttonW < 0) { buttonW = 0;}
            if (idx == 0) {
                button.frame = CGRectMake(self->_itemPadding*0.5+lastButtonMaxX, 0, buttonW, itemScrollViewH);
            } else {
                button.frame = CGRectMake(customSpacing+lastButtonMaxX, 0, buttonW, itemScrollViewH);
            }
        }
        lastButtonMaxX = CGRectGetMaxX(button.frame);
    }];
    
    // 如果selectedButton有缩放，走完上面代码selectedButton的frame会还原，这会导致文字显示不全问题，为了解决这个问题，这里将selectedButton的frame强制缩放
    if (!CGAffineTransformEqualToTransform(self.selectedButton.transform, CGAffineTransformIdentity)) {
        CGRect selectedButtonRect = self.selectedButton.frame;
        selectedButtonRect.origin.y = selectedButtonRect.origin.y-(selectedButtonRect.size.height*_selectedItemZoomScale - selectedButtonRect.size.height)/2;
        selectedButtonRect.origin.x = selectedButtonRect.origin.x-((selectedButtonRect.size.width*_selectedItemZoomScale - selectedButtonRect.size.width)/2);
        selectedButtonRect.size = CGSizeMake(selectedButtonRect.size.width * _selectedItemZoomScale, selectedButtonRect.size.height*_selectedItemZoomScale);
        self.selectedButton.frame = selectedButtonRect;
    }

    [self resetupTrackerFrameWithSelectedButton:self.selectedButton];
    
    self.itemScrollView.contentSize = CGSizeMake(lastButtonMaxX+_itemPadding*0.5, 0);
    
    if (self.translatesAutoresizingMaskIntoConstraints == NO) {
        [self moveItemScrollViewWithSelectedButton:self.selectedButton];
    }
}

- (void)resetupTrackerFrameWithSelectedButton:(SPPageMenuButton *)selectedButton {
    CGFloat trackerX;
    CGFloat trackerY;
    CGFloat trackerW;
    CGFloat trackerH;
    CGFloat selectedButtonWidth = selectedButton.frame.size.width;
    switch (self.trackerStyle) {
        case SPPageMenuTrackerStyleLine:
        {
            trackerW = _trackerWidth ? _trackerWidth : selectedButtonWidth;
            trackerH = _trackerHeight;
            trackerX = selectedButton.frame.origin.x;
            trackerY = self.itemScrollView.bounds.size.height - trackerH;
            self.tracker.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
        }
            break;
        case SPPageMenuTrackerStyleLineLongerThanItem:
        {
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+(selectedButtonWidth ? _itemPadding : 0));
            trackerH = _trackerHeight;
            trackerX = selectedButton.frame.origin.x;
            trackerY = self.itemScrollView.bounds.size.height - trackerH;
            self.tracker.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
        }
            break;
        case SPPageMenuTrackerStyleLineAttachment:
        {
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth ? selectedButton.titleLabel.font.pointSize : 0); // 没有自定义宽度就固定宽度为字体大小
            trackerH = _trackerHeight;
            trackerX = selectedButton.frame.origin.x;
            trackerY = self.itemScrollView.bounds.size.height - trackerH;
            self.tracker.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
        }
            break;
        case SPPageMenuTrackerStyleRect:
        {
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+(selectedButtonWidth ? _itemPadding : 0));
            trackerH = _trackerHeight ? _trackerHeight : (selectedButton.frame.size.height);
            trackerX = selectedButton.frame.origin.x;
            trackerY = (_itemScrollViewH-trackerH)*0.5;
            self.tracker.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
            self.tracker.layer.cornerRadius = 0;
        }
            break;
        case SPPageMenuTrackerStyleSegment:
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+(selectedButtonWidth ? _itemPadding : 0));
            trackerH = _trackerHeight ? _trackerHeight : (selectedButton.frame.size.height);
            trackerX = selectedButton.frame.origin.x;
            trackerY = (_itemScrollViewH-trackerH)*0.5;
            self.tracker.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
            self.tracker.layer.cornerRadius = 0;
            
            self.layer.cornerRadius = self.frame.size.height/2;
            self.clipsToBounds = YES;
            self.layer.borderColor = self.segmentBorderColor.CGColor;
            self.layer.borderWidth = 0.5;
            break;
        case SPPageMenuTrackerStyleRoundedRect:
        {
            trackerH = _trackerHeight ? _trackerHeight : (_itemTitleFont.lineHeight+10);
            trackerW = _trackerWidth ? _trackerWidth : (selectedButtonWidth+_itemPadding);
            trackerX = selectedButton.frame.origin.x;
            trackerY = (_itemScrollViewH-trackerH)*0.5;
            self.tracker.frame = CGRectMake(trackerX, trackerY, trackerW, trackerH);
            self.tracker.layer.cornerRadius = MIN(trackerW, trackerH)*0.5;
            self.tracker.layer.masksToBounds = YES;
        }
            break;
        default:
            break;
    }
    
    CGPoint trackerCenter = self.tracker.center;
    trackerCenter.x = selectedButton.center.x;
    self.tracker.center = trackerCenter;
}

- (void)dealloc {
    [self.bridgeScrollView removeObserver:self forKeyPath:scrollViewContentOffset];
}

@end

#pragma clang diagnostic pop







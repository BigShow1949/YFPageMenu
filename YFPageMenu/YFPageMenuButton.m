//
//  YFPageMenuButton.m
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import "YFPageMenuButton.h"

@implementation YFPageMenuButton


- (instancetype)initWithImagePosition:(SPItemImagePosition)imagePosition {
    if (self = [super init]) {
        self.imagePosition = imagePosition;
    }
    return self;
}

#pragma mark - system methods

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
    
//    self.titleLabel.backgroundColor = [UIColor blueColor];
    
    _imagePosition = SPItemImagePositionLeft;
    _imageTitleSpace = 0.0;
}

// 下面这2个方法，我所知道的:
// 在第一次调用titleLabel和imageView的getter方法(懒加载)时,alloc init之前会调用一次(无论有无图片文字都会直接调)，因此，在重写这2个方法时，在方法里面不要使用self.imageView和self.titleLabel，因为这2个控件是懒加载，如果在重写的这2个方法里是第一调用imageView和titleLabel的getter方法, 则会造成死循环
// 在layoutsSubviews中如果文字或图片不为空时会调用, 测试方式：在重写的这两个方法里调用setNeedsLayout(layutSubviews)，发现会造成死循环
// 设置文字图片、改动文字和图片、设置对齐方式，设置内容区域等时会调用，其实设置这些属性，系统是调用了layoutSubviews从而间接的去调用imageRectForContentRect:和titleRectForContentRect:
// ...
- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    // 先获取系统为我们计算好的rect，这样大小图片在左右时我们就不要自己去计算,我门要改变的，仅仅是origin
    CGRect imageRect = [super imageRectForContentRect:contentRect];
    CGRect titleRect = [super titleRectForContentRect:contentRect];
    if (!self.currentTitle) { // 如果没有文字，则图片占据整个button，空格算一个文字
        return imageRect;
    }
    switch (self.imagePosition) {
        case SPItemImagePositionLeft:
        case SPItemImagePositionDefault: { // 图片在左
            imageRect = [self imageRectImageAtLeftForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
        case SPItemImagePositionRight: {
            imageRect = [self imageRectImageAtRightForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
        case SPItemImagePositionTop: {
            imageRect = [self imageRectImageAtTopForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
        case SPItemImagePositionBottom: {
            imageRect = [self imageRectImageAtBottomForContentRect:contentRect imageRect:imageRect titleRect:titleRect];
        }
            break;
    }
    return imageRect;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGRect titleRect = [super titleRectForContentRect:contentRect];
    CGRect imageRect = [super imageRectForContentRect:contentRect];
    if (!self.currentImage) {  // 如果没有图片
        return titleRect;
    }
    switch (self.imagePosition) {
        case SPItemImagePositionLeft:
        case SPItemImagePositionDefault: {
            titleRect = [self titleRectImageAtLeftForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
        case SPItemImagePositionRight: {
            titleRect = [self titleRectImageAtRightForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
        case SPItemImagePositionTop: {
            titleRect = [self titleRectImageAtTopForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
        case SPItemImagePositionBottom: {
            titleRect = [self titleRectImageAtBottomForContentRect:contentRect titleRect:titleRect imageRect:imageRect];
        }
            break;
    }
    return titleRect;
    
}

#pragma - private

// ----------------------------------------------------- left -----------------------------------------------------

- (CGRect)imageRectImageAtLeftForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = imageRect.size;
    // imageView的x值向左偏移间距的一半，另一半由titleLabe分担，不用管会不会超出contentRect，我定的规则是允许超出，如果对此作出限制，那么必须要对图片或者文字宽高有所压缩，压缩只能由imageEdgeInsets决定，当图片的内容区域容不下时才产生宽度压缩
    imageOrigin.x = imageOrigin.x - _imageTitleSpace*0.5;
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtLeftForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    CGPoint titleOrigin = titleRect.origin;
    CGSize titleSize = titleRect.size;
    
    titleOrigin.x = titleOrigin.x + _imageTitleSpace * 0.5;
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// ----------------------------------------------------- right -----------------------------------------------------

- (CGRect)imageRectImageAtRightForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = imageRect.size;
    CGSize titleSize = titleRect.size;
    
    titleSize = [self calculateTitleSizeForSystemTitleSize:titleSize];
    
    CGFloat imageSafeWidth = contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right;
    if (imageSize.width >= imageSafeWidth) {
        return imageRect;
    }
    // 这里水平中心对齐，跟图片在右边时的中心对齐时差别在于：图片在右边时中心对齐考虑了titleLabel+imageView这个整体，而这里只单独考虑imageView
    if (imageSize.width + titleSize.width > imageSafeWidth) {
        imageSize.width = imageSize.width - (imageSize.width + titleSize.width - imageSafeWidth);
    }
    // (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - (imageSize.width + titleSize.width))/2.0+titleSize.width指的是imageView在其有效区域内联合titleLabel整体居中时的x值，有效区域指的是contentRect内缩imageEdgeInsets后的区域
    imageOrigin.x = (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - (imageSize.width + titleSize.width))/2.0 + titleSize.width + self.contentEdgeInsets.left + self.imageEdgeInsets.left + _imageTitleSpace * 0.5;
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtRightForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    
    CGPoint titleOrigin = titleRect.origin;
    CGSize titleSize = titleRect.size;
    CGSize imageSize = imageRect.size;
    
    // (contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right - (imageSize.width + titleSize.width))/2.0的意思是titleLabel在其有效区域内联合imageView整体居中时的x值，有效区域指的是contentRect内缩titleEdgeInsets后的区域
    titleOrigin.x = (contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right - (imageSize.width + titleSize.width))/2.0 + self.contentEdgeInsets.left + self.titleEdgeInsets.left - _imageTitleSpace * 0.5;
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// ----------------------------------------------------- top -----------------------------------------------------

- (CGRect)imageRectImageAtTopForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = imageRect.size;
    CGSize titleSize = titleRect.size;
    
    CGFloat imageSafeWidth = contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right;
    
    // 这里水平中心对齐，跟图片在右边时的中心对齐时差别在于：图片在右边时中心对齐考虑了titleLabel+imageView这个整体，而这里只单独考虑imageView
    if (imageSize.width > imageSafeWidth) {
        imageSize.width = imageSafeWidth;
    }
    imageOrigin.x = (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - imageSize.width) / 2.0 + self.contentEdgeInsets.left + self.imageEdgeInsets.left;
    
    // 给图片高度作最大限制，超出限制对高度进行压缩，这样还可以保证titeLabel不会超出其有效区域
    CGFloat imageTitleLimitMaxH = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
    if (imageSize.height < imageTitleLimitMaxH) {
        if (titleSize.height + self.currentImage.size.height > imageTitleLimitMaxH) {
            CGFloat beyondValue = titleSize.height + self.currentImage.size.height - imageTitleLimitMaxH;
            imageSize.height = imageSize.height - beyondValue;
        }
        // 之所以采用自己计算的结果，是因为当sizeToFit且titleLabel的numberOfLines > 0时，系统内部会按照2行计算
        titleSize = [self calculateTitleSizeForSystemTitleSize:titleSize];
    }
    // (imageSize.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的insets，计算时都是以图片+文字这个整体作为考虑对象
    imageOrigin.y =  (contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + self.contentEdgeInsets.top + self.imageEdgeInsets.top - _imageTitleSpace * 0.5;
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtTopForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    CGPoint titleOrigin = titleRect.origin;
    CGSize titleSize = titleRect.size;
    
    CGSize imageSize = imageRect.size;
    // 这个if语句的含义是：计算图片由于设置了contentEdgeInsets而被压缩的高度，设置imageEdgeInsets被压缩的高度不计算在内。这样做的目的是，当设置了contentEdgeInsets时，图片可能会被压缩，此时titleLabel的y值依赖于图片压缩后的高度，当设置了imageEdgeInsets时，图片也可能被压缩，此时titleLabel的y值依赖于图片压缩前的高度，这样以来，设置imageEdgeInsets就不会对titleLabel的y值产生影响
    if (self.currentImage.size.height + titleSize.height > contentRect.size.height) {
        imageSize.height = self.currentImage.size.height - (self.currentImage.size.height + titleSize.height - contentRect.size.height);
    }
    
    titleSize = [self calculateTitleSizeForSystemTitleSize:titleSize];
    // titleLabel的安全宽度，这里一定要改变宽度值，因为当外界设置了titleEdgeInsets值时，系统计算出来的所有值都是在”左图右文“的基础上进行的，这个基础上可能会导致titleLabel的宽度被压缩，所以我们在此自己重新计算
    CGFloat titleSafeWidth = contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right;
    if (titleSize.width > titleSafeWidth) {
        titleSize.width = titleSafeWidth;
    }
    titleOrigin.x = (titleSafeWidth - titleSize.width) / 2.0 + self.contentEdgeInsets.left + self.titleEdgeInsets.left;
    
    if (titleSize.height > contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom) {
        titleSize.height = contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom;
    }
    
    // (self.currentImage.size.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的Insets，计算时都是以图片+文字这个整体作为考虑对象
    titleOrigin.y =  (contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + imageSize.height + self.contentEdgeInsets.top + self.titleEdgeInsets.top + _imageTitleSpace * 0.5;
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// ----------------------------------------------------- bottom -----------------------------------------------------

- (CGRect)imageRectImageAtBottomForContentRect:(CGRect)contentRect imageRect:(CGRect)imageRect titleRect:(CGRect)titleRect {
    CGPoint imageOrigin = imageRect.origin;
    CGSize imageSize = imageRect.size;
    CGSize titleSize = titleRect.size;
    
    titleSize = [self calculateTitleSizeForSystemTitleSize:titleSize];
    
    CGFloat imageSafeWidth = contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right;
    // 这里水平中心对齐，跟图片在右边时的中心对齐时差别在于：图片在右边时中心对齐考虑了titleLabel+imageView这个整体，而这里只单独考虑imageView
    if (imageSize.width > imageSafeWidth) {
        imageSize.width = imageSafeWidth;
    }
    
    imageOrigin.x = (contentRect.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right - imageSize.width) / 2.0 + self.contentEdgeInsets.left + self.imageEdgeInsets.left;
    
    // 给图片高度作最大限制，超出限制对高度进行压缩，这样还可以保证titeLabel不会超出其有效区域
    CGFloat imageTitleLimitMaxH = contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
    if (imageSize.height < imageTitleLimitMaxH) {
        if (titleSize.height + self.currentImage.size.height > imageTitleLimitMaxH) {
            CGFloat beyondValue = titleSize.height + self.currentImage.size.height - imageTitleLimitMaxH;
            imageSize.height = imageSize.height - beyondValue;
        }
        // 之所以采用自己计算的结果，是因为当sizeToFit且titleLabel的numberOfLines > 0时，系统内部会按照2行计算
        titleSize = [self calculateTitleSizeForSystemTitleSize:titleSize];
    }
    // (self.currentImage.size.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的insets，计算时都是以图片+文字这个整体作为考虑对象
    imageOrigin.y =  (contentRect.size.height - self.imageEdgeInsets.top - self.imageEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + titleSize.height + self.contentEdgeInsets.top + self.imageEdgeInsets.top + _imageTitleSpace * 0.5;
    imageRect.size = imageSize;
    imageRect.origin = imageOrigin;
    return imageRect;
}

- (CGRect)titleRectImageAtBottomForContentRect:(CGRect)contentRect titleRect:(CGRect)titleRect imageRect:(CGRect)imageRect {
    CGPoint titleOrigin = titleRect.origin;
    CGSize titleSize = titleRect.size;
    
    CGSize imageSize = imageRect.size;
    // 这个if语句的含义是：计算图片由于设置了contentEdgeInsets而被压缩的高度，设置imageEdgeInsets被压缩的高度不计算在内。这样做的目的是，当设置了contentEdgeInsets时，图片可能会被压缩，此时titleLabel的y值依赖于图片压缩后的高度，当设置了imageEdgeInsets时，图片也可能被压缩，此时titleLabel的y值依赖于图片压缩前的高度，这样一来，设置imageEdgeInsets就不会对titleLabel的y值产生影响
    if (self.currentImage.size.height + titleSize.height > contentRect.size.height) {
        imageSize.height = self.currentImage.size.height - (self.currentImage.size.height + titleSize.height - contentRect.size.height);
        if (imageSize.height < 0) {
            imageSize.height = 0;
        }
    }
    
    titleSize = [self calculateTitleSizeForSystemTitleSize:titleSize];
    // titleLabel的安全宽度，因为当外界设置了titleEdgeInsets值时，系统计算出来的所有值都是在”左图右文“的基础上进行的，这个基础上可能会导致titleLabel的宽度被压缩，所以我们在此自己重新计算
    CGFloat titleSafeWidth = contentRect.size.width - self.titleEdgeInsets.left - self.titleEdgeInsets.right;
    if (titleSize.width > titleSafeWidth) {
        titleSize.width = titleSafeWidth;
    }
    
    titleOrigin.x = (titleSafeWidth - titleSize.width) / 2.0 + self.contentEdgeInsets.left + self.titleEdgeInsets.left;
    
    if (titleSize.height > contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom) {
        titleSize.height = contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom;
    }
    
    // (self.currentImage.size.height + titleSize.height)这个整体高度很重要，这里相当于按照按钮原有规则进行对齐，即按钮的对齐方式不管是设置谁的Insets，计算时都是以图片+文字这个整体作为考虑对象
    titleOrigin.y =  (contentRect.size.height - self.titleEdgeInsets.top - self.titleEdgeInsets.bottom - (imageSize.height + titleSize.height)) / 2.0 + self.contentEdgeInsets.top + self.titleEdgeInsets.top - _imageTitleSpace * 0.5;
    titleRect.size = titleSize;
    titleRect.origin = titleOrigin;
    return titleRect;
}

// 自己计算titleLabel的大小
- (CGSize)calculateTitleSizeForSystemTitleSize:(CGSize)titleSize {
    CGSize myTitleSize = titleSize;
    // 获取按钮里的titleLabel,之所以遍历获取而不直接调用self.titleLabel，是因为假如这里是第一次调用self.titleLabel，则会跟titleRectForContentRect: 方法造成死循环,titleLabel的getter方法中，alloc init之前调用了titleRectForContentRect:
    UILabel *titleLabel = [self findTitleLabel];
    if (!titleLabel) { // 此时还没有创建titleLabel，先通过系统button的字体进行文字宽度计算
        CGFloat fontSize = [UIFont buttonFontSize]; // 按钮默认字体，18号
        // 说明外界使用了被废弃的font属性，被废弃但是依然生效
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (self.font.pointSize != [UIFont buttonFontSize]) {
            fontSize = self.font.pointSize;
        }
#pragma clang diagnostic pop
        myTitleSize.height = ceil([self.currentTitle boundingRectWithSize:CGSizeMake(titleSize.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size.height);
        // 根据文字计算宽度，取上整，补齐误差，保证跟titleLabel.intrinsicContentSize.width一致
        myTitleSize.width = ceil([self.currentTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, titleSize.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size.width);
    } else { // 说明此时titeLabel已经产生，直接取titleLabel的内容宽度
        myTitleSize.width = titleLabel.intrinsicContentSize.width;
        myTitleSize.height = titleLabel.intrinsicContentSize.height;
    }
    return myTitleSize;
}

// 遍历获取按钮里面的titleLabel
- (UILabel *)findTitleLabel {
    for (UIView *subView in self.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UIButtonLabel")]) {
            UILabel *titleLabel = (UILabel *)subView;
            return titleLabel;
        }
    }
    return nil;
}



#pragma mark - setter
// 以下所有setter方法中都调用了layoutSubviews, 其实是为了间接的调用imageRectForContentRect:和titleRectForContentRect:，不能直接调用imageRectForContentRect:和titleRectForContentRect:,因为按钮的子控件布局最终都是通过调用layoutSubviews而确定，如果直接调用这两个方法，那么只能保证我们能够获取的CGRect是对的，但并不会作用在titleLabel和imageView上
- (void)setImagePosition:(SPItemImagePosition)imagePosition {
    _imagePosition = imagePosition;
    [self setNeedsLayout];
}

- (void)setImageTitleSpace:(CGFloat)imageTitleSpace {
    _imageTitleSpace = imageTitleSpace;
    [self setNeedsLayout];
}

- (void)setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment {
    [super setContentHorizontalAlignment:contentHorizontalAlignment];
    [self setNeedsLayout];
}

// 垂直方向的排列方式在设置之前如果调用了titleLabel或imageView的getter方法，则设置后不会生效，点击一下按钮之后就生效了，这应该属于按钮的一个小bug，我们只要重写它的setter方法重新布局一次就好
- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];
    [self setNeedsLayout];
}

@end

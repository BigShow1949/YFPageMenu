//
//  YFPageMenuButton.h
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, SPItemImagePosition) {
    SPItemImagePositionDefault,   // 默认图片在左侧
    SPItemImagePositionLeft,      // 图片在文字左侧
    SPItemImagePositionRight,     // 图片在文字右侧
    SPItemImagePositionTop,       // 图片在文字上侧
    SPItemImagePositionBottom     // 图片在文字下侧
};


@interface YFPageMenuButton : UIButton
- (instancetype)initWithImagePosition:(SPItemImagePosition)imagePosition;

@property (nonatomic) SPItemImagePosition imagePosition; // 图片位置
@property (nonatomic,assign) CGFloat imageTitleSpace; // 图片和文字之间的间距
@end

NS_ASSUME_NONNULL_END

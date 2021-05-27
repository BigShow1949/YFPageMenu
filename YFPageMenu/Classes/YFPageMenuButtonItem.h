//
//  YFPageMenuButtonItem.h
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import <Foundation/Foundation.h>

#import "YFPageMenuButton.h"

NS_ASSUME_NONNULL_BEGIN
// 这个类相当于模型,主要用于同时为某个按钮设置图片和文字时使用

@interface YFPageMenuButtonItem : NSObject
// 快速创建同时含有标题和图片的item，默认图片在左边，文字在右边
+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image;
// 快速创建同时含有标题和图片的item，imagePositiona参数为图片位置
+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image imagePosition:(SPItemImagePosition)imagePosition;

@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) UIImage *image;
// 图片的位置
@property (nonatomic,assign) SPItemImagePosition imagePosition;
// 图片与标题之间的间距,默认0.0
@property (nonatomic,assign) CGFloat imageTitleSpace;
@end

NS_ASSUME_NONNULL_END

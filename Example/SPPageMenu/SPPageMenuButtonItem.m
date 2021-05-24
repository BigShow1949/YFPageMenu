//
//  SPPageMenuButtonItem.m
//  Medicine
//
//  Created by BigShow on 2021/5/24.
//

#import "SPPageMenuButtonItem.h"

@implementation SPPageMenuButtonItem
+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image {
    SPPageMenuButtonItem *item = [[SPPageMenuButtonItem alloc] initWithTitle:title image:image imagePosition:SPItemImagePositionDefault];
    return item;
}

+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image imagePosition:(SPItemImagePosition)imagePosition {
    SPPageMenuButtonItem *item = [[SPPageMenuButtonItem alloc] initWithTitle:title image:image imagePosition:imagePosition];
    return item;
}

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image imagePosition:(SPItemImagePosition)imagePosition {
    if (self = [super init]) {
        self.title = title;
        self.image = image;
        self.imagePosition = imagePosition;
    }
    return self;
}

@end

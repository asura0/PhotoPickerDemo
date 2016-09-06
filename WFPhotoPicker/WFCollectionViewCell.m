//
//  WFCollectionViewCell.m
//  WFPhotoPicker
//
//  Created by 赚发2 on 16/9/5.
//  Copyright © 2016年 fengwang. All rights reserved.
//

#import "WFCollectionViewCell.h"

@implementation WFCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:_imageView];
    }
    return self;
}

@end

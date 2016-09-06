//
//  WFTailoringViewController.h
//  WFPhotoPicker
//
//  Created by 赚发2 on 16/9/2.
//  Copyright © 2016年 fengwang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^WFTailoringViewControllerTailoredImageBlock)(UIImage *imgae);

@interface WFTailoringViewController : UIViewController

/** 传入的 data */
@property (nonatomic, strong) NSData *imageData;

@property (nonatomic, copy) WFTailoringViewControllerTailoredImageBlock tailoredImage;


@end

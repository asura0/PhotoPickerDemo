//
//  WFPhotoAlbum.h
//  WFPhotoPicker
//
//  Created by  Asura on 16/9/4.
//  Copyright © 2016年 fengwang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFPhotoAlbum : NSObject

/**
 *  是否有相片列表名,默认没有
 */
@property (nonatomic, assign) BOOL isShowGroups;


+ (WFPhotoAlbum *)standarWFPhotosAlbum;

/**
 *  获取图片方法
 *
 *  @param success 成功回调(分组列表,原图,缩略图)
 *  @param failure 失败回调(error)
 */
- (void)getPhotosSuccess:(void (^)(NSMutableArray *groupPhotos,
                                   NSMutableArray *fullPhotos,
                                   NSMutableArray *thumbnails))success
                 failure:(void (^)(NSError *error))failure;
@end

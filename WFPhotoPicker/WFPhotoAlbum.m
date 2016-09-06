//
//  WFPhotoAlbum.m
//  WFPhotoPicker
//
//  Created by  Asura on 16/9/4.
//  Copyright © 2016年 fengwang. All rights reserved.
//

#import "WFPhotoAlbum.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "PopView.h"

typedef void(^WFPhotoAlbumSuccess)(NSMutableArray *groupPhotos, NSMutableArray *fullPhotos, NSMutableArray *thumbnails);
typedef void(^WFPhotoAlbumFailure)(NSError *error);

#define IPHONE_IOS [[[UIDevice currentDevice] systemVersion] floatValue]

@interface WFPhotoAlbum ()

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) ALAssetsLibrary *ssetLibrary;

//相片资源
@property (nonatomic, strong) NSMutableArray *fullPhotos;
@property (nonatomic, strong) NSMutableArray *thumbnails;
//相册列表资源
@property (nonatomic, strong) NSMutableArray *albums;

@property (nonatomic, copy) WFPhotoAlbumSuccess success;
@property (nonatomic, copy) WFPhotoAlbumFailure failure;

@end

@implementation WFPhotoAlbum

+ (WFPhotoAlbum *)standarWFPhotosAlbum{
    static WFPhotoAlbum *_photosAlbum = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _photosAlbum = [[self alloc] init];
        _photosAlbum.albums = [NSMutableArray array];
        _photosAlbum.fullPhotos = [NSMutableArray array];
        _photosAlbum.thumbnails = [NSMutableArray array];
    });
    return _photosAlbum;
}

- (void)getPhotosSuccess:(void (^)(NSMutableArray *, NSMutableArray<NSString *> *, NSMutableArray<NSData *> *))success failure:(void (^)(NSError *))failure{
    _success = [success copy];
    _failure = [failure copy];
    [self wf_GetPhotos];
}

- (void)wf_GetPhotos{
    if (_fullPhotos.count != 0 && _thumbnails.count != 0) {
        _success ? _success(_albums,_fullPhotos,_thumbnails) : nil;
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (IPHONE_IOS <= 8.0) {
            [self wf_GetPhotosBefore];
        }else{
            [self wf_getPhotosLater];
        }
    });
}

- (void)wf_GetPhotosBefore{
    //获取当前应用对相册的访问授权状态
    ALAuthorizationStatus authorizationState = [ALAssetsLibrary authorizationStatus];
    // 如果没有获取访问授权，或者访问授权状态已经被明确禁止，则显示提示语，引导用户开启授权
    if (authorizationState == ALAuthorizationStatusRestricted || authorizationState == ALAuthorizationStatusDenied) {
        [self wf_alerPhotos];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [PopView initWithWaitingString:@"加载中..."];
        });
        _ssetLibrary  = [[ALAssetsLibrary alloc] init];
        [_ssetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                if (group.numberOfAssets > 0) {
                    if (_isShowGroups) {
                        //将相册列表.
                        [_albums addObject:[NSString stringWithFormat:@"%@(%li)张",[group valueForProperty:ALAssetsGroupPropertyName],group.numberOfAssets]];
                    }
                    
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        //ALAsset的类型
                        NSString *assetType = [result valueForProperty:ALAssetPropertyType];                    if ([assetType isEqualToString:ALAssetTypePhoto]){
                            ALAssetRepresentation *assetRepresentation =[result defaultRepresentation];
                            CGImageRef imageReference = [assetRepresentation fullScreenImage];
                            //压缩存储,不然内存ReceiveMemoryWarning,会 crash
                            [_fullPhotos addObject:UIImageJPEGRepresentation([UIImage imageWithCGImage:imageReference], 0.4)];
                        }
                        CGImageRef CGImage = result.thumbnail;
                        if (CGImage != nil) {
                            //缩略图
                            [_thumbnails addObject:[UIImage imageWithCGImage:CGImage]];
                        }
                    }];
                }
            }else{
                //没有相册列表资源,输出提示
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                _success ? _success(_albums,_fullPhotos,_thumbnails) : nil;
                [PopView dissmissPopview];
            });
        } failureBlock:^(NSError *error) {
            //失败
            dispatch_async(dispatch_get_main_queue(), ^{
                _failure ? _failure(error) : nil;
                [PopView initWithFailureString:@"失败!"];
            });
        }];
    }
}

- (void)wf_getPhotosLater{
    //权限
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status != PHAuthorizationStatusAuthorized) {
        [self wf_alerPhotos];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [PopView initWithWaitingString:@"加载中..."];
        });
        if (_isShowGroups) {
            // 列出所有相册列表
            PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            [smartAlbums enumerateObjectsUsingBlock:^(PHCollection  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [_albums addObject:obj.localizedTitle];
            }];
        }
        
        // 获取所有资源的集合
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:nil];
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        //异步
        requestOptions.synchronous = YES;
        //速度和质量均衡//synchronous ture 时有效
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        //尽快提供要求左右的尺寸图
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        // 在资源的集合中 获取第一个集合，并获取其中的图片
        PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
        [assetsFetchResults enumerateObjectsUsingBlock:^(PHAsset  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //缩略图
            [imageManager requestImageForAsset:obj
                                    targetSize:CGSizeMake(125, 125)
                                   contentMode:PHImageContentModeDefault
                                       options:requestOptions
                                 resultHandler:^(UIImage *result, NSDictionary *info) {
                                     
                                     // 此处的result缩略图示为宽高不一致的图片
                                     [_thumbnails addObject:[self wf_thumbnailsCutfullPhoto:result]];
                                 }];
            //原图
            [imageManager requestImageDataForAsset:obj options:requestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                [_fullPhotos addObject:imageData];
            }];
            if (_fullPhotos.count == assetsFetchResults.count && _thumbnails.count == assetsFetchResults.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _success ? _success(_albums,_fullPhotos,_thumbnails) : nil;
                    [PopView dissmissPopview];
                });
            }
        }];
    }
}

//裁剪图片,此处裁剪为125*125大的图,即为我们的缩略图
- (UIImage *)wf_thumbnailsCutfullPhoto:(UIImage*)fullPhoto
{
    CGSize newSize;
    CGImageRef imageRef = nil;
    if ((fullPhoto.size.width / fullPhoto.size.height) < 1) {
         newSize.width = fullPhoto.size.width;
         newSize.height = fullPhoto.size.width * 1;
         imageRef = CGImageCreateWithImageInRect([fullPhoto CGImage], CGRectMake(0, fabs(fullPhoto.size.height - newSize.height) / 2, newSize.width, newSize.height));

     } else {
         newSize.height = fullPhoto.size.height;
         newSize.width = fullPhoto.size.height * 1;
         imageRef = CGImageCreateWithImageInRect([fullPhoto CGImage], CGRectMake(fabs(fullPhoto.size.width - newSize.width) / 2, 0, newSize.width, newSize.height));

     }
     return [UIImage imageWithCGImage:imageRef];
 }

- (void)wf_alerPhotos{
    NSDictionary *mainInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [mainInfoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *alerString = [NSString stringWithFormat:@"请在设备的\"设置-隐私-照片\"选项中，允许%@访问你的手机相册", appName];
    // 展示提示语
    dispatch_async(dispatch_get_main_queue(), ^{
        [PopView initWithTitle:@"提示" content:alerString buttonTitle:@[@"知道了!"] success:^{
            
        } failure:^{
            
        }];
    });
}
#pragma clang diagnostic pop
@end

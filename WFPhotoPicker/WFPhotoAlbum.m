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
    });
    return _photosAlbum;
}

- (void)getPhotosSuccess:(void (^)(NSMutableArray *, NSMutableArray *, NSMutableArray *))success failure:(void (^)(NSError *))failure{
    _success = [success copy];
    _failure = [failure copy];
    [self wf_GetPhotos];
    
}

- (void)wf_GetPhotos{
    _albums = [NSMutableArray array];
    _fullPhotos = [NSMutableArray array];
    _thumbnails = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (IPHONE_IOS <= 8.0) {
            [self wf_getPhotosBefore];
        }else{
            [self wf_getPhotosLater];
        }
    });
}

- (void)wf_getPhotosBefore{
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [PopView initWithTitle:@"提示" content:@"没有相册资源" buttonTitle:@[@"知道了!"] success:^{
                        
                    } failure:^{
                        
                    }];
                });
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
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        [self wf_alerPhotos];
    }else{
       [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
           if (status == PHAuthorizationStatusAuthorized) {
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
               
               [assetsFetchResults enumerateObjectsUsingBlock:^(PHAsset  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                   [_thumbnails addObject:obj];
                   [_fullPhotos addObject:obj];
                   
                   if (_fullPhotos.count == assetsFetchResults.count && _thumbnails.count == assetsFetchResults.count) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           _success ? _success(_albums,_fullPhotos,_thumbnails) : nil;
                           [PopView dissmissPopview];
                       });
                   }
               }];
           }
       }];
    }
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

//
//  WFPhotosViewController.m
//  WFPhotoPicker
//
//  Created by 赚发2 on 16/9/2.
//  Copyright © 2016年 fengwang. All rights reserved.
//

#import "WFPhotosViewController.h"
#import "WFCollectionViewCell.h"
#import "WFTailoringViewController.h"
#import "WFPhotoAlbum.h"
#import "PopView.h"
#import <Photos/Photos.h>

static NSString *const indentifier = @"CELL";

@interface WFPhotosViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

//资源的集合
@property (nonatomic, strong) PHCachingImageManager *imageManager;

@property (nonatomic, strong) NSMutableArray *fullPhotos;

@property (nonatomic, strong) NSMutableArray *thumbnails;

@end

@implementation WFPhotosViewController

#pragma mark - UIViewController life cycle -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = @"相片";
    [self private_confguireCollectionView];
    
    WFPhotoAlbum *photoAlbum = [WFPhotoAlbum standarWFPhotosAlbum];
    [photoAlbum getPhotosSuccess:^(NSMutableArray *groupPhotos, NSMutableArray *fullPhotos, NSMutableArray *thumbnails) {
        
        self.thumbnails = [thumbnails copy];
        self.fullPhotos = [fullPhotos copy];
        [_collectionView reloadData];
        if ([self.thumbnails.firstObject isKindOfClass:[PHAsset class]]) {
            // 在资源的集合
            _imageManager = [[PHCachingImageManager alloc] init];
            //缓存操作
            [_imageManager startCachingImagesForAssets:self.thumbnails
                                            targetSize:PHImageManagerMaximumSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"error:%@",error);
    }];
}

#pragma mark - event reponse -
- (void)returnPage{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - private methods -
- (void)private_confguireCollectionView{
    
    UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    returnButton.frame = CGRectMake(0, 0, 40, 40);
    [returnButton addTarget:self action:@selector(returnPage) forControlEvents:UIControlEventTouchUpInside];
    [returnButton setTitle:@"返回" forState:UIControlStateNormal];
    [returnButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:returnButton];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 4;
    flowLayout.minimumInteritemSpacing = 4;
    CGFloat width = (self.view.frame.size.width - 12) / 4;
    flowLayout.itemSize = CGSizeMake(width, width);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[WFCollectionViewCell class] forCellWithReuseIdentifier:indentifier];
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

#pragma mark - UICollectionViewDelegate -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.thumbnails.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    id obj = self.thumbnails[indexPath.item];
    WFCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:indentifier forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor orangeColor];
    if ([obj isKindOfClass:[UIImage class]]) {
        cell.imageView.image = obj;
    }else if ([obj isKindOfClass:[PHAsset class]]){

        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        //异步
        requestOptions.synchronous = YES;
        //速度和质量均衡//synchronous ture 时有效
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        //尽快提供要求左右的尺寸图
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        // 遍历资源的集合,获取其中的图片
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_imageManager requestImageForAsset:obj
                                    targetSize:CGSizeMake(125 * [UIScreen mainScreen].scale,
                                                          125 * [UIScreen mainScreen].scale)
                                   contentMode:PHImageContentModeDefault
                                       options:requestOptions
                                 resultHandler:^(UIImage *result, NSDictionary *info) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         cell.imageView.image = [self wf_thumbnailsCutfullPhoto:result];
                                     });
                                     
                                 }];
        });
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    WFTailoringViewController *tailoringVC = [[WFTailoringViewController alloc] init];
    tailoringVC.imageData = _fullPhotos[indexPath.item];
    tailoringVC.tailoredImage = ^ (UIImage *image){
        _tailoredImage ? _tailoredImage(image) : nil;
    };
    [self.navigationController pushViewController:tailoringVC animated:YES];
}

#pragma mark - setters and getters -

- (NSMutableArray *)fullPhotos{
    if (_fullPhotos == nil) {
        _fullPhotos = [NSMutableArray array];
    }
    return _fullPhotos;
}

- (NSMutableArray *)thumbnails{
    if (_thumbnails == nil) {
        _thumbnails = [NSMutableArray array];
    }
    return _thumbnails;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

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

static NSString *const indentifier = @"CELL";

@interface WFPhotosViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *datasource;

@property (nonatomic, strong) NSMutableArray *fullPhotos;


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
        
        self.datasource = [thumbnails copy];
        self.fullPhotos = [fullPhotos copy];
        [_collectionView reloadData];
        
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

#pragma mark - UICollectionViewDelegate -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.datasource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UIImage *image = self.datasource[indexPath.item];
    WFCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:indentifier forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor orangeColor];
    cell.imageView.image = image;
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
- (NSMutableArray *)datasource{
    if (_datasource == nil) {
        _datasource = [NSMutableArray array];
    }
    return _datasource;
}

- (NSMutableArray *)fullPhotos{
    if (_fullPhotos == nil) {
        _fullPhotos = [NSMutableArray array];
    }
    return _fullPhotos;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

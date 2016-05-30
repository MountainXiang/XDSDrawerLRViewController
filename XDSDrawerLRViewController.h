//
//  XDSDrawerLRViewController.h
//  TheHomeOfCars
//
//  Created by XDS on 15-10-11.
//  Copyright (c) 2015年 xds. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface XDSDrawerLRViewController : UIViewController

//#warning 设置主视图透明度是否有渐变效果，默认为YES
@property(nonatomic, assign) BOOL mainViewTransparentCanChanged;

//#warning 设置主视图缩放系数（0 ~ 1），默认为0（按需要设置）,系数越大表示主视图缩放比例越小
@property(nonatomic, assign) CGFloat transformCoefficient;

//#warning 设置是否开启单击主视图恢复到原位，默认为YES
@property(nonatomic, assign) BOOL tapCanBack;

/**
 *  初始化方法
 *
 *  @param mainCtrl  中间视图控制器
 *  @param leftCtrl  左侧视图控制器,nil则往右滑无效果
 *  @param rightCtrl 右侧视图控制器,nil则往左滑无效果
 *
 *  @return 可以左右滑动的抽屉式视图控制器
 */
//#warning 左右视图的背景色设置为clearColor才能显示背景图片，并禁用自动调整：self.navigationController.automaticallyAdjustsScrollViewInsets = NO;
- (id)initWithMainCtrl:(UIViewController *)mainCtrl leftCtrl:(UIViewController *)leftCtrl rightCtrl:(UIViewController *)rightCtrl backGroundImage:(UIImage *)backGroundImage;

@end

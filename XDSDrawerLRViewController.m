//
//  XDSDrawerLRViewController.m
//  TheHomeOfCars
//
//  Created by 项大山 on 15-10-11.
//  Copyright (c) 2015年 xds. All rights reserved.
//

#import "XDSDrawerLRViewController.h"
#import "LeftViewController.h"
#import "MainTabBarController.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ArticlesViewController.h"

#define kScreenW        [UIScreen mainScreen].bounds.size.width
#define kScreenH        [UIScreen mainScreen].bounds.size.height
//可能会改变的值不能设置为宏，数据容易混乱出错
//#define kLeftViewW      _leftCtrl.view.frame.size.width//左侧视图宽度
//#define kRightViewW     _rightCtrl.view.frame.size.width//右侧视图宽度

@interface XDSDrawerLRViewController ()<LeftViewControllerDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate,ArticleViewControllerDelegate>//遵循左侧视图协议方法，遵循系统相册控制器协议方法;遵循详情协议，实现播放视频方法
{
    @private
    MainTabBarController *_mainCtrl;
    
    LeftViewController *_leftCtrl;
    
    UIViewController *_rightCtrl;
    
    UIImageView *_bg;
    
    CGFloat _mainViewTransformScale;//主视图缩放比例，与transformCoefficient有关
    
    UIView          *_transparentView;//覆盖主视图的透明视图
    
    UITapGestureRecognizer *_tap;//覆盖主视图的透明视图上添加单击手势
    
    UIPanGestureRecognizer *_pan;//主视图上的轻滑手势
}
@end

@implementation XDSDrawerLRViewController

- (id)initWithMainCtrl:(UIViewController *)mainCtrl leftCtrl:(UIViewController *)leftCtrl rightCtrl:(UIViewController *)rightCtrl backGroundImage:(UIImage *)backGroundImage{
    _mainCtrl = (MainTabBarController *)mainCtrl;
    _leftCtrl = (LeftViewController *)leftCtrl;
    _rightCtrl = rightCtrl;
    
    
    //设置代理
    _leftCtrl.delegate = self;
    
    ArticlesViewController *articleVC = _mainCtrl.articleVC;
    
    articleVC.delegate = self;
    
    
    //初始化
    _mainViewTransparentCanChanged = YES;
    _transformCoefficient = 0;
    _tapCanBack = YES;
    
    //监听视频播放完毕通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    if (self) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [iv setImage:backGroundImage];
        [self.view addSubview:iv];
        
        //滑动手势，区别于swip轻划
        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.view addGestureRecognizer:_pan];
        
        [self.view addSubview:_leftCtrl.view];
        [self.view addSubview:_rightCtrl.view];
        [self.view addSubview:_mainCtrl.view];
        //设置两侧视图的透明度
        _leftCtrl.view.alpha = 0;
        _rightCtrl.view.alpha = 0;
    }
    return self;
}

#pragma mark 处理滑动手势
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    
    //确保0~1
    _transformCoefficient = _transformCoefficient > 1 ? 1 : _transformCoefficient;
    _transformCoefficient = _transformCoefficient < 0 ? 0 : _transformCoefficient;
    //主视图缩放比例
    _mainViewTransformScale = 0.2 + _transformCoefficient * 0.2;
//    HCLog(@"_mainViewTransformScale = %f",_mainViewTransformScale);
    
//滑动的时候，一侧视图和主视图逐渐缩放，一侧视图的透明度随缩放而改变
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        //获取滑动手势的偏移值
        CGPoint point = [gesture translationInView:self.view];
//        HCLog(@"point.x = %f",point.x);
        _mainCtrl.view.frame = CGRectOffset(_mainCtrl.view.frame, point.x, 0);
    
        //主视图位置水平偏移量
        CGFloat mainViewOriginX = _mainCtrl.view.frame.origin.x;
        //两侧视图的透明度由主视图水平偏移量确定,而不是point.x（每次都会重置）
        if (mainViewOriginX > 0) {//向右滑动
            if (_leftCtrl.view){//如果存在左侧视图
                //左侧视图逐渐缩放，透明度随之改变
                _leftCtrl.view.alpha = mainViewOriginX / kScreenW;
                _leftCtrl.view.layer.anchorPoint = CGPointMake(0.5, 0.5);
                _leftCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5 + (0.5 - _mainViewTransformScale) * _leftCtrl.view.alpha, 1.0f);
                
                //偏移使得左侧视图紧靠屏幕左侧边缘
                CGFloat leftViewOriginX = _leftCtrl.view.frame.origin.x;
                _leftCtrl.view.frame = CGRectOffset(_leftCtrl.view.frame, - leftViewOriginX, 0);
                
                //主视图随之缩放，透明度也随之改变
                _mainCtrl.view.layer.anchorPoint = CGPointMake(0.5, 0.5);
                _mainCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 - (0.5 - _mainViewTransformScale) * _leftCtrl.view.alpha, 1 - (0.5 - _mainViewTransformScale) * _leftCtrl.view.alpha);
                if (_mainViewTransparentCanChanged) {
                    _mainCtrl.view.alpha = (1 - _leftCtrl.view.alpha) < 0.5 ? 0.5 : (1 - _leftCtrl.view.alpha);
                }
            } else {
                [self backToMainCtrl];
            }
        }else if (mainViewOriginX < 0) {//向左滑动
            if (_rightCtrl.view) {//如果右侧视图存在
                //右侧视图逐渐缩放，透明度随之改变
                _rightCtrl.view.alpha = - mainViewOriginX / kScreenW;
                _rightCtrl.view.layer.anchorPoint = CGPointMake(0.5, 0.5);
                _rightCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5 + (0.5 - _mainViewTransformScale) * _rightCtrl.view.alpha, 1.0f);
                CGFloat rightViewOriginX = _rightCtrl.view.frame.origin.x;
                _rightCtrl.view.frame = CGRectOffset(_rightCtrl.view.frame, - rightViewOriginX, 0);
                
                //偏移使得右侧视图紧靠边缘
                CGFloat rightViewMaxX = CGRectGetMaxX(_rightCtrl.view.frame);
                _rightCtrl.view.frame = CGRectOffset(_rightCtrl.view.frame, kScreenW - rightViewMaxX, 0);
                
                //主视图随之缩放，透明度也随之改变
                _mainCtrl.view.layer.anchorPoint = CGPointMake(0.5, 0.5);
                _mainCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 - (0.5 - _mainViewTransformScale) * _rightCtrl.view.alpha, 1 - (0.5 - _mainViewTransformScale) * _rightCtrl.view.alpha);
                if (_mainViewTransparentCanChanged) {
                    _mainCtrl.view.alpha = (1 - _rightCtrl.view.alpha) < 0.5 ? 0.5 : (1 - _rightCtrl.view.alpha);
                }
            }else {
                [self backToMainCtrl];
            }
        }
        //避免重复叠加
        [gesture setTranslation:CGPointZero inView:self.view];
    }

    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (_leftCtrl.view.alpha > 0.5) {
            [self showLeftViewCtrl];
        }else if (_rightCtrl.view.alpha > 0.5) {
            [self showRightViewCtrl];
        }else {
            [self backToMainCtrl];
        }
    }
}

#pragma mark 单击主视图恢复
-  (void)handleTap:(UITapGestureRecognizer *)gesture {
    [self backToMainCtrl];
}

#pragma mark 恢复位置方法
- (void)backToMainCtrl {
    
    if (_transparentView.superview) {
        [_transparentView removeFromSuperview];
    }
    _tap.enabled = NO;
    _mainCtrl.view.alpha = 1.0f;
    _leftCtrl.view.alpha = 0;
    _rightCtrl.view.alpha = 0;
    _mainCtrl.view.transform = CGAffineTransformIdentity;
    _mainCtrl.view.center = self.view.center;
}

#pragma mark 显示左侧视图
- (void)showLeftViewCtrl {
//    HCLog(@"showLeftViewCtrl");
    
    _mainCtrl.view.alpha = 1.0f;
    _leftCtrl.view.alpha = 1.0f;
    _rightCtrl.view.alpha = 0;
    _leftCtrl.view.transform = CGAffineTransformIdentity;
    _leftCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 - _mainViewTransformScale, 1.0f);
    //偏移使得左侧视图左边缘紧靠屏幕左边缘
    CGFloat leftViewOriginX = _leftCtrl.view.frame.origin.x;
    _leftCtrl.view.frame = CGRectOffset(_leftCtrl.view.frame, - leftViewOriginX, 0);
    
    //缩小主视图
    _mainCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 - _mainViewTransformScale, 1 - _mainViewTransformScale);
    //偏移使得主视图左边缘紧靠左侧视图的右边缘
    CGFloat leftViewMaxX = CGRectGetMaxX(_leftCtrl.view.frame);
    CGFloat mainViewOriginX = _mainCtrl.view.frame.origin.x;
    _mainCtrl.view.frame = CGRectOffset(_mainCtrl.view.frame, leftViewMaxX - mainViewOriginX, 0);
//    HCLog(@"%@",NSStringFromCGRect(_mainCtrl.view.frame));
    
    //单击手势
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    if (_transparentView.superview) {
        [_transparentView removeFromSuperview];
    }
    _transparentView = [[UIView alloc] initWithFrame:_mainCtrl.view.frame];
    _transparentView.backgroundColor = [UIColor blackColor];
    _transparentView.alpha = 0.1;
    [self.view addSubview:_transparentView];
    
    [_transparentView addGestureRecognizer:_tap];
    
    if (_tapCanBack) {
        _tap.enabled = YES;
    }else {
        _tap.enabled = NO;
    }
}

#pragma mark 显示右侧视图
- (void)showRightViewCtrl {
    
//    HCLog(@"showRightViewCtrl");
    _mainCtrl.view.alpha = 1.0f;
    _rightCtrl.view.alpha = 1.0f;
    _leftCtrl.view.alpha = 0;
    _rightCtrl.view.transform = CGAffineTransformIdentity;
    _rightCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 - _mainViewTransformScale, 1.0f);
//    HCLog(@"%@",NSStringFromCGRect(_rightCtrl.view.frame));
    //偏移使得右侧视图右边缘紧靠屏幕右边缘
    CGFloat rightViewMaxX = CGRectGetMaxX(_rightCtrl.view.frame);
    _rightCtrl.view.frame = CGRectOffset(_rightCtrl.view.frame,kScreenW - rightViewMaxX, 0);
    
    //缩小主视图
    _mainCtrl.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 - _mainViewTransformScale, 1 - _mainViewTransformScale);
    //偏移使得主视图右边缘紧靠右侧视图的左边缘
    CGFloat rightViewMinX = CGRectGetMinX(_rightCtrl.view.frame);
    CGFloat mainViewMaxX = CGRectGetMaxX(_mainCtrl.view.frame);
    _mainCtrl.view.frame = CGRectOffset(_mainCtrl.view.frame, rightViewMinX - mainViewMaxX, 0);
    
    //单击手势
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    if (_transparentView.superview) {
        [_transparentView removeFromSuperview];
    }
    _transparentView = [[UIView alloc] initWithFrame:_mainCtrl.view.frame];
    _transparentView.backgroundColor = [UIColor blackColor];
    _transparentView.alpha = 0.1;
    [self.view addSubview:_transparentView];
    
    [_transparentView addGestureRecognizer:_tap];
    
    if (_tapCanBack) {
        _tap.enabled = YES;
    }else {
        _tap.enabled = NO;
    }
}

//#warning 隐藏状态栏，主视图为TabbarController时建议隐藏，可以删除此处代码
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark LeftViewControllerDelegate
- (void)presentPickerViewControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
        pickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerVC.delegate = self;
        [self presentViewController:pickerVC animated:YES completion:nil];
    } else if (sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum){
        UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
        pickerVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        pickerVC.delegate = self;
        [self presentViewController:pickerVC animated:YES completion:nil];
    }
}

#pragma mark //改变主视图背景颜色
- (void)alternageDayAndNightWithHCIsDay:(BOOL)isDay {
    if (isDay) {
        _mainCtrl.firstTableView.backgroundColor = [UIColor whiteColor];
        [_mainCtrl.firstTableView reloadData];
    } else {
        _mainCtrl.firstTableView.backgroundColor = [UIColor blackColor];
        [_mainCtrl.firstTableView reloadData];
    }
}

#pragma mark UIImagePickerViewControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation(image);
    [HCTool setObject:imageData forKey:HCUserIcon];
    [_leftCtrl.iconBtn setBackgroundImage:image forState:UIControlStateNormal];
    [self showLeftViewCtrl];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self showLeftViewCtrl];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark DetailViewDelegate
- (void)playVideo:(NSString *)weburl {
    //播放视频时，允许横屏
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    delegate.canRotate = YES;
    MPMoviePlayerViewController *MPV = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:weburl]];
    [self presentViewController:MPV animated:YES completion:nil];
}

#pragma mark 视频播放结束，不允许横屏
- (void)playFinished {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    delegate.canRotate = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

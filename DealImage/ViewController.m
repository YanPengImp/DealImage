//
//  ViewController.m
//  DealImage
//
//  Created by Imp on 17/2/7.
//  Copyright © 2017年 codoon. All rights reserved.
//

#import "ViewController.h"

#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)


@interface ViewController ()

@property (strong, nonatomic) UIImageView *imageV1;
@property (strong, nonatomic) UIImageView *imageV2;
@property (strong, nonatomic) UILabel *label1;
@property (strong, nonatomic) UILabel *label2;
@property (strong, nonatomic) UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self.view addSubview:self.label1];
    [self.view addSubview:self.imageV1];
    [self.view addSubview:self.label2];
    [self.view addSubview:self.imageV2];
    [self.view addSubview:self.button];

    UIImage *image = [UIImage imageNamed:@"IMG_0043"];
    self.imageV1.image = image;
    // Do any additional setup after loading the view, typically from a nib.
}

- (UIImageView *)imageV1 {
    if (_imageV1 == nil) {
        _imageV1 = [[UIImageView alloc] init];
        _imageV1.contentMode = UIViewContentModeScaleAspectFit;
        _imageV1.layer.borderColor = [UIColor blackColor].CGColor;
        _imageV1.layer.borderWidth = 1.0;
        _imageV1.frame = CGRectMake(40, 55, 200, 200);
    }
    return _imageV1;
}

- (UIImageView *)imageV2 {
    if (_imageV2 == nil) {
        _imageV2 = [[UIImageView alloc] init];
        _imageV2.contentMode = UIViewContentModeScaleAspectFit;
        _imageV2.layer.borderColor = [UIColor blackColor].CGColor;
        _imageV2.layer.borderWidth = 1.0;
        _imageV2.frame = CGRectMake(40, 310, 200, 200);
    }
    return _imageV2;
}

- (UILabel *)label1 {
    if (_label1 == nil) {
        _label1 = [[UILabel alloc] init];
        _label1.text = @"原图";
        _label1.frame = CGRectMake(40, 30, 40, 20);
    }
    return _label1;
}

- (UILabel *)label2 {
    if (_label2 == nil) {
        _label2 = [[UILabel alloc] init];
        _label2.text = @"结果图";
        _label2.frame = CGRectMake(40, 280, 70, 20);
    }
    return _label2;
}

- (UIButton *)button {
    if (_button == nil) {
        _button = [[UIButton alloc] init];
        [_button setTitle:@"计算" forState:UIControlStateNormal];
        _button.backgroundColor = [UIColor blueColor];
        [_button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _button.frame = CGRectMake(40, 530, 70, 30);
    }
    return _button;
}

- (void)buttonAction:(UIButton *)b {
    UIImage *image = [UIImage imageNamed:@"IMG_0043"];
    UIImage *img = [self dealImage:image];
    self.imageV2.image = img;
}

- (UIImage *)dealImage:(UIImage *)img{
    // 1.CGDataProviderRef 把 CGImage 转 二进制流
    CGDataProviderRef provider = CGImageGetDataProvider(img.CGImage);
    void *imgData = (void *)CFDataGetBytePtr(CGDataProviderCopyData(provider));
    int width = img.size.width * img.scale;
    int height = img.size.height * img.scale;

    // 2.处理 imgData
//    dealImage(imgData, width, height);//反色
    dealImageMosaic(imgData,width,height,20);//马赛克

    // 3.CGDataProviderRef 把 二进制流 转 CGImage
    CGDataProviderRef pv = CGDataProviderCreateWithData(NULL, imgData, width * height * 4, releaseData);
    CGImageRef content = CGImageCreate(width , height, 8, 32, 4 * width, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, pv, NULL, true, kCGRenderingIntentDefault);
    UIImage *result = [UIImage imageWithCGImage:content];
    CGDataProviderRelease(pv);
    CGImageRelease(content);

    return result;
}

void releaseData(void *info, const void *data, size_t size) {
    free((void *)data);
}

//马赛克处理 level->像素格子数
void dealImageMosaic(UInt32 *image,int width, int height, int level) {
    unsigned char *pixel[4] = {0};
    UInt8 *img = (UInt8 *)image;
    NSUInteger index,preIndex;
    for (NSUInteger i = 0; i < height - 1 ; i++) {
        for (NSUInteger j = 0; j < width - 1; j++) {
            index = i * width + j;
            if (i % level == 0) {
                if (j % level == 0) {
                    UInt8 *p = img + kPixelChannelCount*index;
                    memcpy(pixel, p, kPixelChannelCount);
                }else{
                    UInt8 *p = img + kPixelChannelCount*index;
                    memcpy(p, pixel, kPixelChannelCount);
                }
            } else {
                preIndex = (i-1)*width +j;
                memcpy(img + kPixelChannelCount*index, img + kPixelChannelCount*preIndex, kPixelChannelCount);
            }
        }
    }
}

void dealImage(UInt32 *img, int w, int h) {
    int num = w * h;
    UInt32 *cur = img;
    for (int i=0; i<num; i++, cur++) {
        UInt8 *p = (UInt8 *)cur;
        // RGBA 排列取反色
        p[0] = 255 - p[0];
        p[1] = 255 - p[1];
        p[2] = 255 - p[2];
        p[3] = 255;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

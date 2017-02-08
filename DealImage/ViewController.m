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

struct RGB{
    int r;
    int g;
    int b;
    int a;
    CGPoint point;
};

typedef struct RGB RGB;


@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageV1;
@property (nonatomic, strong) UIImageView *imageV2;
@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UILabel *label2;
@property (nonatomic, strong) UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
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
        _imageV1.frame = CGRectMake(40, 55, 250, 250);
    }
    return _imageV1;
}

- (UIImageView *)imageV2 {
    if (_imageV2 == nil) {
        _imageV2 = [[UIImageView alloc] init];
        _imageV2.contentMode = UIViewContentModeScaleAspectFit;
        _imageV2.layer.borderColor = [UIColor blackColor].CGColor;
        _imageV2.layer.borderWidth = 1.0;
        _imageV2.frame = CGRectMake(40, 360, 250, 250);
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
        _label2.frame = CGRectMake(40, 330, 70, 20);
    }
    return _label2;
}

- (UIButton *)button {
    if (_button == nil) {
        _button = [[UIButton alloc] init];
        [_button setTitle:@"变换" forState:UIControlStateNormal];
        _button.backgroundColor = [UIColor blueColor];
        [_button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _button.frame = CGRectMake(40, 630, 70, 30);
    }
    return _button;
}

- (void)buttonAction:(UIButton *)button {
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
//    dealImageInverse(imgData, width, height);//反色
//    dealImageMosaic(imgData,width,height,20);//马赛克

    const float matrix[] = {0.33f   ,0.33f  ,0.33f  ,0      ,0,
                            0.33f   ,0.33f  ,0.33f  ,0      ,0,
                            0.33f   ,0.33f  ,0.33f  ,0      ,0,
                            0       ,0      ,0      ,1      ,0}; //颜色矩阵滤镜

    const float matrix1[] = {-1  ,0   ,0    ,0   ,255,
                             0   ,-1  ,0    ,0   ,255,
                             0   ,0   ,-1   ,0   ,255,
                             0   ,0   ,0    ,1   ,0}; //颜色矩阵滤镜 该矩阵滤镜同样是取反色

    dealImageFilter(imgData, width, height, matrix);

    // 3.CGDataProviderRef 把 二进制流 转 CGImage
    CGDataProviderRef pv = CGDataProviderCreateWithData(NULL, imgData, width * height * kPixelChannelCount, releaseData);
    CGImageRef content = CGImageCreate(width , height, kBitsPerComponent, kBitsPerPixel, kPixelChannelCount * width, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, pv, NULL, true, kCGRenderingIntentDefault);
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

//取反色
void dealImageInverse(UInt32 *img, int w, int h) {
    UInt32 *cur = img;
    for (int i=0; i< w * h; i++, cur++) {
        UInt8 *p = (UInt8 *)cur;
        // RGBA 排列取反色
        p[0] = 255 - p[0];
        p[1] = 255 - p[1];
        p[2] = 255 - p[2];
        p[3] = 255;
    }
}

//颜色矩阵滤镜
void dealImageFilter(UInt32 *img,int w,int h,const float *matrix) {
    UInt8 *cur = (UInt8 *)img;
    for (int i=0; i< w * h; i++, cur+=kPixelChannelCount) {
        int red = cur[0];
        int green = cur[1];
        int blue = cur[2];
        int alpha = cur[3];
        changeRGBA(&red, &green, &blue, &alpha, matrix);
        cur[0] = red;
        cur[1] = green;
        cur[2] = blue;
        cur[3] = alpha;
    }
}

static void changeRGBA(int *red,int *green,int *blue, int *alpha,const float *matrix) {
    float r = *red;
    float g = *green;
    float b = *blue;
    float a = *alpha;
    *red   = matrix[0] *r + matrix[1] *g + matrix[2] *b + matrix[3] *a + matrix[4];
    *green = matrix[5] *r + matrix[6] *g + matrix[7] *b + matrix[8] *a + matrix[9];
    *blue  = matrix[10]*r + matrix[11]*g + matrix[12]*b + matrix[13]*a + matrix[14];
    *alpha = matrix[15]*r + matrix[16]*g + matrix[17]*b + matrix[18]*a + matrix[19];
    *red > 255 ? *red = 255 :NO;
    *green > 255 ? *green = 255 :NO;
    *blue > 255 ? *blue = 255 :NO;
    *alpha > 255 ? *alpha = 255 :NO;
    *red < 0 ? *red = 0 : NO;
    *green < 0 ? *green = 0 : NO;
    *blue < 0 ? *blue = 0 : NO;
    *alpha < 0 ? *alpha = 0 : NO;
}

//获取随机某点的rgba值
RGB rgbRound(UInt32 *image,int w,int h) {
    CGPoint point = CGPointMake(arc4random() % w, arc4random() % h);
    UInt32 *img = image + (int)point.y*w + (int)point.x;
    UInt8 *p = (UInt8 *)img;
    RGB rgb;
    rgb.r = p[0];
    rgb.g = p[1];
    rgb.b = p[2];
    rgb.a = p[3];
    rgb.point = point;
    return rgb;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

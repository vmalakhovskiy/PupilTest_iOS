//
//  OpenCVImageHelper.h
//  PupilTests
//
//  Created by Vitaliy Malakhovskiy on 9/26/15.
//  Copyright © 2015 Vitalii Malakhovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

@interface OpenCVImageHelper : NSObject

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;

@end

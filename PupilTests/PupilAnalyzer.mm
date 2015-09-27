//
//  PupilAnalyzer.m
//  PupilTests
//
//  Created by Vitaliy Malakhovskiy on 9/26/15.
//  Copyright © 2015 Vitalii Malakhovskyi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import "CIImage+Platform.h"
#import "PupilAnalyzer.h"
#import "BufferReader.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>
#import "OpenCVImageHelper.h"

@interface PupilAnalyzer () <BufferReaderDelegate>
@property (nonatomic, strong) BufferReader *reader;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) CIContext *context;
@end

@implementation PupilAnalyzer

- (instancetype)initWithVideoURL:(NSURL *)url {
    if (self = [super init]) {
        self.reader = [[BufferReader alloc] initWithDelegate:self];
        self.url = url;
        self.context = [CIContext contextWithOptions:nil];
    }
    return self;
}

- (void)startReading {
    AVAsset *asset = [AVAsset assetWithURL:self.url];
    NSError *error = nil;
    [self.reader startReadingAsset:asset error:error];
}

#pragma mark - BufferReaderDelegate

- (void)bufferReader:(BufferReader *)reader didFinishReadingAsset:(AVAsset *)asset {
    
}

- (void)bufferReader:(BufferReader *)reader didGetNextVideoSample:(CMSampleBufferRef)bufferRef {
    CIImage *ciimage = [CIImage imageWithCMBufferRef:bufferRef];
    ciimage = [ciimage imageByApplyingOrientation:UIImageOrientationDownMirrored];
    
    UIImage *image = [self makeUIImageFromCIImage:ciimage];
    
    cv::Mat src = [OpenCVImageHelper cvMatFromUIImage:image];
    
    // gray image
    cv::Mat gray;
    cv::cvtColor(~src, gray, CV_BGR2GRAY);
    
    // Convert to binary image by thresholding it
    cv::threshold(gray, gray, 180, 255, cv::THRESH_BINARY);
    
    // Find all contours
    
    cv::Mat grayCopy = gray.clone();
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(grayCopy, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    grayCopy.release();
    
    // Fill holes in each contour
    cv::drawContours(gray, contours, -1, CV_RGB(255,255,255), -1);
    gray.release();
    src.release();
    
    for (int i = 0; i < contours.size(); i++)
    {
        double area = cv::contourArea(contours[i]);
        cv::Rect rect = cv::boundingRect(contours[i]);
        int radius = rect.width/2;
        
        
        // If contour is big enough and has round shape
        // Then it is the pupil
        if (area >= 200 &&
            std::abs(1 - ((double)rect.width / (double)rect.height)) <= 0.2 &&
            std::abs(1 - (area / (CV_PI * std::pow(radius, 2)))) <= 0.2)
        {
//            cv::circle(src, cv::Point(rect.x + radius, rect.y + radius), radius, CV_RGB(255,0,0), 2);
            
            NSLog(@"radius - %d, seconds - %f", radius, CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(bufferRef)));
        }
    }
    
    contours.clear();
}

- (UIImage *)makeUIImageFromCIImage:(CIImage *)ciImage {
    UIImage* uiImage;
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    
    uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return uiImage;
}

- (void)bufferReader:(BufferReader *)reader didGetErrorRedingSample:(NSError *)error {
    
}

@end
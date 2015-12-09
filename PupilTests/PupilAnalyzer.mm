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

@implementation PupilAnalyzer {
    cv::VideoCapture input_cap;
    cv::VideoWriter output_cap;
    CvVideoWriter *vw;
}

- (instancetype)initWithVideoURL:(NSURL *)url {
    if (self = [super init]) {
        self.reader = [[BufferReader alloc] initWithDelegate:self];
        self.url = url;
        self.context = [CIContext contextWithOptions:nil];
        
        input_cap = cv::VideoCapture([[self.url path] UTF8String]);
        if (!input_cap.isOpened())
        {
            std::cout << "!!! Input video could not be opened" << std::endl;
        }
        
        // Setup output video
//        [[NSFileManager defaultManager] removeItemAtPath:[self outputVideoPath] error:nil];
//        int fourcc = CV_FOURCC('m', 'p', '4', 'v');
//        cv::Size size(1920, 1080);
//        output_cap = cv::VideoWriter([[self outputVideoPath] UTF8String],
//                                   fourcc,
////                                     CV_FOURCC('H','2','6','4'),
////                                     CV_FOURCC('M','J','P','G'),
////                                     CV_FOURCC_DEFAULT,
////                                     24,
////                                     29.8984702,
////                                   input_cap.get(CV_CAP_PROP_FPS),
//                                     30,
//                                   size);
        
//        if (!output_cap.isOpened())
//        {
//            std::cout << "!!! Output video could not be opened" << std::endl;
//        }
        
//        vw = cvCreateVideoWriter([[self outputVideoPath] UTF8String],
//                            fourcc,
//                            //                                     CV_FOURCC('H','2','6','4'),
//                            //                                     CV_FOURCC('M','J','P','G'),
//                            //                                     CV_FOURCC_DEFAULT,
//                            //                                     24,
//                            //                                     29.8984702,
//                            //                                   input_cap.get(CV_CAP_PROP_FPS),
//                            30,
//                            size);
    }
    return self;
}

- (void)startReading {
    AVAsset *asset = [AVAsset assetWithURL:self.url];
    NSError *error = nil;
    [self.reader startReadingAsset:asset error:error];

    return;
    
    cv::Mat src;
    while (!src.empty()) {
        input_cap >> src;
        [self detectPupil:src];
    }
}

#pragma mark - BufferReaderDelegate

- (void)bufferReader:(BufferReader *)reader didFinishReadingAsset:(AVAsset *)asset {
    input_cap.release();
    output_cap.release();
}

int j = 0;

- (void)bufferReader:(BufferReader *)reader didGetNextVideoSample:(CMSampleBufferRef)bufferRef {
    cv::Mat src;
    CIImage *ciimage = [CIImage imageWithCMBufferRef:bufferRef];
    ciimage = [ciimage imageByApplyingOrientation:UIImageOrientationDownMirrored];
    
    UIImage *image = [self makeUIImageFromCIImage:ciimage];
    
//    NSLog(@"%i", ++j);
    
    [self detectPupil:[OpenCVImageHelper cvMatFromUIImage:image]];
    
    return;
//    cv::cvtColor(~src, test, 40);
//    image = [OpenCVImageHelper UIImageFromCVMat:test];
    
//     gray image
    cv::Mat gray = src.clone();
    cv::cvtColor(~src, gray, CV_BGR2GRAY);

//     Convert to binary image by thresholding it
    cv::threshold(gray, gray, 80, 120, cv::THRESH_BINARY);
    image = [OpenCVImageHelper UIImageFromCVMat:gray];
    image = [OpenCVImageHelper UIImageFromCVMat:gray];
    
//     Find all contours
    cv::Mat grayCopy = gray.clone();
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(grayCopy, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
//    image = [OpenCVImageHelper UIImageFromCVMat:grayCopy];
    image = [OpenCVImageHelper UIImageFromCVMat:grayCopy];
//    grayCopy.release();
    
//     Fill holes in each contour
    cv::drawContours(gray, contours, -1, CV_RGB(255,255,255), -1);
//    image = [OpenCVImageHelper UIImageFromCVMat:gray];
//    gray.release();
//    src.release();
    image = [OpenCVImageHelper UIImageFromCVMat:gray];
    
    for (int i = 0; i < contours.size(); i++)
    {
        double area = cv::contourArea(contours[i]);
        cv::Rect rect = cv::boundingRect(contours[i]);
        int radius = rect.width/2;
        
        
        // If contour is big enough and has round shape
        // Then it is the pupil
        if (area >= 200 &&
            std::abs(1 - ((double)rect.width / (double)rect.height)) <= 0.2 &&
            std::abs(1 - (area / (CV_PI * std::pow(radius, 2)))) <= 0.2) {
            
            cv::circle(src, cv::Point(rect.x + radius, rect.y + radius), radius, CV_RGB(255,0,0), 2);
            image = [OpenCVImageHelper UIImageFromCVMat:src];
            [UIImagePNGRepresentation(image) writeToFile:[[self docDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", ++j]] atomically:YES];
            
            output_cap.write(src);

        }
    }
    
    contours.clear();
}

- (void)detectPupil:(cv::Mat)src {
    if (src.empty()) {
        NSLog(@"end of file ");
        return;
    }
    
    UIImage *image = [OpenCVImageHelper UIImageFromCVMat:src];
    UIImage *image1 = [OpenCVImageHelper UIImageFromCVMat:src];
    
    
    cv::Mat gray;
    cv::cvtColor(~src, gray, CV_BGR2GRAY);
    
    cv::threshold(gray, gray, 200, 255, cv::THRESH_BINARY);
    
    image = [OpenCVImageHelper UIImageFromCVMat:gray];
    
    // Find all contours
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(gray.clone(), contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    
    // Fill holes in each contour
    cv::drawContours(gray, contours, -1, CV_RGB(255,255,255), -1);
    
    image = [OpenCVImageHelper UIImageFromCVMat:gray];
    
    for (int i = 0; i < contours.size(); i++)
    {
        double area = cv::contourArea(contours[i]);    // Blob area
        cv::Rect rect = cv::boundingRect(contours[i]); // Bounding box
        int radius = rect.width/2;                     // Approximate radius
        
        // Look for round shaped blob
        if (area >= 20 &&
            std::abs(1 - ((double)rect.width / (double)rect.height)) <= 0.2 &&
            std::abs(1 - (area / (CV_PI * std::pow(radius, 2)))) <= 0.2)
        {
            cv::circle(src, cv::Point(rect.x + radius, rect.y + radius), radius, CV_RGB(255,0,0), 2);
            image = [OpenCVImageHelper UIImageFromCVMat:src];
            
            NSLog(@"%d", radius);
            
            [UIImagePNGRepresentation(image) writeToFile:[[self docDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", ++j]] atomically:YES];
            NSLog(@"%@",[[self docDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", j-1]]);
            
        }
    }
}

- (NSString *)outputVideoPath {
    return [[self docDir] stringByAppendingPathComponent:@"/4.mov"];
}

- (NSString *)docDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
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
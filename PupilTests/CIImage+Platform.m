//
//  CIImage+Platform.m
//  FaceDetectionProcessor
//
//  Created by Vitaliy Malakhovskiy on 7/3/14.
//  Copyright (c) 2014 Vitaliy Malakhovskiy. All rights reserved.
//

#import "CIImage+Platform.h"

@implementation CIImage (Platform)

+ (CIImage *)imageWithCMBufferRef:(CMSampleBufferRef)bufferRef {
    CIImage *ciImage = nil;
#if TARGET_IPHONE_SIMULATOR
#warning FACE DETECTING CURRENTLY DOESNT WORKS ON SIMULATOR, ONLY ON DEVICE
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(bufferRef);
    CVPixelBufferLockBaseAddress(imageBuffer,0);

    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);

    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    ciImage = [CIImage imageWithCGImage:newImage];
#elif TARGET_OS_IPHONE
    ciImage = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(bufferRef)];
#endif
    return ciImage;
}

@end

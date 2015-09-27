//
//  CIImage+Platform.h
//  FaceDetectionProcessor
//
//  Created by Vitaliy Malakhovskiy on 7/3/14.
//  Copyright (c) 2014 Vitaliy Malakhovskiy. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

@interface CIImage (Platform)

+ (CIImage *)imageWithCMBufferRef:(CMSampleBufferRef)buffer;

@end

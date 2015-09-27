//
//  PupilAnalyzer.h
//  PupilTests
//
//  Created by Vitaliy Malakhovskiy on 9/26/15.
//  Copyright © 2015 Vitalii Malakhovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PupilAnalyzer : NSObject

- (instancetype)initWithVideoURL:(NSURL *)url;
- (void)startReading;

@end
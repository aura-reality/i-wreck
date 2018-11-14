//
//  OpenCVWrapper.h
//  ARKitImageRecognition
//
//  Created by Michael Watts on 10/30/18.
//  Copyright © 2018 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Match.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ImageWithFeatures : NSObject

- (instancetype) init:(UIImage *) image;

- (instancetype) initFromCVPixelBuffer:(CVPixelBufferRef) pixelBuffer;

- (Match *) findBestMatch:(NSArray *) trainingImages;

- (void) setName:(NSString *) name;

- (NSString *) getName;

@end

NS_ASSUME_NONNULL_END

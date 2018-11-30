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

+ (NSString *)openCVVersionString;

- (instancetype) initFromUIImage:(UIImage *) image;

- (instancetype) initFromYUVCVPixelBuffer:(CVPixelBufferRef) pixelBuffer;

- (Match *) findBestMatch:(NSArray *) trainingImages;

- (void) setName:(NSString *) name;

- (NSString *) getName;

+ (UIImage *) toCvMatToUIImage:(UIImage *) image;

+ (UIImage *) toCVMatToUIImage:(CVPixelBufferRef) pixelBuffer;

@end

NS_ASSUME_NONNULL_END

//
//  OpenCVWrapper.h
//  ARKitImageRecognition
//
//  Created by Michael Watts on 10/30/18.
//  Copyright © 2018 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ImageWithFeatures : NSObject

+ (NSString *)openCVVersionString;

- (instancetype) init:(UIImage *) image;

@end

NS_ASSUME_NONNULL_END

//
//  OpenCVWrapper.mm
//  ARKitImageRecognition
//
//  Created by Michael Watts on 10/30/18.
//  Copyright © 2018 Apple. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "ImageWithFeatures.h"
#import <opencv2/core.hpp>
#import <opencv2/features2d.hpp>
#import <UIKit/UIKit.h>

using namespace cv;

@implementation ImageWithFeatures {
    
    Mat descriptors;
    std::vector<KeyPoint> keypoints;
    
}

- (instancetype) init:(UIImage *) image {
    if ( self = [super init] ) {
        Mat gray = [self cvMatGrayFromUIImage:image];
        [self computeOrbFeatures:gray];
        return nil;
        
    } else {
        return nil;
    }
}

- (void) computeOrbFeatures:(Mat) image {
    int minHessian = 400;
    Ptr<ORB> detector = ORB::create(minHessian);
    detector->detectAndCompute(image, noArray(), keypoints, descriptors);
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (std::vector<DMatch>) match:(Mat) descriptors1 descriptors2:(Mat) descriptors2  {
    //Ptr<DescriptorMatcher> matcher = DescriptorMatcher::create(DescriptorMatcher::FLANNBASED);

    // Uses hamming distance for binary descriptors (i.e. orb)
    FlannBasedMatcher matcher(new flann::LshIndexParams(20, 10, 2));
    
    std::vector<std::vector<DMatch> > knn_matches;
    matcher.knnMatch(descriptors1, descriptors2, knn_matches, 2);
    
    //-- Filter matches using the Lowe's ratio test
    const float ratio_thresh = 0.7f;
    std::vector<DMatch> good_matches;
    for (size_t i = 0; i < knn_matches.size(); i++) {
        if (knn_matches[i][0].distance < ratio_thresh * knn_matches[i][1].distance) {
            good_matches.push_back(knn_matches[i][0]);
        }
    }
    
    return good_matches;
}

//+ (void) homography:(std::vector<DMatch>) matches {
//    //-- Localize the object
//    std::vector<Point2f> obj;
//    std::vector<Point2f> scene;
//    
//    for( int i = 0; i < matches.size(); i++ )
//    {
//        //-- Get the keypoints from the good matches
//        obj.push_back( keypoints_object[matches[i].queryIdx ].pt );
//        scene.push_back( keypoints_scene[matches[i].trainIdx ].pt );
//    }
//    
//    Mat H = findHomography( obj, scene, CV_RANSAC );
//}

@end

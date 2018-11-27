//
//  OpenCVWrapper.mm
//  ARKitImageRecognition
//
//  Created by Michael Watts on 10/30/18.
//  Copyright © 2018 Apple. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "ImageWithFeatures.h"
#import "Match.h"
#import <opencv2/core.hpp>
#import <opencv2/core/types_c.h>
#import <opencv2/features2d.hpp>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

using namespace cv;

@implementation ImageWithFeatures {
    Mat descriptors;
    std::vector<KeyPoint> keypoints;
    NSString * name;
    long cols;
    long rows;
}

+ (NSString *)openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

+ (UIImage *) toCvMatToUIImage:(UIImage *) image {
    Mat mat = [self cvMatGrayFromUIImage:image];
    return [ImageWithFeatures UIImageFromCVMat_opencvdocs:mat];
    
}

+ (UIImage *) toCVMatToUIImage:(CVPixelBufferRef) pixelBuffer {
    Mat mat = [self cvMatGrayFromYUVCVPixelBuffer:pixelBuffer];
    return [ImageWithFeatures UIImageFromCVMat_opencvdocs:mat];
}

+ (UIImage *) UIImageFromCVMat_opencvdocs:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (instancetype) initFromUIImage:(UIImage *) image {
    if (self = [super init]) {
        Mat gray = [ImageWithFeatures cvMatGrayFromUIImage:image];
        self->cols = gray.cols;
        self->rows = gray.rows;
        [self computeOrbFeatures:gray];
        return self;
        
    } else {
        return nil;
    }
}

- (instancetype) initFromYUVCVPixelBuffer:(CVPixelBufferRef) pixelBuffer {
    if ( self = [super init] ) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        Mat gray = [ImageWithFeatures cvMatGrayFromYUVCVPixelBuffer:pixelBuffer];
        self->cols = gray.cols;
        self->rows = gray.rows;
        [self computeOrbFeatures:gray];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return self;
        
    } else {
        return nil;
    }
}

- (void) setName:(NSString *) name {
    self->name = name;
}

- (NSString *) getName {
    return name;
}

- (void) computeOrbFeatures:(Mat) image {
    int minHessian = 400;
    Ptr<ORB> detector = ORB::create(minHessian);
    detector->detectAndCompute(image, noArray(), keypoints, descriptors);
    if (*descriptors.size.p == 0) {
        printf("Warning: image has 0 descriptors\n");
    }
}

+ (cv::Mat)cvMatGrayFromYUVCVPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    int bufferWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    int bufferHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    int bytePerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    unsigned char *pixel = (unsigned char *) CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    return cv::Mat(bufferHeight, bufferWidth, CV_8UC1, pixel, bytePerRow);
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
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
                                                    kCGImageAlphaNone |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (std::vector<DMatch>) match:(Mat) descriptors1 {
    std::vector<DMatch> good_matches;
    
    if (*descriptors.size.p == 0) {
        return good_matches;
    }
    
    //Ptr<DescriptorMatcher> matcher = DescriptorMatcher::create(DescriptorMatcher::FLANNBASED);
    
    // Uses hamming distance for binary descriptors (i.e. orb) -- LSH imples Hamming
    flann::LshIndexParams * indexParams = new flann::LshIndexParams(20, 10, 2);
    FlannBasedMatcher matcher(indexParams);
    
    std::vector<std::vector<DMatch> > knn_matches;
    matcher.knnMatch(descriptors1, self->descriptors, knn_matches, 2);
    
    //-- Filter matches using the Lowe's ratio test
    const float ratio_thresh = 0.7f;

    for (size_t i = 0; i < knn_matches.size(); i++) {
        if (knn_matches[i][0].distance < ratio_thresh * knn_matches[i][1].distance) {
            good_matches.push_back(knn_matches[i][0]);
        }
    }
    
    return good_matches;
}

- (Match *) findBestMatch:(NSArray *) trainingImages {
    
    // Find the best match
    ImageWithFeatures * bestImage;
    std::vector<DMatch> bestMatches;
    long maxMatches = -1;
    for (int i = 0; i < trainingImages.count; i++) {
        ImageWithFeatures *ti = (ImageWithFeatures *) trainingImages[i];
        std::vector<DMatch> goodMatches = [self match:ti->descriptors];
        long s = goodMatches.size();
        if (s > maxMatches) {
            maxMatches = s;
            bestMatches = goodMatches;
            bestImage = ti;
        }
        
        // printf("%ld feature matches\t%s\n", s, [ti->name  UTF8String]);
    }
    
    if (maxMatches > 10) {
        NSArray * corners = [self homography:bestMatches image:bestImage];
        if (corners == nil) {
            return nil;
        }
        Match * match = [[Match alloc] init];
        printf("Found homography for %s\n", [bestImage->name UTF8String]);
        match.corners = corners;
        match.numGoodMatches = maxMatches;
        match.matchedImageName = bestImage->name;
        return match;
    } else {
        return nil;
    }
}

- (NSArray *) homography:(std::vector<DMatch>) matches image:(ImageWithFeatures *)matchImage {
    
    // Localize the object
    std::vector<Point2f> obj;
    std::vector<Point2f> scene;
    
    for (int i = 0; i < matches.size(); i++) {
        
        // Get the keypoints from the good matches
        obj.push_back( matchImage->keypoints[matches[i].queryIdx ].pt );
        scene.push_back( self->keypoints[matches[i].trainIdx ].pt );
    }
    
    Mat H = findHomography( obj, scene, FM_RANSAC );
    
    if (H.empty()) {
        printf("Attempted but did not find homography\n");
        return nil;
        
    } else {
        
        // Get the corners from the object to be "detected"
        std::vector<Point2f> obj_corners(4);
        obj_corners[0] = cvPoint(0,0); obj_corners[1] = cvPoint(self->cols, 0);
        obj_corners[2] = cvPoint(self->cols, self->rows); obj_corners[3] = cvPoint(0, self->rows);
        std::vector<Point2f> scene_corners(4);
        
        perspectiveTransform(obj_corners, scene_corners, H);
        return @[
                  @[
                      [NSNumber numberWithFloat:scene_corners[0].x],
                      [NSNumber numberWithFloat:scene_corners[0].y]
                  ],
                  @[
                      [NSNumber numberWithFloat:scene_corners[1].x],
                      [NSNumber numberWithFloat:scene_corners[1].y]
                  ],
                  @[
                      [NSNumber numberWithFloat:scene_corners[2].x],
                      [NSNumber numberWithFloat:scene_corners[2].y]
                  ],
                  @[
                      [NSNumber numberWithFloat:scene_corners[3].x],
                      [NSNumber numberWithFloat:scene_corners[3].y]
                  ]
              ];
    }
}

@end

//
//  Match.h
//  ARKitImageRecognition
//
//  Created by Michael Watts on 11/13/18.
//  Copyright © 2018 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Match : NSObject

- (instancetype) init:(NSString *) matchedImageName corners:(NSArray *)corners;

- (NSString *) getMatchedImageName;

- (NSArray *) getCorners;

@end

NS_ASSUME_NONNULL_END

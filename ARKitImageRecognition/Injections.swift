//
//  Injection.swift
//  ARKitImageRecognition
//
//  Created by Michael Watts on 11/30/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import ARKit

class Injections {
    
    static func findMatch(_ frame: ARFrame, ifmatch onmatch: (Match) -> Void) {
        FPSCounter.INSTANCE.frame()
        
        if !RateLimiter.INSTANCE.mustWait() {
            let buffer: CVPixelBuffer = frame.capturedImage
            let imageWithFeatures = ImageWithFeatures.init(fromYUVCVPixelBuffer: buffer)
            if let match = TrainingImages.findBestMatch(image: imageWithFeatures) {
                print("Detected image: \(match.matchedImageName)")
                onmatch(match)
            }
        }
    }
    
    static func initializeOpenCVTracking(_ referenceImages: Set<ARReferenceImage>) {
        let t0 = NSDate.init().timeIntervalSince1970
        
        TrainingImages.reset()
        for r in referenceImages {
            TrainingImages.add(name: r.name!, image: UIImage.init(imageLiteralResourceName: r.name!))
        }
        
        let t1 = NSDate.init().timeIntervalSince1970
        print("Added \(referenceImages.count) training images in \(t1 - t0) seconds")
    }
}

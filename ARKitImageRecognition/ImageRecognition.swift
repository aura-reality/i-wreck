//
//  ImageRecognition.swift
//  ARKitImageRecognition
//
//  Created by Michael Watts on 11/6/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import UIKit

class TrainingImages {
    
    static var IMAGES = [ImageWithFeatures]()
    
    static func add(name: String, image: UIImage) {
        print("Adding image \(name) with size \(image.size)")
        let g = ImageWithFeatures.init(from: image)
        g.setName(name)
        IMAGES.append(g)
    }
    
    static func findBestMatch(image: ImageWithFeatures) -> Match? {
        return image.findBestMatch(IMAGES)
    }
}

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
    
    static var IMAGES: [String : ImageWithFeatures] = [:]
    
    static func add(name: String, image: UIImage) {
        IMAGES[name] = ImageWithFeatures(image)
    }
}

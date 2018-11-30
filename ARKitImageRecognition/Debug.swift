//
//  Logging.swift
//  ARKitImageRecognition
//
//  Created by Michael Watts on 11/30/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation

class ImageSaver {
    
    static var t0 = NSDate.init().timeIntervalSince1970
    
    static var haveSaved = true // set to false to save an image
    
    static func save(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil)
    }
    
    static func maybeSave(_ image: UIImage) {
        let now = NSDate.init().timeIntervalSince1970
        if now - t0 > 3 {
            t0 = now
            save(image)
            haveSaved = true
            print("Saved image")
        }
    }
}

class FPSCounter {
    
    static let INSTANCE = FPSCounter.init()
    
    var t0: Double? = nil
    
    var lastPrint: Double = 0
    
    var frameCount = 0.0
    
    func frame() {
        let now = NSDate.init().timeIntervalSince1970
        frameCount = frameCount + 1
        
        if t0 == nil {
            t0 = now
            
        } else if (now - lastPrint > 10) {
            print("\(Int((frameCount-1.0)/(now-t0!))) frames per second")
            lastPrint = now
        }
    }
}

class RateLimiter {
    
    static let INSTANCE = RateLimiter.init(waitTime: 0.33)
    
    let waitTime: Double // in seconds
    
    var prev: Double = 0
    
    init(waitTime: Double) {
        self.waitTime = waitTime
    }
    
    func mustWait() -> Bool {
        let now = NSDate.init().timeIntervalSince1970
        if (now - prev > waitTime) {
            prev = now
            return false
        } else {
            return true
        }
    }
}


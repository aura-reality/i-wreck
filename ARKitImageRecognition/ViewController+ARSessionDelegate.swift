/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Session status management for `ViewController`.
*/

import ARKit

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
            
        } else if (now - lastPrint > 1) {
            print("\((frameCount-1.0)/(now-t0!)) frames per second")
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

extension ViewController: ARSessionDelegate {
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession,
                 didUpdate frame: ARFrame) {
        
        FPSCounter.INSTANCE.frame()
        
        if !RateLimiter.INSTANCE.mustWait() {
            let buffer: CVPixelBuffer = frame.capturedImage
            let imageWithFeatures = ImageWithFeatures.init(fromYUVCVPixelBuffer: buffer)
            if let match = TrainingImages.findBestMatch(image: imageWithFeatures) {
                showImageName(match.matchedImageName)
            }
        }
        
//        let uiimage = UIImage(pixelBuffer: buffer, context: CIContext())!
//        let imageWithFeatures = ImageWithFeatures(uiimage)
//        ImageSaver.maybeSave(uiimage)
        // CVPixelBuffer.
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Use `flatMap(_:)` to remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        blurView.isHidden = false
        statusViewController.showMessage("""
        SESSION INTERRUPTED
        The session will be reset after the interruption has ended.
        """, autoHide: false)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        blurView.isHidden = true
        statusViewController.showMessage("RESETTING SESSION")
        
        restartExperience()
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Interface Actions
    
    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        
        statusViewController.cancelAllScheduledMessages()
        
        resetTracking()
        
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
    
}

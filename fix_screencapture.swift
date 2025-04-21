import Foundation
import AppKit
import AVFoundation

class ScreenCapture: NSObject, AVCaptureFileOutputRecordingDelegate {
    private var outputURL: URL?
    private var captureSession: AVCaptureSession?
    private var captureOutput: AVCaptureMovieFileOutput?
    
    // Function to capture a screenshot
    func captureScreenshot() -> NSImage? {
        // CGMainDisplayID doesn't return an optional, so don't use guard let
        let displayID = CGMainDisplayID()
        
        guard let image = CGDisplayCreateImage(displayID) else {
            print("Failed to create image from display")
            return nil
        }
        
        // Use image.width and image.height instead of CGImageGetWidth/Height
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        return nsImage
    }
    
    // Save a captured screenshot to a file
    func saveScreenshot(_ image: NSImage, to url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation else {
            print("Failed to get TIFF representation")
            return false
        }
        
        guard let bitmap = NSBitmapImageRep(data: tiffData) else {
            print("Failed to create bitmap representation")
            return false
        }
        
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to create PNG data")
            return false
        }
        
        do {
            try pngData.write(to: url)
            return true
        } catch {
            print("Failed to write PNG data: \(error)")
            return false
        }
    }
    
    // Setup for video recording
    func setupVideoRecording() -> Bool {
        // Create a capture session
        captureSession = AVCaptureSession()
        
        // TODO: Implement full screen capture setup with AVCaptureScreenInput
        // This requires proper permissions and setup
        
        // For now, we'll just return false as it's not implemented
        return false
    }
    
    // Start recording video
    func startRecording(to outputURL: URL) -> Bool {
        self.outputURL = outputURL
        
        guard let captureSession = captureSession, captureSession.isRunning else {
            return false
        }
        
        // Create movie file output if not already created
        if captureOutput == nil {
            captureOutput = AVCaptureMovieFileOutput()
            
            if let captureOutput = captureOutput {
                if captureSession.canAddOutput(captureOutput) {
                    captureSession.addOutput(captureOutput)
                } else {
                    return false
                }
            }
        }
        
        // Start recording to file
        if let captureOutput = captureOutput, !captureOutput.isRecording {
            // Use self as the delegate since we've conformed to AVCaptureFileOutputRecordingDelegate
            captureOutput.startRecording(to: outputURL, recordingDelegate: self)
            return true
        }
        
        return false
    }
    
    // Stop recording video
    func stopRecording() {
        captureOutput?.stopRecording()
    }
    
    // Release resources
    func cleanup() {
        captureOutput = nil
        captureSession?.stopRunning()
        captureSession = nil
        outputURL = nil
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording to file: \(error)")
        } else {
            print("Successfully finished recording to \(outputFileURL.path)")
        }
    }
} 
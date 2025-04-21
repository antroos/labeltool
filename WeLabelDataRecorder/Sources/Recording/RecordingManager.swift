import Foundation
import AppKit

// A basic protocol for recording session delegate
protocol RecordingManagerDelegate: AnyObject {
    func recordingDidStart()
    func recordingDidStop()
    func recordingDidFail(with error: Error)
}

// Recording manager errors
enum RecordingError: Error {
    case permissionDenied
    case captureSetupFailed
    case alreadyRecording
    case notRecording
    case unknown(String)
}

class RecordingManager: EventMonitorDelegate {
    // Singleton instance for easy access
    static let shared = RecordingManager()
    
    // Delegate to receive recording events
    weak var delegate: RecordingManagerDelegate?
    
    // Components
    private let screenCapture = ScreenCapture()
    private let eventMonitor = EventMonitor()
    private let accessibilityHelper = AccessibilityHelper.shared
    
    // Recording state
    private(set) var isRecording = false
    
    // Timer for periodic screenshots
    private var screenshotTimer: Timer?
    private let screenshotInterval: TimeInterval = 1.0 // 1 second
    
    // Initialize
    private init() {
        eventMonitor.delegate = self
    }
    
    // Start a new recording session
    func startRecording() throws {
        guard !isRecording else {
            throw RecordingError.alreadyRecording
        }
        
        // Check permissions before starting
        if !checkPermissions() {
            throw RecordingError.permissionDenied
        }
        
        // Set up components
        eventMonitor.startMonitoring()
        
        // Start screenshot timer
        screenshotTimer = Timer.scheduledTimer(
            timeInterval: screenshotInterval,
            target: self,
            selector: #selector(capturePeriodicScreenshot),
            userInfo: nil,
            repeats: true
        )
        
        // Update state
        isRecording = true
        print("RecordingManager: Started recording")
        
        // Take initial screenshot
        capturePeriodicScreenshot()
        
        // Notify delegate
        delegate?.recordingDidStart()
    }
    
    // Stop the current recording session
    func stopRecording() throws {
        guard isRecording else {
            throw RecordingError.notRecording
        }
        
        // Stop components
        eventMonitor.stopMonitoring()
        
        // Stop screenshot timer
        screenshotTimer?.invalidate()
        screenshotTimer = nil
        
        // Update state
        isRecording = false
        print("RecordingManager: Stopped recording")
        
        // Notify delegate
        delegate?.recordingDidStop()
    }
    
    // Check if we have the necessary permissions
    func checkPermissions() -> Bool {
        // Check accessibility permissions
        let accessibilityEnabled = accessibilityHelper.isAccessibilityEnabled()
        
        // TODO: Check screen recording permissions
        // This requires additional setup with entitlements
        let screenRecordingEnabled = true // Placeholder
        
        return accessibilityEnabled && screenRecordingEnabled
    }
    
    // Request permissions needed for recording
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        // Request accessibility permissions
        accessibilityHelper.requestAccessibilityPermissions()
        
        // TODO: Request screen recording permissions
        
        // For now, just return true
        completion(true)
    }
    
    // MARK: - Screenshot Capture
    
    @objc private func capturePeriodicScreenshot() {
        guard isRecording else { return }
        
        if let screenshot = screenCapture.captureScreenshot() {
            // Create a unique filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "screenshot_\(timestamp).png"
            
            // Get documents directory
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let screenshotsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Screenshots", isDirectory: true)
                
                // Create directory if it doesn't exist
                try? FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
                
                let fileURL = screenshotsDirectory.appendingPathComponent(filename)
                
                // Save screenshot
                if screenCapture.saveScreenshot(screenshot, to: fileURL) {
                    print("Screenshot saved: \(filename)")
                    
                    // Create screenshot interaction
                    let screenshotInteraction = ScreenshotInteraction(
                        timestamp: Date(),
                        imageFileName: filename,
                        screenBounds: NSScreen.main?.frame ?? .zero
                    )
                    
                    // Add to current session
                    SessionManager.shared.currentSession?.addInteraction(screenshotInteraction)
                }
            }
        }
    }
    
    // MARK: - EventMonitorDelegate
    
    func eventMonitor(_ monitor: EventMonitor, didCaptureMouseClick event: NSEvent) {
        guard isRecording else { return }
        
        // Convert to our model
        let interaction = monitor.mouseClickInteractionFrom(event)
        
        // Add to current session
        SessionManager.shared.currentSession?.addInteraction(interaction)
        
        // Capture a screenshot when the user clicks
        capturePeriodicScreenshot()
        
        // Try to get UI element information at click position
        if let elementInfo = accessibilityHelper.getUIElementAtPosition(interaction.position) {
            print("Clicked element: \(elementInfo.role) - \(elementInfo.title ?? "unnamed")")
        }
    }
    
    func eventMonitor(_ monitor: EventMonitor, didCaptureMouseMove event: NSEvent) {
        guard isRecording else { return }
        
        // For mouse moves, we don't need to capture every single one
        // The EventMonitor already filters significant movements
        
        // Create a mouse move interaction
        let currentPosition = NSEvent.mouseLocation
        
        // We need the previous position, but for now we're using (0,0) as a placeholder
        // In a real implementation, we would track the previous position
        let interaction = MouseMoveInteraction(
            timestamp: Date(),
            fromPosition: NSPoint(x: 0, y: 0),
            toPosition: currentPosition
        )
        
        // Add to current session
        SessionManager.shared.currentSession?.addInteraction(interaction)
    }
    
    func eventMonitor(_ monitor: EventMonitor, didCaptureMouseScroll event: NSEvent) {
        guard isRecording else { return }
        
        // Convert to our model
        let interaction = monitor.mouseScrollInteractionFrom(event)
        
        // Add to current session
        SessionManager.shared.currentSession?.addInteraction(interaction)
    }
    
    func eventMonitor(_ monitor: EventMonitor, didCaptureKeyDown event: NSEvent) {
        guard isRecording else { return }
        
        // Convert to our model
        let interaction = monitor.keyInteractionFrom(event, isKeyDown: true)
        
        // Add to current session
        SessionManager.shared.currentSession?.addInteraction(interaction)
        
        // Capture a screenshot when the user presses certain keys
        if event.keyCode == 36 { // Return key
            capturePeriodicScreenshot()
        }
    }
    
    func eventMonitor(_ monitor: EventMonitor, didCaptureKeyUp event: NSEvent) {
        guard isRecording else { return }
        
        // Convert to our model
        let interaction = monitor.keyInteractionFrom(event, isKeyDown: false)
        
        // Add to current session
        SessionManager.shared.currentSession?.addInteraction(interaction)
    }
} 
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
        print("RecordingManager: startRecording called")
        guard !isRecording else {
            print("RecordingManager: ERROR - Already recording")
            throw RecordingError.alreadyRecording
        }
        
        // Check permissions before starting
        print("RecordingManager: Checking permissions")
        if !checkPermissions() {
            print("RecordingManager: ERROR - Permission denied")
            throw RecordingError.permissionDenied
        }
        
        // Set up components
        print("RecordingManager: Starting event monitoring")
        eventMonitor.startMonitoring()
        
        // Start screenshot timer
        print("RecordingManager: Setting up screenshot timer")
        screenshotTimer = Timer.scheduledTimer(
            timeInterval: screenshotInterval,
            target: self,
            selector: #selector(capturePeriodicScreenshot),
            userInfo: nil,
            repeats: true
        )
        
        // Update state
        isRecording = true
        print("RecordingManager: Recording started successfully")
        
        // Take initial screenshot
        print("RecordingManager: Taking initial screenshot")
        capturePeriodicScreenshot()
        
        // Notify delegate
        print("RecordingManager: Notifying delegate")
        delegate?.recordingDidStart()
    }
    
    // Stop the current recording session
    func stopRecording() throws {
        print("RecordingManager: stopRecording called")
        guard isRecording else {
            print("RecordingManager: ERROR - Not recording")
            throw RecordingError.notRecording
        }
        
        // Stop components
        print("RecordingManager: Stopping event monitoring")
        eventMonitor.stopMonitoring()
        
        // Stop screenshot timer
        print("RecordingManager: Stopping screenshot timer")
        screenshotTimer?.invalidate()
        screenshotTimer = nil
        
        // Update state
        isRecording = false
        print("RecordingManager: Recording stopped successfully")
        
        // Notify delegate
        print("RecordingManager: Notifying delegate")
        delegate?.recordingDidStop()
    }
    
    // Check if we have the necessary permissions
    func checkPermissions() -> Bool {
        print("RecordingManager: checkPermissions called")
        // Check accessibility permissions
        let accessibilityEnabled = accessibilityHelper.isAccessibilityEnabled()
        print("RecordingManager: Accessibility permissions: \(accessibilityEnabled)")
        
        // Check screen recording permissions
        // This would normally require actual implementation with CGDisplayStream or AVCaptureScreenInput
        var screenRecordingEnabled = false
        
        // Try to create a test screenshot to see if we have permissions
        print("RecordingManager: Testing screen capture permissions")
        if let _ = screenCapture.captureScreenshot() {
            screenRecordingEnabled = true
            print("RecordingManager: Screen recording permissions granted")
        } else {
            screenRecordingEnabled = false
            print("RecordingManager: Screen recording permissions denied")
        }
        
        let allPermissionsGranted = accessibilityEnabled && screenRecordingEnabled
        print("RecordingManager: All permissions granted: \(allPermissionsGranted)")
        return allPermissionsGranted
    }
    
    // Request permissions needed for recording
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        print("RecordingManager: requestPermissions called")
        // Request accessibility permissions
        print("RecordingManager: Requesting accessibility permissions")
        accessibilityHelper.requestAccessibilityPermissions()
        
        // For screen recording, macOS usually shows a system dialog when an app tries to capture the screen
        // We can trigger this by attempting to create a screen capture
        print("RecordingManager: Trying to trigger screen recording permission dialog")
        let _ = screenCapture.captureScreenshot()
        
        // Since we can't detect the result of the permission dialog directly,
        // we'll just check again after a delay
        print("RecordingManager: Waiting for user to respond to permission dialogs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let granted = self.checkPermissions()
            print("RecordingManager: Permissions after request: \(granted)")
            completion(granted)
        }
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
        
        // Get UI element information at click position
        if let elementInfo = accessibilityHelper.getUIElementAtPosition(interaction.position) {
            print("Clicked element: \(elementInfo.role) - \(elementInfo.title ?? "unnamed")")
            
            // Create UI element interaction
            let elementInteraction = UIElementInteraction(
                timestamp: interaction.timestamp,
                elementInfo: elementInfo,
                action: .click,
                position: interaction.position
            )
            
            // Add to current session
            SessionManager.shared.currentSession?.addInteraction(elementInteraction)
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
        
        // Get focused UI element (for text input and other interactions)
        if let focusedElement = accessibilityHelper.getFocusedElement() {
            print("Focused element: \(focusedElement.role) - \(focusedElement.title ?? "unnamed")")
            
            // Create UI element interaction
            let elementInteraction = UIElementInteraction(
                timestamp: interaction.timestamp,
                elementInfo: focusedElement,
                action: .input,
                position: NSEvent.mouseLocation // Use current mouse position as approximation
            )
            
            // Add to current session
            SessionManager.shared.currentSession?.addInteraction(elementInteraction)
        }
        
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
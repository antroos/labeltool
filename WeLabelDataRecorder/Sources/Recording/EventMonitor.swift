import Foundation
import AppKit

// Delegate protocol for event monitoring
protocol EventMonitorDelegate: AnyObject {
    func eventMonitor(_ monitor: EventMonitor, didCaptureMouseClick event: NSEvent)
    func eventMonitor(_ monitor: EventMonitor, didCaptureMouseMove event: NSEvent)
    func eventMonitor(_ monitor: EventMonitor, didCaptureMouseScroll event: NSEvent)
    func eventMonitor(_ monitor: EventMonitor, didCaptureKeyDown event: NSEvent)
    func eventMonitor(_ monitor: EventMonitor, didCaptureKeyUp event: NSEvent)
}

class EventMonitor {
    weak var delegate: EventMonitorDelegate?
    
    // Event monitors
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var localKeyboardMonitor: Any?
    private var globalKeyboardMonitor: Any?
    
    // Last known mouse position for tracking mouse movements
    private var lastMousePosition: NSPoint?
    
    // Start monitoring events
    func startMonitoring() {
        stopMonitoring() // Stop any existing monitors
        
        // Setup mouse monitors (local events - within the application)
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseUp, .rightMouseUp, .otherMouseUp, .mouseMoved, .scrollWheel]) { [weak self] event in
            self?.processMouseEvent(event)
            return event
        }
        
        // Setup global mouse monitors (system-wide events)
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseUp, .rightMouseUp, .otherMouseUp, .mouseMoved, .scrollWheel]) { [weak self] event in
            self?.processMouseEvent(event)
        }
        
        // Setup keyboard monitors (local events - within the application)
        localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.processKeyboardEvent(event)
            return event
        }
        
        // Setup global keyboard monitors (system-wide events)
        globalKeyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.processKeyboardEvent(event)
        }
    }
    
    // Stop monitoring events
    func stopMonitoring() {
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMonitor = nil
        }
        
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        
        if let monitor = localKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyboardMonitor = nil
        }
        
        if let monitor = globalKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyboardMonitor = nil
        }
        
        lastMousePosition = nil
    }
    
    // Process mouse events
    private func processMouseEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            delegate?.eventMonitor(self, didCaptureMouseClick: event)
            
        case .mouseMoved:
            let currentPosition = NSEvent.mouseLocation
            if let lastPosition = lastMousePosition {
                // Only report significant movements (more than 5 pixels)
                let distance = hypot(currentPosition.x - lastPosition.x, currentPosition.y - lastPosition.y)
                if distance > 5 {
                    delegate?.eventMonitor(self, didCaptureMouseMove: event)
                    lastMousePosition = currentPosition
                }
            } else {
                lastMousePosition = currentPosition
            }
            
        case .scrollWheel:
            delegate?.eventMonitor(self, didCaptureMouseScroll: event)
            
        default:
            break
        }
    }
    
    // Process keyboard events
    private func processKeyboardEvent(_ event: NSEvent) {
        switch event.type {
        case .keyDown:
            delegate?.eventMonitor(self, didCaptureKeyDown: event)
            
        case .keyUp:
            delegate?.eventMonitor(self, didCaptureKeyUp: event)
            
        default:
            break
        }
    }
    
    // Convert NSEvent to our model objects
    func mouseClickInteractionFrom(_ event: NSEvent) -> MouseClickInteraction {
        let position = NSEvent.mouseLocation
        
        var button: MouseButton
        switch event.type {
        case .leftMouseDown, .leftMouseUp:
            button = .left
        case .rightMouseDown, .rightMouseUp:
            button = .right
        case .otherMouseDown, .otherMouseUp:
            button = event.buttonNumber == 2 ? .middle : .other
        default:
            button = .other
        }
        
        return MouseClickInteraction(
            timestamp: Date(),
            position: position,
            button: button,
            clickCount: event.clickCount
        )
    }
    
    func mouseScrollInteractionFrom(_ event: NSEvent) -> MouseScrollInteraction {
        return MouseScrollInteraction(
            timestamp: Date(),
            position: NSEvent.mouseLocation,
            deltaX: event.scrollingDeltaX,
            deltaY: event.scrollingDeltaY
        )
    }
    
    func keyInteractionFrom(_ event: NSEvent, isKeyDown: Bool) -> KeyInteraction {
        return KeyInteraction(
            timestamp: Date(),
            isKeyDown: isKeyDown,
            keyCode: event.keyCode,
            characters: event.characters,
            modifiers: event.modifierFlags
        )
    }
} 
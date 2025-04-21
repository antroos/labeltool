import Foundation
import AppKit

// A structure to hold UI element metadata from the Accessibility API
struct UIElementInfo: Codable {
    let role: String
    let title: String?
    let identifier: String?
    let frame: CGRect
    let children: [UIElementInfo]?
    let value: String?
    let description: String?
    
    // Additional metadata that could be useful
    let isEnabled: Bool
    let isSelected: Bool
    let hasFocus: Bool
    
    // Standard initializer
    init(role: String, title: String?, identifier: String?, frame: CGRect, children: [UIElementInfo]?, value: String?, description: String?, isEnabled: Bool, isSelected: Bool, hasFocus: Bool) {
        self.role = role
        self.title = title
        self.identifier = identifier
        self.frame = frame
        self.children = children
        self.value = value
        self.description = description
        self.isEnabled = isEnabled
        self.isSelected = isSelected
        self.hasFocus = hasFocus
    }
    
    // Create from an AXUIElement
    init?(from element: AXUIElement) {
        // Get Role
        var roleValue: AnyObject?
        let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        
        guard roleResult == .success, let roleString = roleValue as? String else {
            print("Failed to get role: \(roleResult.rawValue)")
            return nil
        }
        self.role = roleString
        
        // Get Title (optional)
        var titleValue: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        self.title = (titleResult == .success) ? (titleValue as? String) : nil
        
        // Get Identifier (optional)
        var identifierValue: AnyObject?
        let identifierResult = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &identifierValue)
        self.identifier = (identifierResult == .success) ? (identifierValue as? String) : nil
        
        // Get Position and Size
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        let positionResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        let sizeResult = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        
        var elementFrame = CGRect.zero
        
        if positionResult == .success, let position = positionValue as? NSValue {
            var point = CGPoint.zero
            AXValueGetValue(position as! AXValue, .cgPoint, &point)
            elementFrame.origin = point
        }
        
        if sizeResult == .success, let size = sizeValue as? NSValue {
            var sizeRect = CGSize.zero
            AXValueGetValue(size as! AXValue, .cgSize, &sizeRect)
            elementFrame.size = sizeRect
        }
        
        self.frame = elementFrame
        
        // Get Value (optional)
        var valueObj: AnyObject?
        let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueObj)
        if valueResult == .success, let obj = valueObj {
            self.value = String(describing: obj)
        } else {
            self.value = nil
        }
        
        // Get Description (optional)
        var descValue: AnyObject?
        let descResult = AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descValue)
        self.description = (descResult == .success) ? (descValue as? String) : nil
        
        // Get Enabled state
        var enabledValue: AnyObject?
        let enabledResult = AXUIElementCopyAttributeValue(element, kAXEnabledAttribute as CFString, &enabledValue)
        self.isEnabled = (enabledResult == .success) ? (enabledValue as? Bool ?? true) : true
        
        // Get Selected state
        var selectedValue: AnyObject?
        let selectedResult = AXUIElementCopyAttributeValue(element, kAXSelectedAttribute as CFString, &selectedValue)
        self.isSelected = (selectedResult == .success) ? (selectedValue as? Bool ?? false) : false
        
        // Get Focus state
        var focusedValue: AnyObject?
        let focusedResult = AXUIElementCopyAttributeValue(element, kAXFocusedAttribute as CFString, &focusedValue)
        self.hasFocus = (focusedResult == .success) ? (focusedValue as? Bool ?? false) : false
        
        // Get Children (optional)
        self.children = nil // We'll implement this in later versions for simplicity
    }
}

class AccessibilityHelper {
    static let shared = AccessibilityHelper()
    
    // Check if accessibility features are enabled
    func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
    
    // Request accessibility permissions from the user
    func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        print("Accessibility permission request result: \(trusted)")
    }
    
    // Get information about the UI element at a specific screen position
    func getUIElementAtPosition(_ position: NSPoint) -> UIElementInfo? {
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWideElement, Float(position.x), Float(position.y), &element)
        
        guard result == .success, let foundElement = element else {
            print("Failed to get element at position: \(result.rawValue)")
            return nil
        }
        
        return UIElementInfo(from: foundElement)
    }
    
    // Get the currently focused UI element
    func getFocusedElement() -> UIElementInfo? {
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            print("Failed to get focused element: \(result.rawValue)")
            return nil
        }
        
        // Element должен быть типа AXUIElement
        guard CFGetTypeID(element as CFTypeRef) == AXUIElementGetTypeID() else {
            print("Object is not an AXUIElement")
            return nil
        }
        
        return UIElementInfo(from: element as! AXUIElement)
    }
} 
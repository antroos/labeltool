import XCTest
import AppKit
@testable import WeLabelDataRecorder

class AccessibilityHelperTests: XCTestCase {
    
    var accessibilityHelper: AccessibilityHelper!
    
    override func setUp() {
        super.setUp()
        accessibilityHelper = AccessibilityHelper.shared
    }
    
    override func tearDown() {
        accessibilityHelper = nil
        super.tearDown()
    }
    
    func testAccessibilityHelperSingleton() {
        // Test that there's only one instance
        let helper1 = AccessibilityHelper.shared
        let helper2 = AccessibilityHelper.shared
        
        XCTAssertTrue(helper1 === helper2, "Singleton instances should be identical")
    }
    
    // This test will only pass if the app has accessibility permissions
    // Since we can't reliably test this in an automated way, it's marked as disabled
    func testAccessibilityPermissionStatus() {
        // This just verifies our method returns a boolean, not the actual value
        let isEnabled = accessibilityHelper.isAccessibilityEnabled()
        
        // Just ensure the method returns without crashing
        XCTAssertNotNil(isEnabled)
        
        // Print the status for informational purposes
        print("Accessibility permissions enabled: \(isEnabled)")
    }
    
    // Test for the UIElementInfo creation with mock data
    func testMockUIElementInfoCreation() {
        // Create a mock UIElementInfo
        let mockInfo = UIElementInfo(
            role: "button",
            title: "Test Button",
            identifier: "testButton",
            frame: CGRect(x: 10, y: 20, width: 100, height: 50),
            children: nil,
            value: nil,
            description: "A test button",
            isEnabled: true,
            isSelected: false,
            hasFocus: true
        )
        
        // Verify the properties are set correctly
        XCTAssertEqual(mockInfo.role, "button")
        XCTAssertEqual(mockInfo.title, "Test Button")
        XCTAssertEqual(mockInfo.frame.origin.x, 10)
        XCTAssertEqual(mockInfo.frame.origin.y, 20)
        XCTAssertEqual(mockInfo.frame.size.width, 100)
        XCTAssertEqual(mockInfo.frame.size.height, 50)
    }
    
    // Note: These next two tests can't be automated reliably
    // They are included here as guidance for manual testing
    
    // MANUAL TEST: This can be run when you need to check element access
    func disabled_testGetElementAtPosition() {
        // Get the center point of the screen
        let mainScreen = NSScreen.main!
        let centerPoint = NSPoint(
            x: mainScreen.frame.origin.x + mainScreen.frame.size.width / 2,
            y: mainScreen.frame.origin.y + mainScreen.frame.size.height / 2
        )
        
        // Try to get the UI element at this position
        // This will only work if accessibility permissions are granted
        if let elementInfo = accessibilityHelper.getUIElementAtPosition(centerPoint) {
            // Print information for manual verification
            print("Found element at center of screen:")
            print("Role: \(elementInfo.role)")
            print("Title: \(elementInfo.title ?? "nil")")
            print("Frame: \(elementInfo.frame)")
            print("Enabled: \(elementInfo.isEnabled)")
        } else {
            print("No element found at center of screen or permissions denied")
        }
        
        // This test is for manual verification, so we don't assert anything
    }
    
    // MANUAL TEST: This can be run when you need to check focus element access
    func disabled_testGetFocusedElement() {
        // Try to get the currently focused element
        // This will only work if accessibility permissions are granted and something has focus
        if let elementInfo = accessibilityHelper.getFocusedElement() {
            // Print information for manual verification
            print("Found focused element:")
            print("Role: \(elementInfo.role)")
            print("Title: \(elementInfo.title ?? "nil")")
            print("Frame: \(elementInfo.frame)")
            print("Enabled: \(elementInfo.isEnabled)")
        } else {
            print("No focused element found or permissions denied")
        }
        
        // This test is for manual verification, so we don't assert anything
    }
} 
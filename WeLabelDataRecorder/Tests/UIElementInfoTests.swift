import XCTest
import AppKit
@testable import WeLabelDataRecorder

class UIElementInfoTests: XCTestCase {
    
    func testUIElementInfoCreation() {
        // Create a basic UIElementInfo with test data
        let testFrame = CGRect(x: 10, y: 20, width: 100, height: 50)
        let elementInfo = UIElementInfo(
            role: "button",
            title: "Test Button",
            identifier: "testButton",
            frame: testFrame,
            children: nil,
            value: nil,
            description: "A test button",
            isEnabled: true,
            isSelected: false,
            hasFocus: true
        )
        
        // Verify properties
        XCTAssertEqual(elementInfo.role, "button")
        XCTAssertEqual(elementInfo.title, "Test Button")
        XCTAssertEqual(elementInfo.identifier, "testButton")
        XCTAssertEqual(elementInfo.frame, testFrame)
        XCTAssertNil(elementInfo.children)
        XCTAssertNil(elementInfo.value)
        XCTAssertEqual(elementInfo.description, "A test button")
        XCTAssertTrue(elementInfo.isEnabled)
        XCTAssertFalse(elementInfo.isSelected)
        XCTAssertTrue(elementInfo.hasFocus)
    }
    
    func testUIElementInfoCodable() {
        // Create a test UIElementInfo
        let testFrame = CGRect(x: 10, y: 20, width: 100, height: 50)
        let elementInfo = UIElementInfo(
            role: "button",
            title: "Test Button",
            identifier: "testButton",
            frame: testFrame,
            children: nil,
            value: nil,
            description: "A test button",
            isEnabled: true,
            isSelected: false,
            hasFocus: true
        )
        
        // Encode to JSON
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(elementInfo)
            
            // Decode from JSON
            let decoder = JSONDecoder()
            let decodedInfo = try decoder.decode(UIElementInfo.self, from: data)
            
            // Verify decoded properties match original
            XCTAssertEqual(decodedInfo.role, elementInfo.role)
            XCTAssertEqual(decodedInfo.title, elementInfo.title)
            XCTAssertEqual(decodedInfo.identifier, elementInfo.identifier)
            XCTAssertEqual(decodedInfo.frame.origin.x, elementInfo.frame.origin.x)
            XCTAssertEqual(decodedInfo.frame.origin.y, elementInfo.frame.origin.y)
            XCTAssertEqual(decodedInfo.frame.size.width, elementInfo.frame.size.width)
            XCTAssertEqual(decodedInfo.frame.size.height, elementInfo.frame.size.height)
            XCTAssertEqual(decodedInfo.description, elementInfo.description)
            XCTAssertEqual(decodedInfo.isEnabled, elementInfo.isEnabled)
            XCTAssertEqual(decodedInfo.isSelected, elementInfo.isSelected)
            XCTAssertEqual(decodedInfo.hasFocus, elementInfo.hasFocus)
        } catch {
            XCTFail("Failed to encode/decode UIElementInfo: \(error)")
        }
    }
    
    func testNestedUIElementInfo() {
        // Create child elements
        let childFrame1 = CGRect(x: 15, y: 25, width: 40, height: 20)
        let child1 = UIElementInfo(
            role: "staticText",
            title: "Label",
            identifier: "label1",
            frame: childFrame1,
            children: nil,
            value: "Text",
            description: "A label",
            isEnabled: true,
            isSelected: false,
            hasFocus: false
        )
        
        let childFrame2 = CGRect(x: 60, y: 25, width: 30, height: 20)
        let child2 = UIElementInfo(
            role: "image",
            title: "Icon",
            identifier: "icon1",
            frame: childFrame2,
            children: nil,
            value: nil,
            description: "An icon",
            isEnabled: true,
            isSelected: false,
            hasFocus: false
        )
        
        // Create parent with children
        let parentFrame = CGRect(x: 10, y: 20, width: 100, height: 50)
        let parent = UIElementInfo(
            role: "group",
            title: "Container",
            identifier: "container1",
            frame: parentFrame,
            children: [child1, child2],
            value: nil,
            description: "A container",
            isEnabled: true,
            isSelected: false,
            hasFocus: false
        )
        
        // Verify parent properties
        XCTAssertEqual(parent.role, "group")
        XCTAssertEqual(parent.children?.count, 2)
        
        // Verify child properties
        XCTAssertEqual(parent.children?[0].role, "staticText")
        XCTAssertEqual(parent.children?[0].value, "Text")
        XCTAssertEqual(parent.children?[1].role, "image")
        XCTAssertEqual(parent.children?[1].title, "Icon")
    }
} 
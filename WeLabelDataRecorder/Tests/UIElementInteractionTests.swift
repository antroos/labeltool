import XCTest
import AppKit
@testable import WeLabelDataRecorder

class UIElementInteractionTests: XCTestCase {
    
    func testUIElementInteractionCreation() {
        // Create a UIElementInfo
        let elementInfo = UIElementInfo(
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
        
        // Create a UIElementInteraction
        let timestamp = Date()
        let position = NSPoint(x: 15, y: 25)
        let interaction = UIElementInteraction(
            timestamp: timestamp,
            elementInfo: elementInfo,
            action: .click,
            position: position
        )
        
        // Verify properties
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.interactionType, .uiElement)
        XCTAssertEqual(interaction.elementInfo.role, "button")
        XCTAssertEqual(interaction.elementInfo.title, "Test Button")
        XCTAssertEqual(interaction.interactionAction, .click)
        XCTAssertEqual(interaction.position.x, position.x)
        XCTAssertEqual(interaction.position.y, position.y)
    }
    
    func testUIElementInteractionCodable() {
        // Create a UIElementInfo
        let elementInfo = UIElementInfo(
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
        
        // Create a UIElementInteraction
        let timestamp = Date()
        let position = NSPoint(x: 15, y: 25)
        let interaction = UIElementInteraction(
            timestamp: timestamp,
            elementInfo: elementInfo,
            action: .click,
            position: position
        )
        
        // Encode to JSON
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(interaction)
            
            // Decode from JSON
            let decoder = JSONDecoder()
            let decodedInteraction = try decoder.decode(UIElementInteraction.self, from: data)
            
            // Verify decoded properties match original
            XCTAssertEqual(decodedInteraction.interactionType, .uiElement)
            XCTAssertEqual(decodedInteraction.elementInfo.role, "button")
            XCTAssertEqual(decodedInteraction.elementInfo.title, "Test Button")
            XCTAssertEqual(decodedInteraction.interactionAction, .click)
            XCTAssertEqual(decodedInteraction.position.x, position.x)
            XCTAssertEqual(decodedInteraction.position.y, position.y)
        } catch {
            XCTFail("Failed to encode/decode UIElementInteraction: \(error)")
        }
    }
    
    func testDifferentUIElementActions() {
        // Create a UIElementInfo
        let elementInfo = UIElementInfo(
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
        
        // Create different types of interactions
        let position = NSPoint(x: 15, y: 25)
        
        let clickInteraction = UIElementInteraction(
            timestamp: Date(),
            elementInfo: elementInfo,
            action: .click,
            position: position
        )
        
        let focusInteraction = UIElementInteraction(
            timestamp: Date(),
            elementInfo: elementInfo,
            action: .focus,
            position: position
        )
        
        let hoverInteraction = UIElementInteraction(
            timestamp: Date(),
            elementInfo: elementInfo,
            action: .hover,
            position: position
        )
        
        let inputInteraction = UIElementInteraction(
            timestamp: Date(),
            elementInfo: elementInfo,
            action: .input,
            position: position
        )
        
        let scrollInteraction = UIElementInteraction(
            timestamp: Date(),
            elementInfo: elementInfo,
            action: .scroll,
            position: position
        )
        
        // Verify actions
        XCTAssertEqual(clickInteraction.interactionAction, .click)
        XCTAssertEqual(focusInteraction.interactionAction, .focus)
        XCTAssertEqual(hoverInteraction.interactionAction, .hover)
        XCTAssertEqual(inputInteraction.interactionAction, .input)
        XCTAssertEqual(scrollInteraction.interactionAction, .scroll)
    }
} 
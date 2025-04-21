import XCTest
import AppKit
@testable import WeLabelDataRecorder

final class UserInteractionTests: XCTestCase {
    
    func testMouseClickInteraction() {
        // Create a mouse click interaction
        let timestamp = Date()
        let position = NSPoint(x: 100, y: 200)
        let interaction = MouseClickInteraction(
            timestamp: timestamp,
            position: position,
            button: .left,
            clickCount: 1
        )
        
        // Verify properties
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.interactionType, .mouseClick)
        XCTAssertEqual(interaction.position.x, 100)
        XCTAssertEqual(interaction.position.y, 200)
        XCTAssertEqual(interaction.button, .left)
        XCTAssertEqual(interaction.clickCount, 1)
    }
    
    func testMouseMoveInteraction() {
        // Create a mouse move interaction
        let timestamp = Date()
        let fromPosition = NSPoint(x: 100, y: 200)
        let toPosition = NSPoint(x: 300, y: 400)
        let interaction = MouseMoveInteraction(
            timestamp: timestamp,
            fromPosition: fromPosition,
            toPosition: toPosition
        )
        
        // Verify properties
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.interactionType, .mouseMove)
        XCTAssertEqual(interaction.fromPosition.x, 100)
        XCTAssertEqual(interaction.fromPosition.y, 200)
        XCTAssertEqual(interaction.toPosition.x, 300)
        XCTAssertEqual(interaction.toPosition.y, 400)
    }
    
    func testKeyInteraction() {
        // Create a key down interaction
        let timestamp = Date()
        let keyCode: UInt16 = 13 // Return key
        let characters = "\r"
        let modifiers: NSEvent.ModifierFlags = [.shift]
        
        let interaction = KeyInteraction(
            timestamp: timestamp,
            isKeyDown: true,
            keyCode: keyCode,
            characters: characters,
            modifiers: modifiers
        )
        
        // Verify properties
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.interactionType, .keyDown)
        XCTAssertEqual(interaction.keyCode, 13)
        XCTAssertEqual(interaction.characters, "\r")
        XCTAssertEqual(interaction.modifiers, .shift)
    }
    
    func testScreenshotInteraction() {
        // Create a screenshot interaction
        let timestamp = Date()
        let imageFileName = "screenshot_123.png"
        let screenBounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let interaction = ScreenshotInteraction(
            timestamp: timestamp,
            imageFileName: imageFileName,
            screenBounds: screenBounds
        )
        
        // Verify properties
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.interactionType, .screenshot)
        XCTAssertEqual(interaction.imageFileName, "screenshot_123.png")
        XCTAssertEqual(interaction.screenBounds, CGRect(x: 0, y: 0, width: 1920, height: 1080))
    }
    
    func testMouseScrollInteraction() {
        // Create a mouse scroll interaction
        let timestamp = Date()
        let position = NSPoint(x: 100, y: 200)
        let deltaX: CGFloat = 0
        let deltaY: CGFloat = 10 // Scroll down
        
        let interaction = MouseScrollInteraction(
            timestamp: timestamp,
            position: position,
            deltaX: deltaX,
            deltaY: deltaY
        )
        
        // Verify properties
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.interactionType, .mouseScroll)
        XCTAssertEqual(interaction.position.x, 100)
        XCTAssertEqual(interaction.position.y, 200)
        XCTAssertEqual(interaction.deltaX, 0)
        XCTAssertEqual(interaction.deltaY, 10)
    }
} 
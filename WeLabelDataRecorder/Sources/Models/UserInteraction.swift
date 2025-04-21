import Foundation
import AppKit

// Base protocol for all user interactions
protocol UserInteraction {
    var timestamp: Date { get }
    var interactionType: InteractionType { get }
}

// Types of user interactions we can record
enum InteractionType: String, Codable {
    case mouseClick
    case mouseMove
    case mouseScroll
    case keyDown
    case keyUp
    case screenshot
}

// Represents a mouse click event
struct MouseClickInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .mouseClick
    let position: NSPoint
    let button: MouseButton
    let clickCount: Int
}

// Represents a mouse move event
struct MouseMoveInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .mouseMove
    let fromPosition: NSPoint
    let toPosition: NSPoint
}

// Represents a mouse scroll event
struct MouseScrollInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .mouseScroll
    let position: NSPoint
    let deltaX: CGFloat
    let deltaY: CGFloat
}

// Represents a key press event
struct KeyInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType
    let keyCode: UInt16
    let characters: String?
    let modifiers: NSEvent.ModifierFlags
    
    init(timestamp: Date, isKeyDown: Bool, keyCode: UInt16, characters: String?, modifiers: NSEvent.ModifierFlags) {
        self.timestamp = timestamp
        self.interactionType = isKeyDown ? .keyDown : .keyUp
        self.keyCode = keyCode
        self.characters = characters
        self.modifiers = modifiers
    }
}

// Represents a screenshot taken during the session
struct ScreenshotInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .screenshot
    let imageFileName: String
    let screenBounds: CGRect
}

// Mouse button types
enum MouseButton: Int, Codable {
    case left = 0
    case right = 1
    case middle = 2
    case other = 3
} 
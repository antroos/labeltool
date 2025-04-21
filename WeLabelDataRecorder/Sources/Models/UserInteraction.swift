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
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case position
        case button
        case clickCount
    }
}

// Represents a mouse move event
struct MouseMoveInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .mouseMove
    let fromPosition: NSPoint
    let toPosition: NSPoint
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case fromPosition
        case toPosition
    }
}

// Represents a mouse scroll event
struct MouseScrollInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .mouseScroll
    let position: NSPoint
    let deltaX: CGFloat
    let deltaY: CGFloat
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case position
        case deltaX
        case deltaY
    }
}

// Represents a key press event
struct KeyInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType
    let keyCode: UInt16
    let characters: String?
    private let modifierFlagsRawValue: UInt // Store the raw value of NSEvent.ModifierFlags
    
    // Computed property to convert the raw value back to NSEvent.ModifierFlags
    var modifiers: NSEvent.ModifierFlags {
        return NSEvent.ModifierFlags(rawValue: modifierFlagsRawValue)
    }
    
    init(timestamp: Date, isKeyDown: Bool, keyCode: UInt16, characters: String?, modifiers: NSEvent.ModifierFlags) {
        self.timestamp = timestamp
        self.interactionType = isKeyDown ? .keyDown : .keyUp
        self.keyCode = keyCode
        self.characters = characters
        self.modifierFlagsRawValue = modifiers.rawValue
    }
    
    // Custom CodingKeys to map the private property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case keyCode
        case characters
        case modifierFlagsRawValue
    }
}

// Represents a screenshot taken during the session
struct ScreenshotInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .screenshot
    let imageFileName: String
    let screenBounds: CGRect
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case imageFileName
        case screenBounds
    }
}

// Mouse button types
enum MouseButton: Int, Codable {
    case left = 0
    case right = 1
    case middle = 2
    case other = 3
} 
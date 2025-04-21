import Foundation
import AppKit

// Вспомогательные структуры для сериализации/десериализации типов AppKit/CoreGraphics
struct CodablePoint: Codable {
    let x: CGFloat
    let y: CGFloat
    
    init(from point: NSPoint) {
        self.x = point.x
        self.y = point.y
    }
    
    var toNSPoint: NSPoint {
        return NSPoint(x: x, y: y)
    }
}

struct CodableRect: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    
    init(from rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
    
    var toCGRect: CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

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
    
    // Используем приватные свойства для обеспечения корректной сериализации
    private let positionPoint: CodablePoint
    let button: MouseButton
    let clickCount: Int
    
    // Публичный доступ через вычисляемое свойство
    var position: NSPoint {
        return positionPoint.toNSPoint
    }
    
    init(timestamp: Date, position: NSPoint, button: MouseButton, clickCount: Int) {
        self.timestamp = timestamp
        self.positionPoint = CodablePoint(from: position)
        self.button = button
        self.clickCount = clickCount
    }
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case positionPoint
        case button
        case clickCount
    }
}

// Represents a mouse move event
struct MouseMoveInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .mouseMove
    
    // Используем приватные свойства для обеспечения корректной сериализации
    private let fromPositionPoint: CodablePoint
    private let toPositionPoint: CodablePoint
    
    // Публичный доступ через вычисляемые свойства
    var fromPosition: NSPoint {
        return fromPositionPoint.toNSPoint
    }
    
    var toPosition: NSPoint {
        return toPositionPoint.toNSPoint
    }
    
    init(timestamp: Date, fromPosition: NSPoint, toPosition: NSPoint) {
        self.timestamp = timestamp
        self.fromPositionPoint = CodablePoint(from: fromPosition)
        self.toPositionPoint = CodablePoint(from: toPosition)
    }
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case fromPositionPoint
        case toPositionPoint
    }
}

// Represents a mouse scroll event
struct MouseScrollInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .mouseScroll
    
    // Используем приватные свойства для обеспечения корректной сериализации
    private let positionPoint: CodablePoint
    let deltaX: CGFloat
    let deltaY: CGFloat
    
    // Публичный доступ через вычисляемое свойство
    var position: NSPoint {
        return positionPoint.toNSPoint
    }
    
    init(timestamp: Date, position: NSPoint, deltaX: CGFloat, deltaY: CGFloat) {
        self.timestamp = timestamp
        self.positionPoint = CodablePoint(from: position)
        self.deltaX = deltaX
        self.deltaY = deltaY
    }
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case positionPoint
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
    
    // Используем приватное свойство для обеспечения корректной сериализации
    private let screenBoundsRect: CodableRect
    
    // Публичный доступ через вычисляемое свойство
    var screenBounds: CGRect {
        return screenBoundsRect.toCGRect
    }
    
    init(timestamp: Date, imageFileName: String, screenBounds: CGRect) {
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.screenBoundsRect = CodableRect(from: screenBounds)
    }
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case imageFileName
        case screenBoundsRect
    }
}

// Mouse button types
enum MouseButton: Int, Codable {
    case left = 0
    case right = 1
    case middle = 2
    case other = 3
} 
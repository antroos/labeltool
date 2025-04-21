import Foundation
import AppKit

// Represents an interaction with a UI element
struct UIElementInteraction: UserInteraction, Codable {
    let timestamp: Date
    let interactionType: InteractionType = .uiElement
    
    // The UI element that was interacted with
    let elementInfo: UIElementInfo
    
    // The type of interaction that occurred (click, focus, hover, etc.)
    let interactionAction: UIElementAction
    
    // Position of the interaction
    private let positionPoint: CodablePoint
    
    // Публичный доступ через вычисляемое свойство
    var position: NSPoint {
        return positionPoint.toNSPoint
    }
    
    init(timestamp: Date, elementInfo: UIElementInfo, action: UIElementAction, position: NSPoint) {
        self.timestamp = timestamp
        self.elementInfo = elementInfo
        self.interactionAction = action
        self.positionPoint = CodablePoint(from: position)
    }
    
    // Add CodingKeys to handle the interactionType property
    enum CodingKeys: String, CodingKey {
        case timestamp
        case interactionType
        case elementInfo
        case interactionAction
        case positionPoint
    }
}

// Types of actions performed on UI elements
enum UIElementAction: String, Codable {
    case click
    case focus
    case hover
    case input
    case scroll
} 
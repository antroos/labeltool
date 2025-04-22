import Foundation
import AppKit

/// Types of relationships between UI elements
enum RelationshipType: String, Codable {
    // Hierarchical relationships
    case parent        // Direct containing element
    case child         // Direct contained element
    case sibling       // Elements sharing the same parent
    case container     // Non-direct parent containing the element
    case contained     // Element is contained within another (not direct parent)
    
    // Functional relationships
    case functional    // Functionally related elements (like a label and textfield)
    
    // Logical relationships
    case logical       // Logically connected elements (like elements of the same form)
}

/// Represents a related UI element with additional relationship context
struct RelatedElement: Codable {
    let element: UIElementInfo
    let relationshipType: RelationshipType
    let relevanceScore: Double
    let notes: String?
    
    init(element: UIElementInfo, relationshipType: RelationshipType, relevanceScore: Double, notes: String? = nil) {
        self.element = element
        self.relationshipType = relationshipType
        self.relevanceScore = min(max(relevanceScore, 0.0), 1.0) // Ensure score is between 0 and 1
        self.notes = notes
    }
    
    var description: String {
        let details = notes != nil ? " (\(notes!))" : ""
        return "[\(relationshipType)] \(element.role) [\(element.title ?? "untitled")] - Score: \(relevanceScore)\(details)"
    }
}

/// Spatial relations between UI elements
enum SpatialRelation: String, Codable {
    case above = "above"           // Above the element
    case below = "below"           // Below the element
    case leftOf = "leftOf"         // To the left of the element
    case rightOf = "rightOf"       // To the right of the element
    case aboveLeft = "aboveLeft"   // Above and to the left
    case aboveRight = "aboveRight" // Above and to the right
    case belowLeft = "belowLeft"   // Below and to the left
    case belowRight = "belowRight" // Below and to the right
}

/// Extensions for UIElementInfo to support relationship analysis
extension UIElementInfo {
    // Virtual parent, not actually stored in the struct but can be set dynamically
    private static var parentMap = [UIElementInfo: UIElementInfo]()
    
    var parent: UIElementInfo? {
        get {
            return UIElementInfo.parentMap[self]
        }
        set {
            if let newValue = newValue {
                UIElementInfo.parentMap[self] = newValue
            } else {
                UIElementInfo.parentMap.removeValue(forKey: self)
            }
        }
    }
    
    // Calculate siblings based on parent
    var siblings: [UIElementInfo] {
        guard let parent = self.parent, let parentChildren = parent.children else {
            return []
        }
        
        return parentChildren.filter { $0 != self }
    }
    
    // Since UIElementInfo doesn't have a siblingIndex property, calculate it
    var siblingIndex: Int {
        guard let parent = self.parent, let parentChildren = parent.children else {
            return 0
        }
        
        return parentChildren.firstIndex(of: self) ?? 0
    }
    
    // Check if this element contains another
    func contains(element: UIElementInfo) -> Bool {
        return frame.contains(element.frame)
    }
    
    // Calculate overlap area between two elements
    func overlapArea(with other: UIElementInfo) -> CGFloat {
        let intersection = frame.intersection(other.frame)
        return intersection.width * intersection.height
    }
    
    // Get the center of the element
    var center: NSPoint {
        return NSPoint(
            x: frame.origin.x + frame.size.width / 2,
            y: frame.origin.y + frame.size.height / 2
        )
    }
    
    // Calculate distance to another element (between centers)
    func distanceTo(_ other: UIElementInfo) -> CGFloat {
        return hypot(center.x - other.center.x, center.y - other.center.y)
    }
    
    // Determine spatial relationship to another element
    func spatialRelationTo(_ other: UIElementInfo) -> SpatialRelation {
        let dx = other.center.x - center.x
        let dy = other.center.y - center.y
        let absDx = abs(dx)
        let absDy = abs(dy)
        
        // If one dimension significantly predominates
        if absDx > absDy * 2 {
            return dx > 0 ? .rightOf : .leftOf
        } else if absDy > absDx * 2 {
            return dy > 0 ? .below : .above
        } else {
            // Diagonal relationship
            if dx > 0 && dy > 0 {
                return .belowRight
            } else if dx > 0 && dy < 0 {
                return .aboveRight
            } else if dx < 0 && dy > 0 {
                return .belowLeft
            } else {
                return .aboveLeft
            }
        }
    }
    
    // Simple description for debugging
    var shortDescription: String {
        return "\(role) [\(title ?? "untitled")]"
    }
} 
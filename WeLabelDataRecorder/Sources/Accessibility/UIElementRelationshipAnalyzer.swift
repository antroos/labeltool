import Foundation
import AppKit

class UIElementRelationshipAnalyzer {
    // Singleton instance
    static let shared = UIElementRelationshipAnalyzer()
    
    private init() {}
    
    // MARK: - Improved Relationship Analysis
    
    /// Analyze all possible relationships between a target element and other elements
    /// Returns an array of RelatedElement objects sorted by relevance
    func analyzeRelationships(for targetElement: UIElementInfo, at position: NSPoint) -> [RelatedElement] {
        var relatedElements: [RelatedElement] = []
        
        // Get hierarchy relationships
        relatedElements.append(contentsOf: findHierarchyRelationships(for: targetElement))
        
        // Get spatial relationships
        relatedElements.append(contentsOf: findSpatialRelationships(for: targetElement))
        
        // Get functional relationships
        relatedElements.append(contentsOf: findFunctionalRelationships(for: targetElement, at: position))
        
        // Get logical relationships
        relatedElements.append(contentsOf: findLogicalRelationships(for: targetElement))
        
        // Sort by relevance score
        return relatedElements.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    // MARK: - Hierarchy Relationships
    
    /// Find relationships based on element hierarchy (parent/child/sibling)
    private func findHierarchyRelationships(for element: UIElementInfo) -> [RelatedElement] {
        var relationships: [RelatedElement] = []
        
        // Parent relationship
        if let parent = element.parent {
            relationships.append(RelatedElement(
                element: parent,
                relationshipType: .parent,
                relevanceScore: 0.9
            ))
            
            // Check for container relationship (grandparent or beyond)
            if let grandparent = parent.parent {
                relationships.append(RelatedElement(
                    element: grandparent,
                    relationshipType: .container,
                    relevanceScore: 0.7
                ))
            }
        }
        
        // Child relationships (with limit to prevent too many)
        if let children = element.children {
            for (index, child) in children.prefix(5).enumerated() {
                let relevance = max(0.85 - (Double(index) * 0.05), 0.6)
                relationships.append(RelatedElement(
                    element: child,
                    relationshipType: .child,
                    relevanceScore: relevance
                ))
            }
        }
        
        // Sibling relationships (with limit to prevent too many)
        for (index, sibling) in element.siblings.prefix(3).enumerated() {
            let relevance = max(0.7 - (Double(index) * 0.1), 0.5)
            relationships.append(RelatedElement(
                element: sibling,
                relationshipType: .sibling,
                relevanceScore: relevance
            ))
        }
        
        return relationships
    }
    
    // MARK: - Spatial Relationships
    
    /// Find relationships based on spatial positioning
    private func findSpatialRelationships(for element: UIElementInfo) -> [RelatedElement] {
        var relationships: [RelatedElement] = []
        
        // Get elements from parent to check for spatial relationships
        guard let parent = element.parent, let siblings = parent.children else {
            return relationships
        }
        
        for sibling in siblings where sibling.siblingIndex != element.siblingIndex {
            // Check if this element contains the other
            if element.contains(element: sibling) {
                relationships.append(RelatedElement(
                    element: sibling,
                    relationshipType: .contained,
                    relevanceScore: 0.8,
                    notes: "Element is contained spatially"
                ))
            }
            
            // Check if this element is contained by the other
            if sibling.contains(element: element) {
                relationships.append(RelatedElement(
                    element: sibling,
                    relationshipType: .container,
                    relevanceScore: 0.8,
                    notes: "Element is a spatial container"
                ))
            }
            
            // Check for significant overlap (but not containment)
            let overlapArea = element.overlapArea(with: sibling)
            let elementArea = element.frame.width * element.frame.height
            let siblingArea = sibling.frame.width * sibling.frame.height
            let smallerArea = min(elementArea, siblingArea)
            
            if overlapArea > 0 && overlapArea / smallerArea > 0.3 {
                relationships.append(RelatedElement(
                    element: sibling,
                    relationshipType: .logical,
                    relevanceScore: 0.7,
                    notes: "Elements overlap spatially"
                ))
            }
        }
        
        return relationships
    }
    
    // MARK: - Functional Relationships
    
    /// Find relationships based on common UI patterns and functional roles
    private func findFunctionalRelationships(for element: UIElementInfo, at position: NSPoint) -> [RelatedElement] {
        var relationships: [RelatedElement] = []
        
        // Case 1: Form elements (label + input fields)
        if element.role == "AXTextField" || element.role == "AXTextArea" || element.role == "AXComboBox" {
            // Find nearby labels that might be associated with this field
            if let nearbyLabels = findNearbyElementsByRoleAndProximity(from: element, roles: ["AXStaticText", "AXLabel"], maxDistance: 50) {
                for (index, label) in nearbyLabels.enumerated() {
                    relationships.append(RelatedElement(
                        element: label,
                        relationshipType: .functional,
                        relevanceScore: 0.9 - (Double(index) * 0.1),
                        notes: "Potential field label"
                    ))
                }
            }
        }
        
        // Case 2: Label describing a UI control
        if element.role == "AXStaticText" || element.role == "AXLabel" {
            // Find nearby interactive elements that this label might describe
            if let nearbyControls = findNearbyElementsByRoleAndProximity(from: element, roles: ["AXButton", "AXCheckBox", "AXRadioButton", "AXTextField", "AXComboBox"], maxDistance: 50) {
                for (index, control) in nearbyControls.enumerated() {
                    relationships.append(RelatedElement(
                        element: control,
                        relationshipType: .functional,
                        relevanceScore: 0.85 - (Double(index) * 0.1),
                        notes: "Element potentially described by this label"
                    ))
                }
            }
        }
        
        // Case 3: Button and its target (content that would change when clicked)
        if element.role == "AXButton" {
            // Find potential containers that might be affected by this button
            if let containers = findNearbyElementsByRoleAndProximity(from: element, roles: ["AXGroup", "AXWindow", "AXSheet", "AXScrollArea"], maxDistance: 200) {
                for container in containers {
                    relationships.append(RelatedElement(
                        element: container,
                        relationshipType: .functional,
                        relevanceScore: 0.7,
                        notes: "Container potentially affected by button"
                    ))
                }
            }
        }
        
        return relationships
    }
    
    // MARK: - Logical Relationships
    
    /// Find relationships based on logical connections (not spatial or hierarchy based)
    private func findLogicalRelationships(for element: UIElementInfo) -> [RelatedElement] {
        var relationships: [RelatedElement] = []
        
        // Case 1: Elements with similar identifiers or naming patterns
        if let identifier = element.identifier, !identifier.isEmpty {
            // Look for siblings or nearby elements with related identifiers
            if let parent = element.parent, let siblings = parent.children {
                for sibling in siblings where sibling.siblingIndex != element.siblingIndex {
                    if let siblingId = sibling.identifier, !siblingId.isEmpty {
                        // Check for related identifiers (common prefix or suffix)
                        if areIdentifiersRelated(identifier, siblingId) {
                            relationships.append(RelatedElement(
                                element: sibling,
                                relationshipType: .logical,
                                relevanceScore: 0.8,
                                notes: "Element with related identifier"
                            ))
                        }
                    }
                    
                    // Check for similar titles that indicate relationship
                    if let elementTitle = element.title, let siblingTitle = sibling.title,
                       !elementTitle.isEmpty && !siblingTitle.isEmpty {
                        if areTitlesRelated(elementTitle, siblingTitle) {
                            relationships.append(RelatedElement(
                                element: sibling,
                                relationshipType: .logical,
                                relevanceScore: 0.75,
                                notes: "Element with related title"
                            ))
                        }
                    }
                }
            }
        }
        
        return relationships
    }
    
    // MARK: - Helper Methods
    
    /// Find elements near a target element with specific roles
    private func findNearbyElementsByRoleAndProximity(from element: UIElementInfo, roles: [String], maxDistance: CGFloat) -> [UIElementInfo]? {
        // Start from the parent to get sibling elements
        guard let parent = element.parent, let siblings = parent.children else {
            return nil
        }
        
        // Filter by role and then by distance
        let filteredByRole = siblings.filter { roles.contains($0.role) && $0.siblingIndex != element.siblingIndex }
        
        // Calculate centers
        let elementCenter = NSPoint(
            x: element.frame.origin.x + element.frame.size.width / 2,
            y: element.frame.origin.y + element.frame.size.height / 2
        )
        
        // Filter and sort by distance
        let filteredByDistance = filteredByRole.filter { sibling in
            let siblingCenter = NSPoint(
                x: sibling.frame.origin.x + sibling.frame.size.width / 2,
                y: sibling.frame.origin.y + sibling.frame.size.height / 2
            )
            
            let distance = hypot(elementCenter.x - siblingCenter.x, elementCenter.y - siblingCenter.y)
            return distance <= maxDistance
        }.sorted { sibling1, sibling2 in
            let center1 = NSPoint(
                x: sibling1.frame.origin.x + sibling1.frame.size.width / 2,
                y: sibling1.frame.origin.y + sibling1.frame.size.height / 2
            )
            let center2 = NSPoint(
                x: sibling2.frame.origin.x + sibling2.frame.size.width / 2,
                y: sibling2.frame.origin.y + sibling2.frame.size.height / 2
            )
            
            let distance1 = hypot(elementCenter.x - center1.x, elementCenter.y - center1.y)
            let distance2 = hypot(elementCenter.x - center2.x, elementCenter.y - center2.y)
            
            return distance1 < distance2
        }
        
        return filteredByDistance.isEmpty ? nil : filteredByDistance
    }
    
    // MARK: - Helper Methods for comparing identifiers and titles
    
    /// Check if two identifiers are related (share common prefix/suffix or pattern)
    private func areIdentifiersRelated(_ id1: String, _ id2: String) -> Bool {
        // Common prefix (e.g., "login_username" and "login_password")
        let commonPrefixLength = min(id1.count, id2.count) / 2
        if commonPrefixLength > 3 {
            let prefix1 = id1.prefix(commonPrefixLength)
            let prefix2 = id2.prefix(commonPrefixLength)
            if prefix1 == prefix2 {
                return true
            }
        }
        
        // Common suffix (e.g., "username_field" and "password_field")
        let commonSuffixLength = min(id1.count, id2.count) / 2
        if commonSuffixLength > 3 {
            let suffix1 = id1.suffix(commonSuffixLength)
            let suffix2 = id2.suffix(commonSuffixLength)
            if suffix1 == suffix2 {
                return true
            }
        }
        
        // Pattern matching (e.g., "btn_1" and "btn_2" or "field1" and "field2")
        let pattern = #"^([a-z]+)([0-9]+)$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        
        if let regex = regex,
           let match1 = regex.firstMatch(in: id1, options: [], range: NSRange(location: 0, length: id1.count)),
           let match2 = regex.firstMatch(in: id2, options: [], range: NSRange(location: 0, length: id2.count)),
           match1.numberOfRanges > 1 && match2.numberOfRanges > 1 {
            
            let prefix1Range = match1.range(at: 1)
            let prefix2Range = match2.range(at: 1)
            
            if let prefixRange1 = Range(prefix1Range, in: id1),
               let prefixRange2 = Range(prefix2Range, in: id2) {
                let prefix1 = id1[prefixRange1]
                let prefix2 = id2[prefixRange2]
                
                if prefix1 == prefix2 {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if two titles suggest a relationship (similar patterns or common terms)
    private func areTitlesRelated(_ title1: String, _ title2: String) -> Bool {
        // If either is contained within the other (e.g., "Email" and "Email Address")
        if title1.contains(title2) || title2.contains(title1) {
            return true
        }
        
        // Look for common terms that suggest relationship (e.g., "First Name" and "Last Name")
        let relatedTermPairs = [
            ["first", "last"],
            ["name", "email"],
            ["username", "password"],
            ["start", "end"],
            ["min", "max"],
            ["open", "close"],
            ["save", "cancel"],
            ["accept", "decline"],
            ["on", "off"],
            ["yes", "no"]
        ]
        
        let lowercaseTitle1 = title1.lowercased()
        let lowercaseTitle2 = title2.lowercased()
        
        for pair in relatedTermPairs {
            if (lowercaseTitle1.contains(pair[0]) && lowercaseTitle2.contains(pair[1])) ||
               (lowercaseTitle1.contains(pair[1]) && lowercaseTitle2.contains(pair[0])) {
                return true
            }
        }
        
        return false
    }
} 
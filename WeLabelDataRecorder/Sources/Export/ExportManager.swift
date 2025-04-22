import Foundation
import AppKit

class ExportManager {
    // Export a session to JSON format
    func exportToJSON(_ session: RecordingSession, to directory: URL) -> URL? {
        // Create metadata for the session
        let metadata = SessionMetadata(
            id: session.id,
            startTime: session.startTime,
            endTime: session.endTime ?? Date(),
            interactionCount: session.interactions.count,
            screenshotCount: countScreenshots(in: session)
        )
        
        // Create export directory
        let exportDir = directory.appendingPathComponent(session.id, isDirectory: true)
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        // Create screenshots directory
        let screenshotsDir = exportDir.appendingPathComponent("screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        
        // Export metadata
        let metadataURL = exportDir.appendingPathComponent("metadata.json")
        if !saveJSONToFile(metadata, to: metadataURL) {
            print("Failed to save metadata")
            return nil
        }
        
        // Export interactions
        let interactionsURL = exportDir.appendingPathComponent("interactions.json")
        if !exportInteractions(session, to: interactionsURL) {
            print("Failed to export interactions")
            return nil
        }
        
        // Copy screenshots
        if !copyScreenshots(from: session, to: screenshotsDir) {
            print("Failed to copy screenshots")
            return nil
        }
        
        return exportDir
    }
    
    // Export to COCO format (Common Objects in Context) - used for computer vision
    func exportToCOCO(_ session: RecordingSession, to directory: URL) -> URL? {
        // TODO: Implement COCO format export
        return nil
    }
    
    // Export to YOLO format (You Only Look Once) - used for object detection
    func exportToYOLO(_ session: RecordingSession, to directory: URL) -> URL? {
        // TODO: Implement YOLO format export
        return nil
    }
    
    // Create a ZIP archive of the exported data
    func createZIPArchive(from directory: URL) -> URL? {
        // TODO: Implement ZIP archiving
        return nil
    }
    
    // MARK: - Helper methods
    
    private func countScreenshots(in session: RecordingSession) -> Int {
        var count = 0
        
        for interaction in session.interactions {
            if interaction.decodeAsScreenshot() != nil {
                count += 1
            }
        }
        
        return count
    }
    
    private func exportInteractions(_ session: RecordingSession, to fileURL: URL) -> Bool {
        // Convert interactions to a format that can be serialized
        var interactionsData: [[String: Any]] = []
        
        for interaction in session.interactions {
            // Use type-safe decoding methods
            if let mouseClick = interaction.decodeAsMouseClick() {
                let data: [String: Any] = [
                    "type": "mouseClick",
                    "timestamp": mouseClick.timestamp.timeIntervalSince1970,
                    "x": mouseClick.position.x,
                    "y": mouseClick.position.y,
                    "button": mouseClick.button.rawValue,
                    "clickCount": mouseClick.clickCount
                ]
                interactionsData.append(data)
            } else if let mouseMove = interaction.decodeAsMouseMove() {
                let data: [String: Any] = [
                    "type": "mouseMove",
                    "timestamp": mouseMove.timestamp.timeIntervalSince1970,
                    "fromX": mouseMove.fromPosition.x,
                    "fromY": mouseMove.fromPosition.y,
                    "toX": mouseMove.toPosition.x,
                    "toY": mouseMove.toPosition.y
                ]
                interactionsData.append(data)
            } else if let mouseScroll = interaction.decodeAsMouseScroll() {
                let data: [String: Any] = [
                    "type": "mouseScroll",
                    "timestamp": mouseScroll.timestamp.timeIntervalSince1970,
                    "x": mouseScroll.position.x,
                    "y": mouseScroll.position.y,
                    "deltaX": mouseScroll.deltaX,
                    "deltaY": mouseScroll.deltaY
                ]
                interactionsData.append(data)
            } else if let key = interaction.decodeAsKeyInteraction() {
                let data: [String: Any] = [
                    "type": key.interactionType == .keyDown ? "keyDown" : "keyUp",
                    "timestamp": key.timestamp.timeIntervalSince1970,
                    "keyCode": key.keyCode,
                    "characters": key.characters ?? "",
                    "modifiers": key.modifiers.rawValue
                ]
                interactionsData.append(data)
            } else if let screenshot = interaction.decodeAsScreenshot() {
                let data: [String: Any] = [
                    "type": "screenshot",
                    "timestamp": screenshot.timestamp.timeIntervalSince1970,
                    "filename": screenshot.imageFileName,
                    "width": screenshot.screenBounds.width,
                    "height": screenshot.screenBounds.height
                ]
                interactionsData.append(data)
            } else if let uiElement = interaction.decodeAsUIElement() {
                // Add UI element interaction export
                let data: [String: Any] = [
                    "type": "uiElement",
                    "timestamp": uiElement.timestamp.timeIntervalSince1970,
                    "action": uiElement.interactionAction.rawValue,
                    "x": uiElement.position.x,
                    "y": uiElement.position.y,
                    "elementRole": uiElement.elementInfo.role,
                    "elementTitle": uiElement.elementInfo.title ?? ""
                ]
                interactionsData.append(data)
            } else if let interactionType = interaction.interactionType {
                print("WARNING: Unknown interaction type: \(interactionType)")
            } else {
                print("WARNING: Could not determine interaction type")
            }
        }
        
        // Convert to JSON and save
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: interactionsData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            return true
        } catch {
            print("Error exporting interactions: \(error)")
            return false
        }
    }
    
    private func saveJSONToFile<T: Encodable>(_ object: T, to fileURL: URL) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(object)
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving JSON: \(error)")
            return false
        }
    }
    
    private func copyScreenshots(from session: RecordingSession, to directory: URL) -> Bool {
        // Get document directory where screenshots are stored
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let screenshotsSourceDir = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Screenshots", isDirectory: true)
        
        // Track which files we've already copied to avoid duplicates
        var copiedFiles = Set<String>()
        
        // Copy each screenshot referenced in the session
        for interaction in session.interactions {
            if let screenshot = interaction.decodeAsScreenshot() {
                let fileName = screenshot.imageFileName
                
                // Skip if we've already copied this file
                if copiedFiles.contains(fileName) {
                    print("Skipping duplicate screenshot: \(fileName)")
                    continue
                }
                
                let sourceURL = screenshotsSourceDir.appendingPathComponent(fileName)
                let destinationURL = directory.appendingPathComponent(fileName)
                
                do {
                    // Check if destination file exists and remove it first to avoid conflicts
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                    
                    // Mark this file as copied
                    copiedFiles.insert(fileName)
                    print("Successfully copied screenshot: \(fileName)")
                } catch {
                    print("Error copying screenshot \(fileName): \(error)")
                    // Continue with other screenshots
                }
            }
        }
        
        return true
    }
}

// Session metadata for export
struct SessionMetadata: Codable {
    let id: String
    let startTime: Date
    let endTime: Date
    let interactionCount: Int
    let screenshotCount: Int
    let exportDate: Date = Date()
    let version: String = "1.0"
    
    // Add CodingKeys to handle properties with default values
    enum CodingKeys: String, CodingKey {
        case id
        case startTime
        case endTime
        case interactionCount
        case screenshotCount
        case exportDate
        case version
    }
} 
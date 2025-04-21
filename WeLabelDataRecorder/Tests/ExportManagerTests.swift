import XCTest
import AppKit
@testable import WeLabelDataRecorder

final class ExportManagerTests: XCTestCase {
    
    var exportManager: ExportManager!
    var testSession: RecordingSession!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        exportManager = ExportManager()
        
        // Create a test session with some interactions
        testSession = RecordingSession(id: "test-session-\(UUID().uuidString)", startTime: Date())
        
        // Add some sample interactions
        let clickInteraction = MouseClickInteraction(
            timestamp: Date(),
            position: NSPoint(x: 100, y: 200),
            button: .left,
            clickCount: 1
        )
        testSession.addInteraction(clickInteraction)
        
        let keyInteraction = KeyInteraction(
            timestamp: Date(),
            isKeyDown: true,
            keyCode: 36, // Return key
            characters: "\r",
            modifiers: []
        )
        testSession.addInteraction(keyInteraction)
        
        // Set end time for the session
        testSession.endTime = Date()
        
        // Create a temporary directory for export testing
        let fileManager = FileManager.default
        let systemTempDir = fileManager.temporaryDirectory
        tempDirectory = systemTempDir.appendingPathComponent("WeLabelDataRecorderTests", isDirectory: true)
        
        try? fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        exportManager = nil
        testSession = nil
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDirectory)
        
        super.tearDown()
    }
    
    func testExportToJSON() {
        // Export the test session
        let exportURL = exportManager.exportToJSON(testSession, to: tempDirectory)
        
        // Verify that the export directory was created
        XCTAssertNotNil(exportURL)
        
        if let exportURL = exportURL {
            // Check if metadata file exists
            let metadataURL = exportURL.appendingPathComponent("metadata.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: metadataURL.path))
            
            // Check if interactions file exists
            let interactionsURL = exportURL.appendingPathComponent("interactions.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: interactionsURL.path))
            
            // Check if screenshots directory exists
            let screenshotsURL = exportURL.appendingPathComponent("screenshots", isDirectory: true)
            XCTAssertTrue(FileManager.default.fileExists(atPath: screenshotsURL.path))
            
            // Verify metadata content
            do {
                let metadataData = try Data(contentsOf: metadataURL)
                let decoder = JSONDecoder()
                let metadata = try decoder.decode(SessionMetadata.self, from: metadataData)
                
                XCTAssertEqual(metadata.id, testSession.id)
                XCTAssertEqual(metadata.interactionCount, testSession.interactions.count)
            } catch {
                XCTFail("Failed to read or decode metadata: \(error)")
            }
            
            // Verify interactions content
            do {
                let interactionsData = try Data(contentsOf: interactionsURL)
                let json = try JSONSerialization.jsonObject(with: interactionsData) as? [[String: Any]]
                
                XCTAssertNotNil(json)
                XCTAssertEqual(json?.count, testSession.interactions.count)
                
                // Verify the types of interactions
                if let interactions = json {
                    let types = interactions.compactMap { $0["type"] as? String }
                    XCTAssertTrue(types.contains("mouseClick"))
                    XCTAssertTrue(types.contains("keyDown"))
                }
            } catch {
                XCTFail("Failed to read or decode interactions: \(error)")
            }
        }
    }
} 
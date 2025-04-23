import XCTest
@testable import WeLabelDataRecorder

class InteractionContextTests: XCTestCase {
    
    func testInteractionContextCodable() {
        // Створення тестових даних
        let timestamp = Date()
        let position = NSPoint(x: 100, y: 100)
        
        // Створення MouseClickInteraction для тесту
        let clickInteraction = MouseClickInteraction(
            timestamp: timestamp,
            position: position,
            button: .left,
            clickCount: 1
        )
        
        // Створення тестових URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let beforeScreenshotURL = documentsDirectory.appendingPathComponent("before.png")
        let afterScreenshotURL = documentsDirectory.appendingPathComponent("after.png")
        
        // Створення InteractionContext
        let context = InteractionContext(
            beforeScreenshotURL: beforeScreenshotURL,
            interaction: clickInteraction,
            afterScreenshotURL: afterScreenshotURL
        )
        
        // Тест кодування
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(context)
            
            // Декодування
            let decoder = JSONDecoder()
            let decodedContext = try decoder.decode(InteractionContext.self, from: data)
            
            // Перевірка результатів
            XCTAssertEqual(decodedContext.beforeScreenshotURL.lastPathComponent, beforeScreenshotURL.lastPathComponent)
            XCTAssertEqual(decodedContext.afterScreenshotURL.lastPathComponent, afterScreenshotURL.lastPathComponent)
            
            // Перевірка декодування взаємодії
            guard let decodedClick = decodedContext.interaction as? MouseClickInteraction else {
                XCTFail("Expected MouseClickInteraction, but got different type")
                return
            }
            
            XCTAssertEqual(decodedClick.interactionType, .mouseClick)
            XCTAssertEqual(decodedClick.position.x, position.x)
            XCTAssertEqual(decodedClick.position.y, position.y)
            XCTAssertEqual(decodedClick.button, .left)
            XCTAssertEqual(decodedClick.clickCount, 1)
            
        } catch {
            XCTFail("Failed to encode/decode InteractionContext: \(error)")
        }
    }
} 
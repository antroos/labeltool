import XCTest
import AppKit
@testable import WeLabelDataRecorder

final class SessionManagerTests: XCTestCase {
    
    var sessionManager: SessionManager!
    
    override func setUp() {
        super.setUp()
        sessionManager = SessionManager()
    }
    
    override func tearDown() {
        sessionManager = nil
        super.tearDown()
    }
    
    func testStartNewSession() {
        // Verify there is no current session initially
        XCTAssertNil(SessionManager.shared.currentSession)
        
        // Start a new session
        let session = SessionManager.shared.startNewSession()
        
        // Verify the session was created with correct properties
        XCTAssertNotNil(session)
        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.interactions.count, 0)
        
        // Verify the current session is set
        XCTAssertNotNil(SessionManager.shared.currentSession)
        XCTAssertEqual(SessionManager.shared.currentSession?.id, session.id)
    }
    
    func testEndCurrentSession() {
        // Start a new session
        let session = SessionManager.shared.startNewSession()
        
        // End the session
        let endedSession = SessionManager.shared.endCurrentSession()
        
        // Verify the session was ended correctly
        XCTAssertNotNil(endedSession)
        XCTAssertEqual(endedSession?.id, session.id)
        XCTAssertNotNil(endedSession?.endTime)
        
        // Verify the current session is cleared
        XCTAssertNil(SessionManager.shared.currentSession)
    }
    
    func testEndNonExistentSession() {
        // Verify ending a non-existent session returns nil
        XCTAssertNil(SessionManager.shared.currentSession)
        XCTAssertNil(SessionManager.shared.endCurrentSession())
    }
    
    func testAddInteractionToSession() {
        // Start a new session
        let session = SessionManager.shared.startNewSession()
        
        // Create a mouse click interaction
        let timestamp = Date()
        let interaction = MouseClickInteraction(
            timestamp: timestamp,
            position: NSPoint(x: 100, y: 200),
            button: .left,
            clickCount: 1
        )
        
        // Add the interaction to the session
        session.addInteraction(interaction)
        
        // Verify the interaction was added
        XCTAssertEqual(session.interactions.count, 1)
    }
    
    func testMultipleInteractionsInSession() {
        // Start a new session
        let session = SessionManager.shared.startNewSession()
        
        // Add different types of interactions
        session.addInteraction(MouseClickInteraction(
            timestamp: Date(),
            position: NSPoint(x: 100, y: 200),
            button: .left,
            clickCount: 1
        ))
        
        session.addInteraction(MouseMoveInteraction(
            timestamp: Date(),
            fromPosition: NSPoint(x: 100, y: 200),
            toPosition: NSPoint(x: 300, y: 400)
        ))
        
        session.addInteraction(KeyInteraction(
            timestamp: Date(),
            isKeyDown: true,
            keyCode: 13,
            characters: "\r",
            modifiers: []
        ))
        
        // Verify all interactions were added
        XCTAssertEqual(session.interactions.count, 3)
    }
} 
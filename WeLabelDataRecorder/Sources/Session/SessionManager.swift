import Foundation

// Manages the recording session, stores data and handles export
class SessionManager {
    static let shared = SessionManager()
    
    // Current recording session
    private(set) var currentSession: RecordingSession?
    
    // Start a new recording session
    func startNewSession() -> RecordingSession {
        // Create a new session
        let session = RecordingSession(id: UUID().uuidString, startTime: Date())
        currentSession = session
        print("Session started: \(session.id)")
        return session
    }
    
    // End the current session
    func endCurrentSession() -> RecordingSession? {
        guard let session = currentSession else {
            return nil
        }
        
        session.endTime = Date()
        print("Session ended: \(session.id)")
        
        // Save the session
        saveSession(session)
        
        // Clear current session
        currentSession = nil
        
        return session
    }
    
    // Save a session to disk
    private func saveSession(_ session: RecordingSession) {
        // TODO: Implement actual saving to disk
        print("Saving session \(session.id) with \(session.interactions.count) interactions")
    }
    
    // Get all saved sessions
    func getAllSessions() -> [RecordingSession] {
        // TODO: Implement actual loading from disk
        return []
    }
    
    // Get a specific session by ID
    func getSession(by id: String) -> RecordingSession? {
        // TODO: Implement actual loading from disk
        return nil
    }
    
    // Export a session to a specific format
    func exportSession(_ session: RecordingSession, format: ExportFormat, destination: URL) -> Bool {
        // TODO: Implement actual export
        print("Exporting session \(session.id) to \(format.rawValue) format at \(destination.path)")
        return true
    }
}

// Recording session model
class RecordingSession: Codable {
    let id: String
    let startTime: Date
    var endTime: Date?
    var interactions: [AnyInteraction] = []
    
    init(id: String, startTime: Date) {
        self.id = id
        self.startTime = startTime
    }
    
    // Add an interaction to the session
    func addInteraction<T: UserInteraction & Codable>(_ interaction: T) {
        let anyInteraction = AnyInteraction(interaction)
        interactions.append(anyInteraction)
    }
}

// Type eraser for UserInteraction protocol
struct AnyInteraction: Codable {
    private let _data: Data
    private let _type: String
    
    init<T: UserInteraction & Codable>(_ interaction: T) {
        self._type = String(describing: type(of: interaction))
        self._data = try! JSONEncoder().encode(interaction)
    }
    
    // Decode back to the original type (if possible)
    func decode<T: UserInteraction & Codable>() -> T? {
        return try? JSONDecoder().decode(T.self, from: _data)
    }
}

// Export formats supported by the application
enum ExportFormat: String, Codable {
    case json
    case coco
    case yolo
    case custom
} 
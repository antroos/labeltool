import Foundation

// Manages the recording session, stores data and handles export
class SessionManager {
    static let shared = SessionManager()
    
    // Current recording session
    private(set) var currentSession: RecordingSession?
    
    // Last completed session
    private(set) var lastSession: RecordingSession?
    
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
            print("SessionManager: No current session to end")
            return nil
        }
        
        session.endTime = Date()
        print("SessionManager: Session ended: \(session.id) with \(session.interactions.count) interactions")
        
        // Save the session
        saveSession(session)
        
        // Keep reference to the last session
        lastSession = session
        print("SessionManager: Last session reference set to \(session.id)")
        
        // Clear current session
        currentSession = nil
        
        return session
    }
    
    // Save a session to disk
    private func saveSession(_ session: RecordingSession) {
        print("Saving session \(session.id) with \(session.interactions.count) interactions")
        
        // Create a dictionary representation of the session
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory")
                return
            }
            
            // Create sessions directory if it doesn't exist
            let sessionsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Sessions", isDirectory: true)
            try FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
            
            // Create a file for this session
            let sessionFile = sessionsDirectory.appendingPathComponent("\(session.id).json")
            
            // Encode the session
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(session)
            
            // Write to disk
            try data.write(to: sessionFile)
            print("Successfully saved session to: \(sessionFile.path)")
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    // Get all saved sessions
    func getAllSessions() -> [RecordingSession] {
        // Return the last session if available
        if let lastSession = lastSession {
            print("SessionManager: Using cached lastSession \(lastSession.id) with \(lastSession.interactions.count) interactions")
            return [lastSession]
        } else {
            print("SessionManager: No cached lastSession available")
        }
        
        // Try to load sessions from disk
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory")
                return []
            }
            
            // Get the sessions directory
            let sessionsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Sessions", isDirectory: true)
            
            // Check if directory exists
            if !FileManager.default.fileExists(atPath: sessionsDirectory.path) {
                print("Sessions directory doesn't exist yet")
                return []
            }
            
            // Get all session files
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: sessionsDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
            
            var sessions: [RecordingSession] = []
            
            // Load each session
            for fileURL in fileURLs {
                let data = try Data(contentsOf: fileURL)
                let session = try JSONDecoder().decode(RecordingSession.self, from: data)
                sessions.append(session)
            }
            
            print("Loaded \(sessions.count) sessions from disk")
            return sessions
        } catch {
            print("Error loading sessions: \(error)")
            return []
        }
    }
    
    // Get a specific session by ID
    func getSession(by id: String) -> RecordingSession? {
        // Check if it's the current session
        if let current = currentSession, current.id == id {
            return current
        }
        
        // Check if it's the last session
        if let last = lastSession, last.id == id {
            return last
        }
        
        // Try to load from disk
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            // Get the session file path
            let sessionFile = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Sessions/\(id).json")
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: sessionFile.path) {
                return nil
            }
            
            // Load and decode the session
            let data = try Data(contentsOf: sessionFile)
            let session = try JSONDecoder().decode(RecordingSession.self, from: data)
            return session
        } catch {
            print("Error loading session \(id): \(error)")
            return nil
        }
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
        
        do {
            self._data = try JSONEncoder().encode(interaction)
        } catch {
            print("ERROR encoding interaction: \(error)")
            // Fallback: создаем пустой Data объект
            self._data = Data()
        }
    }
    
    // Get the interaction type stored in this container
    var interactionType: String {
        return _type
    }
    
    // Check if this interaction is of a specific type before trying to decode
    func isType<T: UserInteraction & Codable>(_ type: T.Type) -> Bool {
        return self._type == String(describing: type)
    }
    
    // Decode back to the original type (if possible)
    func decode<T: UserInteraction & Codable>() -> T? {
        // Only attempt to decode if the stored type matches the requested type
        if !isType(T.self) {
            // Types don't match, return nil without attempting decode
            return nil
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: _data)
        } catch {
            print("ERROR decoding interaction of type \(_type) to \(T.self): \(error)")
            return nil
        }
    }
    
    // Decode to a specific type only if the type matches
    func decodeIfType<T: UserInteraction & Codable>(_ type: T.Type) -> T? {
        guard isType(type) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: _data)
        } catch {
            print("ERROR decoding interaction of type \(_type): \(error)")
            return nil
        }
    }
}

// Export formats supported by the application
enum ExportFormat: String, Codable {
    case json
    case coco
    case yolo
    case custom
} 
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
            
            // Проверка типов взаимодействий перед сохранением
            print("DEBUG SAVE: Session contains \(session.interactions.count) interactions:")
            for (index, interaction) in session.interactions.enumerated() {
                if let type = interaction.interactionType {
                    print("DEBUG SAVE: Interaction \(index): type=\(type)")
                } else {
                    print("DEBUG SAVE: Interaction \(index): type=UNKNOWN")
                }
            }
            
            let data = try encoder.encode(session)
            
            // DEBUG: Print first 200 chars of encoded session
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG SAVE: First 200 chars of encoded session: \(jsonString.prefix(200))")
            }
            
            // Write to disk
            try data.write(to: sessionFile)
            print("Successfully saved session to: \(sessionFile.path)")
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    // Get all saved sessions
    func getAllSessions() -> [RecordingSession] {
        var allSessions: [RecordingSession] = []
        
        // First load sessions from disk
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory")
                
                // Return last session from cache if available
                if let lastSession = lastSession {
                    print("SessionManager: Returning cached lastSession \(lastSession.id) with \(lastSession.interactions.count) interactions")
                    return [lastSession]
                }
                
                return []
            }
            
            // Get the sessions directory
            let sessionsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Sessions", isDirectory: true)
            
            // Check if directory exists
            if !FileManager.default.fileExists(atPath: sessionsDirectory.path) {
                print("Sessions directory doesn't exist yet")
                
                // Return last session from cache if available
                if let lastSession = lastSession {
                    print("SessionManager: Returning cached lastSession \(lastSession.id) with \(lastSession.interactions.count) interactions")
                    return [lastSession]
                }
                
                return []
            }
            
            // Get all session files
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: sessionsDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
            
            print("DEBUG: Found \(fileURLs.count) session files")
            for fileURL in fileURLs {
                print("DEBUG: Found session file: \(fileURL.lastPathComponent)")
            }
            
            // Load each session
            for fileURL in fileURLs {
                print("DEBUG: Loading session from \(fileURL.lastPathComponent)")
                let data = try Data(contentsOf: fileURL)
                
                // Print what we're about to decode
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("DEBUG: First 100 chars of JSON: \(String(jsonStr.prefix(100)))")
                }
                
                let decoder = JSONDecoder()
                do {
                    let session = try decoder.decode(RecordingSession.self, from: data)
                    print("DEBUG: Successfully decoded session \(session.id) with \(session.interactions.count) interactions")
                    allSessions.append(session)
                } catch {
                    print("ERROR decoding session from \(fileURL.lastPathComponent): \(error)")
                }
            }
            
            print("Loaded \(allSessions.count) sessions from disk")
        } catch {
            print("Error loading sessions: \(error)")
        }
        
        // Add the current cached session if it's not already in the list
        if let lastSession = lastSession {
            print("SessionManager: Checking if cached lastSession \(lastSession.id) should be added")
            
            // Check if this session is already loaded from disk
            let sessionExists = allSessions.contains { $0.id == lastSession.id }
            
            if !sessionExists {
                print("SessionManager: Adding cached lastSession \(lastSession.id) to the list")
                allSessions.append(lastSession)
            } else {
                print("SessionManager: Session \(lastSession.id) already exists in the list")
            }
        }
        
        // Sort sessions by start time (newest first)
        allSessions.sort { $0.startTime > $1.startTime }
        
        return allSessions
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
        print("DEBUG: Adding interaction of type \(type(of: interaction)), interactionType: \(interaction.interactionType)")
        let anyInteraction = AnyInteraction(interaction)
        interactions.append(anyInteraction)
    }
}

// Type eraser for UserInteraction protocol
struct AnyInteraction: Codable {
    private let _data: Data
    private let _interactionTypeValue: String
    
    init<T: UserInteraction & Codable>(_ interaction: T) {
        self._interactionTypeValue = interaction.interactionType.rawValue
        
        do {
            self._data = try JSONEncoder().encode(interaction)
        } catch {
            print("ERROR encoding interaction: \(error)")
            // Fallback: создаем пустой Data объект
            self._data = Data()
        }
    }
    
    // Get the stored interaction type
    var interactionType: InteractionType? {
        return InteractionType(rawValue: _interactionTypeValue)
    }
    
    // MARK: - Custom Codable implementation
    
    // These keys must match with the keys used in Codable of all interaction types
    enum CodingKeys: String, CodingKey {
        case _data = "data"
        case _interactionTypeValue = "type"
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_data, forKey: ._data)
        try container.encode(_interactionTypeValue, forKey: ._interactionTypeValue)
    }
    
    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _data = try container.decode(Data.self, forKey: ._data)
        _interactionTypeValue = try container.decode(String.self, forKey: ._interactionTypeValue)
    }
    
    // MARK: - Type-safe decoding methods
    
    // Пытается декодировать взаимодействие определенного типа, только если совпадает хранимый тип
    func decodeAsMouseClick() -> MouseClickInteraction? {
        guard interactionType == .mouseClick else { return nil }
        
        do {
            return try JSONDecoder().decode(MouseClickInteraction.self, from: _data)
        } catch {
            print("ERROR decoding MouseClickInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsMouseMove() -> MouseMoveInteraction? {
        guard interactionType == .mouseMove else { return nil }
        
        do {
            return try JSONDecoder().decode(MouseMoveInteraction.self, from: _data)
        } catch {
            print("ERROR decoding MouseMoveInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsMouseScroll() -> MouseScrollInteraction? {
        guard interactionType == .mouseScroll else { return nil }
        
        do {
            return try JSONDecoder().decode(MouseScrollInteraction.self, from: _data)
        } catch {
            print("ERROR decoding MouseScrollInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsKeyInteraction() -> KeyInteraction? {
        guard interactionType == .keyDown || interactionType == .keyUp else { return nil }
        
        do {
            return try JSONDecoder().decode(KeyInteraction.self, from: _data)
        } catch {
            print("ERROR decoding KeyInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsScreenshot() -> ScreenshotInteraction? {
        guard interactionType == .screenshot else { 
            // Не выводим ошибку здесь, т.к. это нормальная ситуация при переборе типов
            return nil 
        }
        
        do {
            return try JSONDecoder().decode(ScreenshotInteraction.self, from: _data)
        } catch {
            print("ERROR decoding ScreenshotInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsUIElement() -> UIElementInteraction? {
        guard interactionType == .uiElement else { return nil }
        
        do {
            return try JSONDecoder().decode(UIElementInteraction.self, from: _data)
        } catch {
            print("ERROR decoding UIElementInteraction: \(error)")
            return nil
        }
    }
    
    // MARK: - Legacy methods

    // Небезопасный метод, оставлен для обратной совместимости
    // DEPRECATED: This will be removed in future versions
    func decode<T: UserInteraction & Codable>() -> T? {
        // Полностью отключаем этот небезопасный метод, всегда возвращая nil
        print("WARNING: Legacy decode method called - this is deprecated")
        return nil
    }
    
    // Безопасная версия decode, оставлена для обратной совместимости
    func decodeIfType<T: UserInteraction & Codable>(_ type: T.Type) -> T? {
        guard let interactionType = self.interactionType else { return nil }
        
        let typeName = String(describing: type)
        var typeMatches = false
        
        if typeName == "MouseClickInteraction" && interactionType == .mouseClick {
            typeMatches = true
        } else if typeName == "MouseMoveInteraction" && interactionType == .mouseMove {
            typeMatches = true
        } else if typeName == "MouseScrollInteraction" && interactionType == .mouseScroll {
            typeMatches = true
        } else if typeName == "KeyInteraction" && (interactionType == .keyDown || interactionType == .keyUp) {
            typeMatches = true
        } else if typeName == "ScreenshotInteraction" && interactionType == .screenshot {
            typeMatches = true
        } else if typeName == "UIElementInteraction" && interactionType == .uiElement {
            typeMatches = true
        }
        
        if typeMatches {
            do {
                return try JSONDecoder().decode(type, from: _data)
            } catch {
                print("ERROR decoding validated interaction: \(error)")
                return nil
            }
        } else {
            // Не выводим это сообщение, т.к. оно спамит лог при переборе типов
            // print("Type mismatch: trying to decode \(typeName) but actual type is \(interactionType)")
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
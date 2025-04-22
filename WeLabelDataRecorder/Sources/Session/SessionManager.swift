import Foundation

// Manages the recording session, stores data and handles export
class SessionManager {
    static let shared = SessionManager()
    
    // Current recording session
    private(set) var currentSession: RecordingSession?
    
    // Last completed session
    private(set) var lastSession: RecordingSession?
    
    // Current project
    private(set) var currentProject: Project?
    
    // All projects
    private(set) var projects: [Project] = []
    
    // Start a new project
    func createNewProject(name: String, description: String) -> Project {
        // Create a new project
        let project = Project(name: name, description: description)
        currentProject = project
        projects.append(project)
        
        print("Project created: \(project.id)")
        
        // Save the project to disk
        saveProject(project)
        
        return project
    }
    
    // Get the current project or create a default one if none exists
    func getCurrentProject() -> Project {
        if let project = currentProject {
            return project
        }
        
        // If there's no current project, create a default one
        return createNewProject(name: "Untitled Project", description: "Created automatically")
    }
    
    // Start a new recording session
    func startNewSession() -> RecordingSession {
        // Make sure we have a project
        let project = getCurrentProject()
        
        // Create a new session
        let session = RecordingSession(id: UUID().uuidString, startTime: Date(), projectId: project.id)
        currentSession = session
        print("Session started: \(session.id)")
        
        // Add session to project
        project.addSession(session)
        
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
        
        // Save the project since it now has a completed session
        if let projectId = session.projectId, let project = findProject(by: projectId) {
            saveProject(project)
        }
        
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
    
    // Save a project to disk
    private func saveProject(_ project: Project) {
        print("Saving project \(project.id) with \(project.sessions.count) sessions")
        
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory")
                return
            }
            
            // Create projects directory if it doesn't exist
            let projectsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Projects", isDirectory: true)
            try FileManager.default.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
            
            // Create a file for this project
            let projectFile = projectsDirectory.appendingPathComponent("\(project.id).json")
            
            // Encode the project
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(project)
            
            // Write to disk
            try data.write(to: projectFile)
            print("Successfully saved project to: \(projectFile.path)")
        } catch {
            print("Error saving project: \(error)")
        }
    }
    
    // Find a project by ID
    func findProject(by id: String) -> Project? {
        // Check if it's the current project
        if let current = currentProject, current.id == id {
            return current
        }
        
        // Check projects array
        if let project = projects.first(where: { $0.id == id }) {
            return project
        }
        
        // Try to load from disk
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            // Get the project file path
            let projectFile = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Projects/\(id).json")
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: projectFile.path) {
                return nil
            }
            
            // Load and decode the project
            let data = try Data(contentsOf: projectFile)
            let project = try JSONDecoder().decode(Project.self, from: data)
            
            // Add to projects array for future reference
            projects.append(project)
            
            return project
        } catch {
            print("Error loading project \(id): \(error)")
            return nil
        }
    }
    
    // Get all projects
    func getAllProjects() -> [Project] {
        var allProjects: [Project] = []
        
        // First add any projects we already have in memory
        allProjects.append(contentsOf: projects)
        
        // Then try to load additional projects from disk
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory")
                return allProjects
            }
            
            // Get the projects directory
            let projectsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Projects", isDirectory: true)
            
            // Check if directory exists
            if !FileManager.default.fileExists(atPath: projectsDirectory.path) {
                print("Projects directory doesn't exist yet")
                return allProjects
            }
            
            // Get all project files
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: projectsDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
            
            print("DEBUG: Found \(fileURLs.count) project files")
            
            // Load each project
            for fileURL in fileURLs {
                let data = try Data(contentsOf: fileURL)
                
                do {
                    let project = try JSONDecoder().decode(Project.self, from: data)
                    
                    // Check if we already have this project in memory
                    if !allProjects.contains(where: { $0.id == project.id }) {
                        allProjects.append(project)
                    }
                } catch {
                    print("ERROR decoding project from \(fileURL.lastPathComponent): \(error)")
                }
            }
            
        } catch {
            print("Error loading projects: \(error)")
        }
        
        // Sort by creation date (newest first)
        allProjects.sort { $0.creationDate > $1.creationDate }
        
        return allProjects
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

// Project model for grouping recording sessions
class Project: Codable {
    let id: String
    let name: String
    let description: String
    let creationDate: Date
    var sessions: [RecordingSession] = []
    
    init(id: String = UUID().uuidString, name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
        self.creationDate = Date()
    }
    
    // Add a session to this project
    func addSession(_ session: RecordingSession) {
        sessions.append(session)
        // Update session's projectId
        session.projectId = id
    }
}

// Recording session model
class RecordingSession: Codable {
    let id: String
    let startTime: Date
    var endTime: Date?
    var interactions: [AnyInteraction] = []
    var projectId: String?
    
    init(id: String, startTime: Date, projectId: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.projectId = projectId
    }
    
    // MARK: - Custom Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id
        case startTime
        case endTime
        case interactions
        case projectId
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(interactions, forKey: .interactions) // Uses AnyInteraction's encode
        try container.encodeIfPresent(projectId, forKey: .projectId)
    }
    
    // Custom decoding
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        interactions = try container.decode([AnyInteraction].self, forKey: .interactions) // Uses AnyInteraction's init(from:)
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
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
    
    // Дополнительный безопасный метод декодирования, который не печатает ошибки
    func silentTryDecode<T: UserInteraction & Codable>(_ type: T.Type) -> T? {
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
                // Не отображаем ошибки в логах, чтобы не спамить их
                return nil
            }
        } else {
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
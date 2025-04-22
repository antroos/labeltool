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
        print("Session started: \(session.id) for project \(project.id)")
        
        // Add session ID to project
        project.addSessionID(session.id)
        // Note: We might need to save the project here if sessionIDs are persisted
        // saveProject(project) // Uncomment if project saving is desired immediately
        
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
        
        // 1. Prepare main session info dictionary
        var sessionInfo: [String: Any] = [
            "id": session.id,
            "startTime": session.startTime.timeIntervalSince1970 // Store dates as timestamps
        ]
        if let endTime = session.endTime {
            sessionInfo["endTime"] = endTime.timeIntervalSince1970
        }
        if let projectId = session.projectId {
            sessionInfo["projectId"] = projectId
        }

        // 2. Prepare interactions data array
        var interactionsToSave: [[String: String]] = []
        let interactionData = session.internalInteractionData
        let interactionTypes = session.internalInteractionTypes
        
        guard interactionData.count == interactionTypes.count else {
             print("ERROR: Mismatch count during saveSession for session \(session.id). Aborting save.")
             return
        }
        
        for i in 0..<interactionData.count {
            interactionsToSave.append([
                "type": interactionTypes[i],
                "data": interactionData[i].base64EncodedString() // Encode data as base64
            ])
        }
        
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory")
                return
            }
            
            // Create sessions directory if it doesn't exist
            let sessionsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Sessions", isDirectory: true)
            try FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
            
            // Paths for the two files
            let sessionInfoFile = sessionsDirectory.appendingPathComponent("\(session.id).json")
            let interactionsFile = sessionsDirectory.appendingPathComponent("\(session.id)_interactions.json")

            // 3. Save main session info
            let sessionInfoData = try JSONSerialization.data(withJSONObject: sessionInfo, options: .prettyPrinted)
            try sessionInfoData.write(to: sessionInfoFile)
            print("Successfully saved session info to: \(sessionInfoFile.path)")

            // 4. Save interactions data
            let interactionsFileData = try JSONSerialization.data(withJSONObject: interactionsToSave, options: .prettyPrinted)
            try interactionsFileData.write(to: interactionsFile)
            print("Successfully saved interactions to: \(interactionsFile.path)")

        } catch {
            print("Error saving session \(session.id): \(error)")
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
        var loadedSessions: [RecordingSession] = []
        print("SessionManager: getAllSessions - Loading sessions from disk.")
        
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory")
                return [] // Return empty if dir not found
            }
            
            // Get the sessions directory
            let sessionsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Sessions", isDirectory: true)
            
            // Check if directory exists
            if !FileManager.default.fileExists(atPath: sessionsDirectory.path) {
                print("Sessions directory doesn't exist yet")
                return [] // Return empty if dir not found
            }
            
            // Get all main session info files
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: sessionsDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" && !$0.lastPathComponent.contains("_interactions") }
            
            print("DEBUG: Found \(fileURLs.count) main session files")
            
            // Load each session
            for sessionInfoFileURL in fileURLs {
                print("DEBUG: Loading session info from \(sessionInfoFileURL.lastPathComponent)")
                
                do {
                    // 1. Decode main session info
                    let sessionInfoData = try Data(contentsOf: sessionInfoFileURL)
                    guard let sessionInfo = try JSONSerialization.jsonObject(with: sessionInfoData) as? [String: Any], 
                          let id = sessionInfo["id"] as? String,
                          let startTimeInterval = sessionInfo["startTime"] as? TimeInterval else {
                        print("ERROR: Could not decode basic info for session file \(sessionInfoFileURL.lastPathComponent)")
                        continue
                    }
                    
                    let startTime = Date(timeIntervalSince1970: startTimeInterval)
                    let endTime = (sessionInfo["endTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
                    let projectId = sessionInfo["projectId"] as? String
                    
                    // Create the session object (without interactions yet)
                    let session = RecordingSession(id: id, startTime: startTime, projectId: projectId)
                    session.endTime = endTime
                    
                    // 2. Find and decode interactions file
                    let interactionsFileURL = sessionsDirectory.appendingPathComponent("\(id)_interactions.json")
                    if FileManager.default.fileExists(atPath: interactionsFileURL.path) {
                        print("DEBUG: Loading interactions from \(interactionsFileURL.lastPathComponent)")
                        let interactionsFileData = try Data(contentsOf: interactionsFileURL)
                        if let interactionsSaved = try JSONSerialization.jsonObject(with: interactionsFileData) as? [[String: String]] {
                            var loadedInteractionData: [Data] = []
                            var loadedInteractionTypes: [String] = []
                            
                            for interactionDict in interactionsSaved {
                                if let type = interactionDict["type"],
                                   let dataString = interactionDict["data"],
                                   let data = Data(base64Encoded: dataString) {
                                    loadedInteractionData.append(data)
                                    loadedInteractionTypes.append(type)
                                } else {
                                    print("WARNING: Could not decode interaction entry in \(interactionsFileURL.lastPathComponent)")
                                }
                            }
                            // Set interactions on the session object
                            session.setLoadedInteractions(data: loadedInteractionData, types: loadedInteractionTypes)
                            print("DEBUG: Successfully loaded \(loadedInteractionData.count) interactions for session \(id)")
                        } else {
                             print("ERROR: Could not decode interactions file content for \(id)")
                        }
                    } else {
                        print("WARNING: Interactions file not found for session \(id)")
                    }
                    
                    loadedSessions.append(session)
                    
                } catch {
                    print("ERROR processing session file \(sessionInfoFileURL.lastPathComponent): \(error)")
                }
            }
            
            print("Loaded \(loadedSessions.count) sessions from disk")
            
        } catch {
            print("Error accessing sessions directory: \(error)")
        }
        
        // Combine with cached session if necessary (though cache might be less relevant now)
        if let lastSession = lastSession {
             print("SessionManager: Checking if cached lastSession \(lastSession.id) should be added")
             let sessionExists = loadedSessions.contains { $0.id == lastSession.id }
             if !sessionExists {
                 print("SessionManager: Adding cached lastSession \(lastSession.id) to the list")
                 loadedSessions.append(lastSession)
             } else {
                 print("SessionManager: Cached session \(lastSession.id) already loaded from disk")
             }
        }
        
        // Sort sessions by start time (newest first)
        loadedSessions.sort { $0.startTime > $1.startTime }
        
        return loadedSessions
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
        
        // Try to load from disk (manual loading)
        do {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Failed to get documents directory for getSession")
                return nil
            }
            
            // Get the session file paths
            let sessionsDirectory = documentsDirectory.appendingPathComponent("WeLabelDataRecorder/Sessions", isDirectory: true)
            let sessionInfoFileURL = sessionsDirectory.appendingPathComponent("\(id).json")
            let interactionsFileURL = sessionsDirectory.appendingPathComponent("\(id)_interactions.json")

            // Check if main session info file exists
            if !FileManager.default.fileExists(atPath: sessionInfoFileURL.path) {
                print("Session info file not found for ID: \(id)")
                return nil
            }
            
            // 1. Decode main session info
            let sessionInfoData = try Data(contentsOf: sessionInfoFileURL)
            guard let sessionInfo = try JSONSerialization.jsonObject(with: sessionInfoData) as? [String: Any],
                  let startTimeInterval = sessionInfo["startTime"] as? TimeInterval else {
                print("ERROR: Could not decode basic info for session file \(sessionInfoFileURL.lastPathComponent)")
                return nil
            }
            
            let startTime = Date(timeIntervalSince1970: startTimeInterval)
            let endTime = (sessionInfo["endTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
            let projectId = sessionInfo["projectId"] as? String
            
            // Create the session object (without interactions yet)
            let session = RecordingSession(id: id, startTime: startTime, projectId: projectId)
            session.endTime = endTime
                    
            // 2. Find and decode interactions file
            if FileManager.default.fileExists(atPath: interactionsFileURL.path) {
                print("DEBUG: Loading interactions from \(interactionsFileURL.lastPathComponent) for session \(id)")
                let interactionsFileData = try Data(contentsOf: interactionsFileURL)
                if let interactionsSaved = try JSONSerialization.jsonObject(with: interactionsFileData) as? [[String: String]] {
                    var loadedInteractionData: [Data] = []
                    var loadedInteractionTypes: [String] = []
                            
                    for interactionDict in interactionsSaved {
                        if let type = interactionDict["type"],
                           let dataString = interactionDict["data"],
                           let data = Data(base64Encoded: dataString) {
                            loadedInteractionData.append(data)
                            loadedInteractionTypes.append(type)
                        } else {
                            print("WARNING: Could not decode interaction entry in \(interactionsFileURL.lastPathComponent)")
                        }
                    }
                    // Set interactions on the session object
                    session.setLoadedInteractions(data: loadedInteractionData, types: loadedInteractionTypes)
                    print("DEBUG: Successfully loaded \(loadedInteractionData.count) interactions for session \(id)")
                } else {
                     print("ERROR: Could not decode interactions file content for \(id)")
                }
            } else {
                print("WARNING: Interactions file not found for session \(id)")
            }
            
            return session // Return the fully loaded session

        } catch {
            print("Error loading session \(id) from disk: \(error)")
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

// Type eraser for UserInteraction protocol
// NOTE: This struct is NOT Codable itself.
// RecordingSession handles the manual serialization of interactions.
struct AnyInteraction {
    private let _data: Data
    private let _interactionTypeValue: String
    
    // Public init for creating from a concrete interaction
    init<T: UserInteraction & Codable>(_ interaction: T) {
        self._interactionTypeValue = interaction.interactionType.rawValue
        
        do {
            // Use a dedicated encoder here for clarity
            let encoder = JSONEncoder()
            self._data = try encoder.encode(interaction)
        } catch {
            print("ERROR encoding interaction to data: \(error)")
            // Fallback: создаем пустой Data объект
            self._data = Data()
        }
    }
    
    // Private init for reconstructing from saved data (used by RecordingSession)
    fileprivate init(data: Data, typeValue: String) {
        self._data = data
        self._interactionTypeValue = typeValue
    }
    
    // Get the stored interaction type
    var interactionType: InteractionType? {
        return InteractionType(rawValue: _interactionTypeValue)
    }
    
    // Access the raw data (needed for saving by RecordingSession)
    var rawData: Data {
        return _data
    }
    
    // Access the type value (needed for saving by RecordingSession)
    var typeValue: String {
        return _interactionTypeValue
    }
    
    // Static method to reconstruct from saved data (used by RecordingSession)
    static func from(data: Data, typeValue: String) -> AnyInteraction {
        return AnyInteraction(data: data, typeValue: typeValue)
    }

    // MARK: - Type-safe decoding methods
    
    // Пытается декодировать взаимодействие определенного типа, только если совпадает хранимый тип
    func decodeAsMouseClick() -> MouseClickInteraction? {
        guard interactionType == .mouseClick else { return nil }
        
        do {
            // Use a dedicated decoder
            let decoder = JSONDecoder()
            return try decoder.decode(MouseClickInteraction.self, from: _data)
        } catch {
            print("ERROR decoding MouseClickInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsMouseMove() -> MouseMoveInteraction? {
        guard interactionType == .mouseMove else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(MouseMoveInteraction.self, from: _data)
        } catch {
            print("ERROR decoding MouseMoveInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsMouseScroll() -> MouseScrollInteraction? {
        guard interactionType == .mouseScroll else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(MouseScrollInteraction.self, from: _data)
        } catch {
            print("ERROR decoding MouseScrollInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsKeyInteraction() -> KeyInteraction? {
        guard interactionType == .keyDown || interactionType == .keyUp else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(KeyInteraction.self, from: _data)
        } catch {
            print("ERROR decoding KeyInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsScreenshot() -> ScreenshotInteraction? {
        guard interactionType == .screenshot else { 
            return nil 
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ScreenshotInteraction.self, from: _data)
        } catch {
            print("ERROR decoding ScreenshotInteraction: \(error)")
            return nil
        }
    }
    
    func decodeAsUIElement() -> UIElementInteraction? {
        guard interactionType == .uiElement else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(UIElementInteraction.self, from: _data)
        } catch {
            print("ERROR decoding UIElementInteraction: \(error)")
            return nil
        }
    }
}

// MARK: - RecordingSession Update

// Project model for grouping recording sessions
class Project: Codable {
    let id: String
    let name: String
    let description: String
    let creationDate: Date
    var sessionIDs: [String] = [] // Store session IDs instead of full objects initially
    
    // Transient property, loaded on demand
    var sessions: [RecordingSession] = []
    
    init(id: String = UUID().uuidString, name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
        self.creationDate = Date()
    }
    
    // Add a session ID to this project
    func addSessionID(_ sessionID: String) {
        if !sessionIDs.contains(sessionID) {
            sessionIDs.append(sessionID)
        }
    }
    
    // Custom Codable to handle sessions array potentially
    enum CodingKeys: String, CodingKey {
        case id, name, description, creationDate, sessionIDs
    }
    
    // No need for custom encode/decode if we only save IDs
}

// Recording session model
// NOTE: This class is NO LONGER Codable directly.
// SessionManager handles manual serialization.
class RecordingSession {
    let id: String
    let startTime: Date
    var endTime: Date?
    var projectId: String?
    
    // Store interaction data separately
    private var interactionData: [Data] = []
    private var interactionTypes: [String] = []
    
    // Computed property to access interactions (reconstructs them)
    var interactions: [AnyInteraction] {
        get {
            // Reconstruct AnyInteraction objects from stored data and types
            // Use fileprivate init for AnyInteraction
            return zip(interactionData, interactionTypes).map { AnyInteraction(data: $0, typeValue: $1) }
        }
        // Setter is removed as SessionManager will manage loading
    }
    
    init(id: String, startTime: Date, projectId: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.projectId = projectId
    }
    
    // Internal method for SessionManager to set loaded interactions
    func setLoadedInteractions(data: [Data], types: [String]) {
        guard data.count == types.count else {
             print("WARNING: Mismatch count when setting loaded interactions for session \(id).")
             self.interactionData = []
             self.interactionTypes = []
             return
        }
        self.interactionData = data
        self.interactionTypes = types
    }
    
    // Internal accessors for SessionManager saving
    var internalInteractionData: [Data] { return interactionData }
    var internalInteractionTypes: [String] { return interactionTypes }
    
    // Add an interaction to the session
    func addInteraction<T: UserInteraction & Codable>(_ interaction: T) {
        print("DEBUG: Adding interaction of type \(type(of: interaction)), interactionType: \(interaction.interactionType)")
        // Encode the interaction to Data
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(interaction)
            // Store the data and the type string
            interactionData.append(data)
            interactionTypes.append(interaction.interactionType.rawValue)
        } catch {
            print("ERROR encoding interaction during addInteraction: \(error)")
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
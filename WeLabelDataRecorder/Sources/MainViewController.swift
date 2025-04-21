import AppKit

class MainViewController: NSViewController, RecordingManagerDelegate {
    
    // UI Elements
    private let recordButton = NSButton(title: "Start Recording", target: nil, action: #selector(toggleRecording))
    private let exportButton = NSButton(title: "Export Last Session", target: nil, action: #selector(exportLastSession))
    private let statusLabel = NSTextField(labelWithString: "Ready to record")
    
    // State
    private var isRecording = false
    
    // Export manager
    private let exportManager = ExportManager()
    
    // Храним прямую ссылку на последнюю сессию
    private var lastSession: RecordingSession?
    
    override func loadView() {
        print("MainViewController: loadView")
        // Create the main view
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = view
        print("MainViewController: main view created")
        
        // Set up UI components
        setupUI()
        
        // Set self as recording manager delegate
        print("MainViewController: setting self as RecordingManager delegate")
        RecordingManager.shared.delegate = self
        print("MainViewController: loadView complete")
    }
    
    private func setupUI() {
        print("MainViewController: setupUI started")
        // Configure record button
        recordButton.bezelStyle = .rounded
        recordButton.setButtonType(.momentaryPushIn)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.target = self
        view.addSubview(recordButton)
        print("MainViewController: record button added")
        
        // Configure export button
        exportButton.bezelStyle = .rounded
        exportButton.setButtonType(.momentaryPushIn)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.target = self
        exportButton.isEnabled = false // Disabled until we have a session to export
        view.addSubview(exportButton)
        print("MainViewController: export button added")
        
        // Configure status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alignment = .center
        view.addSubview(statusLabel)
        print("MainViewController: status label added")
        
        // Set up constraints
        print("MainViewController: setting up constraints")
        NSLayoutConstraint.activate([
            // Center record button
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Place export button below the record button
            exportButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Place status label below the export button
            statusLabel.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 300)
        ])
        print("MainViewController: constraints activated")
        
        // Add permission check
        print("MainViewController: calling checkPermissions")
        checkPermissions()
        print("MainViewController: setupUI complete")
    }
    
    @objc private func toggleRecording() {
        print("MainViewController: toggleRecording called, isRecording = \(isRecording)")
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        print("MainViewController: startRecording")
        do {
            // Start recording
            print("MainViewController: calling RecordingManager.startRecording")
            try RecordingManager.shared.startRecording()
            
            // Start a new session
            print("MainViewController: starting new session")
            let _ = SessionManager.shared.startNewSession()
            
            // Update UI will be handled by delegate methods
            print("MainViewController: startRecording succeeded")
        } catch {
            print("MainViewController: startRecording failed with error: \(error)")
            handleRecordingError(error)
        }
    }
    
    private func stopRecording() {
        do {
            // Stop recording
            try RecordingManager.shared.stopRecording()
            
            // End session
            if let session = SessionManager.shared.endCurrentSession() {
                print("Recording session ended: \(session.id)")
                
                // Сохраняем прямую ссылку на последнюю сессию
                self.lastSession = session
                
                exportButton.isEnabled = true // Enable export now that we have a session
            }
            
            // Update UI will be handled by delegate methods
        } catch {
            handleRecordingError(error)
        }
    }
    
    @objc private func exportLastSession() {
        print("MainViewController: exportLastSession called")
        
        // Сначала проверяем нашу собственную сохраненную ссылку
        if let session = lastSession {
            print("MainViewController: Using session from local lastSession: \(session.id)")
            performExport(session)
            return
        }
        
        // Напрямую проверим, есть ли сессия в lastSession
        if let session = SessionManager.shared.lastSession {
            print("MainViewController: Using directly lastSession \(session.id) with \(session.interactions.count) interactions")
            performExport(session)
            return
        } else {
            print("MainViewController: No direct lastSession available, trying with getAllSessions()")
        }
        
        // Check current session state
        if let currentSession = SessionManager.shared.currentSession {
            print("MainViewController: Current session active: \(currentSession.id)")
        } else {
            print("MainViewController: No current session active")
        }
        
        // Get all sessions (for now we'll just get one from disk in the future)
        let sessions = SessionManager.shared.getAllSessions()
        print("MainViewController: Found \(sessions.count) sessions from getAllSessions()")
        
        // For now, try to find the most recently ended session
        guard let session = sessions.last ?? SessionManager.shared.currentSession else {
            print("MainViewController: No lastSession found in sessions array or currentSession")
            showExportError("No session available to export")
            return
        }
        
        print("MainViewController: Using session for export: \(session.id)")
        print("MainViewController: Session has \(session.interactions.count) interactions")
        
        performExport(session)
    }
    
    private func performExport(_ session: RecordingSession) {
        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.title = "Export Recording Session"
        savePanel.nameFieldLabel = "Export Name"
        savePanel.nameFieldStringValue = "WeLabelData_Session_\(session.id)"
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        
        savePanel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = savePanel.url {
                self.statusLabel.stringValue = "Exporting..."
                
                // Perform export in background
                DispatchQueue.global(qos: .userInitiated).async {
                    if let exportURL = self.exportManager.exportToJSON(session, to: url) {
                        DispatchQueue.main.async {
                            self.statusLabel.stringValue = "Export complete!"
                            
                            // Show success alert
                            let alert = NSAlert()
                            alert.messageText = "Export Complete"
                            alert.informativeText = "Session exported successfully to \(exportURL.path)"
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showExportError("Failed to export session")
                        }
                    }
                }
            }
        }
    }
    
    private func showExportError(_ message: String) {
        statusLabel.stringValue = "Export failed"
        
        let alert = NSAlert()
        alert.messageText = "Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func handleRecordingError(_ error: Error) {
        var message = "An error occurred"
        
        if let recordingError = error as? RecordingError {
            switch recordingError {
            case .permissionDenied:
                message = "Permission denied. Please enable screen recording in System Preferences."
            case .captureSetupFailed:
                message = "Failed to set up screen capture."
            case .alreadyRecording:
                message = "Already recording."
            case .notRecording:
                message = "Not currently recording."
            case .unknown(let details):
                message = "Unknown error: \(details)"
            }
        }
        
        statusLabel.stringValue = message
        print("Recording error: \(message)")
        
        // Show alert to the user
        let alert = NSAlert()
        alert.messageText = "Recording Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func checkPermissions() {
        print("MainViewController: checkPermissions started")
        let permissionsGranted = RecordingManager.shared.checkPermissions()
        print("MainViewController: RecordingManager.checkPermissions returned \(permissionsGranted)")
        
        if !permissionsGranted {
            statusLabel.stringValue = "Missing permissions"
            print("MainViewController: Missing permissions, showing alert")
            
            // Show permission request alert
            let alert = NSAlert()
            alert.messageText = "Permissions Required"
            alert.informativeText = "This app needs screen recording and accessibility permissions to function properly."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Request Permissions")
            alert.addButton(withTitle: "Later")
            
            print("MainViewController: Running permission alert")
            if alert.runModal() == .alertFirstButtonReturn {
                print("MainViewController: User clicked 'Request Permissions'")
                RecordingManager.shared.requestPermissions { granted in
                    print("MainViewController: Permission request callback, granted = \(granted)")
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = granted ? "Ready to record" : "Missing permissions"
                    }
                }
            } else {
                print("MainViewController: User clicked 'Later'")
            }
        } else {
            print("MainViewController: Permissions already granted")
        }
    }
    
    // MARK: - RecordingManagerDelegate
    
    func recordingDidStart() {
        print("MainViewController: recordingDidStart")
        isRecording = true
        recordButton.title = "Stop Recording"
        statusLabel.stringValue = "Recording..."
        exportButton.isEnabled = false
    }
    
    func recordingDidStop() {
        print("MainViewController: recordingDidStop")
        isRecording = false
        recordButton.title = "Start Recording"
        statusLabel.stringValue = "Ready to record"
        exportButton.isEnabled = true
    }
    
    func recordingDidFail(with error: Error) {
        print("MainViewController: recordingDidFail with error: \(error)")
        handleRecordingError(error)
    }
} 
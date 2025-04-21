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
    
    override func loadView() {
        // Create the main view
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = view
        
        // Set up UI components
        setupUI()
        
        // Set self as recording manager delegate
        RecordingManager.shared.delegate = self
    }
    
    private func setupUI() {
        // Configure record button
        recordButton.bezelStyle = .rounded
        recordButton.setButtonType(.momentaryPushIn)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.target = self
        view.addSubview(recordButton)
        
        // Configure export button
        exportButton.bezelStyle = .rounded
        exportButton.setButtonType(.momentaryPushIn)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.target = self
        exportButton.isEnabled = false // Disabled until we have a session to export
        view.addSubview(exportButton)
        
        // Configure status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alignment = .center
        view.addSubview(statusLabel)
        
        // Set up constraints
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
        
        // Add permission check
        checkPermissions()
    }
    
    @objc private func toggleRecording() {
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        do {
            // Start recording
            try RecordingManager.shared.startRecording()
            
            // Start a new session
            let _ = SessionManager.shared.startNewSession()
            
            // Update UI will be handled by delegate methods
        } catch {
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
                exportButton.isEnabled = true // Enable export now that we have a session
            }
            
            // Update UI will be handled by delegate methods
        } catch {
            handleRecordingError(error)
        }
    }
    
    @objc private func exportLastSession() {
        // Get all sessions (for now we'll just get one from disk in the future)
        let sessions = SessionManager.shared.getAllSessions()
        
        // For now, try to find the most recently ended session
        guard let lastSession = sessions.last ?? SessionManager.shared.currentSession else {
            showExportError("No session available to export")
            return
        }
        
        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.title = "Export Recording Session"
        savePanel.nameFieldLabel = "Export Name"
        savePanel.nameFieldStringValue = "WeLabelData_Session_\(lastSession.id)"
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        
        savePanel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = savePanel.url {
                self.statusLabel.stringValue = "Exporting..."
                
                // Perform export in background
                DispatchQueue.global(qos: .userInitiated).async {
                    if let exportURL = self.exportManager.exportToJSON(lastSession, to: url) {
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
        if !RecordingManager.shared.checkPermissions() {
            statusLabel.stringValue = "Missing permissions"
            
            // Show permission request alert
            let alert = NSAlert()
            alert.messageText = "Permissions Required"
            alert.informativeText = "This app needs screen recording and accessibility permissions to function properly."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Request Permissions")
            alert.addButton(withTitle: "Later")
            
            if alert.runModal() == .alertFirstButtonReturn {
                RecordingManager.shared.requestPermissions { granted in
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = granted ? "Ready to record" : "Missing permissions"
                    }
                }
            }
        }
    }
    
    // MARK: - RecordingManagerDelegate
    
    func recordingDidStart() {
        isRecording = true
        recordButton.title = "Stop Recording"
        statusLabel.stringValue = "Recording..."
        exportButton.isEnabled = false
    }
    
    func recordingDidStop() {
        isRecording = false
        recordButton.title = "Start Recording"
        statusLabel.stringValue = "Ready to record"
        exportButton.isEnabled = true
    }
    
    func recordingDidFail(with error: Error) {
        handleRecordingError(error)
    }
} 
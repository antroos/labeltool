import AppKit

class MainViewController: NSViewController, RecordingManagerDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    // UI Elements
    private let recordButton = NSButton(title: "Start Recording", target: nil, action: #selector(toggleRecording))
    private let exportButton = NSButton(title: "Export Last Session", target: nil, action: #selector(exportLastSession))
    private let statusLabel = NSTextField(labelWithString: "Ready to record")
    
    // Session list UI components
    private let sessionsTableView = NSTableView()
    private let scrollView = NSScrollView()
    private let sessionsLabel = NSTextField(labelWithString: "Recording Sessions")
    private let refreshButton = NSButton(title: "Refresh", target: nil, action: #selector(refreshSessionList))
    
    // Status indicators
    private let permissionStatusView = NSView()
    private let screenRecordingIndicator = NSImageView()
    private let accessibilityIndicator = NSImageView()
    private let diskSpaceIndicator = NSProgressIndicator()
    private let diskSpaceLabel = NSTextField(labelWithString: "Disk Space")
    
    // Data
    private var sessions: [RecordingSession] = []
    
    // State
    private var isRecording = false
    
    // Export manager
    private let exportManager = ExportManager()
    
    // Храним прямую ссылку на последнюю сессию
    private var lastSession: RecordingSession?
    
    override func loadView() {
        print("MainViewController: loadView started")
        // Create the main view
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = view
        print("MainViewController: main view created with size: \(view.frame.size)")
        
        // Set up UI components
        setupUI()
        
        // Set self as recording manager delegate
        print("MainViewController: setting self as RecordingManager delegate")
        RecordingManager.shared.delegate = self
        print("MainViewController: loadView complete")
        
        // Load sessions
        refreshSessionList()
        
        // Make sure view is visible
        print("MainViewController: making sure view is visible")
        DispatchQueue.main.async {
            if let window = self.view.window {
                print("MainViewController: window exists, making key and front")
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                print("MainViewController: WARNING - view has no window attached")
            }
        }
    }
    
    private func setupUI() {
        print("MainViewController: setupUI started")
        
        // Set up status indicators section
        setupStatusIndicators()
        
        // Set up sessions table view
        setupSessionsTableView()
        
        // Configure record button with updated style
        recordButton.bezelStyle = .rounded
        recordButton.setButtonType(.momentaryPushIn)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.target = self
        recordButton.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "Record")
        recordButton.imagePosition = .imageLeading
        recordButton.title = "Start Recording"
        view.addSubview(recordButton)
        print("MainViewController: record button added")
        
        // Configure export button
        exportButton.bezelStyle = .rounded
        exportButton.setButtonType(.momentaryPushIn)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.target = self
        exportButton.isEnabled = false // Disabled until we have a session to export
        exportButton.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Export")
        exportButton.imagePosition = .imageLeading
        view.addSubview(exportButton)
        print("MainViewController: export button added")
        
        // Configure status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alignment = .center
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        view.addSubview(statusLabel)
        print("MainViewController: status label added")
        
        // Set up constraints
        print("MainViewController: setting up constraints")
        NSLayoutConstraint.activate([
            // Status indicators at the top
            permissionStatusView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            permissionStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            permissionStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            permissionStatusView.heightAnchor.constraint(equalToConstant: 30),
            
            // Sessions label
            sessionsLabel.topAnchor.constraint(equalTo: permissionStatusView.bottomAnchor, constant: 20),
            sessionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Refresh button
            refreshButton.centerYAnchor.constraint(equalTo: sessionsLabel.centerYAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Sessions table view
            scrollView.topAnchor.constraint(equalTo: sessionsLabel.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 200),
            
            // Record button below the table view
            recordButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 20),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 180),
            
            // Export button below the record button
            exportButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.widthAnchor.constraint(equalToConstant: 180),
            
            // Status label below the export button
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
    
    private func setupSessionsTableView() {
        print("MainViewController: setupSessionsTableView started")
        
        // Configure sessions label
        sessionsLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        view.addSubview(sessionsLabel)
        print("MainViewController: sessions label added")
        
        // Configure refresh button
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.bezelStyle = .rounded
        refreshButton.setButtonType(.momentaryPushIn)
        refreshButton.target = self
        refreshButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")
        refreshButton.imagePosition = .imageOnly
        view.addSubview(refreshButton)
        print("MainViewController: refresh button added")
        
        // Set up scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        view.addSubview(scrollView)
        print("MainViewController: scroll view added")
        
        // Set up table view
        let thumbnailColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("thumbnail"))
        thumbnailColumn.title = "Thumbnail"
        thumbnailColumn.width = 80
        
        let infoColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("info"))
        infoColumn.title = "Session Info"
        infoColumn.width = 300
        
        let metricsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("metrics"))
        metricsColumn.title = "Metrics"
        metricsColumn.width = 150
        
        let actionsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("actions"))
        actionsColumn.title = "Actions"
        actionsColumn.width = 100
        
        sessionsTableView.addTableColumn(thumbnailColumn)
        sessionsTableView.addTableColumn(infoColumn)
        sessionsTableView.addTableColumn(metricsColumn)
        sessionsTableView.addTableColumn(actionsColumn)
        
        sessionsTableView.delegate = self
        sessionsTableView.dataSource = self
        sessionsTableView.allowsMultipleSelection = false
        sessionsTableView.rowHeight = 60
        
        scrollView.documentView = sessionsTableView
        print("MainViewController: table view configured with \(sessionsTableView.tableColumns.count) columns")
    }
    
    private func setupStatusIndicators() {
        // Configure status view
        permissionStatusView.translatesAutoresizingMaskIntoConstraints = false
        permissionStatusView.wantsLayer = true
        permissionStatusView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        permissionStatusView.layer?.cornerRadius = 6
        view.addSubview(permissionStatusView)
        
        // Configure screen recording indicator
        screenRecordingIndicator.translatesAutoresizingMaskIntoConstraints = false
        screenRecordingIndicator.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Screen Recording")
        screenRecordingIndicator.contentTintColor = NSColor.systemRed
        permissionStatusView.addSubview(screenRecordingIndicator)
        
        // Configure accessibility indicator
        accessibilityIndicator.translatesAutoresizingMaskIntoConstraints = false
        accessibilityIndicator.image = NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: "Accessibility")
        accessibilityIndicator.contentTintColor = NSColor.systemRed
        permissionStatusView.addSubview(accessibilityIndicator)
        
        // Configure disk space indicator
        diskSpaceIndicator.translatesAutoresizingMaskIntoConstraints = false
        diskSpaceIndicator.style = .bar
        diskSpaceIndicator.minValue = 0
        diskSpaceIndicator.maxValue = 100
        diskSpaceIndicator.doubleValue = 75 // Initial value, will be updated
        permissionStatusView.addSubview(diskSpaceIndicator)
        
        // Configure disk space label
        diskSpaceLabel.translatesAutoresizingMaskIntoConstraints = false
        diskSpaceLabel.font = NSFont.systemFont(ofSize: 10)
        diskSpaceLabel.textColor = NSColor.secondaryLabelColor
        permissionStatusView.addSubview(diskSpaceLabel)
        
        // Set up constraints for status indicators
        NSLayoutConstraint.activate([
            // Screen recording indicator
            screenRecordingIndicator.leadingAnchor.constraint(equalTo: permissionStatusView.leadingAnchor, constant: 10),
            screenRecordingIndicator.centerYAnchor.constraint(equalTo: permissionStatusView.centerYAnchor),
            screenRecordingIndicator.widthAnchor.constraint(equalToConstant: 24),
            screenRecordingIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            // Accessibility indicator
            accessibilityIndicator.leadingAnchor.constraint(equalTo: screenRecordingIndicator.trailingAnchor, constant: 20),
            accessibilityIndicator.centerYAnchor.constraint(equalTo: permissionStatusView.centerYAnchor),
            accessibilityIndicator.widthAnchor.constraint(equalToConstant: 24),
            accessibilityIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            // Disk space indicator
            diskSpaceIndicator.trailingAnchor.constraint(equalTo: permissionStatusView.trailingAnchor, constant: -10),
            diskSpaceIndicator.centerYAnchor.constraint(equalTo: permissionStatusView.centerYAnchor),
            diskSpaceIndicator.widthAnchor.constraint(equalToConstant: 100),
            
            // Disk space label
            diskSpaceLabel.trailingAnchor.constraint(equalTo: diskSpaceIndicator.leadingAnchor, constant: -5),
            diskSpaceLabel.centerYAnchor.constraint(equalTo: permissionStatusView.centerYAnchor),
        ])
    }
    
    @objc private func refreshSessionList() {
        print("MainViewController: refreshSessionList called")
        // Load all sessions
        sessions = SessionManager.shared.getAllSessions()
        print("MainViewController: loaded \(sessions.count) sessions")
        sessionsTableView.reloadData()
        print("MainViewController: table view reloaded")
        
        // Update permission indicators
        updatePermissionIndicators()
        
        // Update disk space
        updateDiskSpace()
        
        print("MainViewController: refreshSessionList completed")
    }
    
    private func updatePermissionIndicators() {
        // Use the existing checkPermissions method
        let permissionsGranted = RecordingManager.shared.checkPermissions()
        
        // For now we'll just use the same indicator for both permissions
        // In the future, we could enhance RecordingManager to check specific permissions
        screenRecordingIndicator.contentTintColor = permissionsGranted ? NSColor.systemGreen : NSColor.systemRed
        accessibilityIndicator.contentTintColor = permissionsGranted ? NSColor.systemGreen : NSColor.systemRed
    }
    
    private func updateDiskSpace() {
        // Get available disk space
        let fileManager = FileManager.default
        do {
            if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let attributes = try fileManager.attributesOfFileSystem(forPath: documentDirectory.path)
                if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                    let freeSizeGB = Double(truncating: freeSize) / (1024 * 1024 * 1024)
                    diskSpaceLabel.stringValue = "Free: \(String(format: "%.1f", freeSizeGB)) GB"
                    
                    // Assume 100GB is full capacity for visualization purposes
                    let percentFull = min(100, max(0, 100 - (freeSizeGB / 100 * 100)))
                    diskSpaceIndicator.doubleValue = percentFull
                }
            }
        } catch {
            print("Error getting disk space: \(error)")
            diskSpaceLabel.stringValue = "Disk Space Unknown"
        }
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < sessions.count else { return nil }
        let session = sessions[row]
        
        if tableColumn?.identifier.rawValue == "thumbnail" {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("ThumbnailCell"), owner: self) as? NSTableCellView
                ?? NSTableCellView(frame: NSRect(x: 0, y: 0, width: 80, height: 60))
            cellView.identifier = NSUserInterfaceItemIdentifier("ThumbnailCell")
            
            // Create or reuse image view
            let imageView = cellView.subviews.first as? NSImageView ?? NSImageView(frame: NSRect(x: 5, y: 5, width: 70, height: 50))
            if cellView.subviews.isEmpty {
                imageView.translatesAutoresizingMaskIntoConstraints = false
                cellView.addSubview(imageView)
                
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 5),
                    imageView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -5),
                    imageView.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 5),
                    imageView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -5)
                ])
            }
            
            // Load thumbnail from session screenshots if available
            imageView.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Thumbnail")
            
            // TODO: Load actual thumbnail from session
            
            return cellView
        } else if tableColumn?.identifier.rawValue == "info" {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("InfoCell"), owner: self) as? NSTableCellView
                ?? NSTableCellView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
            cellView.identifier = NSUserInterfaceItemIdentifier("InfoCell")
            
            // Create or update main text field
            if cellView.textField == nil {
                let textField = NSTextField(labelWithString: "Session")
                textField.translatesAutoresizingMaskIntoConstraints = false
                cellView.addSubview(textField)
                cellView.textField = textField
                
                let detailField = NSTextField(labelWithString: "Details")
                detailField.translatesAutoresizingMaskIntoConstraints = false
                detailField.font = NSFont.systemFont(ofSize: 10)
                detailField.textColor = NSColor.secondaryLabelColor
                cellView.addSubview(detailField)
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 5),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -5),
                    textField.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 10),
                    
                    detailField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 5),
                    detailField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -5),
                    detailField.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
                ])
            }
            
            // Format date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let startDate = dateFormatter.string(from: session.startTime)
            let endDate = session.endTime != nil ? dateFormatter.string(from: session.endTime!) : "In progress"
            
            cellView.textField?.stringValue = "Session: \(session.id)"
            
            // Set detail text
            if let detailField = cellView.subviews.last as? NSTextField {
                detailField.stringValue = "Start: \(startDate) | End: \(endDate)"
            }
            
            return cellView
        } else if tableColumn?.identifier.rawValue == "metrics" {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("MetricsCell"), owner: self) as? NSTableCellView
                ?? NSTableCellView(frame: NSRect(x: 0, y: 0, width: 150, height: 60))
            cellView.identifier = NSUserInterfaceItemIdentifier("MetricsCell")
            
            // Create or update metrics field
            if cellView.textField == nil {
                let textField = NSTextField(labelWithString: "Metrics")
                textField.translatesAutoresizingMaskIntoConstraints = false
                cellView.addSubview(textField)
                cellView.textField = textField
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 5),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -5),
                    textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                ])
            }
            
            // Calculate session duration
            var duration = 0.0
            if let endTime = session.endTime {
                duration = endTime.timeIntervalSince(session.startTime)
            } else {
                duration = Date().timeIntervalSince(session.startTime)
            }
            
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            
            cellView.textField?.stringValue = """
                Duration: \(minutes)m \(seconds)s
                Interactions: \(session.interactions.count)
                """
            
            return cellView
        } else if tableColumn?.identifier.rawValue == "actions" {
            let cellView = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 60))
            
            // Create export button
            let exportBtn = NSButton(title: "Export", target: self, action: #selector(exportSessionFromTable(_:)))
            exportBtn.tag = row // Use tag to identify which session to export
            exportBtn.translatesAutoresizingMaskIntoConstraints = false
            exportBtn.bezelStyle = .rounded
            exportBtn.setButtonType(.momentaryPushIn)
            exportBtn.controlSize = .small
            cellView.addSubview(exportBtn)
            
            NSLayoutConstraint.activate([
                exportBtn.centerXAnchor.constraint(equalTo: cellView.centerXAnchor),
                exportBtn.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                exportBtn.widthAnchor.constraint(equalToConstant: 80),
            ])
            
            return cellView
        }
        
        return nil
    }
    
    @objc private func exportSessionFromTable(_ sender: NSButton) {
        guard sender.tag < sessions.count else { return }
        let session = sessions[sender.tag]
        performExport(session)
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if sessionsTableView.selectedRow >= 0 && sessionsTableView.selectedRow < sessions.count {
            lastSession = sessions[sessionsTableView.selectedRow]
            exportButton.isEnabled = true
        }
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
            
            // Вместо модального алерта используем асинхронный показ
            DispatchQueue.main.async {
                // Show permission request alert
                let alert = NSAlert()
                alert.messageText = "Permissions Required"
                alert.informativeText = "This app needs screen recording and accessibility permissions to function properly."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Request Permissions")
                alert.addButton(withTitle: "Later")
                
                // Используем beginSheetModal вместо runModal
                alert.beginSheetModal(for: self.view.window!) { [weak self] response in
                    guard let self = self else { return }
                    print("MainViewController: Alert button clicked, response = \(response)")
                    
                    if response == .alertFirstButtonReturn {
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
                }
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
        
        // Show an indication that recording has started
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = NSColor.systemRed.withAlphaComponent(0.2).cgColor
        animation.toValue = NSColor.systemRed.withAlphaComponent(0.0).cgColor
        animation.duration = 1.0
        animation.autoreverses = true
        animation.repeatCount = 3
        permissionStatusView.layer?.add(animation, forKey: "pulseAnimation")
    }
    
    func recordingDidStop() {
        print("MainViewController: recordingDidStop")
        isRecording = false
        recordButton.title = "Start Recording"
        statusLabel.stringValue = "Ready to record"
        exportButton.isEnabled = true
        
        // Refresh the session list to show the new session
        refreshSessionList()
    }
    
    func recordingDidFail(with error: Error) {
        print("MainViewController: recordingDidFail with error: \(error)")
        handleRecordingError(error)
    }
    
    func recordingStateChanged(isRecording: Bool) {
        print("MainViewController: recordingStateChanged to \(isRecording)")
        self.isRecording = isRecording
        
        if isRecording {
            recordButton.title = "Stop Recording"
            statusLabel.stringValue = "Recording..."
            exportButton.isEnabled = false
        } else {
            recordButton.title = "Start Recording"
            statusLabel.stringValue = "Ready to record"
            exportButton.isEnabled = true
            
            // Refresh the session list
            refreshSessionList()
        }
    }
} 
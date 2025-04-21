import AppKit

class MainWindowController: NSWindowController {
    
    init() {
        // Create a window with standard style and size
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "WeLabelData Recorder"
        window.center()
        
        // Create a view controller for the window
        let viewController = MainViewController()
        window.contentViewController = viewController
        
        // Initialize with the window
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
} 
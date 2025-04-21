import AppKit

class MainWindowController: NSWindowController {
    
    init() {
        print("MainWindowController: init")
        // Create a window with standard style and size
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "WeLabelData Recorder"
        window.center()
        print("MainWindowController: window created and centered")
        
        // Create a view controller for the window
        print("MainWindowController: creating MainViewController")
        let viewController = MainViewController()
        window.contentViewController = viewController
        print("MainWindowController: contentViewController set")
        
        // Initialize with the window
        super.init(window: window)
        print("MainWindowController: super.init complete")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func showWindow(_ sender: Any?) {
        print("MainWindowController: showWindow called")
        super.showWindow(sender)
        if let window = window {
            print("MainWindowController: window is visible: \(window.isVisible)")
            print("MainWindowController: window frame: \(window.frame)")
        } else {
            print("MainWindowController: ERROR - window is nil")
        }
    }
} 
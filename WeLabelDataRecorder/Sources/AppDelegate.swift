import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("=== APPLICATION STARTUP ===")
        print("Application did finish launching")
        
        // Create the main window
        print("Creating main window controller")
        mainWindowController = MainWindowController()
        print("Showing main window")
        mainWindowController?.showWindow(nil)
        
        // Create the status item in the menu bar
        print("Setting up status item")
        setupStatusItem()
        
        print("Startup complete")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate")
    }
    
    // Create a status bar item for quick access to the application
    private func setupStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "Record")
            print("Status item button created")
            
            // Simple menu for the status item
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show App", action: #selector(showApp), keyEquivalent: "s"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem.menu = menu
            print("Status item menu set up")
        } else {
            print("ERROR: Failed to create status item button")
        }
    }
    
    @objc private func showApp() {
        print("showApp called - activating app")
        NSApp.activate(ignoringOtherApps: true)
        print("Showing main window")
        mainWindowController?.showWindow(nil)
    }
} 
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        
        // Create the main window
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(nil)
        
        // Create the status item in the menu bar
        setupStatusItem()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate")
    }
    
    // Create a status bar item for quick access to the application
    private func setupStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "Record")
            
            // Simple menu for the status item
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show App", action: #selector(showApp), keyEquivalent: "s"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem.menu = menu
        }
    }
    
    @objc private func showApp() {
        NSApp.activate(ignoringOtherApps: true)
        mainWindowController?.showWindow(nil)
    }
} 
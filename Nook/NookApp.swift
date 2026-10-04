import SwiftUI
import SwiftData

/// The main entry point for the Nook application.
///
/// Nook is a cozy, local-first digital room where users store thoughts,
/// ideas, notes, and memories as objects inside a miniature room.
@main
struct NookApp: App {
    
    let persistenceController = PersistenceController.shared
    
    @State private var appState = AppState()
    
    var body: some Scene {
        // MARK: - Main Room Window
        WindowGroup("Nook", id: NookWindow.main.id) {
            ContentView()
                .environment(appState)
                .frame(
                    minWidth: 720,
                    idealWidth: 960,
                    minHeight: 520,
                    idealHeight: 640
                )
        }
        .modelContainer(persistenceController.container)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 960, height: 640)
        
        // MARK: - Quick Capture Window
        WindowGroup("Quick Thought", id: NookWindow.quickCapture.id) {
            QuickCaptureView()
                .environment(appState)
        }
        .modelContainer(persistenceController.container)
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 240)
        
        // MARK: - Settings
        Settings {
            SettingsView()
                .environment(appState)
        }
        .modelContainer(persistenceController.container)
        
        // MARK: - Menu Bar
        MenuBarExtra("Nook", systemImage: "house.fill") {
            MenuBarView()
                .environment(appState)
        }
    }
}

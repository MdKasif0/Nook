import SwiftUI
import SwiftData

/// The main entry point for the Nook application.
///
/// Supports two primary entry points:
/// 1. Main Nook Window (Miniature 3D diorama room + thought shelves)
/// 2. Menu Bar Utility (Minimalist quick popover with shortcuts)
@main
struct NookApp: App {
    
    let persistenceController = PersistenceController.shared
    
    @State private var appState = AppState()
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        // MARK: - 1. Main Room Window
        WindowGroup("Nook", id: NookWindow.main.id) {
            ContentView()
                .environment(appState)
                .frame(
                    minWidth: 780,
                    idealWidth: 980,
                    maxWidth: 1400,
                    minHeight: 540,
                    idealHeight: 650,
                    maxHeight: 960
                )
        }
        .modelContainer(persistenceController.container)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 980, height: 650)
        .commands {
            // New Thought (⌘N) and Quick Thought (⌘⇧Space)
            CommandGroup(replacing: .newItem) {
                Button("New Thought in Room") {
                    appState.selectedSection = .room
                    appState.isShowingNewThoughtSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Quick Thought…") {
                    openWindow(id: NookWindow.quickCapture.id)
                }
                .keyboardShortcut(" ", modifiers: [.command, .shift])
            }
            
            // Search / Spotlight Palette (⌘K)
            CommandGroup(after: .textEditing) {
                Button("Search Thoughts…") {
                    appState.openSearch()
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        
        // MARK: - 2. Quick Capture Floating Paper Window
        Window("Quick Thought", id: NookWindow.quickCapture.id) {
            QuickCaptureView()
                .environment(appState)
        }
        .modelContainer(persistenceController.container)
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 440, height: 320)
        
        // MARK: - 3. Settings Window
        Settings {
            SettingsView()
                .environment(appState)
        }
        .modelContainer(persistenceController.container)
        
        // MARK: - 4. Menu Bar Utility Popover
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .modelContainer(persistenceController.container)
        } label: {
            Image(systemName: "house")
                .help("Nook — Your room")
        }
        .menuBarExtraStyle(.window)
    }
}

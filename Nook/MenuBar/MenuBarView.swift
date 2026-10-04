import SwiftUI

/// The menu bar dropdown for Nook.
///
/// Provides quick access to open the main window, quick capture,
/// and shows a summary of items.
struct MenuBarView: View {
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            Button("Open Nook") {
                openWindow(id: NookWindow.main.id)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Button("Quick Thought") {
                openWindow(id: NookWindow.quickCapture.id)
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Settings…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Quit Nook") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

import SwiftUI
import SwiftData

/// The main content view that hosts the sidebar + detail navigation.
struct ContentView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        @Bindable var state = appState
        
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            DetailView()
        }
        .background(NookDesign.Colors.backgroundPrimary)
        .onAppear {
            GlobalShortcutManager.shared.setup(appState: appState) {
                openWindow(id: NookWindow.quickCapture.id)
            }
        }
    }
}

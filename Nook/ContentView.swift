import SwiftUI
import SwiftData

/// The main content view that hosts the sidebar + detail navigation.
struct ContentView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var updateManager = NookUpdateManager.shared
    
    var body: some View {
        @Bindable var state = appState
        @Bindable var updater = updateManager
        
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            DetailView()
        }
        .background(NookDesign.Colors.backgroundPrimary)
        .preferredColorScheme(.light)
        .sheet(isPresented: $updater.isShowingUpdateSheet) {
            UpdateDialogView()
        }
        .onAppear {
            GlobalShortcutManager.shared.setup(appState: appState) {
                openWindow(id: NookWindow.quickCapture.id)
            }
            
            // Check for updates in the background if enabled
            if PreferencesManager.shared.autoCheckUpdates {
                updateManager.checkForUpdates(userInitiated: false)
            }
        }
    }
}

import SwiftUI
import SwiftData

/// The main content view that hosts the sidebar + detail navigation.
struct ContentView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var updateManager = NookUpdateManager.shared
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    
    var body: some View {
        @Bindable var state = appState
        @Bindable var updater = updateManager
        
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            DetailView()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(NookDesign.Animation.springy) {
                        columnVisibility = (columnVisibility == .detailOnly ? .all : .detailOnly)
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                }
                .help("Toggle Sidebar (⌘S)")
            }
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
            GlobalShortcutManager.shared.onToggleSidebar = {
                withAnimation(NookDesign.Animation.springy) {
                    columnVisibility = (columnVisibility == .detailOnly ? .all : .detailOnly)
                }
            }
            
            // Check for updates in the background if scheduled interval elapsed
            if PreferencesManager.shared.autoCheckUpdates {
                updateManager.performBackgroundCheckIfNeeded()
            }
        }
    }
}

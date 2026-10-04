import SwiftUI
import SwiftData

/// The main content view that hosts the sidebar + detail navigation.
struct ContentView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            DetailView()
        }
        .background(NookDesign.Colors.backgroundPrimary)
    }
}

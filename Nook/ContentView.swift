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
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 49 {
                    openWindow(id: NookWindow.quickCapture.id)
                    return nil
                }
                return event
            }
        }
    }
}

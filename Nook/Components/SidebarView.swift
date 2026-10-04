import SwiftUI

/// The sidebar navigation for Nook.
///
/// Lists the room and all item-type sections using the Nook design language.
struct SidebarView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        List(selection: $state.selectedSection) {
            Section {
                Label(SidebarSection.room.rawValue, systemImage: SidebarSection.room.iconName)
                    .tag(SidebarSection.room)
            }
            
            Section("Collect") {
                ForEach(collectSections) { section in
                    Label(section.rawValue, systemImage: section.iconName)
                        .tag(section)
                }
            }
            
            Section {
                Label(SidebarSection.archive.rawValue, systemImage: SidebarSection.archive.iconName)
                    .tag(SidebarSection.archive)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
        .background(NookDesign.Colors.backgroundSecondary)
    }
    
    /// The item-type sections shown under "Collect".
    private var collectSections: [SidebarSection] {
        [.thoughts, .ideas, .notes, .reminders, .quotes, .links, .photos]
    }
}

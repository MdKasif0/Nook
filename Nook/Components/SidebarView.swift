import SwiftUI

/// The sidebar navigation for Nook.
///
/// Lists the room and all item-type sections using high-contrast Nook design tokens,
/// ensuring high legibility across both macOS Light and Dark appearance modes.
struct SidebarView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        List(selection: $state.selectedSection) {
            Section {
                sidebarRow(for: .room)
            }
            
            Section {
                ForEach(collectSections) { section in
                    sidebarRow(for: section)
                }
            } header: {
                Text("Collect")
                    .font(NookDesign.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .textCase(.uppercase)
                    .padding(.top, 4)
            }
            
            Section {
                sidebarRow(for: .archive)
            }
        }
        .listStyle(.sidebar)
        .tint(NookDesign.Colors.olive)
        .scrollContentBackground(.hidden)
        .background(NookDesign.Colors.backgroundSecondary)
        .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    private func sidebarRow(for section: SidebarSection) -> some View {
        let isSelected = (appState.selectedSection == section)
        
        Label {
            Text(section.rawValue)
                .font(NookDesign.Typography.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.white : NookDesign.Colors.textPrimary)
        } icon: {
            Image(systemName: section.iconName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : NookDesign.Colors.olive)
        }
        .tag(section)
    }
    
    /// The item-type sections shown under "Collect".
    private var collectSections: [SidebarSection] {
        [.thoughts, .ideas, .notes, .reminders, .quotes, .links, .photos]
    }
}

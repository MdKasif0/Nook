import SwiftUI

/// Routes the detail pane content based on the selected sidebar section.
struct DetailView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            switch appState.selectedSection {
            case .room:
                RoomView()
            case .archive:
                ItemListView(
                    title: "Archive",
                    icon: "archivebox",
                    filter: .archived
                )
            case let section? where section.itemType != nil:
                ItemListView(
                    title: section.rawValue,
                    icon: section.iconName,
                    filter: .itemType(section.itemType!)
                )
            case nil:
                RoomView()
            default:
                RoomView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NookDesign.Colors.backgroundPrimary)
    }
}

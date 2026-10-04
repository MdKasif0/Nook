import SwiftUI
import SwiftData

/// A filterable list of NookItems, used for the type-specific sidebar sections.
struct ItemListView: View {
    
    let title: String
    let icon: String
    let filter: ItemFilter
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [NookItem]
    
    @State private var isShowingNewItemSheet = false
    
    init(title: String, icon: String, filter: ItemFilter) {
        self.title = title
        self.icon = icon
        self.filter = filter
    }
    
    private var filteredItems: [NookItem] {
        switch filter {
        case .itemType(let type):
            return allItems.filter { $0.itemType == type && !$0.isArchived }
        case .archived:
            return allItems.filter { $0.isArchived }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if filteredItems.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredItems) { item in
                        ItemRowView(item: item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(filteredItems[index])
                        }
                    }
                }
                .listStyle(.inset)
                .alternatingRowBackgrounds()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NookDesign.Colors.backgroundPrimary)
        .navigationTitle(title)
        .toolbar {
            if case .itemType(let type) = filter {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingNewItemSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add new \(type.displayName.lowercased())")
                }
            }
        }
        .sheet(isPresented: $isShowingNewItemSheet) {
            if case .itemType(let type) = filter {
                NewItemSheet(preselectedType: type) { title, content, itemType, objectType in
                    let newItem = NookItem(title: title, content: content, itemType: itemType, objectType: objectType)
                    modelContext.insert(newItem)
                    isShowingNewItemSheet = false
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Text("No \(title.lowercased()) yet")
                .font(NookDesign.Typography.subheading)
                .foregroundStyle(NookDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Defines which items to show.
enum ItemFilter {
    case itemType(NookItemType)
    case archived
}

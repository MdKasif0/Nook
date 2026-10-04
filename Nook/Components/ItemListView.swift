import SwiftUI
import SwiftData

/// A filterable list of NookItems, used for the type-specific sidebar sections and Archive.
struct ItemListView: View {
    
    let title: String
    let icon: String
    let filter: ItemFilter
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) private var appState
    @Query(sort: \NookItem.updatedAt, order: .reverse) private var allItems: [NookItem]
    
    @State private var isShowingNewItemSheet = false
    @State private var selectedDetailItem: NookItem?
    
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDetailItem = item
                            }
                            .contextMenu {
                                if item.isArchived {
                                    Button {
                                        NookActionService.shared.unarchiveItem(
                                            item,
                                            in: modelContext,
                                            undoManager: undoManager,
                                            appState: appState
                                        )
                                    } label: {
                                        Label("Restore to Room", systemImage: "arrow.uturn.backward")
                                    }
                                } else {
                                    Button {
                                        NookActionService.shared.archiveItem(
                                            item,
                                            in: modelContext,
                                            undoManager: undoManager,
                                            appState: appState
                                        )
                                    } label: {
                                        Label("Archive Thought", systemImage: "archivebox")
                                    }
                                }
                                
                                Button {
                                    appState.focusItemInRoom(id: item.id)
                                } label: {
                                    Label("View in Room", systemImage: "house")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    NookActionService.shared.deleteItem(
                                        item,
                                        in: modelContext,
                                        undoManager: undoManager,
                                        appState: appState
                                    )
                                } label: {
                                    Label("Delete (⌘Z to Undo)", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = filteredItems[index]
                            NookActionService.shared.deleteItem(
                                item,
                                in: modelContext,
                                undoManager: undoManager,
                                appState: appState
                            )
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
                    PersistenceController.shared.safeSave(context: modelContext, appState: appState)
                    isShowingNewItemSheet = false
                }
            }
        }
        .sheet(item: $selectedDetailItem) { item in
            ThoughtDetailSheet(
                item: item,
                onEdit: {
                    // Handled within detail sheet
                },
                onMove: { zone in
                    let newPos = zone.naturalPosition(existingCount: allItems.count)
                    NookActionService.shared.moveItem(item, to: newPos, in: modelContext, undoManager: undoManager, appState: appState)
                },
                onArchive: {
                    if item.isArchived {
                        NookActionService.shared.unarchiveItem(item, in: modelContext, undoManager: undoManager, appState: appState)
                    } else {
                        NookActionService.shared.archiveItem(item, in: modelContext, undoManager: undoManager, appState: appState)
                    }
                },
                onDelete: {
                    NookActionService.shared.deleteItem(item, in: modelContext, undoManager: undoManager, appState: appState)
                }
            )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Text(filterTitleEmptyText)
                .font(NookDesign.Typography.subheading)
                .foregroundStyle(NookDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filterTitleEmptyText: String {
        switch filter {
        case .itemType:
            return "No \(title.lowercased()) yet"
        case .archived:
            return "No archived thoughts"
        }
    }
}

/// Defines which items to show.
enum ItemFilter {
    case itemType(NookItemType)
    case archived
}

import SwiftUI
import SwiftData

/// A spotlight-style floating Command Palette triggered via ⌘K.
///
/// Features:
/// - Fast in-memory tokenized local search using `LocalSearchIndex`.
/// - Instant multi-token prefix matching across title, content, item type, and object type.
/// - Weighted relevance scoring.
/// - Complete local-first operation without any search server or network requests.
/// - Full searchability across both active thoughts and archived thoughts.
struct SearchPaletteView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NookItem.updatedAt, order: .reverse)
    private var allItems: [NookItem]
    
    let onSelectItem: (UUID) -> Void
    let onClose: () -> Void
    
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isFieldFocused: Bool
    
    // In-memory tokenized search engine
    private let searchIndex = LocalSearchIndex()
    
    // Search Results calculated via local inverted index
    private var searchResults: [LocalSearchIndex.SearchResult] {
        searchIndex.search(query: query, includeArchived: true, limit: 30)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop to dismiss
            Color.black.opacity(0.30)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            // Floating Command Card
            VStack(spacing: 0) {
                // Search Input Header
                HStack(spacing: NookDesign.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(NookDesign.Colors.olive)
                    
                    TextField("Search thoughts, notes, pebbles... (⌘K)", text: $query)
                        .textFieldStyle(.plain)
                        .font(NookDesign.Typography.body)
                        .focused($isFieldFocused)
                        .onSubmit {
                            selectCurrent()
                        }
                    
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // ESC badge
                    Text("esc")
                        .font(NookDesign.Typography.mono)
                        .font(.system(size: 10))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(NookDesign.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.horizontal, NookDesign.Spacing.md)
                .padding(.vertical, NookDesign.Spacing.md)
                
                Divider()
                    .foregroundStyle(NookDesign.Colors.surfaceBorder)
                
                // Results List
                if searchResults.isEmpty {
                    VStack(spacing: NookDesign.Spacing.xs) {
                        Image(systemName: "tray")
                            .font(.system(size: 20))
                            .foregroundStyle(NookDesign.Colors.textTertiary)
                            .padding(.top, NookDesign.Spacing.lg)
                        
                        Text("No matching thoughts found")
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textSecondary)
                        
                        Text("Search matches title, content, item category, or physical object type")
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textTertiary)
                            .padding(.bottom, NookDesign.Spacing.lg)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, result in
                                    searchResultRow(result: result, isSelected: index == selectedIndex)
                                        .id(index)
                                        .onTapGesture {
                                            chooseItem(result.item)
                                        }
                                }
                            }
                            .padding(.vertical, NookDesign.Spacing.xs)
                            .padding(.horizontal, NookDesign.Spacing.xs)
                        }
                        .frame(maxHeight: 320)
                        .onChange(of: selectedIndex) { _, newIndex in
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                
                // Footer
                Divider()
                    .foregroundStyle(NookDesign.Colors.surfaceBorder)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down")
                            .font(.system(size: 10))
                        Text("Navigate")
                            .font(NookDesign.Typography.caption)
                    }
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    
                    Text("•")
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                    
                    HStack(spacing: 4) {
                        Text("↵")
                            .font(.system(size: 11, weight: .bold))
                        Text("Focus in Room")
                            .font(NookDesign.Typography.caption)
                    }
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    
                    Spacer()
                    
                    Text("\(searchResults.count) \(searchResults.count == 1 ? "thought" : "thoughts")")
                        .font(NookDesign.Typography.mono)
                        .font(.system(size: 11))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                .padding(.horizontal, NookDesign.Spacing.md)
                .padding(.vertical, NookDesign.Spacing.xs + 2)
                .background(NookDesign.Colors.backgroundSecondary.opacity(0.5))
            }
            .frame(width: 520)
            .background(NookDesign.Colors.surface.opacity(0.98))
            .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous)
                    .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.8)
            )
            .nookShadow(NookDesign.Shadow.elevated)
        }
        .onAppear {
            isFieldFocused = true
            selectedIndex = 0
            searchIndex.rebuild(with: allItems)
        }
        .task(id: allItems) {
            searchIndex.rebuild(with: allItems)
        }
        .onChange(of: query) { _, _ in
            selectedIndex = 0
        }
    }
    
    // MARK: - Result Row
    
    private func searchResultRow(result: LocalSearchIndex.SearchResult, isSelected: Bool) -> some View {
        let item = result.item
        
        return HStack(spacing: NookDesign.Spacing.sm) {
            // Physical Object Icon Badge
            ZStack {
                Circle()
                    .fill(item.objectType.tintColor.opacity(isSelected ? 0.22 : 0.12))
                    .frame(width: 30, height: 30)
                
                Image(systemName: item.objectType.iconName)
                    .font(.system(size: 13))
                    .foregroundStyle(item.objectType.tintColor)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(NookDesign.Typography.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                        .lineLimit(1)
                    
                    if result.isArchived {
                        HStack(spacing: 3) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 9))
                            Text("Archived")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(NookDesign.Colors.backgroundSecondary)
                        .clipShape(Capsule())
                    }
                }
                
                if !item.content.isEmpty {
                    Text(item.content.replacingOccurrences(of: "\n", with: " "))
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Object Type Tag
            HStack(spacing: 3) {
                Text(item.objectType.displayName)
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(item.objectType.tintColor)
                
                if isSelected {
                    Text("↵")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(NookDesign.Colors.olive)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isSelected ? item.objectType.tintColor.opacity(0.15) : NookDesign.Colors.backgroundSecondary)
            .clipShape(Capsule())
        }
        .padding(.horizontal, NookDesign.Spacing.sm)
        .padding(.vertical, NookDesign.Spacing.xs + 2)
        .background(isSelected ? NookDesign.Colors.olive.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
        .contentShape(Rectangle())
    }
    
    private func selectCurrent() {
        guard !searchResults.isEmpty else { return }
        let clampedIndex = min(max(0, selectedIndex), searchResults.count - 1)
        chooseItem(searchResults[clampedIndex].item)
    }
    
    private func chooseItem(_ item: NookItem) {
        AudioManager.shared.playObjectSelected()
        if item.isArchived {
            // If the user selected an archived item, unarchive it so it reappears in their room!
            item.isArchived = false
            item.touch()
            try? modelContext.save()
        }
        onSelectItem(item.id)
    }
}

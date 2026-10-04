import SwiftUI
import SwiftData

/// A spotlight-style floating Command Palette triggered via ⌘K.
///
/// Searches locally through title, content, and item type.
/// Displays physical object manifestations and allows instant navigation to the 3D room.
struct SearchPaletteView: View {
    
    @Environment(AppState.self) private var appState
    @Query(
        filter: #Predicate<NookItem> { !$0.isArchived },
        sort: \NookItem.createdAt,
        order: .reverse
    )
    private var allItems: [NookItem]
    
    let onSelectItem: (UUID) -> Void
    let onClose: () -> Void
    
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isFieldFocused: Bool
    
    // Filtered results
    private var filteredItems: [NookItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Array(allItems.prefix(8))
        }
        
        return allItems.filter { item in
            item.title.localizedCaseInsensitiveContains(trimmed) ||
            item.content.localizedCaseInsensitiveContains(trimmed) ||
            item.objectType.displayName.localizedCaseInsensitiveContains(trimmed) ||
            item.itemType.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop to dismiss
            Color.black.opacity(0.28)
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
                if filteredItems.isEmpty {
                    VStack(spacing: NookDesign.Spacing.xs) {
                        Image(systemName: "tray")
                            .font(.system(size: 20))
                            .foregroundStyle(NookDesign.Colors.textTertiary)
                            .padding(.top, NookDesign.Spacing.lg)
                        
                        Text("No matching objects found")
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textSecondary)
                        
                        Text("Try searching by thought text, note, or object type like \"pebble\"")
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textTertiary)
                            .padding(.bottom, NookDesign.Spacing.lg)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                    searchResultRow(item: item, isSelected: index == selectedIndex)
                                        .id(index)
                                        .onTapGesture {
                                            chooseItem(item)
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
                    
                    Text("\(filteredItems.count) \(filteredItems.count == 1 ? "thought" : "thoughts")")
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
        }
    }
    
    // MARK: - Result Row
    
    private func searchResultRow(item: NookItem, isSelected: Bool) -> some View {
        HStack(spacing: NookDesign.Spacing.sm) {
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
                Text(item.title)
                    .font(NookDesign.Typography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                    .lineLimit(1)
                
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
        guard !filteredItems.isEmpty else { return }
        let clampedIndex = min(max(0, selectedIndex), filteredItems.count - 1)
        chooseItem(filteredItems[clampedIndex])
    }
    
    private func chooseItem(_ item: NookItem) {
        AudioManager.shared.playObjectSelected()
        onSelectItem(item.id)
    }
}

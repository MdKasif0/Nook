import SwiftUI

/// A sheet for creating a new NookItem.
///
/// Supports optional preselection of the item type (when opened from
/// a type-specific section) and falls back to a picker otherwise.
struct NewItemSheet: View {
    
    var preselectedType: NookItemType?
    let onSave: (String, String, NookItemType, NookObjectType) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedType: NookItemType = .thought
    @State private var selectedObjectType: NookObjectType = .pebble
    
    init(
        preselectedType: NookItemType? = nil,
        onSave: @escaping (String, String, NookItemType, NookObjectType) -> Void
    ) {
        self.preselectedType = preselectedType
        self.onSave = onSave
        if let preselectedType {
            _selectedType = State(initialValue: preselectedType)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Thought")
                    .font(NookDesign.Typography.subheading)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(NookDesign.Spacing.xl)
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
            
            // Form
            VStack(alignment: .leading, spacing: NookDesign.Spacing.lg) {
                // Title
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(NookDesign.Typography.body)
                
                // Content
                TextEditor(text: $content)
                    .font(NookDesign.Typography.body)
                    .frame(minHeight: 50, maxHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(NookDesign.Spacing.sm)
                    .background(NookDesign.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous)
                            .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5)
                    )
                
                // Physical Object Picker
                VStack(alignment: .leading, spacing: NookDesign.Spacing.xs) {
                    Text("Physical Object:")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                    
                    ObjectPickerView(selectedObjectType: $selectedObjectType)
                }
            }
            .padding(NookDesign.Spacing.xl)
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
            
            // Actions
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Place in Room") {
                    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onSave(title, content, selectedType, selectedObjectType)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(NookDesign.Spacing.xl)
        }
        .frame(width: 440)
        .background(NookDesign.Colors.backgroundPrimary)
    }
}

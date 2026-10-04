import SwiftUI

/// A sheet for creating a new NookItem.
///
/// Supports optional preselection of the item type (when opened from
/// a type-specific section) and falls back to a picker otherwise.
struct NewItemSheet: View {
    
    var preselectedType: NookItemType?
    let onSave: (String, String, NookItemType) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedType: NookItemType = .thought
    
    init(
        preselectedType: NookItemType? = nil,
        onSave: @escaping (String, String, NookItemType) -> Void
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
                Text("New \(selectedType.displayName)")
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
            VStack(spacing: NookDesign.Spacing.lg) {
                // Type picker (only when no preselection)
                if preselectedType == nil {
                    Picker("Type", selection: $selectedType) {
                        ForEach(NookItemType.allCases) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Title
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(NookDesign.Typography.body)
                
                // Content
                TextEditor(text: $content)
                    .font(NookDesign.Typography.body)
                    .frame(minHeight: 60, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(NookDesign.Spacing.sm)
                    .background(NookDesign.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous)
                            .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5)
                    )
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
                
                Button("Save") {
                    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onSave(title, content, selectedType)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(NookDesign.Spacing.xl)
        }
        .frame(width: 380)
        .background(NookDesign.Colors.backgroundPrimary)
    }
}

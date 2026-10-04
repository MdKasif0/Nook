import SwiftUI
import SwiftData

/// A minimal, fast window for capturing a thought without opening the full app.
struct QuickCaptureView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var selectedType: NookItemType = .thought
    
    var body: some View {
        VStack(spacing: NookDesign.Spacing.lg) {
            // Header
            HStack(spacing: NookDesign.Spacing.sm) {
                Image(systemName: "bolt")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NookDesign.Colors.olive)
                
                Text("Quick Thought")
                    .font(NookDesign.Typography.subheading)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Spacer()
                
                Picker("", selection: $selectedType) {
                    ForEach(NookItemType.allCases) { type in
                        Label(type.displayName, systemImage: type.iconName)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 110)
            }
            
            // Input
            TextField("What's on your mind?", text: $title)
                .textFieldStyle(.plain)
                .font(NookDesign.Typography.body)
                .padding(NookDesign.Spacing.md)
                .background(NookDesign.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
                .onSubmit {
                    save()
                }
            
            // Actions
            HStack {
                Text("Press ↵ to save")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(NookDesign.Spacing.xl)
        .frame(width: 380, height: 160)
        .background(NookDesign.Colors.backgroundPrimary)
    }
    
    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let item = NookItem(title: trimmed, itemType: selectedType)
        modelContext.insert(item)
        dismiss()
    }
}

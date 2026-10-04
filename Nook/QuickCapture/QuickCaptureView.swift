import SwiftUI
import SwiftData

/// A minimal, tactile window for capturing a thought and choosing its physical manifestation.
///
/// Triggered via Command + Shift + Space.
struct QuickCaptureView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedObjectType: NookObjectType = .pebble // Default is Pebble
    @State private var selectedZone: PlacementZone = .deskCenter
    
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.lg) {
            // Header
            HStack(spacing: NookDesign.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NookDesign.Colors.olive)
                
                Text("Quick Thought")
                    .font(NookDesign.Typography.subheading)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            // Thought Input TextField
            VStack(alignment: .leading, spacing: NookDesign.Spacing.xs) {
                TextField("I should build a local AI coding assistant...", text: $title)
                    .textFieldStyle(.plain)
                    .font(NookDesign.Typography.body)
                    .focused($isTitleFocused)
                    .padding(NookDesign.Spacing.md)
                    .background(NookDesign.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous)
                            .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5)
                    )
                    .onSubmit {
                        save()
                    }
            }
            
            // Physical Object Representation Picker
            VStack(alignment: .leading, spacing: NookDesign.Spacing.xs) {
                Text("Manifests as:")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                
                ObjectPickerView(selectedObjectType: $selectedObjectType)
            }
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
            
            // Footer Actions
            HStack {
                Text("Press ↵ to place in room")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button {
                    save()
                } label: {
                    HStack(spacing: NookDesign.Spacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Place Object")
                            .font(NookDesign.Typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(NookDesign.Colors.backgroundPrimary)
                    .padding(.horizontal, NookDesign.Spacing.md)
                    .padding(.vertical, NookDesign.Spacing.xs + 2)
                    .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? NookDesign.Colors.taupe : NookDesign.Colors.olive)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(NookDesign.Spacing.xl)
        .frame(width: 440)
        .background(NookDesign.Colors.backgroundPrimary)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTitleFocused = true
            }
        }
    }
    
    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let position = selectedZone.naturalPosition()
        let item = NookItem(
            title: trimmed,
            content: content,
            itemType: .thought,
            objectType: selectedObjectType,
            position: position
        )
        modelContext.insert(item)
        dismiss()
    }
}

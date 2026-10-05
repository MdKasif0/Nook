import SwiftUI
import SwiftData

/// A tactile floating window for capturing a thought and choosing its physical manifestation.
///
/// Designed to feel like a tiny piece of paper floating gently above the desktop.
/// Triggered globally via Command + Shift + Space.
struct QuickCaptureView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<NookItem> { !$0.isArchived })
    private var existingItems: [NookItem]
    
    @State private var content: String = ""
    @State private var optionalTitle: String = ""
    @State private var selectedObjectType: NookObjectType = .pebble
    
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.md) {
            // Header: "What are you thinking about?" with subtle contextual hint
            HStack(alignment: .top, spacing: NookDesign.Spacing.sm) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NookDesign.Colors.olive)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("What are you thinking about?")
                        .font(NookDesign.Typography.subheading)
                        .fontWeight(.medium)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                    
                    Text("Turn a thought into something you can keep.")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help("Dismiss (esc)")
                .accessibilityLabel("Dismiss Quick Thought")
            }
            
            // Large Thought Content TextField
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("Type a thought, idea, memory, or note...")
                        .font(NookDesign.Typography.body)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .padding(.horizontal, NookDesign.Spacing.md)
                        .padding(.vertical, NookDesign.Spacing.sm + 2)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $content)
                    .font(NookDesign.Typography.body)
                    .focused($isContentFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, NookDesign.Spacing.sm)
                    .padding(.vertical, NookDesign.Spacing.xs)
                    .frame(minHeight: 70, maxHeight: 110)
                    .accessibilityLabel("Thought content")
            }
            .background(NookDesign.Colors.backgroundSecondary.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous)
                    .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.6)
            )
            
            // Optional Title Field
            TextField("Title (optional)", text: $optionalTitle)
                .textFieldStyle(.plain)
                .font(NookDesign.Typography.caption)
                .padding(.horizontal, NookDesign.Spacing.md)
                .padding(.vertical, NookDesign.Spacing.xs + 2)
                .background(NookDesign.Colors.backgroundSecondary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous)
                        .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5)
                )
                .accessibilityLabel("Thought title (optional)")
                .onSubmit {
                    saveAndMaterialize()
                }
            
            // Physical Object Selector
            VStack(alignment: .leading, spacing: NookDesign.Spacing.xxs) {
                Text("Manifests in your room as:")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                
                ObjectPickerView(selectedObjectType: $selectedObjectType)
            }
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
            
            // Footer: Keyboard shortcuts & Action buttons
            HStack {
                Text("⌘↵ or Enter to place")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .font(NookDesign.Typography.caption)
                .foregroundStyle(NookDesign.Colors.textSecondary)
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                
                Button {
                    saveAndMaterialize()
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
                    .background(canCreate ? NookDesign.Colors.olive : NookDesign.Colors.taupe.opacity(0.5))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canCreate)
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel("Place Object in Room")
            }
        }
        .padding(NookDesign.Spacing.lg)
        .frame(width: 440)
        .background(NookDesign.Colors.paper)
        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous)
                .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.8)
        )
        .nookShadow(NookDesign.Shadow.elevated)
        .onAppear {
            isContentFocused = true
        }
    }
    
    private var canCreate: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !optionalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveAndMaterialize() {
        guard canCreate else { return }
        
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = optionalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalTitle: String
        let finalContent: String
        
        if !trimmedTitle.isEmpty {
            finalTitle = trimmedTitle
            finalContent = trimmedContent
        } else {
            // First sentence or first 45 characters
            let firstLine = trimmedContent.components(separatedBy: .newlines).first ?? trimmedContent
            if firstLine.count > 50 {
                finalTitle = String(firstLine.prefix(47)) + "..."
            } else {
                finalTitle = firstLine
            }
            finalContent = trimmedContent
        }
        
        // Find intelligent placement zone and collision-free slot
        let targetZone = PlacementZone.defaultZone(for: .thought, objectType: selectedObjectType)
        let existingWorldPositions = existingItems.map { ThoughtEntityBuilder.worldPosition(for: $0.roomPosition) }
        let naturalWorldPos = targetZone.allocateNaturalPosition(existingWorldPositions: existingWorldPositions)
        let position = ThoughtEntityBuilder.roomPosition(from: naturalWorldPos)
        
        let item = NookItem(
            title: finalTitle,
            content: finalContent,
            itemType: .thought,
            objectType: selectedObjectType,
            position: position
        )
        
        modelContext.insert(item)
        PersistenceController.shared.safeSave(context: modelContext)
        
        // Play gentle tactile feedback
        AudioManager.shared.playObjectPlaced()
        
        // Broadcast to notify main room and Cookie
        RoomEventBus.shared.publish(.itemCreated(
            title: finalTitle,
            itemType: .thought,
            objectType: selectedObjectType,
            position: position
        ))
        RoomEventBus.shared.publish(.thoughtCaptured(
            title: finalTitle,
            objectType: selectedObjectType
        ))
        
        // Close floating window
        dismiss()
    }
}

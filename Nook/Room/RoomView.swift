import SwiftUI
import SwiftData
import SceneKit

/// The main room view — the heart of Nook.
///
/// Presents a realistic miniature 3D diorama room with warm daylight,
/// wooden desk, cozy chair, bookshelf, dynamic outdoor window,
/// toggleable desk lamp, and Cookie the cat.
///
/// Features Nook's core concept: Thoughts Become Physical Objects,
/// supporting tactile dragging, object selection, editing, moving, and onboarding.
struct RoomView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<NookItem> { !$0.isArchived },
        sort: \NookItem.createdAt,
        order: .reverse
    )
    private var items: [NookItem]
    
    @State private var sceneController = RoomSceneController()
    @State private var isShowingNewItemSheet = false
    @State private var cookieToastMessage: String?
    @State private var cookieToastDismissTask: Task<Void, Never>?
    @State private var detailItem: NookItem?
    
    // Inspector editing state
    @State private var isEditingSelectedItem = false
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editObjectType: NookObjectType = .pebble
    
    var selectedItem: NookItem? {
        guard let id = sceneController.selectedItemID else { return nil }
        return items.first { $0.id == id }
    }
    
    var body: some View {
        ZStack {
            // 3D Miniature Diorama Room
            RoomSceneView(
                controller: sceneController,
                onSelectItem: { id in
                    withAnimation(NookDesign.Animation.springy) {
                        selectItem(id)
                    }
                },
                onItemMoved: { id, newPosition in
                    handleItemMoved(id: id, newPosition: newPosition)
                },
                onOpenItem: { id in
                    if let item = items.first(where: { $0.id == id }) {
                        detailItem = item
                    }
                },
                onToggleLamp: {
                    sceneController.toggleDeskLamp()
                },
                onPetCookie: {
                    handleCookieInteraction()
                }
            )
            .ignoresSafeArea()
            
            // Floating Overlays & Controls
            VStack(spacing: 0) {
                // Top Room Control Bar
                roomControlHeader
                    .padding(.horizontal, NookDesign.Spacing.lg)
                    .padding(.top, NookDesign.Spacing.md)
                
                Spacer()
                
                // Bottom Area: Selected Item Inspector or Cookie Toast
                HStack(alignment: .bottom) {
                    // Cookie Toast / Reaction (Bottom Left, near Cookie's area)
                    if let message = cookieToastMessage {
                        cookieToastBubble(message)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                    }
                    
                    Spacer()
                    
                    // Selected Item Floating Inspector Card (Bottom Right)
                    if let item = selectedItem {
                        selectedItemInspector(for: item)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            ))
                    }
                }
                .padding(NookDesign.Spacing.xl)
            }
        }
        .task(id: items) {
            sceneController.syncItems(items)
            seedOnboardingItemIfNeeded()
        }
        .onChange(of: sceneController.cookieMessage) { _, newMsg in
            if let newMsg {
                showCookieToast(newMsg)
            }
        }
        .sheet(isPresented: $isShowingNewItemSheet) {
            NewItemSheet { title, content, type, objectType in
                let position = PlacementZone.deskCenter.naturalPosition(existingCount: items.count)
                let newItem = NookItem(
                    title: title,
                    content: content,
                    itemType: type,
                    objectType: objectType,
                    position: position
                )
                modelContext.insert(newItem)
                try? modelContext.save()
                isShowingNewItemSheet = false
                
                // Select the freshly materialized object in the room
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(NookDesign.Animation.springy) {
                        selectItem(newItem.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Top floating bar for lighting, atmosphere, and desk status.
    private var roomControlHeader: some View {
        HStack(spacing: NookDesign.Spacing.md) {
            // Time of Day Selector
            HStack(spacing: NookDesign.Spacing.xxs) {
                ForEach(RoomTimeOfDay.allCases) { tod in
                    Button {
                        sceneController.setTimeOfDay(tod)
                    } label: {
                        HStack(spacing: NookDesign.Spacing.xs) {
                            Image(systemName: tod.iconName)
                                .font(.system(size: 11, weight: .medium))
                            if sceneController.timeOfDay == tod {
                                Text(tod.rawValue)
                                    .font(NookDesign.Typography.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, NookDesign.Spacing.sm)
                        .padding(.vertical, NookDesign.Spacing.xs)
                        .foregroundStyle(sceneController.timeOfDay == tod ? NookDesign.Colors.textPrimary : NookDesign.Colors.textSecondary)
                        .background(sceneController.timeOfDay == tod ? NookDesign.Colors.backgroundPrimary : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Set lighting to \(tod.rawValue)")
                }
            }
            .padding(NookDesign.Spacing.xxs)
            .background(NookDesign.Colors.surface.opacity(0.92))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
            .nookShadow(NookDesign.Shadow.subtle)
            
            // Desk Lamp Toggle Button
            Button {
                sceneController.toggleDeskLamp()
            } label: {
                HStack(spacing: NookDesign.Spacing.xs) {
                    Image(systemName: sceneController.isDeskLampOn ? "lamp.desk.fill" : "lamp.desk")
                        .font(.system(size: 12))
                        .foregroundStyle(sceneController.isDeskLampOn ? NookDesign.Colors.terracotta : NookDesign.Colors.textSecondary)
                    
                    Text("Lamp")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                }
                .padding(.horizontal, NookDesign.Spacing.md)
                .padding(.vertical, NookDesign.Spacing.xs + 2)
                .background(NookDesign.Colors.surface.opacity(0.92))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
                .nookShadow(NookDesign.Shadow.subtle)
            }
            .buttonStyle(.plain)
            .help(sceneController.isDeskLampOn ? "Turn off desk lamp" : "Turn on desk lamp")
            
            Spacer()
            
            // Room item counter badge
            HStack(spacing: NookDesign.Spacing.xs) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 11))
                    .foregroundStyle(NookDesign.Colors.woodBrown)
                
                Text(items.count == 1 ? "1 physical object" : "\(items.count) physical objects")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
            }
            .padding(.horizontal, NookDesign.Spacing.md)
            .padding(.vertical, NookDesign.Spacing.xs + 2)
            .background(NookDesign.Colors.surface.opacity(0.92))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
            .nookShadow(NookDesign.Shadow.subtle)
            
            // Add Item Button
            Button {
                isShowingNewItemSheet = true
            } label: {
                HStack(spacing: NookDesign.Spacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Place Thought")
                        .font(NookDesign.Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(NookDesign.Colors.backgroundPrimary)
                .padding(.horizontal, NookDesign.Spacing.md)
                .padding(.vertical, NookDesign.Spacing.xs + 2)
                .background(NookDesign.Colors.olive)
                .clipShape(Capsule())
                .nookShadow(NookDesign.Shadow.subtle)
            }
            .buttonStyle(.plain)
            .help("Add a new thought or note to your room (⌘⇧Space)")
        }
    }
    
    /// Contextual inspector panel when an object in the 3D room is selected.
    private func selectedItemInspector(for item: NookItem) -> some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.md) {
            // Inspector Header: Object token + type name + close button
            HStack {
                HStack(spacing: NookDesign.Spacing.xs) {
                    Image(systemName: item.objectType.iconName)
                        .font(.system(size: 11))
                    Text(item.objectType.displayName)
                        .font(NookDesign.Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(item.objectType.tintColor)
                .padding(.horizontal, NookDesign.Spacing.sm)
                .padding(.vertical, NookDesign.Spacing.xxs)
                .background(item.objectType.tintColor.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                Button {
                    withAnimation(NookDesign.Animation.springy) {
                        sceneController.selectedItemID = nil
                        isEditingSelectedItem = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .padding(NookDesign.Spacing.xxs)
                }
                .buttonStyle(.plain)
                .help("Close inspector")
            }
            
            if isEditingSelectedItem {
                // EDITING MODE
                VStack(alignment: .leading, spacing: NookDesign.Spacing.md) {
                    TextField("Title", text: $editTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(NookDesign.Typography.body)
                    
                    TextEditor(text: $editContent)
                        .font(NookDesign.Typography.body)
                        .frame(minHeight: 50, maxHeight: 90)
                        .scrollContentBackground(.hidden)
                        .padding(NookDesign.Spacing.xs)
                        .background(NookDesign.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous)
                                .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5)
                        )
                    
                    VStack(alignment: .leading, spacing: NookDesign.Spacing.xxs) {
                        Text("Object Representation:")
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textSecondary)
                        
                        ObjectPickerView(selectedObjectType: $editObjectType)
                    }
                    
                    HStack {
                        Button("Cancel") {
                            withAnimation(NookDesign.Animation.standard) {
                                isEditingSelectedItem = false
                            }
                        }
                        .font(NookDesign.Typography.caption)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveEdits(for: item)
                        }
                        .font(NookDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(NookDesign.Colors.backgroundPrimary)
                        .padding(.horizontal, NookDesign.Spacing.md)
                        .padding(.vertical, NookDesign.Spacing.xxs + 2)
                        .background(NookDesign.Colors.olive)
                        .clipShape(Capsule())
                    }
                }
            } else {
                // VIEW MODE
                VStack(alignment: .leading, spacing: NookDesign.Spacing.sm) {
                    Text(item.title)
                        .font(NookDesign.Typography.subheading)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                        .lineLimit(3)
                    
                    if !item.content.isEmpty {
                        Text(item.content)
                            .font(NookDesign.Typography.body)
                            .foregroundStyle(NookDesign.Colors.textSecondary)
                            .lineLimit(6)
                    }
                }
                
                Divider()
                    .foregroundStyle(NookDesign.Colors.surfaceBorder)
                
                // Footer: Timestamp & Actions
                VStack(alignment: .leading, spacing: NookDesign.Spacing.sm) {
                    HStack {
                        Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(NookDesign.Typography.mono)
                            .foregroundStyle(NookDesign.Colors.textTertiary)
                        
                        Spacer()
                        
                        Text("Drag to rearrange")
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textTertiary)
                    }
                    
                    // Native Action Bar: Open, Edit, Move, Delete, Archive
                    HStack(spacing: NookDesign.Spacing.xs) {
                        // Edit Action
                        Button {
                            beginEditing(item)
                        } label: {
                            HStack(spacing: NookDesign.Spacing.xxs) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                Text("Edit")
                                    .font(NookDesign.Typography.caption)
                            }
                            .foregroundStyle(NookDesign.Colors.textPrimary)
                            .padding(.horizontal, NookDesign.Spacing.sm)
                            .padding(.vertical, NookDesign.Spacing.xxs + 1)
                            .background(NookDesign.Colors.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .help("Edit title, content, or object type")
                        
                        // Accessible Move Menu
                        Menu {
                            ForEach(PlacementZone.allCases) { zone in
                                Button {
                                    moveItem(item, to: zone)
                                } label: {
                                    Label(zone.displayName, systemImage: zone.iconName)
                                }
                            }
                        } label: {
                            HStack(spacing: NookDesign.Spacing.xxs) {
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .font(.system(size: 10))
                                Text("Move")
                                    .font(NookDesign.Typography.caption)
                            }
                            .foregroundStyle(NookDesign.Colors.textPrimary)
                            .padding(.horizontal, NookDesign.Spacing.sm)
                            .padding(.vertical, NookDesign.Spacing.xxs + 1)
                            .background(NookDesign.Colors.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous))
                        }
                        .menuStyle(.borderlessButton)
                        .help("Move object to a placement zone")
                        
                        Spacer()
                        
                        // Archive Action
                        Button {
                            withAnimation(NookDesign.Animation.standard) {
                                item.isArchived = true
                                sceneController.selectedItemID = nil
                                try? modelContext.save()
                            }
                        } label: {
                            Image(systemName: "archivebox")
                                .font(.system(size: 11))
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                                .padding(NookDesign.Spacing.xxs + 2)
                        }
                        .buttonStyle(.plain)
                        .help("Archive this object from the room")
                        
                        // Delete Action
                        Button {
                            withAnimation(NookDesign.Animation.standard) {
                                sceneController.selectedItemID = nil
                                modelContext.delete(item)
                                try? modelContext.save()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(NookDesign.Colors.terracotta)
                                .padding(NookDesign.Spacing.xxs + 2)
                        }
                        .buttonStyle(.plain)
                        .help("Permanently delete this thought")
                    }
                }
            }
        }
        .padding(NookDesign.Spacing.lg)
        .frame(width: 350)
        .background(NookDesign.Colors.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous)
                .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5)
        )
        .nookShadow(NookDesign.Shadow.elevated)
    }
    
    /// Speech bubble when Cookie is petted or clicked in the room.
    private func cookieToastBubble(_ message: String) -> some View {
        HStack(spacing: NookDesign.Spacing.sm) {
            Image(systemName: "cat.fill")
                .font(.system(size: 13))
                .foregroundStyle(NookDesign.Colors.terracotta)
            
            Text(message)
                .font(NookDesign.Typography.caption)
                .foregroundStyle(NookDesign.Colors.textPrimary)
        }
        .padding(.horizontal, NookDesign.Spacing.md)
        .padding(.vertical, NookDesign.Spacing.sm)
        .background(NookDesign.Colors.surface.opacity(0.95))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
        .nookShadow(NookDesign.Shadow.soft)
    }
    
    // MARK: - Interactions & Logic
    
    private func selectItem(_ id: UUID?) {
        sceneController.selectedItemID = id
        isEditingSelectedItem = false
    }
    
    private func handleItemMoved(id: UUID, newPosition: RoomPosition) {
        if let item = items.first(where: { $0.id == id }) {
            item.roomPosition = newPosition
            item.touch()
            try? modelContext.save()
        }
    }
    
    private func beginEditing(_ item: NookItem) {
        editTitle = item.title
        editContent = item.content
        editObjectType = item.objectType
        withAnimation(NookDesign.Animation.standard) {
            isEditingSelectedItem = true
        }
    }
    
    private func saveEdits(for item: NookItem) {
        item.title = editTitle
        item.content = editContent
        item.objectType = editObjectType
        item.touch()
        try? modelContext.save()
        
        withAnimation(NookDesign.Animation.standard) {
            isEditingSelectedItem = false
        }
    }
    
    private func moveItem(_ item: NookItem, to zone: PlacementZone) {
        let newPos = zone.naturalPosition(existingCount: items.count)
        item.roomPosition = newPos
        item.touch()
        try? modelContext.save()
        sceneController.moveItem(item.id, to: newPos)
    }
    
    private func handleCookieInteraction() {
        sceneController.petCookie()
    }
    
    private func showCookieToast(_ message: String) {
        cookieToastDismissTask?.cancel()
        withAnimation(NookDesign.Animation.springy) {
            cookieToastMessage = message
        }
        cookieToastDismissTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(NookDesign.Animation.gentle) {
                    cookieToastMessage = nil
                }
            }
        }
    }
    
    /// Seeds the subtle onboarding introductory Pebble on the desk if the room is empty.
    private func seedOnboardingItemIfNeeded() {
        guard items.isEmpty else { return }
        
        let welcomePebble = NookItem(
            title: "Welcome to your Nook.",
            content: "This is your quiet, miniature digital room. Your thoughts exist as physical objects.\n\n• Drag me anywhere across the desk\n• Click any object to inspect or edit\n• Press ⌘⇧Space anytime to capture a thought",
            itemType: .thought,
            objectType: .pebble,
            position: PlacementZone.deskCenter.basePosition
        )
        modelContext.insert(welcomePebble)
        try? modelContext.save()
    }
}

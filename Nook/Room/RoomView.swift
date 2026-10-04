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
/// Fully integrated with local-first persistence, native macOS undo (⌘Z),
/// room environment persistence, and graceful error recovery.
struct RoomView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) private var appState
    
    @Query(
        filter: #Predicate<NookItem> { !$0.isArchived },
        sort: \NookItem.createdAt,
        order: .reverse
    )
    private var items: [NookItem]
    
    @Query private var roomStates: [RoomState]
    
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
    @State private var isHeaderHovered = false
    
    private var currentRoomState: RoomState {
        if let first = roomStates.first {
            return first
        }
        let room = RoomState()
        modelContext.insert(room)
        PersistenceController.shared.safeSave(context: modelContext, appState: appState)
        return room
    }
    
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
                    persistRoomState()
                },
                onPetCookie: {
                    handleCookieInteraction()
                }
            )
            .ignoresSafeArea()
            
            // Floating Overlays & Controls
            VStack(spacing: 0) {
                // Top Persistence Error Alert Banner (if save error occurs)
                if let errorMsg = appState.persistenceErrorMessage {
                    persistenceErrorBanner(errorMsg)
                        .padding(.horizontal, NookDesign.Spacing.lg)
                        .padding(.top, NookDesign.Spacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Top Room Control Bar
                roomControlHeader
                    .padding(.horizontal, NookDesign.Spacing.lg)
                    .padding(.top, NookDesign.Spacing.md)
                
                Spacer()
                
                // Bottom Area: Undo Toast, Selected Item Inspector or Cookie Toast
                VStack(spacing: NookDesign.Spacing.sm) {
                    if let undoMessage = appState.undoToastMessage {
                        undoToastPill(undoMessage)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                    
                    HStack(alignment: .bottom) {
                        // Cookie Speech Bubble / Reaction (Bottom Left, near Cookie's area)
                        if let message = sceneController.cookieController.state.speechBubble ?? cookieToastMessage {
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
                }
                .padding(NookDesign.Spacing.xl)
            }
            
            // Command + K Spotlight Search Palette
            if appState.isSearchOpen {
                SearchPaletteView(
                    onSelectItem: { id in
                        appState.focusItemInRoom(id: id)
                    },
                    onClose: {
                        appState.closeSearch()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(100)
            }
        }
        .onAppear {
            sceneController.applySavedRoomState(currentRoomState)
            RoomEventBus.shared.publish(.roomOpened(wasAwayForDuration: 60))
            GlobalShortcutManager.shared.onEscapePressed = { [weak appState] in
                if let appState, appState.isSearchOpen {
                    appState.closeSearch()
                    return true
                }
                if sceneController.selectedItemID != nil {
                    withAnimation(NookDesign.Animation.springy) {
                        sceneController.selectedItemID = nil
                        sceneController.resetCameraFraming()
                    }
                    return true
                }
                return false
            }
        }
        .onChange(of: appState.focusedItemID) { _, newID in
            if let id = newID {
                withAnimation(NookDesign.Animation.springy) {
                    sceneController.focusItem(id: id)
                }
                appState.focusedItemID = nil
            }
        }
        .task(id: items) {
            sceneController.syncItems(items)
            seedOnboardingItemIfNeeded()
        }
        .sheet(isPresented: $isShowingNewItemSheet) {
            NewItemSheet { title, content, type, objectType in
                placeNewThought(title: title, content: content, type: type, objectType: objectType)
            }
        }
        .sheet(isPresented: Bindable(appState).isShowingNewThoughtSheet) {
            NewItemSheet { title, content, type, objectType in
                placeNewThought(title: title, content: content, type: type, objectType: objectType)
            }
        }
        .sheet(item: $detailItem) { item in
            ThoughtDetailSheet(
                item: item,
                onEdit: {
                    beginEditing(item)
                },
                onMove: { zone in
                    moveItem(item, to: zone)
                },
                onArchive: {
                    withAnimation(NookDesign.Animation.standard) {
                        sceneController.selectedItemID = nil
                        NookActionService.shared.archiveItem(
                            item,
                            in: modelContext,
                            undoManager: undoManager,
                            appState: appState
                        )
                    }
                },
                onDelete: {
                    withAnimation(NookDesign.Animation.standard) {
                        sceneController.selectedItemID = nil
                        NookActionService.shared.deleteItem(
                            item,
                            in: modelContext,
                            undoManager: undoManager,
                            appState: appState
                        )
                    }
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    /// User-friendly persistence error banner with "Try Again" recovery path.
    private func persistenceErrorBanner(_ message: String) -> some View {
        HStack(spacing: NookDesign.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(NookDesign.Colors.terracotta)
            
            Text(message)
                .font(NookDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(NookDesign.Colors.textPrimary)
            
            Spacer()
            
            Button("Try Again") {
                appState.persistenceRetryAction?()
            }
            .font(NookDesign.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(NookDesign.Colors.backgroundPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(NookDesign.Colors.terracotta)
            .clipShape(Capsule())
            
            Button {
                appState.clearPersistenceError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NookDesign.Spacing.md)
        .padding(.vertical, NookDesign.Spacing.xs + 3)
        .background(NookDesign.Colors.surface.opacity(0.96))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(NookDesign.Colors.terracotta.opacity(0.4), lineWidth: 0.8))
        .nookShadow(NookDesign.Shadow.elevated)
    }
    
    /// Subtle floating toast with native undo trigger and ⌘Z reminder.
    private func undoToastPill(_ message: String) -> some View {
        HStack(spacing: NookDesign.Spacing.sm) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NookDesign.Colors.olive)
            
            Text(message)
                .font(NookDesign.Typography.caption)
                .foregroundStyle(NookDesign.Colors.textPrimary)
            
            Text("•")
                .font(.system(size: 8))
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Text("⌘Z to Undo")
                .font(NookDesign.Typography.mono)
                .font(.system(size: 10))
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Button("Undo") {
                appState.undoToastAction?()
                appState.dismissUndoToast()
            }
            .font(NookDesign.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(NookDesign.Colors.backgroundPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(NookDesign.Colors.olive)
            .clipShape(Capsule())
        }
        .padding(.horizontal, NookDesign.Spacing.md)
        .padding(.vertical, NookDesign.Spacing.xs + 2)
        .background(NookDesign.Colors.surface.opacity(0.96))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
        .nookShadow(NookDesign.Shadow.soft)
    }
    
    /// Minimalist floating top island for lighting and room status, leaving breathing room.
    private var roomControlHeader: some View {
        HStack(spacing: NookDesign.Spacing.sm) {
            // Time of Day Selector Capsule
            HStack(spacing: 2) {
                ForEach(RoomTimeOfDay.allCases) { tod in
                    Button {
                        sceneController.setTimeOfDay(tod)
                        persistRoomState()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tod.iconName)
                                .font(.system(size: 11, weight: .medium))
                            if sceneController.timeOfDay == tod {
                                Text(tod.rawValue)
                                    .font(NookDesign.Typography.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .foregroundStyle(sceneController.timeOfDay == tod ? NookDesign.Colors.textPrimary : NookDesign.Colors.textSecondary)
                        .background(sceneController.timeOfDay == tod ? NookDesign.Colors.backgroundPrimary : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Lighting: \(tod.rawValue)")
                }
            }
            .padding(3)
            .background(NookDesign.Colors.surface.opacity(0.88))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
            
            // Desk Lamp Quick Toggle
            Button {
                sceneController.toggleDeskLamp()
                persistRoomState()
            } label: {
                Image(systemName: sceneController.isDeskLampOn ? "lamp.desk.fill" : "lamp.desk")
                    .font(.system(size: 12))
                    .foregroundStyle(sceneController.isDeskLampOn ? NookDesign.Colors.terracotta : NookDesign.Colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(NookDesign.Colors.surface.opacity(0.88))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help(sceneController.isDeskLampOn ? "Turn off desk lamp" : "Turn on desk lamp")
            
            // Wall Sconce Quick Toggle
            Button {
                sceneController.toggleWallSconce()
                persistRoomState()
            } label: {
                Image(systemName: sceneController.isWallSconceOn ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 11))
                    .foregroundStyle(sceneController.isWallSconceOn ? NookDesign.Colors.terracotta : NookDesign.Colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(NookDesign.Colors.surface.opacity(0.88))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help(sceneController.isWallSconceOn ? "Turn off wall sconce" : "Turn on wall sconce")
            
            Spacer()
            
            // Minimalist Objects Counter & Quick Add
            HStack(spacing: 8) {
                Text("\(items.count) \(items.count == 1 ? "object" : "objects")")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .padding(.leading, 6)
                
                Button {
                    isShowingNewItemSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(NookDesign.Colors.backgroundPrimary)
                        .frame(width: 26, height: 26)
                        .background(NookDesign.Colors.olive)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Add thought to room (⌘⇧Space)")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(NookDesign.Colors.surface.opacity(0.88))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
        }
        .opacity(isHeaderHovered ? 1.0 : 0.82)
        .onHover { isHeaderHovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: isHeaderHovered)
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
                        // Open Action
                        Button {
                            detailItem = item
                        } label: {
                            HStack(spacing: NookDesign.Spacing.xxs) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.system(size: 11))
                                Text("Open")
                                    .font(NookDesign.Typography.caption)
                            }
                            .foregroundStyle(NookDesign.Colors.textPrimary)
                            .padding(.horizontal, NookDesign.Spacing.sm)
                            .padding(.vertical, NookDesign.Spacing.xxs + 1)
                            .background(NookDesign.Colors.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .help("Open and read thought in full")
                        
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
                                sceneController.selectedItemID = nil
                                NookActionService.shared.archiveItem(
                                    item,
                                    in: modelContext,
                                    undoManager: undoManager,
                                    appState: appState
                                )
                            }
                        } label: {
                            Image(systemName: "archivebox")
                                .font(.system(size: 11))
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                                .padding(NookDesign.Spacing.xxs + 2)
                        }
                        .buttonStyle(.plain)
                        .help("Archive this object from the room (⌘Z to undo)")
                        
                        // Delete Action
                        Button {
                            withAnimation(NookDesign.Animation.standard) {
                                sceneController.selectedItemID = nil
                                NookActionService.shared.deleteItem(
                                    item,
                                    in: modelContext,
                                    undoManager: undoManager,
                                    appState: appState
                                )
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(NookDesign.Colors.terracotta)
                                .padding(NookDesign.Spacing.xxs + 2)
                        }
                        .buttonStyle(.plain)
                        .help("Delete this thought (⌘Z to undo)")
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
    
    private func persistRoomState() {
        sceneController.syncToRoomState(currentRoomState)
        PersistenceController.shared.safeSave(context: modelContext, appState: appState)
    }
    
    private func placeNewThought(title: String, content: String, type: NookItemType, objectType: NookObjectType) {
        let position = PlacementZone.deskCenter.naturalPosition(existingCount: items.count)
        let newItem = NookItem(
            title: title,
            content: content,
            itemType: type,
            objectType: objectType,
            position: position
        )
        modelContext.insert(newItem)
        PersistenceController.shared.safeSave(context: modelContext, appState: appState)
        
        AudioManager.shared.playObjectPlaced()
        
        RoomEventBus.shared.publish(.itemCreated(title: title, itemType: type, objectType: objectType, position: position))
        isShowingNewItemSheet = false
        appState.isShowingNewThoughtSheet = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(NookDesign.Animation.springy) {
                selectItem(newItem.id)
            }
        }
    }
    
    private func selectItem(_ id: UUID?) {
        sceneController.selectedItemID = id
        isEditingSelectedItem = false
    }
    
    private func handleItemMoved(id: UUID, newPosition: RoomPosition) {
        if let item = items.first(where: { $0.id == id }) {
            NookActionService.shared.moveItem(
                item,
                to: newPosition,
                in: modelContext,
                undoManager: undoManager,
                appState: appState
            )
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
        NookActionService.shared.updateItem(
            item,
            title: editTitle,
            content: editContent,
            objectType: editObjectType,
            in: modelContext,
            undoManager: undoManager,
            appState: appState
        )
        withAnimation(NookDesign.Animation.standard) {
            isEditingSelectedItem = false
        }
    }
    
    private func moveItem(_ item: NookItem, to zone: PlacementZone) {
        let newPos = zone.naturalPosition(existingCount: items.count)
        NookActionService.shared.moveItem(
            item,
            to: newPos,
            in: modelContext,
            undoManager: undoManager,
            appState: appState
        )
        sceneController.moveItem(item.id, to: newPos)
    }
    
    private func handleCookieInteraction() {
        sceneController.petCookie()
        currentRoomState.cookiePetCount += 1
        currentRoomState.cookieLastInteractedAt = .now
        persistRoomState()
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
        PersistenceController.shared.safeSave(context: modelContext, appState: appState)
    }
}

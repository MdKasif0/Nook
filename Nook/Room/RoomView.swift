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
    
    @State private var sceneController = RoomSceneCoordinator()
    @State private var isShowingNewItemSheet = false
    @State private var cookieToastMessage: String?
    @State private var cookieToastDismissTask: Task<Void, Never>?
    @State private var detailItem: NookItem?
    
    @AppStorage("nook_first_launch_dismissed") private var firstLaunchDismissed: Bool = false
    @AppStorage("nook_has_interacted_with_object") private var hasInteractedWithObject: Bool = false
    @FocusState private var isRoomFocused: Bool
    
    // Inspector editing state
    @State private var isEditingSelectedItem = false
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editObjectType: NookObjectType = .pebble
    @State private var isHeaderHovered = false
    
    // Interactive prop selection state
    @State private var selectedPropInfo: InteractivePropComponent?
    
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
            // 3D Miniature Diorama Room (Native RealityKit RealityView)
            RoomRealityView(coordinator: sceneController)
                .ignoresSafeArea()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Miniature Room with \(items.count) \(items.count == 1 ? "thought" : "thoughts")")
                .accessibilityHint("Use Tab or arrow keys to cycle through objects. Press Return to open.")
                .contextMenu {
                    if let prop = selectedPropInfo {
                        if prop.allowsRotation {
                            Button {
                                sceneController.interactionSystem?.rotateProp(id: prop.propId, angleDegrees: 45, undoManager: undoManager)
                            } label: {
                                Label("Rotate 45°", systemImage: "rotate.right")
                            }
                        }
                        Button {
                            sceneController.interactionSystem?.resetPropPosition(id: prop.propId, undoManager: undoManager)
                        } label: {
                            Label("Reset Position", systemImage: "arrow.counterclockwise")
                        }
                    } else if let item = selectedItem {
                        Button {
                            detailItem = item
                        } label: {
                            Label("Open Thought", systemImage: "arrow.up.forward.app")
                        }
                        Button {
                            beginEditing(item)
                        } label: {
                            Label("Edit Thought", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            deleteSelectedItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            
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
                
                // First Launch Welcome Intro (subtle, non-intrusive, dismissible)
                if !firstLaunchDismissed {
                    firstLaunchIntroBanner
                        .padding(.horizontal, NookDesign.Spacing.lg)
                        .padding(.top, NookDesign.Spacing.sm)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Spacer()
                
                // Bottom Area: Hover Hint, Undo Toast, Selected Item Inspector or Cookie Toast
                VStack(spacing: NookDesign.Spacing.sm) {
                    if !hasInteractedWithObject, sceneController.hoveredItemID != nil, selectedItem == nil {
                        firstTimeHoverHint
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
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
                        
                        // Selected Item or Prop Floating Inspector Card (Bottom Right)
                        if let item = selectedItem {
                            selectedItemInspector(for: item)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .scale(scale: 0.96))
                                ))
                        } else if let prop = selectedPropInfo {
                            selectedPropInspector(for: prop)
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
        .focusable()
        .focused($isRoomFocused)
        .onKeyPress(phases: .down) { press in
            handleKeyPress(press)
        }
        .onAppear {
            isRoomFocused = true
            sceneController.onSelectItem = { id in
                withAnimation(NookDesign.Animation.springy) {
                    selectItem(id)
                }
            }
            sceneController.onItemMoved = { id, newPosition in
                handleItemMoved(id: id, newPosition: newPosition)
            }
            sceneController.onOpenItem = { id in
                hasInteractedWithObject = true
                if let item = items.first(where: { $0.id == id }) {
                    detailItem = item
                }
            }
            sceneController.onToggleLamp = {
                persistRoomState()
            }
            sceneController.onPetCookie = {
                handleCookieInteraction()
            }
            sceneController.onPropSelected = { id in
                withAnimation(NookDesign.Animation.springy) {
                    if let id = id, let entity = sceneController.findPropEntity(id: id) {
                        selectedPropInfo = entity.components[InteractivePropComponent.self]
                    } else {
                        selectedPropInfo = nil
                    }
                }
            }
            sceneController.onPropTransformSaved = { transform in
                currentRoomState.setPropTransform(transform)
                PersistenceController.shared.safeSave(context: modelContext, appState: appState)
            }
            sceneController.onPropTransformReset = { propId in
                currentRoomState.resetPropTransform(propId: propId)
                PersistenceController.shared.safeSave(context: modelContext, appState: appState)
            }
            sceneController.applySavedRoomState(currentRoomState)
            RoomEventBus.shared.publish(.roomOpened(wasAwayForDuration: 60))
            GlobalShortcutManager.shared.onEscapePressed = { [weak appState] in
                if let appState, appState.isSearchOpen {
                    appState.closeSearch()
                    return true
                }
                if isEditingSelectedItem {
                    isEditingSelectedItem = false
                    return true
                }
                if selectedPropInfo != nil {
                    withAnimation(NookDesign.Animation.springy) {
                        sceneController.interactionSystem?.clearPropSelection()
                        selectedPropInfo = nil
                    }
                    return true
                }
                if sceneController.selectedItemID != nil {
                    withAnimation(NookDesign.Animation.springy) {
                        sceneController.selectedItemID = nil
                        sceneController.resetCameraFraming()
                    }
                    return true
                }
                if !firstLaunchDismissed {
                    withAnimation(NookDesign.Animation.standard) {
                        firstLaunchDismissed = true
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
        .opacity(isHeaderHovered ? 1.0 : 0.40)
        .onHover { isHeaderHovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: isHeaderHovered)
    }
    
    /// Single subtle introduction card on first launch.
    /// Non-intrusive, no multi-page carousel, dismissible with xmark or Esc.
    private var firstLaunchIntroBanner: some View {
        HStack(alignment: .center, spacing: NookDesign.Spacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Welcome to your Nook.")
                    .font(NookDesign.Typography.subheading)
                    .fontWeight(.medium)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                HStack(spacing: 5) {
                    Text("Capture a thought with")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                    
                    Text("⌘⇧Space")
                        .font(NookDesign.Typography.mono)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(NookDesign.Colors.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5)
                        )
                }
            }
            
            Spacer()
            
            Button {
                withAnimation(NookDesign.Animation.standard) {
                    firstLaunchDismissed = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    .padding(5)
            }
            .buttonStyle(.plain)
            .help("Dismiss")
            .accessibilityLabel("Dismiss welcome introduction")
        }
        .padding(.horizontal, NookDesign.Spacing.md)
        .padding(.vertical, NookDesign.Spacing.sm)
        .frame(maxWidth: 380)
        .background(NookDesign.Colors.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous)
                .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.8)
        )
        .nookShadow(NookDesign.Shadow.elevated)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to your Nook. Capture a thought with Command Shift Space.")
    }
    
    /// Subtle first-time hover hint on physical room objects.
    private var firstTimeHoverHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.tap")
                .font(.system(size: 11))
                .foregroundStyle(NookDesign.Colors.olive)
            
            Text("Click to open")
                .font(NookDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(NookDesign.Colors.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(NookDesign.Colors.surface.opacity(0.94))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
        .nookShadow(NookDesign.Shadow.soft)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Click to open")
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
                        .accessibilityLabel("Delete thought")
                    }
                    
                    // Keyboard navigation legend
                    HStack(spacing: 4) {
                        Text("↵ Open")
                        Text("•")
                        Text("e Edit")
                        Text("•")
                        Text("⌫ Delete")
                        Text("•")
                        Text("Esc Close")
                    }
                    .font(NookDesign.Typography.mono)
                    .font(.system(size: 9))
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    .padding(.top, 2)
                }
            }
        }
        .padding(NookDesign.Spacing.lg)
        .frame(width: 350)
        .background(NookDesign.Colors.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NookDesign.Radius.xl, style: .continuous)
                .strokeBorder(NookDesign.Colors.olive.opacity(0.7), lineWidth: 1.2)
        )
        .nookShadow(NookDesign.Shadow.elevated)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Inspector for \(item.title), \(item.objectType.displayName)")
    }
    
    /// Contextual floating inspector panel when a movable room prop is selected.
    private func selectedPropInspector(for prop: InteractivePropComponent) -> some View {
        HStack(spacing: NookDesign.Spacing.md) {
            // Prop Category / Nature Icon
            Image(systemName: iconForProp(prop.propId))
                .font(.system(size: 15))
                .foregroundStyle(NookDesign.Colors.olive)
                .frame(width: 32, height: 32)
                .background(NookDesign.Colors.olive.opacity(0.12))
                .clipShape(Circle())
            
            // Display Name and micro-instruction
            VStack(alignment: .leading, spacing: 2) {
                Text(prop.displayName)
                    .font(NookDesign.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Text("Drag to move • Arrow keys to nudge")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textTertiary)
            }
            
            Spacer(minLength: 16)
            
            // Action Controls
            HStack(spacing: NookDesign.Spacing.xs) {
                if prop.allowsRotation {
                    Button {
                        sceneController.interactionSystem?.rotateProp(id: prop.propId, angleDegrees: 45, undoManager: undoManager)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rotate.right")
                                .font(.system(size: 11))
                            Text("Rotate")
                                .font(NookDesign.Typography.caption)
                                .fontWeight(.medium)
                            Text("R")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(NookDesign.Colors.surfaceAlt)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(NookDesign.Colors.surfaceAlt)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Rotate 45° (R)")
                }
                
                Button {
                    sceneController.interactionSystem?.resetPropPosition(id: prop.propId, undoManager: undoManager)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                        Text("Reset")
                            .font(NookDesign.Typography.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(NookDesign.Colors.surfaceAlt)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Reset position to default")
                
                Button {
                    withAnimation(NookDesign.Animation.springy) {
                        sceneController.interactionSystem?.clearPropSelection()
                        selectedPropInfo = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .padding(6)
                }
                .buttonStyle(.plain)
                .help("Deselect (Esc)")
            }
        }
        .padding(.horizontal, NookDesign.Spacing.md)
        .padding(.vertical, NookDesign.Spacing.sm)
        .background(NookDesign.Colors.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NookDesign.Colors.borderSubtle, lineWidth: 0.8)
        )
        .nookShadow(NookDesign.Shadow.elevated)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(prop.displayName), movable diorama object")
    }
    
    private func iconForProp(_ propId: String) -> String {
        if propId.contains("lamp") { return "lamp.table.fill" }
        if propId.contains("monitor") { return "display" }
        if propId.contains("laptop") { return "laptopcomputer" }
        if propId.contains("keyboard") { return "keyboard" }
        if propId.contains("mouse") { return "computermouse" }
        if propId.contains("phone") { return "iphone" }
        if propId.contains("notebook") { return "book.pages" }
        if propId.contains("pillow") { return "square.fill" }
        if propId.contains("skateboard") { return "figure.skateboarding" }
        if propId.contains("plant") || propId.contains("succulent") || propId.contains("monstera") { return "leaf.fill" }
        if propId.contains("record") { return "opticaldisc.fill" }
        if propId.contains("mug") { return "cup.and.saucer.fill" }
        if propId.contains("pencil") { return "pencil.tip" }
        if propId.contains("clock") { return "alarm.fill" }
        if propId.contains("cookie") { return "cat.fill" }
        if propId.contains("box") { return "shippingbox.fill" }
        if propId.contains("headphones") { return "headphones" }
        return "cube.fill"
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
        if id != nil {
            hasInteractedWithObject = true
        }
    }
    
    private func navigateNextItem() {
        let activeItems = items.filter { !$0.isArchived }
        guard !activeItems.isEmpty else { return }
        hasInteractedWithObject = true
        if let currentID = sceneController.selectedItemID,
           let currentIndex = activeItems.firstIndex(where: { $0.id == currentID }) {
            let nextIndex = (currentIndex + 1) % activeItems.count
            selectItem(activeItems[nextIndex].id)
            sceneController.focusItem(id: activeItems[nextIndex].id)
        } else {
            selectItem(activeItems[0].id)
            sceneController.focusItem(id: activeItems[0].id)
        }
    }
    
    private func navigatePreviousItem() {
        let activeItems = items.filter { !$0.isArchived }
        guard !activeItems.isEmpty else { return }
        hasInteractedWithObject = true
        if let currentID = sceneController.selectedItemID,
           let currentIndex = activeItems.firstIndex(where: { $0.id == currentID }) {
            let prevIndex = (currentIndex - 1 + activeItems.count) % activeItems.count
            selectItem(activeItems[prevIndex].id)
            sceneController.focusItem(id: activeItems[prevIndex].id)
        } else {
            selectItem(activeItems[activeItems.count - 1].id)
            sceneController.focusItem(id: activeItems[activeItems.count - 1].id)
        }
    }
    
    private func deleteSelectedItem(_ item: NookItem) {
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
    
    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        // 1. If a movable prop is selected, handle its direct manipulation
        if let prop = selectedPropInfo {
            if press.characters == "r" || press.characters == "R" {
                sceneController.interactionSystem?.rotateProp(id: prop.propId, angleDegrees: 45, undoManager: undoManager)
                return .handled
            }
            if press.key == .upArrow {
                sceneController.interactionSystem?.nudgeProp(id: prop.propId, deltaX: 0, deltaZ: -0.02, undoManager: undoManager)
                return .handled
            }
            if press.key == .downArrow {
                sceneController.interactionSystem?.nudgeProp(id: prop.propId, deltaX: 0, deltaZ: 0.02, undoManager: undoManager)
                return .handled
            }
            if press.key == .leftArrow {
                sceneController.interactionSystem?.nudgeProp(id: prop.propId, deltaX: -0.02, deltaZ: 0, undoManager: undoManager)
                return .handled
            }
            if press.key == .rightArrow {
                sceneController.interactionSystem?.nudgeProp(id: prop.propId, deltaX: 0.02, deltaZ: 0, undoManager: undoManager)
                return .handled
            }
            if press.key == .escape {
                withAnimation(NookDesign.Animation.springy) {
                    sceneController.interactionSystem?.clearPropSelection()
                    selectedPropInfo = nil
                }
                return .handled
            }
        }
        
        // 2. Regular thought item navigation
        if press.key == .tab {
            if press.modifiers.contains(.shift) {
                navigatePreviousItem()
            } else {
                navigateNextItem()
            }
            return .handled
        }
        if press.key == .rightArrow || press.key == .downArrow {
            if !isEditingSelectedItem {
                navigateNextItem()
                return .handled
            }
        }
        if press.key == .leftArrow || press.key == .upArrow {
            if !isEditingSelectedItem {
                navigatePreviousItem()
                return .handled
            }
        }
        if press.key == .return || press.key == .space {
            if let item = selectedItem, !isEditingSelectedItem {
                hasInteractedWithObject = true
                detailItem = item
                return .handled
            }
        }
        if press.characters == "e" || press.characters == "E" {
            if let item = selectedItem, !isEditingSelectedItem {
                beginEditing(item)
                return .handled
            }
        }
        if press.key == .delete || press.key == .deleteForward {
            if let item = selectedItem, !isEditingSelectedItem {
                deleteSelectedItem(item)
                return .handled
            }
        }
        if press.key == .escape {
            if isEditingSelectedItem {
                isEditingSelectedItem = false
                return .handled
            }
            if sceneController.selectedItemID != nil {
                withAnimation(NookDesign.Animation.springy) {
                    sceneController.selectedItemID = nil
                    sceneController.resetCameraFraming()
                }
                return .handled
            }
            if !firstLaunchDismissed {
                withAnimation(NookDesign.Animation.standard) {
                    firstLaunchDismissed = true
                }
                return .handled
            }
        }
        return .ignored
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
            content: "Capture a thought with ⌘⇧Space.\n\nEvery thought here exists as a small tactile object. You can drag them across your desk, pick them up, or open them anytime.",
            itemType: .thought,
            objectType: .pebble,
            position: PlacementZone.deskCenter.basePosition
        )
        modelContext.insert(welcomePebble)
        PersistenceController.shared.safeSave(context: modelContext, appState: appState)
    }
}

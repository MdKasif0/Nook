import SwiftUI
import SwiftData
import SceneKit

/// The main room view — the heart of Nook.
///
/// Presents a realistic miniature 3D diorama room with warm daylight,
/// wooden desk, cozy chair, bookshelf, dynamic outdoor window,
/// toggleable desk lamp, and Cookie the cat.
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
                        sceneController.selectedItemID = id
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
                    
                    // Selected Item Floating Card (Bottom Right)
                    if let item = selectedItem {
                        selectedItemCard(for: item)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            ))
                    } else if items.isEmpty {
                        emptyRoomHint
                            .transition(.opacity)
                    }
                }
                .padding(NookDesign.Spacing.xl)
            }
        }
        .task(id: items) {
            sceneController.syncItems(items)
        }
        .onChange(of: sceneController.cookieMessage) { _, newMsg in
            if let newMsg {
                showCookieToast(newMsg)
            }
        }
        .sheet(isPresented: $isShowingNewItemSheet) {
            NewItemSheet { title, content, type in
                let newItem = NookItem(title: title, content: content, itemType: type)
                modelContext.insert(newItem)
                isShowingNewItemSheet = false
                
                // Select the freshly created item in the room
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(NookDesign.Animation.springy) {
                        sceneController.selectedItemID = newItem.id
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
                Image(systemName: "deskclock")
                    .font(.system(size: 11))
                    .foregroundStyle(NookDesign.Colors.woodBrown)
                
                Text(items.count == 1 ? "1 item on desk" : "\(items.count) items on desk")
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
            .help("Add a new thought or note to your room")
        }
    }
    
    /// Floating detail card when an object in the 3D room is tapped.
    private func selectedItemCard(for item: NookItem) -> some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.md) {
            // Header: Type badge & dismiss button
            HStack {
                HStack(spacing: NookDesign.Spacing.xs) {
                    Image(systemName: item.itemType.iconName)
                        .font(.system(size: 12))
                    Text(item.itemType.displayName)
                        .font(NookDesign.Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(item.itemType.badgeColor)
                .padding(.horizontal, NookDesign.Spacing.sm)
                .padding(.vertical, NookDesign.Spacing.xxs)
                .background(item.itemType.badgeColor.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                Button {
                    withAnimation(NookDesign.Animation.springy) {
                        sceneController.selectedItemID = nil
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
            
            // Title
            Text(item.title)
                .font(NookDesign.Typography.subheading)
                .foregroundStyle(NookDesign.Colors.textPrimary)
                .lineLimit(2)
            
            // Content
            if !item.content.isEmpty {
                Text(item.content)
                    .font(NookDesign.Typography.body)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .lineLimit(5)
            }
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
            
            // Footer: Timestamp & Actions
            HStack {
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(NookDesign.Typography.mono)
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                
                Spacer()
                
                Button {
                    withAnimation(NookDesign.Animation.standard) {
                        item.isArchived = true
                        sceneController.selectedItemID = nil
                    }
                } label: {
                    HStack(spacing: NookDesign.Spacing.xxs) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 11))
                        Text("Archive")
                            .font(NookDesign.Typography.caption)
                    }
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    .padding(.horizontal, NookDesign.Spacing.sm)
                    .padding(.vertical, NookDesign.Spacing.xxs)
                    .background(NookDesign.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Archive this item from the room")
            }
        }
        .padding(NookDesign.Spacing.lg)
        .frame(width: 320)
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
    
    /// Subtle hint when room has no items.
    private var emptyRoomHint: some View {
        HStack(spacing: NookDesign.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(NookDesign.Colors.olive)
            
            Text("Your desk is peaceful and clear. Place a thought to begin.")
                .font(NookDesign.Typography.caption)
                .foregroundStyle(NookDesign.Colors.textSecondary)
        }
        .padding(.horizontal, NookDesign.Spacing.md)
        .padding(.vertical, NookDesign.Spacing.xs + 2)
        .background(NookDesign.Colors.surface.opacity(0.90))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.5))
        .nookShadow(NookDesign.Shadow.subtle)
    }
    
    // MARK: - Interactions
    
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
}

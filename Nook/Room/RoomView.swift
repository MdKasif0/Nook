import SwiftUI
import SwiftData

/// The main room view — the heart of Nook.
///
/// Displays items as small objects scattered across a warm, cozy surface.
/// This is the initial 2D flat-room placeholder that will evolve
/// into a full 3D room experience.
struct RoomView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<NookItem> { !$0.isArchived },
        sort: \NookItem.createdAt,
        order: .reverse
    )
    private var items: [NookItem]
    
    @State private var selectedItemID: UUID?
    @State private var isShowingNewItemSheet = false
    
    var body: some View {
        ZStack {
            // Room background
            roomBackground
            
            if items.isEmpty {
                emptyRoomPrompt
            } else {
                // Items scattered on the room surface
                GeometryReader { geometry in
                    ForEach(items) { item in
                        RoomItemView(item: item, isSelected: item.id == selectedItemID)
                            .position(
                                x: item.positionX * geometry.size.width,
                                y: item.positionY * geometry.size.height
                            )
                            .onTapGesture {
                                withAnimation(NookDesign.Animation.quick) {
                                    selectedItemID = (selectedItemID == item.id) ? nil : item.id
                                }
                            }
                    }
                }
                .padding(NookDesign.Spacing.xxl)
            }
            
            // Cookie placeholder (bottom-right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    CookieBadge()
                        .padding(NookDesign.Spacing.xl)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingNewItemSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add a new item to your room")
            }
        }
        .sheet(isPresented: $isShowingNewItemSheet) {
            NewItemSheet { title, content, type in
                let newItem = NookItem(title: title, content: content, itemType: type)
                modelContext.insert(newItem)
                isShowingNewItemSheet = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var roomBackground: some View {
        ZStack {
            NookDesign.Colors.backgroundPrimary
            
            // Subtle warm gradient to suggest a floor/wall divide
            LinearGradient(
                colors: [
                    NookDesign.Colors.backgroundSecondary.opacity(0.3),
                    NookDesign.Colors.backgroundPrimary,
                    NookDesign.Colors.taupe.opacity(0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
    
    private var emptyRoomPrompt: some View {
        VStack(spacing: NookDesign.Spacing.lg) {
            Image(systemName: "house")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Text("Your Nook is empty")
                .font(NookDesign.Typography.title)
                .foregroundStyle(NookDesign.Colors.textSecondary)
            
            Text("Add your first thought, idea, or note.")
                .font(NookDesign.Typography.body)
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Button {
                isShowingNewItemSheet = true
            } label: {
                HStack(spacing: NookDesign.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Add something")
                }
                .font(NookDesign.Typography.body)
                .foregroundStyle(NookDesign.Colors.backgroundPrimary)
                .padding(.horizontal, NookDesign.Spacing.xl)
                .padding(.vertical, NookDesign.Spacing.md)
                .background(NookDesign.Colors.olive)
                .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, NookDesign.Spacing.sm)
        }
    }
}

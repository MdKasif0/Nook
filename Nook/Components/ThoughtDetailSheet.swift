import SwiftUI
import SwiftData

/// A serene, focused reader sheet for an open thought object.
///
/// Gives the user a calm, tactile view to reflect upon their thought,
/// with actions to edit, move, archive, or delete.
struct ThoughtDetailSheet: View {
    
    @Bindable var item: NookItem
    let onEdit: () -> Void
    let onMove: (PlacementZone) -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                // Object Type Badge
                HStack(spacing: NookDesign.Spacing.xs) {
                    Image(systemName: item.objectType.iconName)
                        .font(.system(size: 12))
                    Text(item.objectType.displayName)
                        .font(NookDesign.Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(item.objectType.tintColor)
                .padding(.horizontal, NookDesign.Spacing.sm)
                .padding(.vertical, NookDesign.Spacing.xxs + 1)
                .background(item.objectType.tintColor.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                // Done / Dismiss Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(NookDesign.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                        .padding(.horizontal, NookDesign.Spacing.md)
                        .padding(.vertical, NookDesign.Spacing.xxs + 2)
                        .background(NookDesign.Colors.backgroundSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, NookDesign.Spacing.xl)
            .padding(.top, NookDesign.Spacing.xl)
            .padding(.bottom, NookDesign.Spacing.md)
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
            
            // Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: NookDesign.Spacing.lg) {
                    // Object Miniature Icon & Title
                    VStack(alignment: .leading, spacing: NookDesign.Spacing.sm) {
                        Text(item.title)
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(NookDesign.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Main Content / Thoughts
                    if !item.content.isEmpty {
                        Text(item.content)
                            .font(NookDesign.Typography.body)
                            .foregroundStyle(NookDesign.Colors.textSecondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: NookDesign.Spacing.xl)
                    
                    // Physical Location & Metadata Box
                    VStack(alignment: .leading, spacing: NookDesign.Spacing.xs) {
                        HStack(spacing: NookDesign.Spacing.xs) {
                            Image(systemName: "deskclock")
                                .font(.system(size: 11))
                                .foregroundStyle(NookDesign.Colors.woodBrown)
                            Text("Created \(item.createdAt.formatted(date: .long, time: .shortened))")
                                .font(NookDesign.Typography.caption)
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                        }
                        
                        HStack(spacing: NookDesign.Spacing.xs) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 11))
                                .foregroundStyle(NookDesign.Colors.woodBrown)
                            Text("Location: Desk surface")
                                .font(NookDesign.Typography.caption)
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                        }
                    }
                    .padding(NookDesign.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NookDesign.Colors.backgroundSecondary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
                }
                .padding(NookDesign.Spacing.xl)
            }
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
            
            // Bottom Action Bar: Edit, Move, Archive, Delete
            HStack(spacing: NookDesign.Spacing.sm) {
                // Edit
                Button {
                    dismiss()
                    onEdit()
                } label: {
                    HStack(spacing: NookDesign.Spacing.xs) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                        Text("Edit")
                            .font(NookDesign.Typography.caption)
                    }
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                    .padding(.horizontal, NookDesign.Spacing.md)
                    .padding(.vertical, NookDesign.Spacing.xs)
                    .background(NookDesign.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                
                // Move Menu
                Menu {
                    ForEach(PlacementZone.allCases) { zone in
                        Button {
                            onMove(zone)
                        } label: {
                            Label(zone.displayName, systemImage: zone.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: NookDesign.Spacing.xs) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 10))
                        Text("Move")
                            .font(NookDesign.Typography.caption)
                    }
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                    .padding(.horizontal, NookDesign.Spacing.md)
                    .padding(.vertical, NookDesign.Spacing.xs)
                    .background(NookDesign.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.sm, style: .continuous))
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
                
                // Archive
                Button {
                    dismiss()
                    onArchive()
                } label: {
                    HStack(spacing: NookDesign.Spacing.xs) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 11))
                        Text("Archive")
                            .font(NookDesign.Typography.caption)
                    }
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .padding(.horizontal, NookDesign.Spacing.sm)
                    .padding(.vertical, NookDesign.Spacing.xs)
                }
                .buttonStyle(.plain)
                
                // Delete
                Button {
                    dismiss()
                    onDelete()
                } label: {
                    HStack(spacing: NookDesign.Spacing.xs) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Delete")
                            .font(NookDesign.Typography.caption)
                    }
                    .foregroundStyle(NookDesign.Colors.terracotta)
                    .padding(.horizontal, NookDesign.Spacing.sm)
                    .padding(.vertical, NookDesign.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, NookDesign.Spacing.xl)
            .padding(.vertical, NookDesign.Spacing.md)
            .background(NookDesign.Colors.surface)
        }
        .frame(width: 480, height: 420)
        .background(NookDesign.Colors.backgroundPrimary)
    }
}

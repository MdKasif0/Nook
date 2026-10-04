import SwiftUI

/// A single item rendered as a small physical object inside the room.
///
/// Styled as a warm paper card with subtle shadow and type-specific accent.
struct RoomItemView: View {
    
    let item: NookItem
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.xs) {
            // Type icon
            HStack(spacing: NookDesign.Spacing.xs) {
                Image(systemName: item.itemType.iconName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(accentColor)
                
                Spacer()
            }
            
            // Title
            Text(item.title)
                .font(NookDesign.Typography.caption)
                .foregroundStyle(NookDesign.Colors.textPrimary)
                .lineLimit(2)
            
            // Preview of content
            if !item.content.isEmpty {
                Text(item.content)
                    .font(.system(size: 9))
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(NookDesign.Spacing.sm)
        .frame(width: 100)
        .background(NookDesign.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous)
                .strokeBorder(
                    isSelected ? accentColor : NookDesign.Colors.surfaceBorder,
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        )
        .nookShadow(isSelected ? NookDesign.Shadow.soft : NookDesign.Shadow.subtle)
        .rotationEffect(.degrees(item.rotation))
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(NookDesign.Animation.springy, value: isSelected)
    }
    
    private var accentColor: Color {
        switch item.itemType.accentColor {
        case .sage:       return NookDesign.Colors.sage
        case .olive:      return NookDesign.Colors.olive
        case .terracotta: return NookDesign.Colors.terracotta
        case .woodBrown:  return NookDesign.Colors.woodBrown
        case .taupe:      return NookDesign.Colors.taupe
        }
    }
}

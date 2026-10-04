import SwiftUI

/// A single row in the item list.
struct ItemRowView: View {
    
    let item: NookItem
    
    var body: some View {
        HStack(spacing: NookDesign.Spacing.md) {
            // Type indicator
            Image(systemName: item.itemType.iconName)
                .font(.system(size: 12))
                .foregroundStyle(item.itemType.badgeColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: NookDesign.Spacing.xxxs) {
                Text(item.title)
                    .font(NookDesign.Typography.body)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                    .lineLimit(1)
                
                if !item.content.isEmpty {
                    Text(item.content)
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(item.createdAt, style: .relative)
                .font(NookDesign.Typography.mono)
                .foregroundStyle(NookDesign.Colors.textTertiary)
        }
        .padding(.vertical, NookDesign.Spacing.xxs)
    }
}


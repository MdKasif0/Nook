import SwiftUI

/// A small badge showing Cookie's current mood in the room corner.
///
/// This is a placeholder — the full Cookie character will replace it later.
struct CookieBadge: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack(spacing: NookDesign.Spacing.xs) {
            Image(systemName: appState.cookieState.iconName)
                .font(.system(size: 14))
                .foregroundStyle(NookDesign.Colors.woodBrown)
            
            Text("Cookie")
                .font(NookDesign.Typography.caption)
                .foregroundStyle(NookDesign.Colors.textTertiary)
        }
        .padding(.horizontal, NookDesign.Spacing.md)
        .padding(.vertical, NookDesign.Spacing.xs)
        .background(NookDesign.Colors.surface.opacity(0.85))
        .clipShape(Capsule())
        .nookShadow(NookDesign.Shadow.subtle)
    }
}

import SwiftUI

/// Design tokens for the Nook application.
///
/// Warm, sophisticated palette inspired by natural materials.
/// Light theme only. No blues, purples, neons, or cyberpunk styling.
enum NookDesign {
    
    // MARK: - Colors
    
    enum Colors {
        /// Primary background — warm ivory.
        static let backgroundPrimary = Color(hex: 0xFCFAF6)
        
        /// Secondary background — soft cream.
        static let backgroundSecondary = Color(hex: 0xF7F4EE)
        
        /// Tertiary background — warm stone.
        static let backgroundTertiary = Color(hex: 0xE8E2D8)
        
        /// Surface — for cards, panels, elevated surfaces.
        static let surface = Color(hex: 0xF2EFE8)
        
        /// Surface border — subtle warm divider.
        static let surfaceBorder = Color(hex: 0xE0D9CD)
        
        /// Muted sage accent.
        static let sage = Color(hex: 0xA8B09A)
        
        /// Deeper olive.
        static let olive = Color(hex: 0x879178)
        
        /// Warm terracotta.
        static let terracotta = Color(hex: 0xB8795F)
        
        /// Earthy wood brown.
        static let woodBrown = Color(hex: 0x8A7564)
        
        /// Warm taupe.
        static let taupe = Color(hex: 0xD8D1C4)
        
        /// Primary text — soft charcoal, not pure black.
        static let textPrimary = Color(hex: 0x3A3835)
        
        /// Secondary text — warm gray.
        static let textSecondary = Color(hex: 0x7A756D)
        
        /// Tertiary text — light muted.
        static let textTertiary = Color(hex: 0xA8A29A)
        
        /// Near-black for strong emphasis.
        static let ink = Color(hex: 0x4A4945)
    }
    
    // MARK: - Typography
    
    enum Typography {
        /// Large title — used for the room header.
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: .semibold)
        
        /// Section title.
        static let title = Font.system(.title2, design: .default, weight: .medium)
        
        /// Subheading.
        static let subheading = Font.system(.headline, design: .default, weight: .medium)
        
        /// Body text.
        static let body = Font.system(.body, design: .default, weight: .regular)
        
        /// Small caption.
        static let caption = Font.system(.caption, design: .default, weight: .regular)
        
        /// Monospaced — for timestamps, metadata.
        static let mono = Font.system(.caption, design: .monospaced, weight: .regular)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 6
        static let lg: CGFloat = 8
        static let xl: CGFloat = 12
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static let subtle = ShadowStyle(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        static let soft = ShadowStyle(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        static let elevated = ShadowStyle(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let springy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    }
}

/// A simple shadow descriptor.
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension

extension Color {
    /// Initialize a Color from a hex integer (e.g., 0xF7F4EE).
    init(hex: UInt, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies a Nook shadow style.
    func nookShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
    
    /// Applies the standard Nook card appearance.
    func nookCard() -> some View {
        self
            .background(NookDesign.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.lg, style: .continuous))
            .nookShadow(NookDesign.Shadow.subtle)
    }
}

// MARK: - Accent Color SwiftUI Mapping

extension NookAccentColor {
    /// Maps the model-layer accent token to a concrete SwiftUI Color.
    var color: Color {
        switch self {
        case .sage:       return NookDesign.Colors.sage
        case .olive:      return NookDesign.Colors.olive
        case .terracotta: return NookDesign.Colors.terracotta
        case .woodBrown:  return NookDesign.Colors.woodBrown
        case .taupe:      return NookDesign.Colors.taupe
        }
    }
}

extension NookItemType {
    /// The badge tint color for this item type.
    var badgeColor: Color {
        accentColor.color
    }
}


import SwiftUI

/// A minimal, tactile object picker for choosing how a thought manifests physically.
///
/// Features miniature previews of all 6 tactile objects without
/// resorting to generic dashboard cards.
struct ObjectPickerView: View {
    
    @Binding var selectedObjectType: NookObjectType
    
    var body: some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.sm) {
            // Horizontal row of miniature physical object tokens
            HStack(spacing: NookDesign.Spacing.sm) {
                ForEach(NookObjectType.allCases) { type in
                    Button {
                        withAnimation(NookDesign.Animation.springy) {
                            selectedObjectType = type
                        }
                    } label: {
                        VStack(spacing: NookDesign.Spacing.xs) {
                            // Miniature visual preview
                            objectMiniaturePreview(for: type)
                                .frame(width: 44, height: 44)
                            
                            // Label
                            Text(type.displayName)
                                .font(NookDesign.Typography.caption)
                                .fontWeight(selectedObjectType == type ? .semibold : .regular)
                                .foregroundStyle(selectedObjectType == type ? NookDesign.Colors.textPrimary : NookDesign.Colors.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(.vertical, NookDesign.Spacing.xs)
                        .padding(.horizontal, NookDesign.Spacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedObjectType == type
                            ? NookDesign.Colors.backgroundPrimary
                            : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: NookDesign.Radius.md, style: .continuous)
                                .strokeBorder(
                                    selectedObjectType == type
                                    ? NookDesign.Colors.olive
                                    : NookDesign.Colors.surfaceBorder.opacity(0.6),
                                    lineWidth: selectedObjectType == type ? 1.5 : 0.5
                                )
                        )
                        .nookShadow(selectedObjectType == type ? NookDesign.Shadow.subtle : NookDesign.Shadow.subtle)
                    }
                    .buttonStyle(.plain)
                    .help(type.subtitle)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(type.displayName)
                    .accessibilityValue(type.subtitle)
                    .accessibilityAddTraits(selectedObjectType == type ? [.isSelected, .isButton] : [.isButton])
                    .accessibilityHint("Selects \(type.displayName) as the physical representation in your room")
                }
            }
            .padding(NookDesign.Spacing.xs)
            .background(NookDesign.Colors.backgroundSecondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: NookDesign.Radius.lg, style: .continuous))
            
            // Contextual subtitle explaining the selected object
            HStack(spacing: NookDesign.Spacing.xs) {
                Image(systemName: selectedObjectType.iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(selectedObjectType.tintColor)
                
                Text(selectedObjectType.subtitle)
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textTertiary)
            }
            .padding(.leading, NookDesign.Spacing.xs)
        }
    }
    
    // MARK: - Miniature Previews
    
    @ViewBuilder
    private func objectMiniaturePreview(for type: NookObjectType) -> some View {
        ZStack {
            switch type {
            case .pebble:
                // Smooth river stone with soft shadow
                ZStack {
                    Ellipse()
                        .fill(Color.black.opacity(0.12))
                        .frame(width: 32, height: 22)
                        .offset(y: 2)
                    
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x968E82), Color(hex: 0x766E63)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 20)
                        .overlay(
                            Ellipse()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                }
                
            case .paperNote:
                // Folded cream paper with corner fold
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 26, height: 30)
                        .offset(y: 1)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: 0xFDFBF7))
                        .frame(width: 24, height: 28)
                        .overlay(
                            VStack(spacing: 3) {
                                Capsule().fill(Color.gray.opacity(0.25)).frame(width: 14, height: 2)
                                Capsule().fill(Color.gray.opacity(0.25)).frame(width: 16, height: 2)
                                Capsule().fill(Color.gray.opacity(0.25)).frame(width: 12, height: 2)
                            }
                        )
                }
                
            case .stickyNote:
                // Buttery square note with curled edge
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: 0xFBF5C4))
                        .frame(width: 26, height: 26)
                        .rotationEffect(.degrees(-3))
                        .overlay(
                            Circle()
                                .fill(NookDesign.Colors.terracotta)
                                .frame(width: 3, height: 3)
                                .offset(y: -9)
                        )
                }
                
            case .card:
                // Heavy cardstock with debossed border
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: 0xF5F2EB))
                    .frame(width: 32, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.8)
                            .padding(2)
                    )
                
            case .polaroid:
                // Miniature photo frame
                VStack(spacing: 1) {
                    Rectangle()
                        .fill(Color(hex: 0xB5ABA0))
                        .frame(width: 22, height: 18)
                        .padding(.top, 2)
                    Spacer()
                }
                .frame(width: 26, height: 30)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .shadow(color: Color.black.opacity(0.08), radius: 1, y: 1)
                .rotationEffect(.degrees(2))
                
            case .bookmark:
                // Slender sage ribbon with ribbon split
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color(hex: 0xC8BAA6))
                        .frame(width: 4, height: 4)
                        .offset(y: 2)
                    
                    Rectangle()
                        .fill(NookDesign.Colors.sage)
                        .frame(width: 12, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }
        }
    }
}

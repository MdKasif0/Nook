import SwiftUI

/// Minimal, native macOS menu bar utility popover for Nook.
///
/// Contains:
/// - Nook / Your room header
/// - Quick Thought (⌘⇧Space)
/// - Search (⌘K)
/// - Open Nook
/// - Settings
/// - Quit Nook
struct MenuBarView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: NookDesign.Spacing.xs) {
                Image(systemName: "house.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NookDesign.Colors.olive)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Nook")
                        .font(NookDesign.Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                    
                    Text("Your room")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                
                Spacer()
            }
            .padding(.horizontal, NookDesign.Spacing.md)
            .padding(.top, NookDesign.Spacing.md)
            .padding(.bottom, NookDesign.Spacing.xs)
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
                .padding(.vertical, NookDesign.Spacing.xxs)
            
            // Actions
            VStack(spacing: 2) {
                menuRow(
                    title: "Quick Thought",
                    icon: "sparkles",
                    shortcut: "⌘⇧Space"
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: NookWindow.quickCapture.id)
                }
                
                menuRow(
                    title: "Search",
                    icon: "magnifyingglass",
                    shortcut: "⌘K"
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: NookWindow.main.id)
                    appState.openSearch()
                }
                
                menuRow(
                    title: "Open Nook",
                    icon: "arrow.up.forward.app",
                    shortcut: nil
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: NookWindow.main.id)
                }
            }
            .padding(.horizontal, NookDesign.Spacing.xs)
            .padding(.vertical, NookDesign.Spacing.xxs)
            
            Divider()
                .foregroundStyle(NookDesign.Colors.surfaceBorder)
                .padding(.vertical, NookDesign.Spacing.xxs)
            
            // Settings & Quit
            VStack(spacing: 2) {
                menuRow(
                    title: "Settings",
                    icon: "gearshape",
                    shortcut: "⌘,"
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                
                menuRow(
                    title: "Quit Nook",
                    icon: "power",
                    shortcut: "⌘Q"
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, NookDesign.Spacing.xs)
            .padding(.bottom, NookDesign.Spacing.xs)
        }
        .frame(width: 220)
        .background(NookDesign.Colors.surface)
    }
    
    private func menuRow(
        title: String,
        icon: String,
        shortcut: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NookDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .frame(width: 14)
                
                Text(title)
                    .font(NookDesign.Typography.body)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Spacer()
                
                if let shortcut {
                    Text(shortcut)
                        .font(NookDesign.Typography.mono)
                        .font(.system(size: 10))
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(NookDesign.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .padding(.horizontal, NookDesign.Spacing.sm)
            .padding(.vertical, NookDesign.Spacing.xs + 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

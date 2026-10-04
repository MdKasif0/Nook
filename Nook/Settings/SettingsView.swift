import SwiftUI
import SwiftData

/// Native macOS Settings window.
///
/// Features the 5 core user preferences:
/// 1. Reduce Motion
/// 2. Launch at Login
/// 3. Sound Effects
/// 4. Cookie reactions
/// 5. Reset Room Layout
struct SettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<NookItem> { !$0.isArchived },
        sort: \NookItem.createdAt,
        order: .reverse
    )
    private var activeItems: [NookItem]
    
    @State private var prefs = PreferencesManager.shared
    @State private var hasResetLayout = false
    
    var body: some View {
        @Bindable var preferences = prefs
        
        TabView {
            // MARK: - General Tab
            Form {
                Section {
                    Toggle("Reduce Motion", isOn: $preferences.reduceMotion)
                        .help("Disables continuous 3D idle animations, breathing loops, and walking bobs.")
                    Text("Simplifies camera transitions and disables continuous character breathing and ambient loops.")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
                        .help("Starts Nook automatically when you log into your Mac.")
                    Text("Keeps your miniature room ready in the background and menu bar.")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Toggle("Sound Effects", isOn: $preferences.soundEffectsEnabled)
                        .help("Play subtle, tactile audio clicks when interacting with objects.")
                    Text("Plays gentle tactile clicks when objects are placed, selected, or completed.")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                } header: {
                    Text("Experience")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            // MARK: - Room & Companion Tab
            Form {
                Section {
                    Toggle("Cookie reactions", isOn: $preferences.cookieReactionsEnabled)
                        .help("Allow Cookie to react when you create, delete, or complete thoughts.")
                    Text("When enabled, Cookie perks up, looks toward newly materialized objects, and wiggles ears.")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                } header: {
                    Text("Companion Cat")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                }
                
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Object Positions")
                                .font(NookDesign.Typography.body)
                            Text("Reorganizes all \(activeItems.count) physical thoughts on the desk into natural clusters.")
                                .font(NookDesign.Typography.caption)
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation(NookDesign.Animation.springy) {
                                prefs.resetRoomLayout(modelContext: modelContext, items: activeItems)
                                AudioManager.shared.playObjectPlaced()
                                hasResetLayout = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                hasResetLayout = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: hasResetLayout ? "checkmark" : "arrow.counterclockwise")
                                    .font(.system(size: 11))
                                Text(hasResetLayout ? "Reset!" : "Reset Layout")
                                    .font(NookDesign.Typography.caption)
                            }
                        }
                        .disabled(activeItems.isEmpty)
                    }
                } header: {
                    Text("Room Diorama")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Room & Cookie", systemImage: "house")
            }
            
            // MARK: - About Tab
            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 460, height: 320)
    }
}

// MARK: - About Tab Subview

struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Spacer()
            
            Image(systemName: "house.fill")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(NookDesign.Colors.olive)
            
            VStack(spacing: 2) {
                Text("Nook")
                    .font(NookDesign.Typography.title)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Text("A cozy, tactile place for your thoughts.")
                    .font(NookDesign.Typography.body)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
            }
            
            Text("Version 1.0 (Native macOS)")
                .font(NookDesign.Typography.mono)
                .font(.system(size: 11))
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

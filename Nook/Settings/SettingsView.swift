import SwiftUI
import SwiftData
import AppKit

/// Native macOS Settings window.
///
/// Features:
/// 1. General Preferences (Reduce motion, Launch at login, Sound effects)
/// 2. Room & Companion Cat settings
/// 3. Data & Privacy (Local-First guarantee, offline status, JSON Export/Restore)
/// 4. About Nook
enum SettingsTab: Hashable {
    case general
    case room
    case privacy
    case about
}

struct SettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query(sort: \NookItem.createdAt, order: .reverse)
    private var allItems: [NookItem]
    
    @Query private var roomStates: [RoomState]
    
    @State private var prefs = PreferencesManager.shared
    @State private var hasResetLayout = false
    @State private var backupStatusMessage: String?
    @State private var selectedTab: SettingsTab
    
    init(initialTab: SettingsTab = .general) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    private var activeItems: [NookItem] {
        allItems.filter { !$0.isArchived }
    }
    
    var body: some View {
        @Bindable var preferences = prefs
        
        TabView(selection: $selectedTab) {
            // MARK: - 1. General Tab
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
            .tag(SettingsTab.general)
            
            // MARK: - 2. Room & Companion Tab
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
            .tag(SettingsTab.room)
            
            // MARK: - 3. Data & Privacy Tab
            Form {
                Section {
                    VStack(alignment: .leading, spacing: NookDesign.Spacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(NookDesign.Colors.olive)
                            Text("Your thoughts stay on your Mac.")
                                .font(NookDesign.Typography.subheading)
                                .fontWeight(.semibold)
                                .foregroundStyle(NookDesign.Colors.textPrimary)
                        }
                        
                        Text("Nook is 100% local-first. There are no servers, no cloud databases, no user accounts, and zero analytics. Everything is stored privately inside your local SwiftData database.")
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Privacy & Storage")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                }
                
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Offline Backup")
                                .font(NookDesign.Typography.body)
                            Text("Saves all thoughts and room state to a standalone JSON file.")
                                .font(NookDesign.Typography.caption)
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        Button("Export…") {
                            exportBackup()
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 2)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Restore Backup")
                                .font(NookDesign.Typography.body)
                            Text("Imports thoughts and room preferences from a previously saved JSON backup.")
                                .font(NookDesign.Typography.caption)
                                .foregroundStyle(NookDesign.Colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        Button("Restore…") {
                            restoreBackup()
                        }
                    }
                    
                    if let status = backupStatusMessage {
                        Text(status)
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.olive)
                            .padding(.top, 2)
                    }
                } header: {
                    Text("Backup & Portability")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Privacy & Data", systemImage: "internaldrive")
            }
            .tag(SettingsTab.privacy)
            
            // MARK: - 4. About Tab
            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 500, height: 350)
    }
    
    // MARK: - Backup Export & Restore Logic
    
    private func exportBackup() {
        do {
            let data = try NookBackupService.shared.exportBackup(
                items: allItems,
                roomState: roomStates.first
            )
            
            let panel = NSSavePanel()
            panel.title = "Export Nook Backup"
            panel.prompt = "Export"
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "NookBackup-\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).json"
            
            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
                withAnimation {
                    backupStatusMessage = "Successfully exported \(allItems.count) thoughts."
                }
            }
        } catch {
            withAnimation {
                backupStatusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func restoreBackup() {
        let panel = NSOpenPanel()
        panel.title = "Restore Nook Backup"
        panel.prompt = "Restore"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            do {
                let result = try NookBackupService.shared.importBackup(from: data, into: modelContext)
                withAnimation {
                    backupStatusMessage = "Restored \(result.itemsImported) new thoughts!"
                }
            } catch {
                withAnimation {
                    backupStatusMessage = "Restore failed: \(error.localizedDescription)"
                }
            }
        }
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
            
            VStack(spacing: 4) {
                Text("Local-First • Zero Cloud • Native macOS")
                    .font(NookDesign.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                
                Text("Version 1.0 (Build 1)")
                    .font(NookDesign.Typography.mono)
                    .font(.system(size: 11))
                    .foregroundStyle(NookDesign.Colors.textTertiary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

import SwiftUI

/// The application settings window.
///
/// Placeholder for future preferences — currently shows app info.
struct SettingsView: View {
    
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 280)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    var body: some View {
        Form {
            Section {
                Text("Preferences will appear here as Nook grows.")
                    .font(NookDesign.Typography.body)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab

struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: NookDesign.Spacing.lg) {
            Spacer()
            
            Image(systemName: "house.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(NookDesign.Colors.olive)
            
            Text("Nook")
                .font(NookDesign.Typography.title)
                .foregroundStyle(NookDesign.Colors.textPrimary)
            
            Text("A cozy place for your thoughts.")
                .font(NookDesign.Typography.body)
                .foregroundStyle(NookDesign.Colors.textSecondary)
            
            Text("Version 0.1.0")
                .font(NookDesign.Typography.mono)
                .foregroundStyle(NookDesign.Colors.textTertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

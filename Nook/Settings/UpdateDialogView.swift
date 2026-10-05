import SwiftUI

/// A native macOS modal view displaying update availability, release notes, and download action.
struct UpdateDialogView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var updateManager = NookUpdateManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: NookDesign.Spacing.md) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(NookDesign.Colors.olive)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Software Update")
                        .font(NookDesign.Typography.title)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                    
                    Text("Nook for macOS")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                
                Spacer()
            }
            .padding(NookDesign.Spacing.lg)
            .background(NookDesign.Colors.backgroundSecondary.opacity(0.5))
            
            Divider()
            
            // Content Body
            VStack(spacing: NookDesign.Spacing.md) {
                switch updateManager.state {
                case .checking:
                    checkingView
                case .upToDate:
                    upToDateView
                case .updateAvailable(let item):
                    updateAvailableView(item: item)
                case .error(let message):
                    errorView(message: message)
                case .idle:
                    checkingView
                }
            }
            .padding(NookDesign.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Footer Action Bar
            HStack {
                if let lastDate = updateManager.lastCheckedDate {
                    Text("Checked: \(lastDate.formatted(date: .omitted, time: .shortened))")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                switch updateManager.state {
                case .checking:
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                case .upToDate:
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(NookDesign.Colors.olive)
                    
                case .updateAvailable(let item):
                    Button("Later") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                    Button {
                        NSWorkspace.shared.open(item.downloadURL)
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download Update")
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(NookDesign.Colors.olive)
                    
                case .error:
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                    Button("Try Again") {
                        updateManager.checkForUpdates(userInitiated: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(NookDesign.Colors.olive)
                    
                case .idle:
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(NookDesign.Spacing.md)
            .background(NookDesign.Colors.backgroundSecondary.opacity(0.3))
        }
        .frame(width: 480, height: 380)
        .background(NookDesign.Colors.surface)
    }
    
    // MARK: - Subviews
    
    private var checkingView: some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Spacer()
            ProgressView()
                .scaleEffect(0.9)
            Text("Checking for updates…")
                .font(NookDesign.Typography.body)
                .foregroundStyle(NookDesign.Colors.textSecondary)
            Spacer()
        }
    }
    
    private var upToDateView: some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(NookDesign.Colors.olive)
            
            VStack(spacing: 4) {
                Text("You're up to date!")
                    .font(NookDesign.Typography.subheading)
                    .fontWeight(.semibold)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Text("Nook \(updateManager.currentVersion) is currently the newest version available.")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
    
    private func updateAvailableView(item: AppCastItem) -> some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nook \(item.versionString) is now available!")
                        .font(NookDesign.Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundStyle(NookDesign.Colors.textPrimary)
                    
                    Text("You have version \(updateManager.currentVersion).")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                if item.fileSize > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file))
                        .font(NookDesign.Typography.mono)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(NookDesign.Colors.backgroundTertiary)
                        .clipShape(Capsule())
                }
            }
            
            Text("Release Notes:")
                .font(NookDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(NookDesign.Colors.textSecondary)
                .padding(.top, 4)
            
            ScrollView {
                Text(cleanHTMLText(item.releaseNotesHTML))
                    .font(NookDesign.Typography.body)
                    .font(.system(size: 12))
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(NookDesign.Spacing.sm)
            }
            .background(NookDesign.Colors.backgroundTertiary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(NookDesign.Colors.surfaceBorder, lineWidth: 0.8)
            )
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(NookDesign.Colors.terracotta)
            
            VStack(spacing: 4) {
                Text("Could Not Check for Updates")
                    .font(NookDesign.Typography.subheading)
                    .fontWeight(.semibold)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Text(message)
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
    
    private func cleanHTMLText(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<h2>", with: "\n")
            .replacingOccurrences(of: "</h2>", with: "\n\n")
            .replacingOccurrences(of: "<ul>", with: "")
            .replacingOccurrences(of: "</ul>", with: "")
            .replacingOccurrences(of: "<li>", with: "• ")
            .replacingOccurrences(of: "</li>", with: "\n")
            .replacingOccurrences(of: "<strong>", with: "")
            .replacingOccurrences(of: "</strong>", with: "")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

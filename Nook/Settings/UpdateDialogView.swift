import SwiftUI

/// A native macOS modal view displaying update availability, release notes, cryptographic verification, and installation.
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
                
                if let key = updateManager.publicEDKey, !key.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                        Text("Ed25519 Verified")
                            .font(NookDesign.Typography.mono)
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NookDesign.Colors.olive.opacity(0.12))
                    .foregroundStyle(NookDesign.Colors.olive)
                    .clipShape(Capsule())
                }
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
                case .downloading(let progress):
                    downloadingView(progress: progress)
                case .readyToInstall(let dmgURL):
                    readyToInstallView(dmgURL: dmgURL)
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
                    Text("Last checked: \(lastDate.formatted(date: .omitted, time: .shortened))")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                switch updateManager.state {
                case .checking, .idle:
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
                    
                    if let webLink = item.releaseNotesLink {
                        Button {
                            NSWorkspace.shared.open(webLink)
                        } label: {
                            Image(systemName: "safari")
                            Text("Release Page")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button {
                        Task {
                            await updateManager.downloadAndInstall(item: item)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download & Install")
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(NookDesign.Colors.olive)
                    
                case .downloading:
                    Button("Cancel") {
                        updateManager.state = .idle
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    
                case .readyToInstall:
                    Button("Done") {
                        dismiss()
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
                }
            }
            .padding(NookDesign.Spacing.md)
            .background(NookDesign.Colors.backgroundSecondary.opacity(0.3))
        }
        .frame(width: 520, height: 410)
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Nook \(item.versionString)")
                            .font(NookDesign.Typography.subheading)
                            .fontWeight(.bold)
                            .foregroundStyle(NookDesign.Colors.textPrimary)
                        
                        if item.isCritical {
                            Text("CRITICAL")
                                .font(NookDesign.Typography.mono)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(NookDesign.Colors.terracotta)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("Installed version: \(updateManager.currentVersion)")
                        .font(NookDesign.Typography.caption)
                        .foregroundStyle(NookDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if item.fileSize > 0 {
                        Text(ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file))
                            .font(NookDesign.Typography.mono)
                            .font(.system(size: 11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(NookDesign.Colors.backgroundTertiary)
                            .clipShape(Capsule())
                    }
                    
                    if let pubDate = item.publishDate {
                        Text(pubDate.formatted(date: .abbreviated, time: .omitted))
                            .font(NookDesign.Typography.caption)
                            .foregroundStyle(NookDesign.Colors.textTertiary)
                    }
                }
            }
            
            Text("Release Highlights:")
                .font(NookDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(NookDesign.Colors.textSecondary)
                .padding(.top, 2)
            
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
    
    private func downloadingView(progress: Double) -> some View {
        VStack(spacing: NookDesign.Spacing.lg) {
            Spacer()
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(NookDesign.Colors.olive)
            
            VStack(spacing: 8) {
                Text("Downloading & Verifying Update…")
                    .font(NookDesign.Typography.subheading)
                    .fontWeight(.semibold)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                ProgressView(value: max(0.05, progress), total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 320)
                
                Text(progress >= 0.90 ? "Verifying Ed25519 digital signature…" : "\(Int(progress * 100))% completed")
                    .font(NookDesign.Typography.caption)
                    .foregroundStyle(NookDesign.Colors.textSecondary)
            }
            Spacer()
        }
    }
    
    private func readyToInstallView(dmgURL: URL) -> some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(NookDesign.Colors.olive)
            
            VStack(spacing: 6) {
                Text("Update Verified & Ready")
                    .font(NookDesign.Typography.subheading)
                    .fontWeight(.bold)
                    .foregroundStyle(NookDesign.Colors.textPrimary)
                
                Text("The disk image has been opened in Finder.\nDrag Nook to Applications to complete the update.")
                    .font(NookDesign.Typography.body)
                    .font(.system(size: 12))
                    .foregroundStyle(NookDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Reveal DMG in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([dmgURL])
            }
            .buttonStyle(.link)
            .font(NookDesign.Typography.caption)
            
            Spacer()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: NookDesign.Spacing.md) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(NookDesign.Colors.terracotta)
            
            VStack(spacing: 4) {
                Text("Could Not Complete Update")
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

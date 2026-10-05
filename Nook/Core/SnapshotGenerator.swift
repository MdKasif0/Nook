import SwiftUI
import AppKit

/// Generates pixel-perfect snapshots of Nook's native UI surfaces for preview and documentation.
@MainActor
enum SnapshotGenerator {
    
    static func renderAll() {
        let artifactDir = "/Users/mdkasifuddin/.gemini/antigravity-ide/brain/140570a3-7f05-48a8-b0eb-0e864a19b6b3"
        let container = PersistenceController.shared.container
        let state = AppState()
        
        // 1. Quick Capture Floating Paper Window
        let quickCaptureView = QuickCaptureView()
            .environment(state)
            .modelContainer(container)
            .padding(30)
            .background(
                Color(red: 0.94, green: 0.92, blue: 0.88)
            )
        saveView(quickCaptureView, size: CGSize(width: 500, height: 420), to: "\(artifactDir)/nook_quick_capture.png")
        
        // 2. Menu Bar Minimalist Utility Popover
        let menuBarView = MenuBarView()
            .environment(state)
            .modelContainer(container)
            .padding(24)
            .background(
                Color(red: 0.94, green: 0.92, blue: 0.88)
            )
        saveView(menuBarView, size: CGSize(width: 280, height: 340), to: "\(artifactDir)/nook_menu_bar.png")
        
        // 3. Search / Command Palette (⌘K)
        let searchPaletteView = SearchPaletteView(onSelectItem: { _ in }, onClose: {})
            .environment(state)
            .modelContainer(container)
            .padding(30)
            .background(
                Color(red: 0.94, green: 0.92, blue: 0.88)
            )
        saveView(searchPaletteView, size: CGSize(width: 580, height: 500), to: "\(artifactDir)/nook_search_palette.png")
        
        // 4. Contextual Empty State (Ideas: "Your first idea is waiting for a shelf.")
        let ideasEmptyView = ItemListView(title: "Ideas", icon: "lightbulb", filter: .itemType(.idea))
            .environment(state)
            .modelContainer(container)
            .frame(width: 480, height: 320)
        saveView(ideasEmptyView, size: CGSize(width: 480, height: 320), to: "\(artifactDir)/nook_ideas_empty_state.png")
        
        // 5. Thought Detail Reader Sheet
        let sampleItem = NookItem(
            title: "Local AI Coding Assistant",
            content: "Build a quiet, tactile miniature environment where thoughts become physical objects on a wooden desk.",
            itemType: .idea,
            objectType: .pebble
        )
        let thoughtDetailView = ThoughtDetailSheet(
            item: sampleItem,
            onEdit: {},
            onMove: { _ in },
            onArchive: {},
            onDelete: {}
        )
        .padding(16)
        .background(Color(red: 0.94, green: 0.92, blue: 0.88))
        saveView(thoughtDetailView, size: CGSize(width: 520, height: 460), to: "\(artifactDir)/nook_thought_detail.png")
    }
    
    private static func saveView<V: View>(_ view: V, size: CGSize, to path: String) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: size)
        window.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()
        
        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else { return }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        
        if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            let targetURL = URL(fileURLWithPath: path)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(targetURL.lastPathComponent)
            
            do {
                try pngData.write(to: targetURL)
                print("Successfully rendered snapshot to: \(targetURL.path)")
            } catch {
                do {
                    try pngData.write(to: tempURL)
                    print("Rendered snapshot to sandbox temp: \(tempURL.path)")
                } catch {
                    print("Failed to write snapshot: \(error)")
                }
            }
        } else {
            print("Failed to get PNG data representation for \(path)")
        }
    }
}

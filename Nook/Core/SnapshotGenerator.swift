import SwiftUI
import AppKit
import RealityKit
import Metal

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
        
        // 6. RealityKit 3D Miniature Room Diorama
        renderRoomSnapshot(to: "\(artifactDir)/nook_reality_room.png")
        
        // 7. Cookie the Cat Character Close-Up
        renderCookieCloseUpSnapshot(to: "\(artifactDir)/nook_cookie_character.png")
    }
    
    static func renderCookieCloseUpSnapshot(to path: String) {
        let coordinator = RoomSceneCoordinator()
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let width = 1400
        let height = 1400
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        desc.usage = [.renderTarget, .shaderRead]
        guard let texture = device.makeTexture(descriptor: desc) else { return }
        
        do {
            let renderer = try RealityRenderer()
            renderer.entities.append(coordinator.rootEntity)
            
            // Dedicated close-up camera positioned to frame Cookie at 3/4 angle
            let closeCamera = Entity()
            var cam = PerspectiveCameraComponent()
            cam.fieldOfViewInDegrees = 31.0
            closeCamera.components.set(cam)
            
            let cookiePos = CookieRealityEntity.bedPerchPos
            let cameraEye = SIMD3<Float>(cookiePos.x + 0.22, cookiePos.y + 0.16, cookiePos.z + 0.42)
            let cameraTarget = SIMD3<Float>(cookiePos.x - 0.02, cookiePos.y + 0.060, cookiePos.z)
            closeCamera.position = cameraEye
            closeCamera.look(at: cameraTarget, from: cameraEye, relativeTo: nil)
            coordinator.rootEntity.addChild(closeCamera)
            renderer.activeCamera = closeCamera
            
            let outputDesc = RealityRenderer.CameraOutput.Descriptor.singleProjection(colorTexture: texture)
            let cameraOutput = try RealityRenderer.CameraOutput(outputDesc)
            
            let semaphore = DispatchSemaphore(value: 0)
            try renderer.updateAndRender(deltaTime: 0.016, cameraOutput: cameraOutput, onComplete: { _ in
                semaphore.signal()
            })
            semaphore.wait()
            
            guard let ci = CIImage(mtlTexture: texture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()]) else { return }
            let flipTransform = CGAffineTransform(1, 0, 0, -1, 0, CGFloat(height))
            let flippedCI = ci.transformed(by: flipTransform)
            let bg = CIImage(color: CIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1.0)).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
            let compositedCI = flippedCI.composited(over: bg)
            let rep = NSCIImageRep(ciImage: compositedCI)
            let nsImage = NSImage(size: NSSize(width: width, height: height))
            nsImage.addRepresentation(rep)
            guard let tiff = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else { return }
            let targetURL = URL(fileURLWithPath: path)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(targetURL.lastPathComponent)
            do {
                try png.write(to: targetURL)
                print("Successfully rendered Cookie close-up snapshot to: \(targetURL.path)")
            } catch {
                do {
                    try png.write(to: tempURL)
                    print("Rendered Cookie close-up snapshot to sandbox temp: \(tempURL.path)")
                } catch {
                    print("Failed to write Cookie close-up snapshot: \(error)")
                }
            }
        } catch {
            print("Error rendering Cookie close-up snapshot: \(error)")
        }
    }
    
    static func renderRoomSnapshot(to path: String) {
        let coordinator = RoomSceneCoordinator()
        let sampleItems = [
            NookItem(title: "Morning Reflection", content: "Quiet, tactile focus.", itemType: .note, objectType: .paperNote, position: RoomPosition(x: 0.35, y: 0.45, z: 0.5)),
            NookItem(title: "Warm Palette", content: "Warm ivory, honey oak, and muted sage.", itemType: .idea, objectType: .stickyNote, position: RoomPosition(x: 0.65, y: 0.55, z: 0.5)),
            NookItem(title: "Memory", content: "A quiet moment with Cookie.", itemType: .photo, objectType: .polaroid, position: RoomPosition(x: 0.50, y: 0.30, z: 0.5))
        ]
        coordinator.syncItems(sampleItems)
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let width = 1600
        let height = 1100
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        desc.usage = [.renderTarget, .shaderRead]
        guard let texture = device.makeTexture(descriptor: desc) else { return }
        
        do {
            let renderer = try RealityRenderer()
            coordinator.cameraRig.resetToDefaultFraming(animated: false)
            renderer.entities.append(coordinator.rootEntity)
            renderer.activeCamera = coordinator.cameraRig.cameraEntity
            
            let outputDesc = RealityRenderer.CameraOutput.Descriptor.singleProjection(colorTexture: texture)
            let cameraOutput = try RealityRenderer.CameraOutput(outputDesc)
            
            let semaphore = DispatchSemaphore(value: 0)
            try renderer.updateAndRender(deltaTime: 0.016, cameraOutput: cameraOutput, onComplete: { _ in
                semaphore.signal()
            })
            semaphore.wait()
            
            guard let ci = CIImage(mtlTexture: texture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()]) else { return }
            let flipTransform = CGAffineTransform(1, 0, 0, -1, 0, CGFloat(height))
            let flippedCI = ci.transformed(by: flipTransform)
            let bg = CIImage(color: CIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1.0)).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
            let compositedCI = flippedCI.composited(over: bg)
            let rep = NSCIImageRep(ciImage: compositedCI)
            let nsImage = NSImage(size: NSSize(width: width, height: height))
            nsImage.addRepresentation(rep)
            guard let tiff = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else { return }
            let targetURL = URL(fileURLWithPath: path)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(targetURL.lastPathComponent)
            do {
                try png.write(to: targetURL)
                print("Successfully rendered reality room snapshot to: \(targetURL.path)")
            } catch {
                do {
                    try png.write(to: tempURL)
                    print("Rendered reality room snapshot to sandbox temp: \(tempURL.path)")
                } catch {
                    print("Failed to write reality room snapshot: \(error)")
                }
            }
        } catch {
            print("Error rendering reality room snapshot: \(error)")
        }
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

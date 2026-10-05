import SwiftUI
import RealityKit
import AppKit

/// SwiftUI container for the Nook 3D RealityKit miniature room diorama.
///
/// Embeds the scene graph via `RealityView`, configures the virtual isometric camera,
/// enables entity hit-testing, tap actions, and tactile drag manipulation.
struct RoomRealityView: View {
    
    let coordinator: RoomSceneCoordinator
    
    @State private var draggedEntity: Entity?
    @State private var dragInitialPosition: SIMD3<Float> = .zero
    
    var body: some View {
        RealityView { content in
            content.add(coordinator.rootEntity)
            content.camera = .virtual
        } update: { content in
            // Coordinates updates if needed
        }
        .realityViewCameraControls(.none) // Keep the diorama composition locked to the reference isometric angle
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    coordinator.interactionSystem?.handleEntityTap(value.entity)
                }
        )
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let entity = value.entity
                    // Only allow dragging thought items
                    guard entity.name.hasPrefix("thought_") || entity.findAncestor(prefix: "thought_") != nil else { return }
                    let target = entity.name.hasPrefix("thought_") ? entity : entity.findAncestor(prefix: "thought_")!
                    
                    if draggedEntity == nil {
                        draggedEntity = target
                        dragInitialPosition = target.position
                    }
                    
                    // Convert screen translation to ground plane X/Z translation
                    // Isometric projection mapping:
                    let deltaX = Float(value.translation.width) * 0.0025
                    let deltaZ = Float(value.translation.height) * 0.0025
                    
                    let newX = dragInitialPosition.x + (deltaX - deltaZ) * 0.707
                    let newZ = dragInitialPosition.z + (deltaX + deltaZ) * 0.707
                    
                    // Clamp to room bounds
                    let clampedX = min(max(newX, -1.15), 1.15)
                    let clampedZ = min(max(newZ, -1.05), 1.05)
                    
                    target.position = [clampedX, dragInitialPosition.y + 0.03, clampedZ]
                }
                .onEnded { value in
                    guard let target = draggedEntity else { return }
                    // Drop down to surface
                    target.position.y = dragInitialPosition.y
                    
                    let idStr = String(target.name.dropFirst("thought_".count))
                    if let uuid = UUID(uuidString: idStr) {
                        let finalPos = SIMD3<Float>(target.position.x, target.position.y, target.position.z)
                        coordinator.interactionSystem?.handleItemDrag(id: uuid, newPosition: finalPos)
                    }
                    draggedEntity = nil
                }
        )
        .background(Color(red: 0.98, green: 0.965, blue: 0.945))
    }
}

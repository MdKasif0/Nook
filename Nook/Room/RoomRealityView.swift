import SwiftUI
import RealityKit
import AppKit

/// SwiftUI container for the Nook 3D RealityKit miniature room diorama.
///
/// Embeds the scene graph via `RealityView`, configures the virtual isometric camera,
/// enables entity hit-testing, tap actions, physical dragging, rotation, settling physics,
/// and subtle camera exploration when dragging empty room space.
struct RoomRealityView: View {
    
    let coordinator: RoomSceneCoordinator
    @Environment(\.undoManager) private var undoManager
    
    @State private var activeDragTarget: Entity?
    @State private var dragInitialPosition: SIMD3<Float> = .zero
    @State private var previousBackgroundDrag: CGSize = .zero
    
    var body: some View {
        RealityView { content in
            content.add(coordinator.rootEntity)
            content.camera = .virtual
        } update: { content in
            // Coordinates updates
        }
        .realityViewCameraControls(.none) // Use custom clamped exploration controls
        // 1. Gesture targeted to interactive entities (High Priority)
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
                    guard let interaction = coordinator.interactionSystem,
                          interaction.canDragEntity(value.entity) else { return }
                    
                    if activeDragTarget == nil {
                        if let target = interaction.handleDragStart(for: value.entity) {
                            activeDragTarget = target
                            dragInitialPosition = target.position
                        }
                    }
                    
                    guard let target = activeDragTarget else { return }
                    interaction.handleDragUpdate(target: target, translation: value.translation, startPos: dragInitialPosition)
                }
                .onEnded { value in
                    guard let interaction = coordinator.interactionSystem,
                          let target = activeDragTarget else { return }
                    
                    interaction.handleDragEnd(target: target, undoManager: undoManager)
                    activeDragTarget = nil
                }
        )
        // 2. Gesture on empty room space: Subtle camera orbit exploration (Lower Priority)
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    // Only orbit camera if user is NOT dragging a physical room object
                    guard activeDragTarget == nil else { return }
                    
                    let deltaX = Float(value.translation.width - previousBackgroundDrag.width) * 0.003
                    let deltaY = Float(value.translation.height - previousBackgroundDrag.height) * 0.003
                    previousBackgroundDrag = value.translation
                    
                    coordinator.cameraRig.orbit(deltaYaw: deltaX, deltaPitch: -deltaY)
                }
                .onEnded { _ in
                    previousBackgroundDrag = .zero
                }
        )
        // 3. Magnification Gesture on Trackpad: Subtle zoom
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    guard activeDragTarget == nil else { return }
                    let delta = Float(value.magnification)
                    if delta > 1.0 {
                        coordinator.cameraRig.zoom(by: 1.015)
                    } else if delta < 1.0 {
                        coordinator.cameraRig.zoom(by: 0.985)
                    }
                }
        )
        // 4. Double Click empty room space to reset view
        .onTapGesture(count: 2) {
            if activeDragTarget == nil && coordinator.selectedItemID == nil {
                coordinator.resetCameraFraming()
            }
        }
        .background(Color(red: 0.98, green: 0.965, blue: 0.945))
    }
}

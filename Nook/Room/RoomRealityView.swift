import SwiftUI
import RealityKit
import AppKit

/// SwiftUI container for the Nook 3D RealityKit miniature room diorama.
///
/// Embeds the scene graph via `RealityView`, configures the virtual isometric camera,
/// enables entity hit-testing, tap actions, physical dragging, rotation, settling physics,
/// and native UndoManager integration.
struct RoomRealityView: View {
    
    let coordinator: RoomSceneCoordinator
    @Environment(\.undoManager) private var undoManager
    
    @State private var activeDragTarget: Entity?
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
        .background(Color(red: 0.98, green: 0.965, blue: 0.945))
    }
}

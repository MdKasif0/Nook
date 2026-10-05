import RealityKit
import AppKit

/// Precision isometric camera rig reproducing the 3/4 elevated perspective from the reference image:
/// - Three-quarter isometric angle looking diagonally into the diorama
/// - Slightly elevated view (~32° pitch downward)
/// - Balanced medium-wide framing with pleasant margins around the diorama base
/// - Controlled field of view (36°) eliminating wide-angle fisheye distortion
@MainActor
final class RoomCameraRig {
    
    let cameraEntity: Entity
    private var cameraComponent: PerspectiveCameraComponent
    
    // Default reference composition framing
    static let defaultCameraPosition = SIMD3<Float>(2.12, 2.78, 2.98)
    static let defaultTargetPosition = SIMD3<Float>(-0.04, 0.68, -0.06)
    static let defaultFieldOfView: Float = 33.0 // in degrees
    
    init() {
        self.cameraEntity = Entity()
        self.cameraEntity.name = "diorama_camera"
        
        var cam = PerspectiveCameraComponent()
        cam.fieldOfViewInDegrees = Self.defaultFieldOfView
        self.cameraComponent = cam
        self.cameraEntity.components.set(cam)
        
        resetToDefaultFraming()
    }
    
    func resetToDefaultFraming() {
        cameraEntity.position = Self.defaultCameraPosition
        cameraEntity.look(
            at: Self.defaultTargetPosition,
            from: cameraEntity.position,
            relativeTo: nil
        )
    }
    
    /// Gently pan/zoom framing if user inspects an item
    func frameItem(at target: SIMD3<Float>) {
        let offset = Self.defaultCameraPosition - Self.defaultTargetPosition
        cameraEntity.position = target + offset * 0.75
        cameraEntity.look(at: target, from: cameraEntity.position, relativeTo: nil)
    }
}

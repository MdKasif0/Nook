import RealityKit
import AppKit

/// Precision isometric camera rig reproducing the 3/4 elevated perspective from the reference image:
/// - Three-quarter isometric angle looking diagonally into the diorama
/// - Slightly elevated view (~32° pitch downward)
/// - Balanced medium-wide framing with pleasant margins around the diorama base
/// - Controlled field of view (32.5°) eliminating wide-angle distortion
/// - Subtle exploration capabilities (clamped orbit, subtle pan, gentle zoom)
/// - Instant and animated "Reset View" returning precisely to reference composition
@MainActor
public final class RoomCameraRig {
    
    public let cameraEntity: Entity
    private var cameraComponent: PerspectiveCameraComponent
    
    // Default reference composition framing
    public static let defaultCameraPosition = SIMD3<Float>(2.06, 2.70, 2.90)
    public static let defaultTargetPosition = SIMD3<Float>(-0.02, 0.70, -0.04)
    public static let defaultFieldOfView: Float = 32.5 // in degrees
    
    // Current exploration offsets
    private var orbitYaw: Float = 0.0      // clamped: -0.38 ... +0.38 (~±22°)
    private var orbitPitch: Float = 0.0    // clamped: -0.20 ... +0.20
    private var zoomFactor: Float = 1.0    // clamped: 0.82 ... 1.25
    private var panOffset: SIMD3<Float> = .zero // clamped lateral pan
    
    public init() {
        self.cameraEntity = Entity()
        self.cameraEntity.name = "diorama_camera"
        
        var cam = PerspectiveCameraComponent()
        cam.fieldOfViewInDegrees = Self.defaultFieldOfView
        self.cameraComponent = cam
        self.cameraEntity.components.set(cam)
        
        resetToDefaultFraming()
    }
    
    /// Resets the camera precisely to the reference image composition.
    public func resetToDefaultFraming(animated: Bool = true) {
        self.orbitYaw = 0.0
        self.orbitPitch = 0.0
        self.zoomFactor = 1.0
        self.panOffset = .zero
        
        let targetEye = Self.defaultCameraPosition
        let targetLookAt = Self.defaultTargetPosition
        
        if !animated {
            cameraEntity.position = targetEye
            cameraEntity.look(at: targetLookAt, from: targetEye, relativeTo: nil)
            return
        }
        
        Task { @MainActor in
            let steps = 12
            let startEye = self.cameraEntity.position
            
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: 18_000_000)
                let t = Float(i) / Float(steps)
                let ease = sin(t * Float.pi * 0.5)
                
                let curEye = simd_mix(startEye, targetEye, SIMD3<Float>(ease, ease, ease))
                self.cameraEntity.position = curEye
                self.cameraEntity.look(at: targetLookAt, from: curEye, relativeTo: nil)
            }
            
            self.cameraEntity.position = targetEye
            self.cameraEntity.look(at: targetLookAt, from: targetEye, relativeTo: nil)
        }
    }
    
    /// Gently orbits the camera within strictly constrained angles so user never loses the room.
    public func orbit(deltaYaw: Float, deltaPitch: Float) {
        orbitYaw = min(max(orbitYaw + deltaYaw, -0.38), 0.38)
        orbitPitch = min(max(orbitPitch + deltaPitch, -0.20), 0.20)
        recomputeTransform()
    }
    
    /// Adjusts zoom factor between 0.82x (wide) and 1.25x (closer).
    public func zoom(by delta: Float) {
        zoomFactor = min(max(zoomFactor * delta, 0.82), 1.25)
        recomputeTransform()
    }
    
    /// Subtly pans the camera center.
    public func pan(deltaX: Float, deltaZ: Float) {
        let maxPan: Float = 0.28
        panOffset.x = min(max(panOffset.x + deltaX, -maxPan), maxPan)
        panOffset.z = min(max(panOffset.z + deltaZ, -maxPan), maxPan)
        recomputeTransform()
    }
    
    /// Recomputes camera position and orientation based on current exploration state.
    private func recomputeTransform() {
        let baseDir = Self.defaultCameraPosition - Self.defaultTargetPosition
        let distance = simd_length(baseDir) / zoomFactor
        
        // Apply yaw & pitch rotation
        let rot = simd_quatf(angle: orbitYaw, axis: [0, 1, 0]) * simd_quatf(angle: orbitPitch, axis: [1, 0, -1])
        let rotatedDir = rot.act(simd_normalize(baseDir))
        
        let target = Self.defaultTargetPosition + panOffset
        let eye = target + rotatedDir * distance
        
        cameraEntity.position = eye
        cameraEntity.look(at: target, from: eye, relativeTo: nil)
    }
    
    /// Gently frames a thought object without a disorienting sudden jump.
    public func frameItem(at target: SIMD3<Float>) {
        let baseDir = Self.defaultCameraPosition - Self.defaultTargetPosition
        let gentleDistance = simd_length(baseDir) * 0.85
        let eye = target + simd_normalize(baseDir) * gentleDistance
        
        Task { @MainActor in
            let steps = 14
            let startEye = self.cameraEntity.position
            let startTarget = Self.defaultTargetPosition + self.panOffset
            
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: 20_000_000)
                let t = Float(i) / Float(steps)
                let ease = sin(t * Float.pi * 0.5)
                
                let curEye = simd_mix(startEye, eye, SIMD3<Float>(ease, ease, ease))
                let curTarget = simd_mix(startTarget, target, SIMD3<Float>(ease, ease, ease))
                
                self.cameraEntity.position = curEye
                self.cameraEntity.look(at: curTarget, from: curEye, relativeTo: nil)
            }
            
            self.cameraEntity.position = eye
            self.cameraEntity.look(at: target, from: eye, relativeTo: nil)
        }
    }
}

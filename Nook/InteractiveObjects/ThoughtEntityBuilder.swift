import RealityKit
import AppKit

/// Builds authentic 3D physical thought objects placed naturally into the diorama:
/// - Smooth River Pebble: Rounded irregular stone, matte warm gray/brown material
/// - Folded Paper Note: Realistic thickness, subtle folded flap geometry, soft cream texture
/// - Sticky Note: Thin paper, slightly curled corner, buttery warm yellow
/// - Polaroid Print: Physical white frame, slight thickness, miniature photo inset
/// - Small Card: Heavy watercolor cardstock, clean beveled edges
/// - Bookmark: Thin woven card with miniature hanging ribbon tassel
///
/// Features animated physical entrance, interactive collision shapes, and surface snapping.
@MainActor
final class ThoughtEntityBuilder {
    
    static func buildThoughtEntity(for item: NookItem) -> ModelEntity {
        let mats = RoomMaterials.shared
        let entity: ModelEntity
        
        switch item.objectType {
        case .pebble:
            // Smooth irregular river stone (asymmetrical rounded box with high corner radius)
            var pebbleMat = PhysicallyBasedMaterial()
            pebbleMat.baseColor = .init(tint: NSColor(red: 0.62, green: 0.58, blue: 0.54, alpha: 1.0))
            pebbleMat.roughness = .init(floatLiteral: 0.32)
            pebbleMat.specular = .init(floatLiteral: 0.15)
            
            let mesh = MeshResource.generateBox(size: [0.078, 0.034, 0.062], cornerRadius: 0.016)
            entity = ModelEntity(mesh: mesh, materials: [pebbleMat])
            entity.scale = [1.05, 0.95, 1.0]
            
        case .paperNote:
            // Folded paper note with slight thickness and folded top flap
            let bodyMesh = MeshResource.generateBox(size: [0.082, 0.008, 0.068], cornerRadius: 0.002)
            entity = ModelEntity(mesh: bodyMesh, materials: [mats.creamLinenFabric])
            
            // Subtle folded corner flap
            let flapMesh = MeshResource.generateBox(size: [0.024, 0.003, 0.024], cornerRadius: 0.001)
            let flap = ModelEntity(mesh: flapMesh, materials: [mats.paperWhite])
            flap.position = [0.028, 0.005, -0.022]
            flap.orientation = simd_quatf(angle: Float.pi * 0.25, axis: [0, 1, 0])
            entity.addChild(flap)
            
        case .stickyNote:
            // Thin note with slightly curled corner
            let noteMesh = MeshResource.generateBox(size: [0.070, 0.003, 0.070], cornerRadius: 0.0015)
            entity = ModelEntity(mesh: noteMesh, materials: [mats.daisyYellow])
            
            // Curled edge accent
            let curlMesh = MeshResource.generateBox(size: [0.020, 0.002, 0.020], cornerRadius: 0.001)
            let curl = ModelEntity(mesh: curlMesh, materials: [mats.daisyYellow])
            curl.position = [0.026, 0.003, 0.026]
            curl.orientation = simd_quatf(angle: -Float.pi * 0.18, axis: [1, 0, 1])
            entity.addChild(curl)
            
        case .polaroid:
            // Physical white frame with slight thickness & photo inset
            let frameMesh = MeshResource.generateBox(size: [0.072, 0.005, 0.086], cornerRadius: 0.002)
            entity = ModelEntity(mesh: frameMesh, materials: [mats.paperWhite])
            
            // Photo image square inset
            let photoMesh = MeshResource.generateBox(size: [0.060, 0.002, 0.058], cornerRadius: 0.001)
            let photo = ModelEntity(mesh: photoMesh, materials: [mats.botanicalArt1Material])
            photo.position = [0, 0.003, -0.008]
            entity.addChild(photo)
            
        case .card:
            // Heavy watercolor / linen index card with beveled edge
            let cardMesh = MeshResource.generateBox(size: [0.095, 0.004, 0.065], cornerRadius: 0.002)
            entity = ModelEntity(mesh: cardMesh, materials: [mats.openNotebookMaterial])
            
        case .bookmark:
            // Thin woven card with hanging ribbon tassel
            let bookmarkMesh = MeshResource.generateBox(size: [0.032, 0.003, 0.115], cornerRadius: 0.0015)
            entity = ModelEntity(mesh: bookmarkMesh, materials: [mats.creamLinenFabric])
            
            // Hanging ribbon cord at top
            let ribbonMesh = MeshResource.generateCylinder(height: 0.040, radius: 0.0025)
            let ribbon = ModelEntity(mesh: ribbonMesh, materials: [mats.sageGreenFabric])
            ribbon.position = [0, 0.001, -0.068]
            ribbon.orientation = simd_quatf(angle: Float.pi * 0.45, axis: [1, 0, 0])
            entity.addChild(ribbon)
        }
        
        entity.name = "thought_\(item.id.uuidString)"
        
        // Initial world position
        let worldPos = worldPosition(for: item.roomPosition)
        entity.position = worldPos
        
        // Apply rotation
        let rotY = Float(item.rotation * .pi / 180.0)
        entity.orientation = simd_quatf(angle: rotY, axis: [0, 1, 0])
        
        // Interactive Collision, Input & Representation Components
        let bounds = entity.visualBounds(relativeTo: nil)
        let colSize = SIMD3<Float>(max(0.06, bounds.extents.x), max(0.03, bounds.extents.y), max(0.06, bounds.extents.z))
        let collisionShape = ShapeResource.generateBox(size: colSize)
        entity.components.set(CollisionComponent(shapes: [collisionShape]))
        entity.components.set(InputTargetComponent())
        entity.components.set(ThoughtRepresentationComponent(objectType: item.objectType))
        
        return entity
    }
    
    /// Converts a normalized RoomPosition to 3D world coordinates.
    ///
    /// If coordinates are already in direct metric range (from physical zones),
    /// preserves them; otherwise maps normalized (0...1) coordinates onto the desk surface.
    nonisolated static func worldPosition(for roomPos: RoomPosition) -> SIMD3<Float> {
        // If x is negative or > 1.5, it represents direct metric world coordinates
        if roomPos.x < 0 || roomPos.x > 1.0 || roomPos.y < 0 || roomPos.y > 1.0 {
            return SIMD3<Float>(Float(roomPos.x), Float(roomPos.y), Float(roomPos.z))
        }
        
        // Standard mapping across desk surface
        let deskX: Float = -0.70
        let deskZ: Float = -0.56
        let surfaceY: Float = 0.735
        
        let offsetX = (Float(roomPos.x) - 0.5) * 0.44
        let offsetZ = (Float(roomPos.y) - 0.5) * 0.28
        return SIMD3<Float>(deskX + offsetX, surfaceY, deskZ + offsetZ)
    }
    
    /// Converts 3D world coordinates to a persistent RoomPosition.
    nonisolated static func roomPosition(from worldPos: SIMD3<Float>) -> RoomPosition {
        return RoomPosition(
            x: Double(worldPos.x),
            y: Double(worldPos.y),
            z: Double(worldPos.z)
        )
    }
    
    /// Animates the physical entrance of a newly placed thought object.
    /// Floats down gently from slightly above the surface with a soft settling spring.
    static func animateEntrance(entity: Entity, targetPosition: SIMD3<Float>) {
        let spawnY = targetPosition.y + 0.12
        entity.position = SIMD3<Float>(targetPosition.x, spawnY, targetPosition.z)
        entity.scale = SIMD3<Float>(0.3, 0.3, 0.3)
        
        Task { @MainActor in
            let steps = 14
            let duration: Double = 0.38
            let stepInterval = UInt64((duration / Double(steps)) * 1_000_000_000)
            
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: stepInterval)
                let t = Float(i) / Float(steps)
                
                // Spring ease-out with soft bounce
                let easeOut = sin(t * Float.pi * 0.5)
                let currentY = spawnY - (spawnY - targetPosition.y) * easeOut
                let currentScale = 0.3 + (1.0 - 0.3) * easeOut
                
                entity.position.y = currentY
                entity.scale = SIMD3<Float>(currentScale, currentScale, currentScale)
            }
            
            // Snap firmly to resting surface
            entity.position = targetPosition
            entity.scale = SIMD3<Float>(1.0, 1.0, 1.0)
        }
    }
}

/// RealityKit component identifying the physical 3D representation type of a thought object.
struct ThoughtRepresentationComponent: Component {
    var objectType: NookObjectType
    
    init(objectType: NookObjectType) {
        self.objectType = objectType
    }
}


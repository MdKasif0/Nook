import RealityKit
import AppKit

/// Builds tactile 3D physical thought objects placed in the room:
/// - Smooth Zen Pebble
/// - Folded Kraft Paper Note
/// - Pastel Sticky Note
/// - Polaroid Photo Print
/// - Ruled Index Card
/// - Leather Bookmark with Tassel
///
/// Each entity is configured with physical collision shapes and input targets
/// for clicking, hovering, selection halos, and physical dragging.
@MainActor
final class ThoughtEntityBuilder {
    
    static func buildThoughtEntity(for item: NookItem) -> ModelEntity {
        let mats = RoomMaterials.shared
        let entity: ModelEntity
        
        switch item.objectType {
        case .pebble:
            // Smooth river stone
            var pebbleMat = PhysicallyBasedMaterial()
            pebbleMat.baseColor = .init(tint: NSColor(red: 0.65, green: 0.63, blue: 0.60, alpha: 1.0))
            pebbleMat.roughness = .init(floatLiteral: 0.28)
            let mesh = MeshResource.generateBox(size: [0.08, 0.038, 0.065], cornerRadius: 0.018)
            entity = ModelEntity(mesh: mesh, materials: [pebbleMat])
            
        case .paperNote:
            // Folded paper note
            let mesh = MeshResource.generateBox(size: [0.09, 0.012, 0.07], cornerRadius: 0.003)
            entity = ModelEntity(mesh: mesh, materials: [mats.creamLinenFabric])
            
        case .stickyNote:
            // Pastel sticky note
            let mesh = MeshResource.generateBox(size: [0.075, 0.004, 0.075], cornerRadius: 0.002)
            entity = ModelEntity(mesh: mesh, materials: [mats.daisyYellow])
            
        case .polaroid:
            // Polaroid photo print
            let mesh = MeshResource.generateBox(size: [0.075, 0.006, 0.09], cornerRadius: 0.003)
            entity = ModelEntity(mesh: mesh, materials: [mats.botanicalArt1Material])
            
        case .card:
            // Ruled index card
            let mesh = MeshResource.generateBox(size: [0.11, 0.005, 0.075], cornerRadius: 0.002)
            entity = ModelEntity(mesh: mesh, materials: [mats.openNotebookMaterial])
            
        case .bookmark:
            // Leather / Ribbon bookmark
            let mesh = MeshResource.generateBox(size: [0.035, 0.004, 0.13], cornerRadius: 0.002)
            entity = ModelEntity(mesh: mesh, materials: [mats.sageGreenFabric])
        }
        
        entity.name = "thought_\(item.id.uuidString)"
        
        // Position according to item's persistent RoomPosition
        let worldPos = worldPosition(for: item.roomPosition)
        entity.position = worldPos
        
        // Interactive Collision & Input Components
        let bounds = entity.visualBounds(relativeTo: nil)
        let collisionShape = ShapeResource.generateBox(size: bounds.extents)
        entity.components.set(CollisionComponent(shapes: [collisionShape]))
        entity.components.set(InputTargetComponent())
        
        return entity
    }
    
    /// Converts a normalized RoomPosition (0...1) to 3D world coordinates on the desk surface.
    static func worldPosition(for roomPos: RoomPosition) -> SIMD3<Float> {
        let deskX: Float = -0.72
        let deskZ: Float = -0.55
        let surfaceY: Float = RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.015
        
        let offsetX = (Float(roomPos.x) - 0.5) * 0.55
        let offsetZ = (Float(roomPos.y) - 0.5) * 0.35
        return SIMD3<Float>(deskX + offsetX, surfaceY, deskZ + offsetZ)
    }
    
    /// Converts 3D world coordinates on the desk to a normalized RoomPosition (0...1).
    static func roomPosition(from worldPos: SIMD3<Float>) -> RoomPosition {
        let deskX: Float = -0.72
        let deskZ: Float = -0.55
        let normX = Double((worldPos.x - deskX) / 0.55 + 0.5)
        let normY = Double((worldPos.z - deskZ) / 0.35 + 0.5)
        return RoomPosition(
            x: min(0.95, max(0.05, normX)),
            y: min(0.95, max(0.05, normY)),
            z: 0.5
        )
    }
}

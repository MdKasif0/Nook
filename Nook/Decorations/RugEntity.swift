import RealityKit
import AppKit

/// Builds the woven cream botanical area rug sitting under the ergonomic office chair:
/// - Cream woven wool material
/// - Subtle sage green botanical branch pattern
/// - Thin beveled floor plane
@MainActor
final class RugEntity: Entity {
    
    required init() {
        super.init()
        self.name = "desk_rug"
        buildRug()
    }
    
    private func buildRug() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        
        // Rug placed under the chair in front of the desk
        // X = -0.52, Z = -0.15
        let rugWidth: Float = 0.72
        let rugLength: Float = 0.95
        let rugMesh = MeshResource.generateBox(size: [rugWidth, 0.003, rugLength], cornerRadius: 0.015)
        let rug = ModelEntity(mesh: rugMesh, materials: [mats.rugBotanicalMaterial])
        rug.position = [-0.52, floorY + 0.0015, -0.15]
        addChild(rug)
    }
}

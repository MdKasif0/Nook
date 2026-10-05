import RealityKit
import AppKit

/// Builds the center-right cozy platform bed matching the reference image:
/// - Warm honey-oak wooden frame and headboard
/// - Cream mattress and duvet bedding
/// - Layered sleeping pillows
/// - Muted sage accent pillow
/// - Adorable daisy flower pillow (white petals with yellow center)
/// - Soft textured sage green throw blanket with organic ripple folds
/// - Small wooden bedside nightstand with tiny succulent
@MainActor
final class BedEntity: Entity {
    
    // Bed dimensions
    static let bedWidth: Float = 0.95   // along X
    static let bedLength: Float = 1.35  // along Z
    static let frameHeight: Float = 0.28
    
    required init() {
        super.init()
        self.name = "bed_setup"
        buildBed()
    }
    
    private func buildBed() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        
        // Bed positioned at center-right against back wall and near right window
        // X = +0.58, Z = -0.45
        self.position = [0.58, floorY, -0.45]
        
        // 1. Warm Wooden Bed Frame
        let frameMesh = MeshResource.generateBox(size: [Self.bedWidth, Self.frameHeight, Self.bedLength], cornerRadius: 0.015)
        let bedFrame = ModelEntity(mesh: frameMesh, materials: [mats.honeyOakWood])
        bedFrame.position = [0, Self.frameHeight * 0.5, 0]
        bedFrame.name = "bed_frame"
        addChild(bedFrame)
        
        // 2. Headboard against the back wall
        let headboardHeight: Float = 0.45
        let headboardMesh = MeshResource.generateBox(size: [Self.bedWidth, headboardHeight, 0.04], cornerRadius: 0.01)
        let headboard = ModelEntity(mesh: headboardMesh, materials: [mats.honeyOakWood])
        headboard.position = [0, Self.frameHeight + headboardHeight * 0.5 - 0.05, -Self.bedLength * 0.5 + 0.02]
        addChild(headboard)
        
        // 3. Cream Mattress & Duvet Base
        let mattressWidth: Float = Self.bedWidth - 0.06
        let mattressLength: Float = Self.bedLength - 0.06
        let mattressHeight: Float = 0.16
        let mattressMesh = MeshResource.generateBox(size: [mattressWidth, mattressHeight, mattressLength], cornerRadius: 0.025)
        let mattress = ModelEntity(mesh: mattressMesh, materials: [mats.creamLinenFabric])
        mattress.position = [0, Self.frameHeight + mattressHeight * 0.5 - 0.02, 0.01]
        mattress.name = "mattress"
        addChild(mattress)
        
        // 4. Layered Pillows at Head of Bed
        // Back sleeping pillows (2 white/cream plump pillows)
        let pillowMesh = ProceduralMeshGenerator.generatePillowMesh(width: 0.36, height: 0.10, depth: 0.22)
        
        let leftPillow = ModelEntity(mesh: pillowMesh, materials: [mats.creamLinenFabric])
        leftPillow.position = [-0.20, Self.frameHeight + mattressHeight + 0.04, -Self.bedLength * 0.5 + 0.20]
        leftPillow.orientation = simd_quatf(angle: -Float.pi * 0.08, axis: [1, 0, 0])
        addChild(leftPillow)
        
        let rightPillow = ModelEntity(mesh: pillowMesh, materials: [mats.creamLinenFabric])
        rightPillow.position = [0.20, Self.frameHeight + mattressHeight + 0.04, -Self.bedLength * 0.5 + 0.20]
        rightPillow.orientation = simd_quatf(angle: -Float.pi * 0.08, axis: [1, 0, 0])
        addChild(rightPillow)
        
        // Muted Sage Square Accent Pillow
        let sagePillowMesh = ProceduralMeshGenerator.generatePillowMesh(width: 0.24, height: 0.08, depth: 0.24)
        let sagePillow = ModelEntity(mesh: sagePillowMesh, materials: [mats.sageGreenFabric])
        sagePillow.position = [0.18, Self.frameHeight + mattressHeight + 0.07, -Self.bedLength * 0.5 + 0.32]
        sagePillow.orientation = simd_quatf(angle: -Float.pi * 0.15, axis: [1, 0, 0]) * simd_quatf(angle: Float.pi * 0.1, axis: [0, 1, 0])
        addChild(sagePillow)
        
        // 5. Adorable Daisy Flower Pillow (White petals with yellow center)
        let daisyEntity = buildDaisyPillow(materials: mats)
        daisyEntity.position = [-0.14, Self.frameHeight + mattressHeight + 0.06, -Self.bedLength * 0.5 + 0.34]
        daisyEntity.orientation = simd_quatf(angle: -Float.pi * 0.12, axis: [1, 0, 0])
        daisyEntity.name = "daisy_pillow_bed"
        addChild(daisyEntity)
        
        // 6. Soft Textured Sage Green Throw Blanket (draped across foot of bed with organic folds)
        let blanketMesh = ProceduralMeshGenerator.generateBlanketMesh(width: mattressWidth + 0.04, depth: 0.65, drapeY: 0.14)
        let blanket = ModelEntity(mesh: blanketMesh, materials: [mats.sageGreenFabric])
        blanket.position = [0, Self.frameHeight + mattressHeight + 0.005, 0.28]
        blanket.name = "throw_blanket"
        addChild(blanket)
        
        // 7. Small Wooden Bedside Nightstand (between bed and desk)
        let nightstandMesh = MeshResource.generateBox(size: [0.22, 0.26, 0.24], cornerRadius: 0.01)
        let nightstand = ModelEntity(mesh: nightstandMesh, materials: [mats.honeyOakWood])
        nightstand.position = [-Self.bedWidth * 0.5 - 0.13, 0.13, -Self.bedLength * 0.5 + 0.22]
        nightstand.name = "bedside_nightstand"
        addChild(nightstand)
        
        // Tiny Succulent on Nightstand
        let pot = ModelEntity(mesh: .generateCylinder(height: 0.04, radius: 0.024), materials: [mats.glazedWhiteCeramic])
        pot.position = [0, 0.13 + 0.02, 0]
        let plant = ModelEntity(mesh: .generateSphere(radius: 0.022), materials: [mats.foliageLight])
        plant.position = [0, 0.025, 0]
        pot.addChild(plant)
        nightstand.addChild(pot)
    }
    
    // Builds a miniature daisy flower cushion (8 rounded petals around a center disk)
    private func buildDaisyPillow(materials: RoomMaterials) -> Entity {
        let daisyRoot = Entity()
        daisyRoot.name = "daisy_pillow"
        
        // Center yellow button
        let centerMesh = MeshResource.generateCylinder(height: 0.035, radius: 0.045)
        let center = ModelEntity(mesh: centerMesh, materials: [materials.daisyYellow])
        daisyRoot.addChild(center)
        
        // 8 white oval petals arranged circularly
        let petalMesh = MeshResource.generateBox(size: [0.05, 0.025, 0.07], cornerRadius: 0.012)
        for i in 0..<8 {
            let angle = Float(i) * (Float.pi * 2.0 / 8.0)
            let petal = ModelEntity(mesh: petalMesh, materials: [materials.creamLinenFabric])
            let dist: Float = 0.065
            petal.position = [cos(angle) * dist, 0, sin(angle) * dist]
            petal.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
            daisyRoot.addChild(petal)
        }
        return daisyRoot
    }
}

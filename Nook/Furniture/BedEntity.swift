import RealityKit
import AppKit

/// Builds the cozy platform bed placed along the back wall under the window:
/// - Warm honey-oak wooden frame and headboard
/// - Cream mattress and duvet bedding
/// - Layered sleeping pillows, sage pillow, and daisy flower pillow
/// - Soft textured sage green throw blanket with organic ripple folds
/// - Small wooden bedside nightstand with tiny succulent
@MainActor
final class BedEntity: Entity {
    
    // Bed dimensions
    static let bedLength: Float = 1.25  // along X (from head to foot)
    static let bedWidth: Float = 0.82   // along Z
    static let frameHeight: Float = 0.28
    
    required init() {
        super.init()
        self.name = "bed_setup"
        buildBed()
    }
    
    private func buildBed() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        
        // Bed positioned along the back wall right under the window:
        // Centered at X = +0.48, Z = -0.78
        self.position = [0.48, floorY, -0.78]
        
        // 1. Warm Wooden Bed Frame
        let frameMesh = MeshResource.generateBox(size: [Self.bedLength, Self.frameHeight, Self.bedWidth], cornerRadius: 0.015)
        let bedFrame = ModelEntity(mesh: frameMesh, materials: [mats.honeyOakWood])
        bedFrame.position = [0, Self.frameHeight * 0.5, 0]
        bedFrame.name = "bed_frame"
        addChild(bedFrame)
        
        // 2. Headboard on the left end (against bookcase)
        let headboardHeight: Float = 0.45
        let headboardMesh = MeshResource.generateBox(size: [0.04, headboardHeight, Self.bedWidth], cornerRadius: 0.01)
        let headboard = ModelEntity(mesh: headboardMesh, materials: [mats.honeyOakWood])
        headboard.position = [-Self.bedLength * 0.5 + 0.02, Self.frameHeight + headboardHeight * 0.5 - 0.05, 0]
        addChild(headboard)
        
        // 3. Cream Mattress & Duvet Base
        let mattressLength: Float = Self.bedLength - 0.06
        let mattressWidth: Float = Self.bedWidth - 0.06
        let mattressHeight: Float = 0.16
        let mattressMesh = MeshResource.generateBox(size: [mattressLength, mattressHeight, mattressWidth], cornerRadius: 0.025)
        let mattress = ModelEntity(mesh: mattressMesh, materials: [mats.creamLinenFabric])
        mattress.position = [0.01, Self.frameHeight + mattressHeight * 0.5 - 0.02, 0]
        mattress.name = "mattress"
        addChild(mattress)
        
        // 4. Layered Pillows at Head of Bed (near X = -Self.bedLength * 0.5)
        let pillowMesh = ProceduralMeshGenerator.generatePillowMesh(width: 0.22, height: 0.10, depth: 0.32)
        
        let backPillow1 = ModelEntity(mesh: pillowMesh, materials: [mats.creamLinenFabric])
        backPillow1.position = [-Self.bedLength * 0.5 + 0.18, Self.frameHeight + mattressHeight + 0.04, -0.16]
        backPillow1.orientation = simd_quatf(angle: Float.pi * 0.08, axis: [0, 0, 1])
        addChild(backPillow1)
        
        let backPillow2 = ModelEntity(mesh: pillowMesh, materials: [mats.creamLinenFabric])
        backPillow2.position = [-Self.bedLength * 0.5 + 0.18, Self.frameHeight + mattressHeight + 0.04, 0.16]
        backPillow2.orientation = simd_quatf(angle: Float.pi * 0.08, axis: [0, 0, 1])
        addChild(backPillow2)
        
        // Muted Sage Square Accent Pillow
        let sagePillowMesh = ProceduralMeshGenerator.generatePillowMesh(width: 0.22, height: 0.08, depth: 0.22)
        let sagePillow = ModelEntity(mesh: sagePillowMesh, materials: [mats.sageGreenFabric])
        sagePillow.position = [-Self.bedLength * 0.5 + 0.28, Self.frameHeight + mattressHeight + 0.06, 0.14]
        sagePillow.orientation = simd_quatf(angle: Float.pi * 0.12, axis: [0, 0, 1]) * simd_quatf(angle: -Float.pi * 0.1, axis: [0, 1, 0])
        addChild(sagePillow)
        
        // Adorable Daisy Flower Pillow (White petals with yellow center)
        let daisyEntity = buildDaisyPillow(materials: mats)
        daisyEntity.position = [-Self.bedLength * 0.5 + 0.30, Self.frameHeight + mattressHeight + 0.06, -0.12]
        daisyEntity.orientation = simd_quatf(angle: Float.pi * 0.10, axis: [0, 0, 1])
        daisyEntity.name = "daisy_pillow_bed"
        addChild(daisyEntity)
        
        // 5. Soft Textured Sage Green Throw Blanket (Draped across foot of bed)
        let blanketMesh = ProceduralMeshGenerator.generateBlanketMesh(width: 0.60, depth: mattressWidth + 0.04, drapeY: 0.14)
        let blanket = ModelEntity(mesh: blanketMesh, materials: [mats.sageGreenFabric])
        blanket.position = [Self.bedLength * 0.5 - 0.30, Self.frameHeight + mattressHeight + 0.005, 0]
        blanket.name = "throw_blanket"
        addChild(blanket)
        
        // 6. Bedside Nightstand (between bed and bookcase)
        let nightstandMesh = MeshResource.generateBox(size: [0.22, 0.26, 0.24], cornerRadius: 0.01)
        let nightstand = ModelEntity(mesh: nightstandMesh, materials: [mats.honeyOakWood])
        nightstand.position = [-Self.bedLength * 0.5 - 0.13, 0.13, -Self.bedWidth * 0.5 + 0.16]
        nightstand.name = "bedside_nightstand"
        addChild(nightstand)
        
        let pot = ModelEntity(mesh: .generateCylinder(height: 0.04, radius: 0.024), materials: [mats.glazedWhiteCeramic])
        pot.position = [0, 0.13 + 0.02, 0]
        let plant = ModelEntity(mesh: .generateSphere(radius: 0.022), materials: [mats.foliageLight])
        plant.position = [0, 0.025, 0]
        pot.addChild(plant)
        nightstand.addChild(pot)
    }
    
    private func buildDaisyPillow(materials: RoomMaterials) -> Entity {
        let daisyRoot = Entity()
        daisyRoot.name = "daisy_pillow"
        
        let center = ModelEntity(mesh: .generateCylinder(height: 0.035, radius: 0.045), materials: [materials.daisyYellow])
        daisyRoot.addChild(center)
        
        let petalMesh = MeshResource.generateBox(size: [0.07, 0.025, 0.05], cornerRadius: 0.012)
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

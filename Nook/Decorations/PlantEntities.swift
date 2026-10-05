import RealityKit
import AppKit

/// Builds the indoor plants throughout the Nook diorama:
/// - Trailing ivy vines cascading down from the top shelf and left corner
/// - Large potted Monstera deliciosa in tall white ceramic cylinder pot
/// - Potted leafy floor plant on plant stand next to desk drawers
/// - Tiny potted succulents on the wooden stairs and floor ledge
@MainActor
final class PlantEntities: Entity {
    
    required init() {
        super.init()
        self.name = "room_plants"
        buildPlants()
    }
    
    private func buildPlants() {
        let mats = RoomMaterials.shared
        let upperFloorY = RoomArchitectureEntity.upperFloorY
        let lowerFloorY = RoomArchitectureEntity.lowerFloorY
        
        // 1. Cascading Ivy Vines Hanging from Top Shelf (Left Wall & Shelf corner)
        // Positioned at X = -1.18, Y = 1.65, Z = -1.10
        let vineRoot = Entity()
        vineRoot.position = [-1.15, upperFloorY + 1.45, -1.10]
        vineRoot.name = "trailing_ivy"
        addChild(vineRoot)
        
        // Multiple hanging vine strands cascading down the corner
        let vineOffsets: [(x: Float, z: Float, length: Float)] = [
            (0.00, 0.00, 0.65),
            (0.06, 0.03, 0.45),
            (-0.04, 0.08, 0.55),
            (0.12, 0.02, 0.35),
            (0.04, 0.12, 0.70)
        ]
        
        for (i, v) in vineOffsets.enumerated() {
            let strand = Entity()
            strand.position = [v.x, 0, v.z]
            
            // Stem strand
            let stemMesh = MeshResource.generateCylinder(height: v.length, radius: 0.004)
            let stem = ModelEntity(mesh: stemMesh, materials: [mats.foliageDeep])
            stem.position = [0, -v.length * 0.5, 0]
            strand.addChild(stem)
            
            // Alternating leaves cascading down the stem
            let leafCount = Int(v.length / 0.06)
            let leafMesh = MeshResource.generateBox(size: [0.032, 0.003, 0.042], cornerRadius: 0.008)
            for j in 0..<leafCount {
                let leafY = -Float(j) * 0.06 - 0.03
                let leaf = ModelEntity(mesh: leafMesh, materials: [j % 2 == 0 ? mats.foliageDeep : mats.foliageLight])
                let angle = Float(j) * 1.3
                leaf.position = [cos(angle) * 0.022, leafY, sin(angle) * 0.022]
                leaf.orientation = simd_quatf(angle: angle, axis: [0, 1, 0]) * simd_quatf(angle: Float.pi * 0.15, axis: [1, 0, 0])
                strand.addChild(leaf)
            }
            vineRoot.addChild(strand)
        }
        
        // 2. Large Potted Monstera Deliciosa (Right Foreground Lounge, in front of record bench)
        // Positioned at X = +0.95, Z = +0.65, Y = lowerFloorY
        let monsteraRoot = Entity()
        monsteraRoot.position = [0.95, lowerFloorY, 0.65]
        monsteraRoot.name = "monstera_plant"
        addChild(monsteraRoot)
        
        // Tall White Glazed Ceramic Pot
        let potHeight: Float = 0.18
        let potRadius: Float = 0.08
        let potMesh = MeshResource.generateCylinder(height: potHeight, radius: potRadius)
        let pot = ModelEntity(mesh: potMesh, materials: [mats.glazedWhiteCeramic])
        pot.position = [0, potHeight * 0.5, 0]
        monsteraRoot.addChild(pot)
        
        // Soil disc
        let soilMesh = MeshResource.generateCylinder(height: 0.01, radius: potRadius - 0.005)
        let soil = ModelEntity(mesh: soilMesh, materials: [mats.terracottaClay])
        soil.position = [0, potHeight + 0.002, 0]
        monsteraRoot.addChild(soil)
        
        // Lush Monstera Leaves branching outwards
        let leafConfigs: [(pitch: Float, yaw: Float, height: Float, scale: Float)] = [
            (0.25, 0.2, 0.14, 1.0),
            (0.35, 1.4, 0.18, 1.1),
            (0.30, 2.6, 0.16, 0.95),
            (0.40, 3.8, 0.20, 1.05),
            (0.20, 5.0, 0.12, 0.85)
        ]
        
        for c in leafConfigs {
            let stalk = ModelEntity(mesh: .generateCylinder(height: c.height, radius: 0.005), materials: [mats.foliageDeep])
            stalk.position = [0, potHeight + c.height * 0.4, 0]
            stalk.orientation = simd_quatf(angle: c.yaw, axis: [0, 1, 0]) * simd_quatf(angle: c.pitch, axis: [1, 0, 0])
            
            // Broad split leaf blade
            let bladeMesh = MeshResource.generateBox(size: [0.12 * c.scale, 0.004, 0.16 * c.scale], cornerRadius: 0.02)
            let blade = ModelEntity(mesh: bladeMesh, materials: [mats.foliageDeep])
            blade.position = [0, c.height * 0.5 + 0.05 * c.scale, 0]
            blade.orientation = simd_quatf(angle: Float.pi * 0.2, axis: [1, 0, 0])
            stalk.addChild(blade)
            
            monsteraRoot.addChild(stalk)
        }
        
        // 3. Potted Floor Plant next to Desk Drawers (Left Floor)
        // Positioned at X = -1.10, Z = +0.10, Y = upperFloorY
        let deskFloorPlant = Entity()
        deskFloorPlant.position = [-1.10, upperFloorY, 0.10]
        deskFloorPlant.name = "desk_floor_plant"
        addChild(deskFloorPlant)
        
        // Small 3-legged wooden plant stand
        let standHeight: Float = 0.10
        let stoolTop = ModelEntity(mesh: .generateCylinder(height: 0.015, radius: 0.075), materials: [mats.honeyOakWood])
        stoolTop.position = [0, standHeight, 0]
        deskFloorPlant.addChild(stoolTop)
        
        for i in 0..<3 {
            let a = Float(i) * (Float.pi * 2.0 / 3.0)
            let leg = ModelEntity(mesh: .generateCylinder(height: standHeight, radius: 0.008), materials: [mats.honeyOakWood])
            leg.position = [cos(a) * 0.055, standHeight * 0.5, sin(a) * 0.055]
            deskFloorPlant.addChild(leg)
        }
        
        // Ceramic Pot & Plant on stand
        let floorPot = ModelEntity(mesh: .generateCylinder(height: 0.10, radius: 0.065), materials: [mats.glazedWhiteCeramic])
        floorPot.position = [0, standHeight + 0.055, 0]
        deskFloorPlant.addChild(floorPot)
        
        let leafyPlant = ModelEntity(mesh: .generateSphere(radius: 0.075), materials: [mats.foliageLight])
        leafyPlant.position = [0, standHeight + 0.12, 0]
        deskFloorPlant.addChild(leafyPlant)
        
        // 4. Succulents on Stairs & Floor Step
        // Middle stair step: Stack of books + tiny succulent
        let stepPlantRoot = Entity()
        stepPlantRoot.position = [-0.35, 0.09, 0.25]
        stepPlantRoot.name = "step_succulent_setup"
        addChild(stepPlantRoot)
        
        // 2 books under plant
        let stepBook1 = ModelEntity(mesh: .generateBox(size: [0.12, 0.018, 0.09], cornerRadius: 0.002), materials: [mats.terracottaClay])
        stepBook1.position = [0, 0.009, 0]
        stepPlantRoot.addChild(stepBook1)
        
        let stepBook2 = ModelEntity(mesh: .generateBox(size: [0.11, 0.016, 0.085], cornerRadius: 0.002), materials: [mats.creamLinenFabric])
        stepBook2.position = [0, 0.026, 0]
        stepBook2.orientation = simd_quatf(angle: Float.pi * 0.06, axis: [0, 1, 0])
        stepPlantRoot.addChild(stepBook2)
        
        let stepPot = ModelEntity(mesh: .generateCylinder(height: 0.035, radius: 0.022), materials: [mats.glazedWhiteCeramic])
        stepPot.position = [0, 0.052, 0]
        let stepFoliage = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [mats.foliageLight])
        stepFoliage.position = [0, 0.022, 0]
        stepPot.addChild(stepFoliage)
        stepPlantRoot.addChild(stepPot)
        
        // Lower step corner: Tiny square potted plant
        let cornerPlant = ModelEntity(mesh: .generateBox(size: [0.045, 0.045, 0.045], cornerRadius: 0.004), materials: [mats.glazedWhiteCeramic])
        cornerPlant.position = [-0.22, 0.022, 0.50]
        let cornerFoliage = ModelEntity(mesh: .generateSphere(radius: 0.022), materials: [mats.foliageDeep])
        cornerFoliage.position = [0, 0.028, 0]
        cornerPlant.addChild(cornerFoliage)
        addChild(cornerPlant)
    }
}

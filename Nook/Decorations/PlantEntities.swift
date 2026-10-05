import RealityKit
import AppKit

/// Builds the indoor plants throughout the Nook diorama:
/// - Trailing ivy vines cascading down from the corner shelves
/// - Large potted Monstera deliciosa in tall white ceramic cylinder pot near the record bench
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
        
        // 1. Cascading Ivy Vines in Back-Left Corner (hanging from top shelf down the corner)
        // Corner at X = -1.15, Z = -1.15
        let vineRoot = Entity()
        vineRoot.position = [-1.12, upperFloorY + 1.48, -1.12]
        vineRoot.name = "trailing_ivy"
        addChild(vineRoot)
        
        let vineOffsets: [(x: Float, z: Float, length: Float)] = [
            (0.00, 0.00, 0.68),
            (0.06, 0.03, 0.48),
            (-0.02, 0.07, 0.58),
            (0.12, 0.02, 0.38),
            (0.03, 0.12, 0.72)
        ]
        
        for (_, v) in vineOffsets.enumerated() {
            let strand = Entity()
            strand.position = [v.x, 0, v.z]
            
            let stemMesh = MeshResource.generateCylinder(height: v.length, radius: 0.004)
            let stem = ModelEntity(mesh: stemMesh, materials: [mats.foliageDeep])
            stem.position = [0, -v.length * 0.5, 0]
            strand.addChild(stem)
            
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
        
        // 1b. Cascading Ivy Vines down Front-Left Wall Edge / Column (Matching prominent reference feature)
        let frontVineRoot = Entity()
        frontVineRoot.position = [-1.15, upperFloorY + 1.42, 0.32]
        frontVineRoot.name = "front_trailing_ivy"
        addChild(frontVineRoot)
        
        let frontVineOffsets: [(x: Float, z: Float, length: Float)] = [
            (0.00, 0.00, 0.95),
            (0.04, -0.03, 0.75),
            (-0.03, 0.04, 0.60),
            (0.05, 0.02, 0.85)
        ]
        
        for v in frontVineOffsets {
            let strand = Entity()
            strand.position = [v.x, 0, v.z]
            let stemMesh = MeshResource.generateCylinder(height: v.length, radius: 0.004)
            let stem = ModelEntity(mesh: stemMesh, materials: [mats.foliageDeep])
            stem.position = [0, -v.length * 0.5, 0]
            strand.addChild(stem)
            
            let leafCount = Int(v.length / 0.055)
            let leafMesh = MeshResource.generateBox(size: [0.034, 0.003, 0.044], cornerRadius: 0.008)
            for j in 0..<leafCount {
                let leafY = -Float(j) * 0.055 - 0.025
                let leaf = ModelEntity(mesh: leafMesh, materials: [j % 2 == 0 ? mats.foliageDeep : mats.foliageLight])
                let angle = Float(j) * 1.4
                leaf.position = [cos(angle) * 0.024, leafY, sin(angle) * 0.024]
                leaf.orientation = simd_quatf(angle: angle, axis: [0, 1, 0]) * simd_quatf(angle: Float.pi * 0.18, axis: [1, 0, 0])
                strand.addChild(leaf)
            }
            frontVineRoot.addChild(strand)
        }
        
        // 2. Large Potted Monstera Deliciosa (Right side near record player bench)
        // Positioned at X = +1.02, Z = +0.10, Y = upperFloorY
        let monsteraRoot = Entity()
        monsteraRoot.position = [1.02, upperFloorY, 0.10]
        monsteraRoot.name = "monstera_plant"
        addChild(monsteraRoot)
        
        let potHeight: Float = 0.18
        let potRadius: Float = 0.08
        let potMesh = MeshResource.generateCylinder(height: potHeight, radius: potRadius)
        let pot = ModelEntity(mesh: potMesh, materials: [mats.glazedWhiteCeramic])
        pot.position = [0, potHeight * 0.5, 0]
        monsteraRoot.addChild(pot)
        
        let soilMesh = MeshResource.generateCylinder(height: 0.01, radius: potRadius - 0.005)
        let soil = ModelEntity(mesh: soilMesh, materials: [mats.terracottaClay])
        soil.position = [0, potHeight + 0.002, 0]
        monsteraRoot.addChild(soil)
        
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
            
            let bladeMesh = MeshResource.generateBox(size: [0.12 * c.scale, 0.004, 0.16 * c.scale], cornerRadius: 0.02)
            let blade = ModelEntity(mesh: bladeMesh, materials: [mats.foliageDeep])
            blade.position = [0, c.height * 0.5 + 0.05 * c.scale, 0]
            blade.orientation = simd_quatf(angle: Float.pi * 0.2, axis: [1, 0, 0])
            stalk.addChild(blade)
            
            monsteraRoot.addChild(stalk)
        }
        
        // 3. Potted Floor Plant next to Desk Drawers (Left Floor)
        // Positioned at X = -0.95, Z = +0.25, Y = upperFloorY
        let deskFloorPlant = Entity()
        deskFloorPlant.position = [-0.95, upperFloorY, 0.25]
        deskFloorPlant.name = "desk_floor_plant"
        addChild(deskFloorPlant)
        
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
        
        let floorPot = ModelEntity(mesh: .generateCylinder(height: 0.10, radius: 0.065), materials: [mats.glazedWhiteCeramic])
        floorPot.position = [0, standHeight + 0.055, 0]
        deskFloorPlant.addChild(floorPot)
        
        let leafyPlant = ModelEntity(mesh: .generateSphere(radius: 0.075), materials: [mats.foliageLight])
        leafyPlant.position = [0, standHeight + 0.12, 0]
        deskFloorPlant.addChild(leafyPlant)
        
        // 4. Succulents on Stairs & Floor Step
        let stepPlantRoot = Entity()
        stepPlantRoot.position = [-0.38, 0.09, 0.22]
        stepPlantRoot.name = "step_succulent_setup"
        addChild(stepPlantRoot)
        
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
        
        let cornerPlant = ModelEntity(mesh: .generateBox(size: [0.045, 0.045, 0.045], cornerRadius: 0.004), materials: [mats.glazedWhiteCeramic])
        cornerPlant.position = [-0.25, 0.022, 0.48]
        let cornerFoliage = ModelEntity(mesh: .generateSphere(radius: 0.022), materials: [mats.foliageDeep])
        cornerFoliage.position = [0, 0.028, 0]
        cornerPlant.addChild(cornerFoliage)
        addChild(cornerPlant)
    }
}

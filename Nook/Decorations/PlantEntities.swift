import RealityKit
import AppKit

/// Builds the floor objects and decorations hierarchy matching the reference image:
///
/// FloorObjects
/// ├── Skateboard (Movable)
/// ├── BouclePouf (White fluffy pouf with daisy button - Movable)
/// ├── MonsteraPlant (Large potted monstera - Movable)
/// ├── DeskFloorPlant (Leafy plant on wooden tripod stool - Movable)
/// ├── StepBooks (Books & succulent on wooden steps - Movable)
/// ├── StepSucculent (Miniature corner succulent - Movable)
/// ├── TrailingIvy (Cascading corner vines - Immovable)
/// ├── Rug (Area rug under chair - Immovable)
/// └── WallDecor (Framed art, sconce, pinned polaroids - Immovable)
@MainActor
final class FloorObjectsAreaEntity: Entity {
    
    let skateboard: SkateboardEntity
    let bouclePouf: BouclePoufEntity
    let monstera: MonsteraPlantEntity
    let deskFloorPlant: DeskFloorPlantEntity
    let stepBooks: StepBooksEntity
    let stepSucculent: StepSucculentEntity
    let trailingIvy: TrailingIvyEntity
    let rug: RugEntity
    let wallDecor: WallDecorEntities
    
    required init() {
        self.skateboard = SkateboardEntity()
        self.bouclePouf = BouclePoufEntity()
        self.monstera = MonsteraPlantEntity()
        self.deskFloorPlant = DeskFloorPlantEntity()
        self.stepBooks = StepBooksEntity()
        self.stepSucculent = StepSucculentEntity()
        self.trailingIvy = TrailingIvyEntity()
        self.rug = RugEntity()
        self.wallDecor = WallDecorEntities()
        
        super.init()
        self.name = "floor_objects_area"
        
        // Assemble hierarchy under FloorObjects
        addChild(skateboard)
        addChild(bouclePouf)
        addChild(monstera)
        addChild(deskFloorPlant)
        addChild(stepBooks)
        addChild(stepSucculent)
        addChild(trailingIvy)
        addChild(rug)
        addChild(wallDecor)
    }
}

// MARK: - White Boucle Floor Pouf (Movable)

@MainActor
final class BouclePoufEntity: Entity {
    static let defaultPos = SIMD3<Float>(0.75, RoomArchitectureEntity.lowerFloorY, 0.62)
    
    required init() {
        super.init()
        self.name = "prop_boucle_pouf"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let poufRadius: Float = 0.22
        let poufHeight: Float = 0.16
        let poufMesh = MeshResource.generateBox(size: [poufRadius * 2.0, poufHeight, poufRadius * 2.0], cornerRadius: 0.08)
        let pouf = ModelEntity(mesh: poufMesh, materials: [mats.whiteBoucleFabric])
        pouf.position = [0, poufHeight * 0.5, 0]
        addChild(pouf)
        
        // Flower / Daisy tufting button on top center
        let button = ModelEntity(mesh: .generateCylinder(height: 0.018, radius: 0.038), materials: [mats.daisyYellow])
        button.position = [0, poufHeight + 0.002, 0]
        addChild(button)
        
        let petalMesh = MeshResource.generateSphere(radius: 0.024)
        for i in 0..<6 {
            let angle = Float(i) * (Float.pi * 2.0 / 6.0)
            let petal = ModelEntity(mesh: petalMesh, materials: [mats.whiteBoucleFabric])
            petal.position = [cos(angle) * 0.055, poufHeight, sin(angle) * 0.055]
            addChild(petal)
        }
        
        let colShape = ShapeResource.generateBox(size: [0.46, 0.20, 0.46])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_boucle_pouf",
            displayName: "Bouclé Floor Pouf",
            accessibilityLabel: "White bouclé floor cushion with daisy button",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            allowsScaling: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.lowerFloorY
        ))
    }
}

// MARK: - Monstera Deliciosa Plant (Movable)

@MainActor
final class MonsteraPlantEntity: Entity {
    static let defaultPos = SIMD3<Float>(1.02, RoomArchitectureEntity.upperFloorY, 0.10)
    
    required init() {
        super.init()
        self.name = "prop_monstera"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let potHeight: Float = 0.18
        let potRadius: Float = 0.08
        let potMesh = MeshResource.generateCylinder(height: potHeight, radius: potRadius)
        let pot = ModelEntity(mesh: potMesh, materials: [mats.glazedWhiteCeramic])
        pot.position = [0, potHeight * 0.5, 0]
        addChild(pot)
        
        let soilMesh = MeshResource.generateCylinder(height: 0.01, radius: potRadius - 0.005)
        let soil = ModelEntity(mesh: soilMesh, materials: [mats.terracottaClay])
        soil.position = [0, potHeight + 0.002, 0]
        addChild(soil)
        
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
            
            addChild(stalk)
        }
        
        let colShape = ShapeResource.generateBox(size: [0.36, 0.42, 0.36])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_monstera",
            displayName: "Monstera Plant",
            accessibilityLabel: "Large potted monstera plant in white ceramic cylinder",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            allowsScaling: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY
        ))
    }
}

// MARK: - Desk Floor Plant on Wooden Stand (Movable)

@MainActor
final class DeskFloorPlantEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.95, RoomArchitectureEntity.upperFloorY, 0.25)
    
    required init() {
        super.init()
        self.name = "prop_desk_floor_plant"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let standHeight: Float = 0.10
        let stoolTop = ModelEntity(mesh: .generateCylinder(height: 0.015, radius: 0.075), materials: [mats.honeyOakWood])
        stoolTop.position = [0, standHeight, 0]
        addChild(stoolTop)
        
        for i in 0..<3 {
            let a = Float(i) * (Float.pi * 2.0 / 3.0)
            let leg = ModelEntity(mesh: .generateCylinder(height: standHeight, radius: 0.008), materials: [mats.honeyOakWood])
            leg.position = [cos(a) * 0.055, standHeight * 0.5, sin(a) * 0.055]
            addChild(leg)
        }
        
        let floorPot = ModelEntity(mesh: .generateCylinder(height: 0.10, radius: 0.065), materials: [mats.glazedWhiteCeramic])
        floorPot.position = [0, standHeight + 0.055, 0]
        addChild(floorPot)
        
        let leafyPlant = ModelEntity(mesh: .generateSphere(radius: 0.075), materials: [mats.foliageLight])
        leafyPlant.position = [0, standHeight + 0.12, 0]
        addChild(leafyPlant)
        
        let colShape = ShapeResource.generateBox(size: [0.24, 0.32, 0.24])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_desk_floor_plant",
            displayName: "Floor Plant",
            accessibilityLabel: "Potted leafy plant on wooden tripod stand",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY
        ))
    }
}

// MARK: - Books & Succulent on Wooden Steps (Movable)

@MainActor
final class StepBooksEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.38, 0.09, 0.22)
    
    required init() {
        super.init()
        self.name = "prop_step_books"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let stepBook1 = ModelEntity(mesh: .generateBox(size: [0.12, 0.018, 0.09], cornerRadius: 0.002), materials: [mats.terracottaClay])
        stepBook1.position = [0, 0.009, 0]
        addChild(stepBook1)
        
        let stepBook2 = ModelEntity(mesh: .generateBox(size: [0.11, 0.016, 0.085], cornerRadius: 0.002), materials: [mats.creamLinenFabric])
        stepBook2.position = [0, 0.026, 0]
        stepBook2.orientation = simd_quatf(angle: Float.pi * 0.06, axis: [0, 1, 0])
        addChild(stepBook2)
        
        let stepPot = ModelEntity(mesh: .generateCylinder(height: 0.035, radius: 0.022), materials: [mats.glazedWhiteCeramic])
        stepPot.position = [0, 0.052, 0]
        let stepFoliage = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [mats.foliageLight])
        stepFoliage.position = [0, 0.022, 0]
        stepPot.addChild(stepFoliage)
        addChild(stepPot)
        
        let colShape = ShapeResource.generateBox(size: [0.14, 0.12, 0.12])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_step_books",
            displayName: "Step Books",
            accessibilityLabel: "Stack of books and small succulent on the wooden step",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: 0.09
        ))
    }
}

// MARK: - Miniature Corner Floor Succulent (Movable)

@MainActor
final class StepSucculentEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.25, RoomArchitectureEntity.lowerFloorY + 0.022, 0.48)
    
    required init() {
        super.init()
        self.name = "prop_step_succulent"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let cornerPlant = ModelEntity(mesh: .generateBox(size: [0.045, 0.045, 0.045], cornerRadius: 0.004), materials: [mats.glazedWhiteCeramic])
        cornerPlant.position = [0, 0, 0]
        let cornerFoliage = ModelEntity(mesh: .generateSphere(radius: 0.022), materials: [mats.foliageDeep])
        cornerFoliage.position = [0, 0.028, 0]
        cornerPlant.addChild(cornerFoliage)
        addChild(cornerPlant)
        
        let colShape = ShapeResource.generateBox(size: [0.06, 0.08, 0.06])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_step_succulent",
            displayName: "Corner Succulent",
            accessibilityLabel: "Miniature ceramic pot succulent on floor corner",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.lowerFloorY
        ))
    }
}

// MARK: - Cascading Corner Ivy Vines (Immovable Decor)

@MainActor
final class TrailingIvyEntity: Entity {
    required init() {
        super.init()
        self.name = "trailing_ivy"
        buildIvy()
    }
    
    private func buildIvy() {
        let mats = RoomMaterials.shared
        let upperFloorY = RoomArchitectureEntity.upperFloorY
        
        // 1. Back-Left Corner Vines
        let vineRoot = Entity()
        vineRoot.position = [-1.12, upperFloorY + 1.48, -1.12]
        addChild(vineRoot)
        
        let vineOffsets: [(x: Float, z: Float, length: Float)] = [
            (0.00, 0.00, 0.68),
            (0.06, 0.03, 0.48),
            (-0.02, 0.07, 0.58),
            (0.12, 0.02, 0.38),
            (0.03, 0.12, 0.72)
        ]
        
        for v in vineOffsets {
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
        
        // 2. Front-Left Column Vines
        let frontVineRoot = Entity()
        frontVineRoot.position = [-1.15, upperFloorY + 1.42, 0.32]
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
    }
}

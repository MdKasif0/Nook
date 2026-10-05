import RealityKit
import AppKit

/// Builds the cozy daybed area hierarchy matching the reference image:
///
/// BedArea
/// ├── Bed (Honey oak frame and headboard - Immovable)
/// ├── Mattress (Cream mattress & duvet - Immovable)
/// ├── Sheets (Cream bedding sheets - Immovable)
/// ├── Pillows
/// │   ├── DaisyPillow (White petals, yellow center - Movable)
/// │   ├── SagePillow (Square sage accent pillow - Movable)
/// │   └── SleepingPillows (Layered head pillows - Movable)
/// ├── Blanket (Sage green throw blanket - Immovable)
/// └── BedDecor (Bedside nightstand & succulent - Movable)
@MainActor
final class BedAreaEntity: Entity {
    
    let bedFrame: BedEntity
    let mattress: MattressEntity
    let daisyPillow: DaisyPillowEntity
    let sagePillow: SagePillowEntity
    let sleepingPillows: SleepingPillowsEntity
    let blanket: BlanketEntity
    let bedDecor: BedDecorEntity
    
    required init() {
        self.bedFrame = BedEntity()
        self.mattress = MattressEntity()
        self.daisyPillow = DaisyPillowEntity()
        self.sagePillow = SagePillowEntity()
        self.sleepingPillows = SleepingPillowsEntity()
        self.blanket = BlanketEntity()
        self.bedDecor = BedDecorEntity()
        
        super.init()
        self.name = "bed_area"
        
        // Assemble hierarchy under BedArea
        addChild(bedFrame)
        addChild(mattress)
        addChild(daisyPillow)
        addChild(sagePillow)
        addChild(sleepingPillows)
        addChild(blanket)
        addChild(bedDecor)
    }
}

// MARK: - Bed Frame & Headboard (Immovable)

@MainActor
final class BedEntity: Entity {
    static let bedLength: Float = 1.25  // along X (from head to foot)
    static let bedWidth: Float = 0.82   // along Z
    static let frameHeight: Float = 0.28
    static let bedOrigin = SIMD3<Float>(0.48, RoomArchitectureEntity.upperFloorY, -0.78)
    
    required init() {
        super.init()
        self.name = "bed_frame"
        self.position = Self.bedOrigin
        
        let mats = RoomMaterials.shared
        
        // 1. Warm Wooden Bed Frame
        let frameMesh = MeshResource.generateBox(size: [Self.bedLength, Self.frameHeight, Self.bedWidth], cornerRadius: 0.015)
        let bedFrame = ModelEntity(mesh: frameMesh, materials: [mats.honeyOakWood])
        bedFrame.position = [0, Self.frameHeight * 0.5, 0]
        addChild(bedFrame)
        
        // 2. Headboard on the left end (against bookcase)
        let headboardHeight: Float = 0.45
        let headboardMesh = MeshResource.generateBox(size: [0.04, headboardHeight, Self.bedWidth], cornerRadius: 0.01)
        let headboard = ModelEntity(mesh: headboardMesh, materials: [mats.honeyOakWood])
        headboard.position = [-Self.bedLength * 0.5 + 0.02, Self.frameHeight + headboardHeight * 0.5 - 0.05, 0]
        addChild(headboard)
        
        // Immovable component
        self.components.set(InteractivePropComponent(
            propId: "prop_bed_furniture",
            displayName: "Daybed Frame",
            accessibilityLabel: "Honey oak daybed platform frame and headboard",
            category: .immovable,
            allowsDragging: false,
            allowsRotation: false,
            defaultPosition: Self.bedOrigin,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY
        ))
    }
}

// MARK: - Mattress & Duvet Base (Immovable)

@MainActor
final class MattressEntity: Entity {
    static let mattressOrigin = SIMD3<Float>(0.49, RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.06, -0.78)
    
    required init() {
        super.init()
        self.name = "bed_mattress"
        self.position = Self.mattressOrigin
        
        let mats = RoomMaterials.shared
        let mattressLength: Float = BedEntity.bedLength - 0.06
        let mattressWidth: Float = BedEntity.bedWidth - 0.06
        let mattressHeight: Float = 0.16
        let mattressMesh = MeshResource.generateBox(size: [mattressLength, mattressHeight, mattressWidth], cornerRadius: 0.025)
        let mattress = ModelEntity(mesh: mattressMesh, materials: [mats.creamLinenFabric])
        mattress.position = [0, 0, 0]
        addChild(mattress)
    }
}

// MARK: - Daisy Flower Pillow (Movable)

@MainActor
final class DaisyPillowEntity: Entity {
    static let defaultPos = SIMD3<Float>(0.235, RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16 + 0.08, -0.83)
    static let defaultRot = simd_quatf(angle: Float.pi * 0.38, axis: [1, 0, 0]) * simd_quatf(angle: Float.pi * 0.18, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_daisy_pillow"
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        let mats = RoomMaterials.shared
        
        // Center yellow button
        let center = ModelEntity(mesh: .generateCylinder(height: 0.035, radius: 0.045), materials: [mats.daisyYellow])
        addChild(center)
        
        // 8 White Petals
        let petalMesh = MeshResource.generateBox(size: [0.07, 0.025, 0.05], cornerRadius: 0.012)
        for i in 0..<8 {
            let angle = Float(i) * (Float.pi * 2.0 / 8.0)
            let petal = ModelEntity(mesh: petalMesh, materials: [mats.creamLinenFabric])
            let dist: Float = 0.065
            petal.position = [cos(angle) * dist, 0, sin(angle) * dist]
            petal.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
            addChild(petal)
        }
        
        let colShape = ShapeResource.generateBox(size: [0.22, 0.06, 0.22])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_daisy_pillow",
            displayName: "Daisy Pillow",
            accessibilityLabel: "White daisy flower cushion with yellow center",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            allowsScaling: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16
        ))
    }
}

// MARK: - Sage Square Accent Pillow (Movable)

@MainActor
final class SagePillowEntity: Entity {
    static let defaultPos = SIMD3<Float>(0.135, RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16 + 0.06, -0.64)
    static let defaultRot = simd_quatf(angle: Float.pi * 0.12, axis: [0, 0, 1]) * simd_quatf(angle: -Float.pi * 0.1, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_sage_pillow"
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        let mats = RoomMaterials.shared
        let sagePillowMesh = ProceduralMeshGenerator.generatePillowMesh(width: 0.22, height: 0.08, depth: 0.22)
        let sagePillow = ModelEntity(mesh: sagePillowMesh, materials: [mats.sageGreenFabric])
        sagePillow.position = [0, 0, 0]
        addChild(sagePillow)
        
        let colShape = ShapeResource.generateBox(size: [0.24, 0.10, 0.24])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_sage_pillow",
            displayName: "Sage Pillow",
            accessibilityLabel: "Square sage green linen accent pillow",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            allowsScaling: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16
        ))
    }
}

// MARK: - Sleeping Pillows (Movable)

@MainActor
final class SleepingPillowsEntity: Entity {
    static let defaultPos = SIMD3<Float>(0.035, RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16 + 0.04, -0.78)
    
    required init() {
        super.init()
        self.name = "prop_sleeping_pillows"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let pillowMesh = ProceduralMeshGenerator.generatePillowMesh(width: 0.22, height: 0.10, depth: 0.32)
        
        let backPillow1 = ModelEntity(mesh: pillowMesh, materials: [mats.creamLinenFabric])
        backPillow1.position = [0, 0, -0.16]
        backPillow1.orientation = simd_quatf(angle: Float.pi * 0.08, axis: [0, 0, 1])
        addChild(backPillow1)
        
        let backPillow2 = ModelEntity(mesh: pillowMesh, materials: [mats.creamLinenFabric])
        backPillow2.position = [0, 0, 0.16]
        backPillow2.orientation = simd_quatf(angle: Float.pi * 0.08, axis: [0, 0, 1])
        addChild(backPillow2)
        
        let colShape = ShapeResource.generateBox(size: [0.24, 0.14, 0.66])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_sleeping_pillows",
            displayName: "Sleeping Pillows",
            accessibilityLabel: "Set of plush cream sleeping pillows",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16
        ))
    }
}

// MARK: - Throw Blanket (Immovable)

@MainActor
final class BlanketEntity: Entity {
    static let defaultPos = SIMD3<Float>(0.805, RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16 + 0.005, -0.78)
    
    required init() {
        super.init()
        self.name = "bed_blanket"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let mattressWidth: Float = BedEntity.bedWidth - 0.06
        let blanketMesh = ProceduralMeshGenerator.generateBlanketMesh(width: 0.60, depth: mattressWidth + 0.04, drapeY: 0.14)
        let blanket = ModelEntity(mesh: blanketMesh, materials: [mats.sageGreenFabric])
        blanket.position = [0, 0, 0]
        addChild(blanket)
    }
}

// MARK: - Bedside Nightstand & Succulent Decor (Movable)

@MainActor
final class BedDecorEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.265, RoomArchitectureEntity.upperFloorY, -1.03)
    
    required init() {
        super.init()
        self.name = "prop_bedside_decor"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let nightstandMesh = MeshResource.generateBox(size: [0.22, 0.26, 0.24], cornerRadius: 0.01)
        let nightstand = ModelEntity(mesh: nightstandMesh, materials: [mats.honeyOakWood])
        nightstand.position = [0, 0.13, 0]
        addChild(nightstand)
        
        let pot = ModelEntity(mesh: .generateCylinder(height: 0.04, radius: 0.024), materials: [mats.glazedWhiteCeramic])
        pot.position = [0, 0.26 + 0.02, 0]
        let plant = ModelEntity(mesh: .generateSphere(radius: 0.022), materials: [mats.foliageLight])
        plant.position = [0, 0.025, 0]
        pot.addChild(plant)
        addChild(pot)
        
        let colShape = ShapeResource.generateBox(size: [0.24, 0.35, 0.26])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_bedside_decor",
            displayName: "Bedside Table & Succulent",
            accessibilityLabel: "Honey oak bedside nightstand with small potted succulent",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY
        ))
    }
}

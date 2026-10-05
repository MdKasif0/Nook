import RealityKit
import AppKit

/// Builds the vinyl listening setup hierarchy matching the reference image:
///
/// RecordArea
/// ├── Ottoman (Sage green upholstered bench - Immovable)
/// ├── RecordPlayer (Vintage suitcase turntable - Movable, Interactive)
/// ├── Vinyl (Spinning vinyl record inside player)
/// └── Records (Stack of vinyl album sleeves - Movable)
@MainActor
final class RecordAreaEntity: Entity {
    
    let bench: RecordBenchEntity
    let recordPlayer: RecordPlayerEntity
    let albumStack: RecordAlbumsEntity
    
    required init() {
        self.bench = RecordBenchEntity()
        self.recordPlayer = RecordPlayerEntity()
        self.albumStack = RecordAlbumsEntity()
        
        super.init()
        self.name = "record_area"
        
        // Assemble hierarchy under RecordArea
        addChild(bench)
        addChild(recordPlayer)
        addChild(albumStack)
    }
}

// MARK: - Muted Sage Green Bench / Ottoman (Immovable)

@MainActor
final class RecordBenchEntity: Entity {
    static let benchOrigin = SIMD3<Float>(0.78, RoomArchitectureEntity.upperFloorY, -0.18)
    static let benchWidth: Float = 0.38
    static let benchLength: Float = 0.52
    static let benchHeight: Float = 0.22
    static let legHeight: Float = 0.10
    
    required init() {
        super.init()
        self.name = "record_bench"
        self.position = Self.benchOrigin
        
        let mats = RoomMaterials.shared
        
        // 4 Honey Oak Wooden Legs
        let legRadius: Float = 0.016
        let legMesh = MeshResource.generateCylinder(height: Self.legHeight, radius: legRadius)
        let legPositions: [SIMD3<Float>] = [
            [-Self.benchWidth * 0.5 + 0.04, Self.legHeight * 0.5, -Self.benchLength * 0.5 + 0.04],
            [Self.benchWidth * 0.5 - 0.04, Self.legHeight * 0.5, -Self.benchLength * 0.5 + 0.04],
            [-Self.benchWidth * 0.5 + 0.04, Self.legHeight * 0.5, Self.benchLength * 0.5 - 0.04],
            [Self.benchWidth * 0.5 - 0.04, Self.legHeight * 0.5, Self.benchLength * 0.5 - 0.04]
        ]
        for pos in legPositions {
            let leg = ModelEntity(mesh: legMesh, materials: [mats.honeyOakWood])
            leg.position = pos
            addChild(leg)
        }
        
        // Wooden frame base
        let frameMesh = MeshResource.generateBox(size: [Self.benchWidth, 0.025, Self.benchLength], cornerRadius: 0.005)
        let benchFrame = ModelEntity(mesh: frameMesh, materials: [mats.honeyOakWood])
        benchFrame.position = [0, Self.legHeight + 0.012, 0]
        addChild(benchFrame)
        
        // Thick Sage Green Upholstered Cushion
        let cushionHeight: Float = Self.benchHeight - Self.legHeight - 0.025
        let cushionMesh = MeshResource.generateBox(size: [Self.benchWidth - 0.02, cushionHeight, Self.benchLength - 0.02], cornerRadius: 0.02)
        let cushion = ModelEntity(mesh: cushionMesh, materials: [mats.sageGreenFabric])
        cushion.position = [0, Self.legHeight + 0.025 + cushionHeight * 0.5, 0]
        addChild(cushion)
        
        self.components.set(InteractivePropComponent(
            propId: "prop_record_bench",
            displayName: "Upholstered Bench",
            accessibilityLabel: "Sage green upholstered wooden bench",
            category: .immovable,
            allowsDragging: false,
            allowsRotation: false,
            defaultPosition: Self.benchOrigin,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY
        ))
    }
}

// MARK: - Vintage Suitcase Record Player (Movable, Interactive)

@MainActor
final class RecordPlayerEntity: Entity {
    static let defaultPos = SIMD3<Float>(0.78, RoomArchitectureEntity.upperFloorY + RecordBenchEntity.benchHeight, -0.24)
    
    private(set) var vinylRecord: ModelEntity?
    private(set) var isSpinning: Bool = true
    
    required init() {
        super.init()
        self.name = "prop_record_player"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let playerWidth: Float = 0.26
        let playerLength: Float = 0.28
        let playerHeight: Float = 0.07
        
        // Chassis (cream linen/pastel)
        let caseMesh = MeshResource.generateBox(size: [playerWidth, playerHeight, playerLength], cornerRadius: 0.012)
        let playerCase = ModelEntity(mesh: caseMesh, materials: [mats.creamLinenFabric])
        playerCase.position = [0, playerHeight * 0.5, 0]
        addChild(playerCase)
        
        // Open lid propped up at 80 degrees
        let lidMesh = MeshResource.generateBox(size: [playerWidth, 0.012, playerLength], cornerRadius: 0.008)
        let lid = ModelEntity(mesh: lidMesh, materials: [mats.creamLinenFabric])
        lid.position = [0, playerHeight + 0.10, -playerLength * 0.5 + 0.01]
        lid.orientation = simd_quatf(angle: -Float.pi * 0.42, axis: [1, 0, 0])
        addChild(lid)
        
        // Turntable Platter
        let platterMesh = MeshResource.generateCylinder(height: 0.006, radius: 0.09)
        let platter = ModelEntity(mesh: platterMesh, materials: [mats.brushedAluminum])
        platter.position = [-0.02, playerHeight + 0.004, 0]
        addChild(platter)
        
        // Black Vinyl Record
        let vinylMesh = MeshResource.generateCylinder(height: 0.003, radius: 0.085)
        let vinyl = ModelEntity(mesh: vinylMesh, materials: [mats.vinylRecord])
        vinyl.position = [0, 0.004, 0]
        vinyl.name = "spinning_vinyl"
        platter.addChild(vinyl)
        self.vinylRecord = vinyl
        
        // Red Center Record Label
        let labelMesh = MeshResource.generateCylinder(height: 0.002, radius: 0.028)
        let label = ModelEntity(mesh: labelMesh, materials: [mats.vinylLabelMaterial])
        label.position = [0, 0.002, 0]
        vinyl.addChild(label)
        
        let spindle = ModelEntity(mesh: .generateCylinder(height: 0.012, radius: 0.004), materials: [mats.warmBrass])
        spindle.position = [0, 0.006, 0]
        vinyl.addChild(spindle)
        
        // Brass Tonearm
        let armBase = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: 0.008), materials: [mats.warmBrass])
        armBase.position = [0.08, playerHeight + 0.01, -0.06]
        addChild(armBase)
        
        let armTube = ModelEntity(mesh: .generateCylinder(height: 0.11, radius: 0.003), materials: [mats.warmBrass])
        armTube.position = [-0.035, 0.018, 0.035]
        armTube.orientation = simd_quatf(angle: Float.pi * 0.38, axis: [0, 1, 0]) * simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        armBase.addChild(armTube)
        
        // Miniature Control Dials
        let dialMesh = MeshResource.generateCylinder(height: 0.008, radius: 0.007)
        let dial1 = ModelEntity(mesh: dialMesh, materials: [mats.warmBrass])
        dial1.position = [0.08, playerHeight + 0.005, 0.06]
        addChild(dial1)
        
        let dial2 = ModelEntity(mesh: dialMesh, materials: [mats.warmBrass])
        dial2.position = [0.08, playerHeight + 0.005, 0.09]
        addChild(dial2)
        
        let colShape = ShapeResource.generateBox(size: [0.30, 0.22, 0.30])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_record_player",
            displayName: "Record Player",
            accessibilityLabel: "Vintage turntable playing vinyl record",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + RecordBenchEntity.benchHeight
        ))
    }
    
    func togglePlayback() {
        isSpinning.toggle()
    }
}

// MARK: - Stack of Vinyl Record Albums (Movable)

@MainActor
final class RecordAlbumsEntity: Entity {
    static let defaultPos = SIMD3<Float>(0.78, RoomArchitectureEntity.upperFloorY + RecordBenchEntity.benchHeight, -0.02)
    
    required init() {
        super.init()
        self.name = "prop_record_albums"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        for i in 0..<3 {
            let albumMesh = MeshResource.generateBox(size: [0.16, 0.012, 0.16], cornerRadius: 0.003)
            let albumMat = (i == 0) ? mats.terracottaClay : ((i == 1) ? mats.creamLinenFabric : mats.sageGreenFabric)
            let album = ModelEntity(mesh: albumMesh, materials: [albumMat])
            album.position = [0, Float(i) * 0.014, 0]
            album.orientation = simd_quatf(angle: Float(i) * 0.06, axis: [0, 1, 0])
            addChild(album)
        }
        
        let colShape = ShapeResource.generateBox(size: [0.18, 0.06, 0.18])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_record_albums",
            displayName: "Vinyl Records",
            accessibilityLabel: "Stack of collectible vinyl album sleeves",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + RecordBenchEntity.benchHeight
        ))
    }
}

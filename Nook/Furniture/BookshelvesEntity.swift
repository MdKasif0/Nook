import RealityKit
import AppKit

/// Builds the built-in shelving, pegboard, and decor hierarchy matching the reference image:
///
/// ShelfArea
/// ├── Shelf (Honey-oak shelves & pegboard - Immovable)
/// ├── Books (Hardcover book rows - Movable)
/// ├── Plants (Potted shelf plant - Movable)
/// ├── Clock (Vintage brass alarm clock - Movable)
/// └── Decorations (Storage box, cat figurine - Movable)
@MainActor
final class ShelfAreaEntity: Entity {
    
    let shelves: BookshelvesEntity
    let clock: ShelfAlarmClockEntity
    let catFigurine: ShelfCatFigurineEntity
    let storageBox: ShelfStorageBoxEntity
    let books: ShelfBooksEntity
    let shelfPlant: ShelfPlantEntity
    
    required init() {
        self.shelves = BookshelvesEntity()
        self.clock = ShelfAlarmClockEntity()
        self.catFigurine = ShelfCatFigurineEntity()
        self.storageBox = ShelfStorageBoxEntity()
        self.books = ShelfBooksEntity()
        self.shelfPlant = ShelfPlantEntity()
        
        super.init()
        self.name = "shelf_area"
        
        // Assemble hierarchy under ShelfArea
        addChild(shelves)
        addChild(clock)
        addChild(catFigurine)
        addChild(storageBox)
        addChild(books)
        addChild(shelfPlant)
    }
}

// MARK: - Built-in Shelves & Pegboard Structure (Immovable)

@MainActor
final class BookshelvesEntity: Entity {
    
    private(set) var shelfLight: PointLight?
    
    required init() {
        super.init()
        self.name = "built_in_shelving_structure"
        buildShelving()
    }
    
    private func buildShelving() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        
        let leftWallX: Float = -1.16
        let backWallZ: Float = -1.16
        let shelfThickness: Float = 0.028
        let shelfDepth: Float = 0.20
        
        // 1. Pegboard Mounted on Left Wall Above Desk
        let pegboardWidth: Float = 0.58  // along Z
        let pegboardHeight: Float = 0.44
        let pegboardMesh = MeshResource.generateBox(size: [0.015, pegboardHeight, pegboardWidth], cornerRadius: 0.005)
        let pegboard = ModelEntity(mesh: pegboardMesh, materials: [mats.pegboardPatternMaterial])
        pegboard.position = [leftWallX + 0.01, floorY + DeskEntity.deskHeight + 0.32, -0.32]
        pegboard.name = "desk_pegboard"
        addChild(pegboard)
        
        // Pinned Polaroid Photo Prints on Pegboard
        let photo1 = ModelEntity(mesh: .generateBox(size: [0.003, 0.07, 0.06], cornerRadius: 0.002), materials: [mats.creamLinenFabric])
        photo1.position = [0.01, 0.08, -0.15]
        photo1.orientation = simd_quatf(angle: Float.pi * 0.06, axis: [1, 0, 0])
        pegboard.addChild(photo1)
        
        let photo2 = ModelEntity(mesh: .generateBox(size: [0.003, 0.07, 0.06], cornerRadius: 0.002), materials: [mats.botanicalArt1Material])
        photo2.position = [0.01, -0.05, -0.16]
        pegboard.addChild(photo2)
        
        // Small Yellow Sticky Note
        let sticky = ModelEntity(mesh: .generateBox(size: [0.002, 0.045, 0.045], cornerRadius: 0.002), materials: [mats.daisyYellow])
        sticky.position = [0.01, 0.02, -0.04]
        pegboard.addChild(sticky)
        
        // 2. Upper Shelf Above Desk along Left Wall
        let deskShelfLength: Float = 0.95
        let upperDeskShelf = ModelEntity(
            mesh: .generateBox(size: [shelfDepth, shelfThickness, deskShelfLength], cornerRadius: 0.006),
            materials: [mats.honeyOakWood]
        )
        upperDeskShelf.position = [leftWallX + shelfDepth * 0.5, floorY + DeskEntity.deskHeight + 0.60, -0.32]
        upperDeskShelf.name = "shelf_desk_upper"
        addChild(upperDeskShelf)
        
        // 3. Tall Built-in Bookcase on Back Wall (between desk corner and bed)
        let bookcaseWidth: Float = 0.55  // along X
        let bookcaseCenterX: Float = -0.35
        let bookcaseShelfY: [Float] = [
            floorY + DeskEntity.deskHeight + 0.35,
            floorY + DeskEntity.deskHeight + 0.60,
            floorY + DeskEntity.deskHeight + 0.88
        ]
        
        for (i, y) in bookcaseShelfY.enumerated() {
            let shelf = ModelEntity(
                mesh: .generateBox(size: [bookcaseWidth, shelfThickness, shelfDepth], cornerRadius: 0.006),
                materials: [mats.honeyOakWood]
            )
            shelf.position = [bookcaseCenterX, y, backWallZ + shelfDepth * 0.5]
            shelf.name = "bookcase_shelf_\(i + 1)"
            addChild(shelf)
        }
        
        // 4. Built-in Under-Shelf Warm LED Light Strip
        let light = PointLight()
        light.light.color = .init(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0)
        light.light.intensity = 1400
        light.light.attenuationRadius = 1.6
        light.position = [bookcaseCenterX, bookcaseShelfY[1] - 0.03, backWallZ + shelfDepth * 0.5]
        light.name = "under_shelf_light"
        addChild(light)
        self.shelfLight = light
        
        // Immovable component
        self.components.set(InteractivePropComponent(
            propId: "prop_shelving_structure",
            displayName: "Built-in Bookcase",
            accessibilityLabel: "Honey oak wall bookcase and pegboard",
            category: .immovable,
            allowsDragging: false,
            allowsRotation: false,
            defaultPosition: [0, 0, 0],
            restingSurfaceY: floorY
        ))
    }
}

// MARK: - Vintage Brass Alarm Clock (Movable)

@MainActor
final class ShelfAlarmClockEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.20, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.35 + 0.05, -1.06)
    
    required init() {
        super.init()
        self.name = "prop_alarm_clock"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let body = ModelEntity(mesh: .generateCylinder(height: 0.035, radius: 0.04), materials: [mats.warmBrass])
        body.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        addChild(body)
        
        let face = ModelEntity(mesh: .generatePlane(width: 0.07, depth: 0.07, cornerRadius: 0.035), materials: [mats.creamLinenFabric])
        face.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        face.position = [0, 0, 0.018]
        addChild(face)
        
        let leftBell = ModelEntity(mesh: .generateSphere(radius: 0.014), materials: [mats.warmBrass])
        leftBell.position = [-0.025, 0.045, 0]
        addChild(leftBell)
        
        let rightBell = ModelEntity(mesh: .generateSphere(radius: 0.014), materials: [mats.warmBrass])
        rightBell.position = [0.025, 0.045, 0]
        addChild(rightBell)
        
        let colShape = ShapeResource.generateBox(size: [0.10, 0.12, 0.08])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_alarm_clock",
            displayName: "Alarm Clock",
            accessibilityLabel: "Vintage brass twin-bell alarm clock",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.35
        ))
    }
}

// MARK: - Ceramic Cat Figurine (Movable)

@MainActor
final class ShelfCatFigurineEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.49, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.88 + 0.045, -1.06)
    
    required init() {
        super.init()
        self.name = "prop_cat_figurine"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let head = ModelEntity(mesh: .generateSphere(radius: 0.042), materials: [mats.glazedWhiteCeramic])
        addChild(head)
        
        let leftEar = ModelEntity(mesh: .generateBox(size: [0.022, 0.028, 0.018], cornerRadius: 0.004), materials: [mats.glazedWhiteCeramic])
        leftEar.position = [-0.025, 0.038, 0]
        leftEar.orientation = simd_quatf(angle: Float.pi * 0.2, axis: [0, 0, 1])
        addChild(leftEar)
        
        let rightEar = ModelEntity(mesh: .generateBox(size: [0.022, 0.028, 0.018], cornerRadius: 0.004), materials: [mats.glazedWhiteCeramic])
        rightEar.position = [0.025, 0.038, 0]
        rightEar.orientation = simd_quatf(angle: -Float.pi * 0.2, axis: [0, 0, 1])
        addChild(rightEar)
        
        let colShape = ShapeResource.generateSphere(radius: 0.06)
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_cat_figurine",
            displayName: "Cat Figurine",
            accessibilityLabel: "White glazed ceramic cat figurine",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.88
        ))
    }
}

// MARK: - Honey Oak Storage Box (Movable)

@MainActor
final class ShelfStorageBoxEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.25, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.88 + 0.07, -1.06)
    
    required init() {
        super.init()
        self.name = "prop_storage_box"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let boxMesh = MeshResource.generateBox(size: [0.22, 0.14, 0.16], cornerRadius: 0.008)
        let storageBox = ModelEntity(mesh: boxMesh, materials: [mats.honeyOakWood])
        addChild(storageBox)
        
        let colShape = ShapeResource.generateBox(size: [0.24, 0.16, 0.18])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_storage_box",
            displayName: "Storage Box",
            accessibilityLabel: "Honey oak lidded storage box",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.88
        ))
    }
}

// MARK: - Stack of Shelf Books (Movable)

@MainActor
final class ShelfBooksEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.35, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.60 + 0.05, -1.06)
    
    required init() {
        super.init()
        self.name = "prop_shelf_books"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        for b in 0..<3 {
            let book = ModelEntity(
                mesh: .generateBox(size: [0.14, 0.022, 0.11], cornerRadius: 0.003),
                materials: [b % 2 == 0 ? mats.terracottaClay : mats.sageGreenFabric]
            )
            book.position = [0, Float(b) * 0.025, 0]
            addChild(book)
        }
        
        let colShape = ShapeResource.generateBox(size: [0.16, 0.10, 0.14])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_shelf_books",
            displayName: "Shelf Books",
            accessibilityLabel: "Stack of colorful hardcover books",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.60
        ))
    }
}

// MARK: - Shelf Potted Plant (Movable)

@MainActor
final class ShelfPlantEntity: Entity {
    static let defaultPos = SIMD3<Float>(-1.06, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.60 + 0.05, -0.07)
    
    required init() {
        super.init()
        self.name = "prop_shelf_plant"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let pot = ModelEntity(mesh: .generateCylinder(height: 0.06, radius: 0.038), materials: [mats.glazedWhiteCeramic])
        pot.position = [0, 0.03, 0]
        addChild(pot)
        
        let foliage = ModelEntity(mesh: .generateSphere(radius: 0.042), materials: [mats.foliageLight])
        foliage.position = [0, 0.065, 0]
        addChild(foliage)
        
        let colShape = ShapeResource.generateBox(size: [0.10, 0.12, 0.10])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_shelf_plant",
            displayName: "Shelf Plant",
            accessibilityLabel: "Small white ceramic potted plant on wall shelf",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            allowsScaling: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.60
        ))
    }
}

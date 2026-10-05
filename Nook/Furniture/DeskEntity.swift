import RealityKit
import AppKit

/// Builds the comprehensive DeskArea hierarchy matching the reference image:
///
/// DeskArea
/// ├── Desk (Tabletop, Drawers, Desk Mat - Immovable)
/// ├── Monitor (Stand, Casing, "hello ♡" display - Movable)
/// ├── Laptop (Open base & screen with nature display - Movable)
/// ├── Keyboard (White chiclet keyboard - Movable)
/// ├── Mouse (Ceramic white mouse - Movable)
/// ├── Phone (Smartphone on wooden stand - Movable)
/// ├── Notebook (Open notebook with pen - Movable)
/// ├── Lamp (Warm brass toggleable desk lamp - Movable, Clickable)
/// ├── Mug (Smiley ceramic mug - Movable)
/// ├── Plant (Small desk succulent pot - Movable)
/// └── Headphones (White over-ear headphones - Movable)
@MainActor
final class DeskAreaEntity: Entity {
    
    let deskEntity: DeskEntity
    let monitorEntity: DeskMonitorEntity
    let laptopEntity: DeskLaptopEntity
    let keyboardEntity: DeskKeyboardEntity
    let mouseEntity: DeskMouseEntity
    let phoneEntity: DeskPhoneEntity
    let notebookEntity: DeskNotebookEntity
    let lampEntity: DeskLampEntity
    let mugEntity: DeskMugEntity
    let plantEntity: DeskPlantEntity
    let headphonesEntity: DeskHeadphonesEntity
    let pencilCupEntity: DeskPencilCupEntity
    
    required init() {
        self.deskEntity = DeskEntity()
        self.monitorEntity = DeskMonitorEntity()
        self.laptopEntity = DeskLaptopEntity()
        self.keyboardEntity = DeskKeyboardEntity()
        self.mouseEntity = DeskMouseEntity()
        self.phoneEntity = DeskPhoneEntity()
        self.notebookEntity = DeskNotebookEntity()
        self.lampEntity = DeskLampEntity()
        self.mugEntity = DeskMugEntity()
        self.plantEntity = DeskPlantEntity()
        self.headphonesEntity = DeskHeadphonesEntity()
        self.pencilCupEntity = DeskPencilCupEntity()
        
        super.init()
        self.name = "desk_area"
        
        // Assemble hierarchy under DeskArea
        addChild(deskEntity)
        addChild(monitorEntity)
        addChild(laptopEntity)
        addChild(keyboardEntity)
        addChild(mouseEntity)
        addChild(phoneEntity)
        addChild(notebookEntity)
        addChild(lampEntity)
        addChild(mugEntity)
        addChild(plantEntity)
        addChild(headphonesEntity)
        addChild(pencilCupEntity)
    }
}

// MARK: - Desk Structure (Immovable)

@MainActor
final class DeskEntity: Entity {
    static let deskWidth: Float = 0.58   // along X
    static let deskLength: Float = 1.25  // along Z
    static let deskThickness: Float = 0.04
    static let deskHeight: Float = 0.72
    static let deskOrigin = SIMD3<Float>(-0.88, RoomArchitectureEntity.upperFloorY, -0.32)
    
    required init() {
        super.init()
        self.name = "desk_structure"
        self.position = Self.deskOrigin
        
        let mats = RoomMaterials.shared
        
        // 1. Desk Surface Tabletop (Honey Oak with soft rounded corners)
        let topMesh = MeshResource.generateBox(size: [Self.deskWidth, Self.deskThickness, Self.deskLength], cornerRadius: 0.012)
        let topEntity = ModelEntity(mesh: topMesh, materials: [mats.honeyOakWood])
        topEntity.position = [0, Self.deskHeight - Self.deskThickness * 0.5, 0]
        topEntity.name = "desk_surface"
        addChild(topEntity)
        
        // 2. Front 2-Drawer Pedestal Cabinet
        let drawerWidth: Float = Self.deskWidth - 0.06
        let drawerLength: Float = 0.34
        let drawerHeight: Float = Self.deskHeight - Self.deskThickness
        let drawerMesh = MeshResource.generateBox(size: [drawerWidth, drawerHeight, drawerLength], cornerRadius: 0.01)
        let drawerCabinet = ModelEntity(mesh: drawerMesh, materials: [mats.honeyOakWood])
        drawerCabinet.position = [0, drawerHeight * 0.5, Self.deskLength * 0.5 - drawerLength * 0.5 - 0.02]
        drawerCabinet.name = "desk_drawers"
        addChild(drawerCabinet)
        
        // Drawer horizontal pulls
        for i in 0..<2 {
            let pullY = drawerHeight * 0.30 + Float(i) * (drawerHeight * 0.40)
            let pullMesh = MeshResource.generateBox(size: [0.018, 0.012, 0.08], cornerRadius: 0.003)
            let pull = ModelEntity(mesh: pullMesh, materials: [mats.warmBrass])
            pull.position = [drawerWidth * 0.5 + 0.01, pullY, Self.deskLength * 0.5 - drawerLength * 0.5 - 0.02]
            addChild(pull)
        }
        
        // Back Leg Support Frame
        let legMesh = MeshResource.generateBox(size: [drawerWidth, drawerHeight, 0.04], cornerRadius: 0.008)
        let backLeg = ModelEntity(mesh: legMesh, materials: [mats.honeyOakWood])
        backLeg.position = [0, drawerHeight * 0.5, -Self.deskLength * 0.5 + 0.04]
        addChild(backLeg)
        
        // 3. Cream Desk Mat / Blotter
        let matMesh = MeshResource.generateBox(size: [0.38, 0.003, 0.68], cornerRadius: 0.008)
        let deskMat = ModelEntity(mesh: matMesh, materials: [mats.creamLinenFabric])
        deskMat.position = [0.06, Self.deskHeight + 0.0015, -0.06]
        addChild(deskMat)
        
        // Immovable interaction component
        self.components.set(InteractivePropComponent(
            propId: "prop_desk_furniture",
            displayName: "Honey Oak Desk",
            accessibilityLabel: "Honey oak wooden workstation desk",
            category: .immovable,
            allowsDragging: false,
            allowsRotation: false,
            defaultPosition: Self.deskOrigin,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY
        ))
    }
}

// MARK: - Desktop Monitor (Movable)

@MainActor
final class DeskMonitorEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.96, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.64)
    static let defaultRot = simd_quatf(angle: -Float.pi * 0.28, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_monitor"
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        let mats = RoomMaterials.shared
        let monitorWidth: Float = 0.48
        let monitorHeight: Float = 0.30
        let monitorDepth: Float = 0.02
        
        // Stand base
        let standBase = ModelEntity(mesh: .generateBox(size: [0.14, 0.008, 0.16], cornerRadius: 0.005), materials: [mats.brushedAluminum])
        standBase.position = [0, 0.004, 0]
        addChild(standBase)
        
        // Stand upright post
        let standPost = ModelEntity(mesh: .generateBox(size: [0.015, 0.18, 0.035], cornerRadius: 0.004), materials: [mats.brushedAluminum])
        standPost.position = [-0.02, 0.09, -0.01]
        addChild(standPost)
        
        // Monitor casing
        let casingMesh = MeshResource.generateBox(size: [monitorDepth, monitorHeight, monitorWidth], cornerRadius: 0.008)
        let monitorCasing = ModelEntity(mesh: casingMesh, materials: [mats.brushedAluminum])
        monitorCasing.position = [0, 0.24, 0]
        addChild(monitorCasing)
        
        // Screen with "hello ♡" display
        let screenMesh = MeshResource.generatePlane(width: monitorWidth - 0.02, depth: monitorHeight - 0.02, cornerRadius: 0.004)
        let screenEntity = ModelEntity(mesh: screenMesh, materials: [mats.monitorScreenMaterial])
        screenEntity.orientation = simd_quatf(angle: -Float.pi * 0.5, axis: [0, 1, 0]) * simd_quatf(angle: -Float.pi * 0.5, axis: [1, 0, 0])
        screenEntity.position = [monitorDepth * 0.5 + 0.002, 0, 0]
        monitorCasing.addChild(screenEntity)
        
        // Collision & Interaction
        let colShape = ShapeResource.generateBox(size: [0.20, 0.38, 0.48])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_monitor",
            displayName: "Desktop Monitor",
            accessibilityLabel: "Desktop monitor displaying hello",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Open Laptop (Movable)

@MainActor
final class DeskLaptopEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.86, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.26)
    static let defaultRot = simd_quatf(angle: -Float.pi * 0.22, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_laptop"
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        let mats = RoomMaterials.shared
        
        let laptopBase = ModelEntity(
            mesh: .generateBox(size: [0.17, 0.010, 0.24], cornerRadius: 0.005),
            materials: [mats.brushedAluminum]
        )
        laptopBase.position = [0, 0.005, 0]
        addChild(laptopBase)
        
        let laptopScreen = ModelEntity(
            mesh: .generateBox(size: [0.006, 0.16, 0.24], cornerRadius: 0.004),
            materials: [mats.brushedAluminum]
        )
        laptopScreen.position = [-0.08, 0.08, 0]
        laptopScreen.orientation = simd_quatf(angle: -Float.pi * 0.12, axis: [0, 0, 1])
        laptopBase.addChild(laptopScreen)
        
        let laptopDisplay = ModelEntity(
            mesh: .generatePlane(width: 0.22, depth: 0.14, cornerRadius: 0.003),
            materials: [mats.laptopScreenMaterial]
        )
        laptopDisplay.orientation = simd_quatf(angle: -Float.pi * 0.5, axis: [0, 1, 0]) * simd_quatf(angle: -Float.pi * 0.5, axis: [1, 0, 0])
        laptopDisplay.position = [0.005, 0, 0]
        laptopScreen.addChild(laptopDisplay)
        
        let colShape = ShapeResource.generateBox(size: [0.22, 0.18, 0.26])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_laptop",
            displayName: "Laptop",
            accessibilityLabel: "Open silver laptop displaying nature landscape",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Keyboard (Movable)

@MainActor
final class DeskKeyboardEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.80, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.54)
    static let defaultRot = simd_quatf(angle: Float.pi * 0.06, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_keyboard"
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        let mats = RoomMaterials.shared
        let keyboard = ModelEntity(
            mesh: .generateBox(size: [0.12, 0.008, 0.32], cornerRadius: 0.004),
            materials: [mats.creamLinenFabric]
        )
        keyboard.position = [0, 0.004, 0]
        addChild(keyboard)
        
        let colShape = ShapeResource.generateBox(size: [0.14, 0.03, 0.34])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_keyboard",
            displayName: "Keyboard",
            accessibilityLabel: "White chiclet wireless keyboard",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Mouse (Movable)

@MainActor
final class DeskMouseEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.80, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.24)
    
    required init() {
        super.init()
        self.name = "prop_mouse"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let mouse = ModelEntity(
            mesh: .generateBox(size: [0.08, 0.015, 0.05], cornerRadius: 0.015),
            materials: [mats.glazedWhiteCeramic]
        )
        mouse.position = [0, 0.008, 0]
        addChild(mouse)
        
        let colShape = ShapeResource.generateBox(size: [0.10, 0.04, 0.08])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_mouse",
            displayName: "Mouse",
            accessibilityLabel: "Minimalist ceramic white wireless mouse",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Phone on Wooden Stand (Movable)

@MainActor
final class DeskPhoneEntity: Entity {
    static let defaultPos = SIMD3<Float>(-1.06, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.84)
    
    required init() {
        super.init()
        self.name = "prop_phone"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let phoneStand = ModelEntity(mesh: .generateBox(size: [0.06, 0.05, 0.06], cornerRadius: 0.004), materials: [mats.honeyOakWood])
        phoneStand.position = [0, 0.025, 0]
        addChild(phoneStand)
        
        let phone = ModelEntity(mesh: .generateBox(size: [0.008, 0.12, 0.06], cornerRadius: 0.005), materials: [mats.vinylRecord])
        phone.orientation = simd_quatf(angle: Float.pi * 0.15, axis: [0, 0, 1])
        phone.position = [0.01, 0.04, 0]
        phoneStand.addChild(phone)
        
        let colShape = ShapeResource.generateBox(size: [0.08, 0.14, 0.08])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_phone",
            displayName: "Smartphone",
            accessibilityLabel: "Smartphone resting on wooden stand",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Open Notebook with Pen (Movable)

@MainActor
final class DeskNotebookEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.74, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.74)
    static let defaultRot = simd_quatf(angle: Float.pi * 0.08, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_notebook"
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        let mats = RoomMaterials.shared
        let notebook = ModelEntity(
            mesh: .generateBox(size: [0.13, 0.008, 0.18], cornerRadius: 0.003),
            materials: [mats.openNotebookMaterial]
        )
        notebook.position = [0, 0.004, 0]
        addChild(notebook)
        
        let pen = ModelEntity(
            mesh: .generateCylinder(height: 0.11, radius: 0.003),
            materials: [mats.brushedAluminum]
        )
        pen.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        pen.position = [0, 0.012, 0]
        addChild(pen)
        
        let colShape = ShapeResource.generateBox(size: [0.16, 0.03, 0.20])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_notebook",
            displayName: "Open Notebook",
            accessibilityLabel: "Open lined notebook with silver pen",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Desk Lamp with Warm Spotlight (Movable, Toggleable Light)

@MainActor
final class DeskLampEntity: Entity {
    static let defaultPos = SIMD3<Float>(-1.02, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.14)
    private(set) var lampLight: PointLight?
    
    required init() {
        super.init()
        self.name = "prop_desk_lamp"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let lampBase = ModelEntity(mesh: .generateCylinder(height: 0.015, radius: 0.045), materials: [mats.glazedWhiteCeramic])
        lampBase.position = [0, 0.008, 0]
        addChild(lampBase)
        
        let lampStem = ModelEntity(mesh: .generateCylinder(height: 0.22, radius: 0.006), materials: [mats.brushedAluminum])
        lampStem.position = [0, 0.11, 0]
        lampBase.addChild(lampStem)
        
        let lampShade = ModelEntity(mesh: .generateSphere(radius: 0.042), materials: [mats.glazedWhiteCeramic])
        lampShade.position = [0.06, 0.21, -0.04]
        lampBase.addChild(lampShade)
        
        let light = PointLight()
        light.light.color = .init(red: 1.0, green: 0.90, blue: 0.70, alpha: 1.0)
        light.light.intensity = 1800
        light.light.attenuationRadius = 1.8
        light.position = [0.06, 0.18, -0.04]
        light.name = "lamp_point_light"
        lampBase.addChild(light)
        self.lampLight = light
        
        let colShape = ShapeResource.generateCylinder(height: 0.28, radius: 0.08)
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_lamp",
            displayName: "Desk Lamp",
            accessibilityLabel: "Warm white ceramic and brass desk lamp",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
    
    func setEnabled(_ isEnabled: Bool) {
        lampLight?.light.intensity = isEnabled ? 1800 : 0
    }
    
    func toggle() {
        if let light = lampLight {
            let isOn = light.light.intensity > 0
            setEnabled(!isOn)
        }
    }
}

// MARK: - Ceramic Smiley Mug (Movable)

@MainActor
final class DeskMugEntity: Entity {
    static let defaultPos = SIMD3<Float>(-0.86, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, 0.00)
    
    required init() {
        super.init()
        self.name = "prop_mug"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let mug = ModelEntity(mesh: .generateCylinder(height: 0.075, radius: 0.035), materials: [mats.smileyMugMaterial])
        mug.position = [0, 0.038, 0]
        addChild(mug)
        
        let colShape = ShapeResource.generateCylinder(height: 0.08, radius: 0.045)
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_mug",
            displayName: "Smiley Mug",
            accessibilityLabel: "Yellow ceramic smiley face coffee mug",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Pencil Cup (Movable)

@MainActor
final class DeskPencilCupEntity: Entity {
    static let defaultPos = SIMD3<Float>(-1.04, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, 0.00)
    
    required init() {
        super.init()
        self.name = "prop_pencil_cup"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let cup = ModelEntity(mesh: .generateCylinder(height: 0.08, radius: 0.03), materials: [mats.glazedWhiteCeramic])
        cup.position = [0, 0.04, 0]
        addChild(cup)
        
        for i in 0..<3 {
            let pencil = ModelEntity(mesh: .generateCylinder(height: 0.11, radius: 0.004), materials: [i % 2 == 0 ? mats.terracottaClay : mats.sageGreenFabric])
            pencil.position = [0, 0.03, Float(i - 1) * 0.012]
            pencil.orientation = simd_quatf(angle: Float(i - 1) * 0.15, axis: [1, 0, 0])
            cup.addChild(pencil)
        }
        
        let colShape = ShapeResource.generateCylinder(height: 0.12, radius: 0.04)
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_pencil_cup",
            displayName: "Pencil Cup",
            accessibilityLabel: "White ceramic pencil cup with drawing tools",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Desk Succulent Plant (Movable)

@MainActor
final class DeskPlantEntity: Entity {
    static let defaultPos = SIMD3<Float>(-1.06, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight, -0.30)
    
    required init() {
        super.init()
        self.name = "prop_desk_plant"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let deskPlantPot = ModelEntity(mesh: .generateCylinder(height: 0.05, radius: 0.028), materials: [mats.terracottaClay])
        deskPlantPot.position = [0, 0.025, 0]
        addChild(deskPlantPot)
        
        let deskFoliage = ModelEntity(mesh: .generateSphere(radius: 0.032), materials: [mats.foliageLight])
        deskFoliage.position = [0, 0.03, 0]
        deskPlantPot.addChild(deskFoliage)
        
        let colShape = ShapeResource.generateCylinder(height: 0.09, radius: 0.04)
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_desk_plant",
            displayName: "Desk Plant",
            accessibilityLabel: "Small potted terracotta succulent on desk",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            allowsScaling: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

// MARK: - Over-Ear Headphones (Movable)

@MainActor
final class DeskHeadphonesEntity: Entity {
    static let defaultPos = SIMD3<Float>(-1.12, RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight + 0.38, -0.17)
    
    required init() {
        super.init()
        self.name = "prop_headphones"
        self.position = Self.defaultPos
        
        let mats = RoomMaterials.shared
        let headphoneMesh = MeshResource.generateCylinder(height: 0.04, radius: 0.035)
        let leftCup = ModelEntity(mesh: headphoneMesh, materials: [mats.creamLinenFabric])
        leftCup.position = [0, 0, -0.04]
        addChild(leftCup)
        
        let rightCup = ModelEntity(mesh: headphoneMesh, materials: [mats.creamLinenFabric])
        rightCup.position = [0, 0, 0.04]
        addChild(rightCup)
        
        let headband = ModelEntity(mesh: .generateCylinder(height: 0.08, radius: 0.005), materials: [mats.brushedAluminum])
        headband.position = [0, 0.04, 0]
        headband.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        addChild(headband)
        
        let colShape = ShapeResource.generateBox(size: [0.08, 0.12, 0.12])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_headphones",
            displayName: "Headphones",
            accessibilityLabel: "White minimalist over-ear headphones",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + DeskEntity.deskHeight
        ))
    }
}

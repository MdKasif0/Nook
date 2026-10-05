import RealityKit
import AppKit

/// Builds the comprehensive left workstation matching the reference image:
/// - Honey-oak desk surface against the left wall
/// - Drawer unit underneath
/// - Large desktop monitor displaying "hello ♡"
/// - Open silver laptop displaying nature landscape
/// - White chiclet keyboard & minimalist mouse on a cream desk mat
/// - Open notebook with pen
/// - Wooden phone stand with smartphone
/// - Ceramic smiley mug
/// - Pencil cup with writing tools
/// - Desk lamp with warm toggleable spotlight
/// - Small potted desk plant
@MainActor
final class DeskEntity: Entity {
    
    // Desk surface coordinate reference
    static let deskWidth: Float = 0.58   // along X
    static let deskLength: Float = 1.25  // along Z
    static let deskThickness: Float = 0.04
    static let deskHeight: Float = 0.72
    
    private(set) var lampLight: PointLight?
    
    required init() {
        super.init()
        self.name = "desk_workstation"
        buildWorkstation()
    }
    
    private func buildWorkstation() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        
        // Desk positioned against the left wall (X = -1.20m), centered at Z = -0.32m
        // X = -0.88, Z = -0.32
        self.position = [-0.88, floorY, -0.32]
        
        // 1. Desk Surface Tabletop (Honey Oak with soft rounded corners)
        let topMesh = MeshResource.generateBox(size: [Self.deskWidth, Self.deskThickness, Self.deskLength], cornerRadius: 0.012)
        let topEntity = ModelEntity(mesh: topMesh, materials: [mats.honeyOakWood])
        topEntity.position = [0, Self.deskHeight - Self.deskThickness * 0.5, 0]
        topEntity.name = "desk_surface"
        addChild(topEntity)
        
        // 2. Front 2-Drawer Pedestal Cabinet (Under desk at front edge)
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
        
        // 4. Large Desktop Monitor (Thin bezel, stand, "hello ♡" display)
        // Positioned at the back of the desk (Z = -0.35), facing +X / +Z
        let monitorWidth: Float = 0.48
        let monitorHeight: Float = 0.30
        let monitorDepth: Float = 0.02
        let monitorCenter = SIMD3<Float>(-0.08, Self.deskHeight + 0.24, -0.32)
        
        // Stand base
        let standBase = ModelEntity(mesh: .generateBox(size: [0.14, 0.008, 0.16], cornerRadius: 0.005), materials: [mats.brushedAluminum])
        standBase.position = [monitorCenter.x, Self.deskHeight + 0.004, monitorCenter.z]
        standBase.orientation = simd_quatf(angle: Float.pi * 0.22, axis: [0, 1, 0])
        addChild(standBase)
        
        // Stand upright post
        let standPost = ModelEntity(mesh: .generateBox(size: [0.015, 0.18, 0.035], cornerRadius: 0.004), materials: [mats.brushedAluminum])
        standPost.position = [monitorCenter.x - 0.02, Self.deskHeight + 0.09, monitorCenter.z - 0.01]
        standPost.orientation = simd_quatf(angle: Float.pi * 0.22, axis: [0, 1, 0])
        addChild(standPost)
        
        // Monitor casing
        let casingMesh = MeshResource.generateBox(size: [monitorDepth, monitorHeight, monitorWidth], cornerRadius: 0.008)
        let monitorCasing = ModelEntity(mesh: casingMesh, materials: [mats.brushedAluminum])
        monitorCasing.position = monitorCenter
        monitorCasing.orientation = simd_quatf(angle: Float.pi * 0.22, axis: [0, 1, 0])
        monitorCasing.name = "desktop_monitor"
        addChild(monitorCasing)
        
        // Screen with "hello ♡" procedural texture
        let screenMesh = MeshResource.generatePlane(width: monitorWidth - 0.02, depth: monitorHeight - 0.02, cornerRadius: 0.004)
        let screenEntity = ModelEntity(mesh: screenMesh, materials: [mats.monitorScreenMaterial])
        screenEntity.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1]) * simd_quatf(angle: Float.pi * 0.5, axis: [0, 1, 0])
        screenEntity.position = [monitorDepth * 0.5 + 0.001, 0, 0]
        monitorCasing.addChild(screenEntity)
        
        // 5. Open Silver Laptop (Beside monitor at Z = 0.08)
        let laptopCenter = SIMD3<Float>(0.02, Self.deskHeight, 0.06)
        let laptopBase = ModelEntity(
            mesh: .generateBox(size: [0.17, 0.010, 0.24], cornerRadius: 0.005),
            materials: [mats.brushedAluminum]
        )
        laptopBase.position = [laptopCenter.x, laptopCenter.y + 0.005, laptopCenter.z]
        laptopBase.orientation = simd_quatf(angle: Float.pi * 0.24, axis: [0, 1, 0])
        laptopBase.name = "laptop"
        addChild(laptopBase)
        
        // Laptop screen (propped open)
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
        laptopDisplay.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1]) * simd_quatf(angle: Float.pi * 0.5, axis: [0, 1, 0])
        laptopDisplay.position = [0.004, 0, 0]
        laptopScreen.addChild(laptopDisplay)
        
        // 6. Keyboard & Mouse (In front of monitor/laptop)
        let keyboard = ModelEntity(
            mesh: .generateBox(size: [0.12, 0.008, 0.32], cornerRadius: 0.004),
            materials: [mats.creamLinenFabric]
        )
        keyboard.position = [0.08, Self.deskHeight + 0.006, -0.22]
        keyboard.orientation = simd_quatf(angle: Float.pi * 0.06, axis: [0, 1, 0])
        keyboard.name = "keyboard"
        addChild(keyboard)
        
        let mouse = ModelEntity(
            mesh: .generateBox(size: [0.08, 0.015, 0.05], cornerRadius: 0.015),
            materials: [mats.glazedWhiteCeramic]
        )
        mouse.position = [0.08, Self.deskHeight + 0.01, 0.08]
        mouse.name = "mouse"
        addChild(mouse)
        
        // 7. Open Notebook with Pen
        let notebook = ModelEntity(
            mesh: .generateBox(size: [0.13, 0.008, 0.18], cornerRadius: 0.003),
            materials: [mats.openNotebookMaterial]
        )
        notebook.position = [0.14, Self.deskHeight + 0.006, -0.42]
        notebook.orientation = simd_quatf(angle: Float.pi * 0.08, axis: [0, 1, 0])
        notebook.name = "open_notebook"
        addChild(notebook)
        
        let pen = ModelEntity(
            mesh: .generateCylinder(height: 0.11, radius: 0.003),
            materials: [mats.brushedAluminum]
        )
        pen.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        pen.position = [0.14, Self.deskHeight + 0.014, -0.42]
        addChild(pen)
        
        // 8. Smartphone on Wooden Stand
        let phoneStand = ModelEntity(mesh: .generateBox(size: [0.06, 0.05, 0.06], cornerRadius: 0.004), materials: [mats.honeyOakWood])
        phoneStand.position = [-0.18, Self.deskHeight + 0.025, -0.52]
        addChild(phoneStand)
        
        let phone = ModelEntity(mesh: .generateBox(size: [0.008, 0.12, 0.06], cornerRadius: 0.005), materials: [mats.vinylRecord])
        phone.orientation = simd_quatf(angle: Float.pi * 0.15, axis: [0, 0, 1])
        phone.position = [0.01, 0.04, 0]
        phoneStand.addChild(phone)
        
        // 9. Ceramic Smiley Mug & Pencil Cup
        let mug = ModelEntity(mesh: .generateCylinder(height: 0.075, radius: 0.035), materials: [mats.smileyMugMaterial])
        mug.position = [0.02, Self.deskHeight + 0.038, 0.32]
        mug.name = "smiley_mug"
        addChild(mug)
        
        let cup = ModelEntity(mesh: .generateCylinder(height: 0.08, radius: 0.03), materials: [mats.glazedWhiteCeramic])
        cup.position = [-0.16, Self.deskHeight + 0.04, 0.32]
        cup.name = "pencil_cup"
        addChild(cup)
        
        for i in 0..<3 {
            let pencil = ModelEntity(mesh: .generateCylinder(height: 0.11, radius: 0.004), materials: [i % 2 == 0 ? mats.terracottaClay : mats.sageGreenFabric])
            pencil.position = [0, 0.03, Float(i - 1) * 0.012]
            pencil.orientation = simd_quatf(angle: Float(i - 1) * 0.15, axis: [1, 0, 0])
            cup.addChild(pencil)
        }
        
        // 10. Desk Lamp with Warm Spotlight
        let lampBase = ModelEntity(mesh: .generateCylinder(height: 0.015, radius: 0.045), materials: [mats.glazedWhiteCeramic])
        lampBase.position = [-0.14, Self.deskHeight + 0.008, 0.18]
        lampBase.name = "desk_lamp"
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
        
        // 11. Small Desk Plant
        let deskPlantPot = ModelEntity(mesh: .generateCylinder(height: 0.05, radius: 0.028), materials: [mats.terracottaClay])
        deskPlantPot.position = [-0.18, Self.deskHeight + 0.025, 0.02]
        let deskFoliage = ModelEntity(mesh: .generateSphere(radius: 0.032), materials: [mats.foliageLight])
        deskFoliage.position = [0, 0.03, 0]
        deskPlantPot.addChild(deskFoliage)
        addChild(deskPlantPot)
    }
    
    func setLampEnabled(_ isEnabled: Bool) {
        lampLight?.light.intensity = isEnabled ? 1800 : 0
    }
}

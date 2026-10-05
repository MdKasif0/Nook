import RealityKit
import AppKit

/// Builds the comprehensive left workstation matching the reference image:
/// - Honey-oak desk surface
/// - Left 2-drawer wooden pedestal with horizontal pulls
/// - Right wooden leg support frame
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
    static let deskWidth: Float = 1.15
    static let deskDepth: Float = 0.65
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
        
        // Desk centered around X = -0.72, Z = -0.55
        self.position = [-0.72, floorY, -0.55]
        
        // 1. Desk Surface Tabletop (Honey Oak with soft rounded corners)
        let topMesh = MeshResource.generateBox(size: [Self.deskWidth, Self.deskThickness, Self.deskDepth], cornerRadius: 0.012)
        let topEntity = ModelEntity(mesh: topMesh, materials: [mats.honeyOakWood])
        topEntity.position = [0, Self.deskHeight - Self.deskThickness * 0.5, 0]
        topEntity.name = "desk_surface"
        addChild(topEntity)
        
        // 2. Left 2-Drawer Pedestal Cabinet
        let drawerWidth: Float = 0.32
        let drawerDepth: Float = 0.58
        let drawerHeight: Float = Self.deskHeight - Self.deskThickness
        let drawerMesh = MeshResource.generateBox(size: [drawerWidth, drawerHeight, drawerDepth], cornerRadius: 0.01)
        let drawerCabinet = ModelEntity(mesh: drawerMesh, materials: [mats.honeyOakWood])
        drawerCabinet.position = [-Self.deskWidth * 0.5 + drawerWidth * 0.5 + 0.03, drawerHeight * 0.5, 0]
        drawerCabinet.name = "desk_drawers"
        addChild(drawerCabinet)
        
        // Drawer front lines and horizontal pulls
        for i in 0..<2 {
            let pullY = drawerHeight * 0.30 + Float(i) * (drawerHeight * 0.40)
            let pullMesh = MeshResource.generateBox(size: [0.08, 0.012, 0.018], cornerRadius: 0.003)
            let pull = ModelEntity(mesh: pullMesh, materials: [mats.warmBrass])
            pull.position = [-Self.deskWidth * 0.5 + drawerWidth * 0.5 + 0.03, pullY, drawerDepth * 0.5 + 0.01]
            addChild(pull)
        }
        
        // 3. Right Wooden Leg Frame
        let legThickness: Float = 0.04
        let rightLegMesh = MeshResource.generateBox(size: [legThickness, drawerHeight, drawerDepth], cornerRadius: 0.008)
        let rightLeg = ModelEntity(mesh: rightLegMesh, materials: [mats.honeyOakWood])
        rightLeg.position = [Self.deskWidth * 0.5 - legThickness * 0.5 - 0.03, drawerHeight * 0.5, 0]
        addChild(rightLeg)
        
        // 4. Cream Desk Mat / Blotter
        let matMesh = MeshResource.generateBox(size: [0.72, 0.003, 0.38], cornerRadius: 0.008)
        let deskMat = ModelEntity(mesh: matMesh, materials: [mats.creamLinenFabric])
        deskMat.position = [-0.04, Self.deskHeight + 0.0015, 0.08]
        addChild(deskMat)
        
        // 5. Large Desktop Monitor (Thin bezel, stand, "hello ♡" display)
        let monitorWidth: Float = 0.52
        let monitorHeight: Float = 0.32
        let monitorDepth: Float = 0.02
        let monitorCenter = SIMD3<Float>(-0.22, Self.deskHeight + 0.26, -0.16)
        
        // Monitor stand base
        let standBase = ModelEntity(mesh: .generateBox(size: [0.16, 0.008, 0.14], cornerRadius: 0.005), materials: [mats.brushedAluminum])
        standBase.position = [monitorCenter.x, Self.deskHeight + 0.004, monitorCenter.z]
        addChild(standBase)
        
        // Stand upright post
        let standPost = ModelEntity(mesh: .generateBox(size: [0.035, 0.18, 0.015], cornerRadius: 0.004), materials: [mats.brushedAluminum])
        standPost.position = [monitorCenter.x, Self.deskHeight + 0.09, monitorCenter.z - 0.03]
        addChild(standPost)
        
        // Monitor frame & back casing
        let casingMesh = MeshResource.generateBox(size: [monitorWidth, monitorHeight, monitorDepth], cornerRadius: 0.008)
        let monitorCasing = ModelEntity(mesh: casingMesh, materials: [mats.brushedAluminum])
        monitorCasing.position = monitorCenter
        monitorCasing.name = "desktop_monitor"
        addChild(monitorCasing)
        
        // Screen with "hello ♡" procedural texture
        let screenMesh = MeshResource.generatePlane(width: monitorWidth - 0.02, depth: monitorHeight - 0.02, cornerRadius: 0.004)
        let screenEntity = ModelEntity(mesh: screenMesh, materials: [mats.monitorScreenMaterial])
        screenEntity.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        screenEntity.position = [0, 0, monitorDepth * 0.5 + 0.001]
        monitorCasing.addChild(screenEntity)
        
        // 6. Open Laptop (Silver, nature wallpaper)
        let laptopCenter = SIMD3<Float>(0.24, Self.deskHeight, -0.06)
        let laptopBaseMesh = MeshResource.generateBox(size: [0.24, 0.010, 0.17], cornerRadius: 0.005)
        let laptopBase = ModelEntity(mesh: laptopBaseMesh, materials: [mats.brushedAluminum])
        laptopBase.position = [laptopCenter.x, laptopCenter.y + 0.005, laptopCenter.z]
        // Angled slightly toward the user
        laptopBase.orientation = simd_quatf(angle: -Float.pi * 0.12, axis: [0, 1, 0])
        laptopBase.name = "laptop"
        addChild(laptopBase)
        
        // Laptop screen (propped open at ~110 degrees)
        let laptopScreenMesh = MeshResource.generateBox(size: [0.24, 0.16, 0.006], cornerRadius: 0.004)
        let laptopScreen = ModelEntity(mesh: laptopScreenMesh, materials: [mats.brushedAluminum])
        laptopScreen.position = [0, 0.08, -0.08]
        laptopScreen.orientation = simd_quatf(angle: Float.pi * 0.12, axis: [1, 0, 0])
        laptopBase.addChild(laptopScreen)
        
        let laptopDisplay = ModelEntity(
            mesh: .generatePlane(width: 0.22, depth: 0.14, cornerRadius: 0.003),
            materials: [mats.laptopScreenMaterial]
        )
        laptopDisplay.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        laptopDisplay.position = [0, 0, 0.004]
        laptopScreen.addChild(laptopDisplay)
        
        // 7. White Chiclet Keyboard & Mouse
        let kbMesh = MeshResource.generateBox(size: [0.32, 0.008, 0.12], cornerRadius: 0.004)
        let keyboard = ModelEntity(mesh: kbMesh, materials: [mats.creamLinenFabric])
        keyboard.position = [-0.14, Self.deskHeight + 0.006, 0.12]
        keyboard.name = "keyboard"
        addChild(keyboard)
        
        let mouseMesh = MeshResource.generateBox(size: [0.05, 0.015, 0.09], cornerRadius: 0.015)
        let mouse = ModelEntity(mesh: mouseMesh, materials: [mats.glazedWhiteCeramic])
        mouse.position = [0.14, Self.deskHeight + 0.01, 0.12]
        mouse.name = "mouse"
        addChild(mouse)
        
        // 8. Open Notebook with Pen
        let nbMesh = MeshResource.generateBox(size: [0.18, 0.008, 0.13], cornerRadius: 0.003)
        let notebook = ModelEntity(mesh: nbMesh, materials: [mats.openNotebookMaterial])
        notebook.position = [-0.38, Self.deskHeight + 0.006, 0.16]
        notebook.orientation = simd_quatf(angle: Float.pi * 0.08, axis: [0, 1, 0])
        notebook.name = "open_notebook"
        addChild(notebook)
        
        let penMesh = MeshResource.generateCylinder(height: 0.11, radius: 0.003)
        let pen = ModelEntity(mesh: penMesh, materials: [mats.brushedAluminum])
        pen.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1])
        pen.position = [-0.38, Self.deskHeight + 0.014, 0.16]
        addChild(pen)
        
        // 9. Smartphone on Wooden Stand
        let standMesh = MeshResource.generateBox(size: [0.06, 0.05, 0.06], cornerRadius: 0.004)
        let phoneStand = ModelEntity(mesh: standMesh, materials: [mats.honeyOakWood])
        phoneStand.position = [-0.48, Self.deskHeight + 0.025, -0.05]
        phoneStand.orientation = simd_quatf(angle: Float.pi * 0.15, axis: [0, 1, 0])
        addChild(phoneStand)
        
        let phoneMesh = MeshResource.generateBox(size: [0.06, 0.12, 0.008], cornerRadius: 0.005)
        let phone = ModelEntity(mesh: phoneMesh, materials: [mats.vinylRecord])
        phone.orientation = simd_quatf(angle: -Float.pi * 0.15, axis: [1, 0, 0])
        phone.position = [0, 0.04, 0.01]
        phoneStand.addChild(phone)
        
        // 10. Ceramic Smiley Mug
        let mugMesh = MeshResource.generateCylinder(height: 0.075, radius: 0.035)
        let mug = ModelEntity(mesh: mugMesh, materials: [mats.smileyMugMaterial])
        mug.position = [0.38, Self.deskHeight + 0.038, 0.08]
        mug.name = "smiley_mug"
        addChild(mug)
        
        // Mug handle
        let handle = ModelEntity(mesh: .generateCylinder(height: 0.04, radius: 0.006), materials: [mats.glazedWhiteCeramic])
        handle.position = [0.04, 0, 0]
        mug.addChild(handle)
        
        // 11. Pencil Cup with Pencils
        let cupMesh = MeshResource.generateCylinder(height: 0.08, radius: 0.03)
        let cup = ModelEntity(mesh: cupMesh, materials: [mats.glazedWhiteCeramic])
        cup.position = [-0.48, Self.deskHeight + 0.04, -0.22]
        cup.name = "pencil_cup"
        addChild(cup)
        
        for i in 0..<3 {
            let pencil = ModelEntity(mesh: .generateCylinder(height: 0.11, radius: 0.004), materials: [i % 2 == 0 ? mats.terracottaClay : mats.sageGreenFabric])
            pencil.position = [Float(i - 1) * 0.012, 0.03, 0]
            pencil.orientation = simd_quatf(angle: Float(i - 1) * 0.15, axis: [0, 0, 1])
            cup.addChild(pencil)
        }
        
        // 12. Desk Lamp with Warm Spotlight / Point Light
        let lampCenter = SIMD3<Float>(0.38, Self.deskHeight, -0.20)
        let lampBase = ModelEntity(mesh: .generateCylinder(height: 0.015, radius: 0.045), materials: [mats.glazedWhiteCeramic])
        lampBase.position = [lampCenter.x, lampCenter.y + 0.008, lampCenter.z]
        lampBase.name = "desk_lamp"
        addChild(lampBase)
        
        let lampStem = ModelEntity(mesh: .generateCylinder(height: 0.22, radius: 0.006), materials: [mats.brushedAluminum])
        lampStem.position = [0, 0.11, 0]
        lampBase.addChild(lampStem)
        
        let lampShade = ModelEntity(mesh: .generateSphere(radius: 0.042), materials: [mats.glazedWhiteCeramic])
        lampShade.position = [-0.05, 0.21, 0.05]
        lampBase.addChild(lampShade)
        
        // Warm point light inside the lamp shade
        let light = PointLight()
        light.light.color = .init(red: 1.0, green: 0.90, blue: 0.70, alpha: 1.0)
        light.light.intensity = 1800
        light.light.attenuationRadius = 1.8
        light.position = [-0.05, 0.18, 0.05]
        light.name = "lamp_point_light"
        lampBase.addChild(light)
        self.lampLight = light
        
        // 13. Small Potted Desk Plant
        let deskPlantPot = ModelEntity(mesh: .generateCylinder(height: 0.05, radius: 0.028), materials: [mats.terracottaClay])
        deskPlantPot.position = [0.42, Self.deskHeight + 0.025, -0.06]
        let deskFoliage = ModelEntity(mesh: .generateSphere(radius: 0.032), materials: [mats.foliageLight])
        deskFoliage.position = [0, 0.03, 0]
        deskPlantPot.addChild(deskFoliage)
        addChild(deskPlantPot)
    }
    
    func setLampEnabled(_ isEnabled: Bool) {
        lampLight?.light.intensity = isEnabled ? 1800 : 0
    }
}

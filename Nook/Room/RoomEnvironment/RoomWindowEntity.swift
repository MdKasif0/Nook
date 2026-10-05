import RealityKit
import AppKit

/// Builds the right wall window setup:
/// - Warm honey-oak double-hung window frame
/// - Vertical and horizontal mullions dividing glass into 4 panes
/// - Translucent glass panes
/// - Wooden curtain rod with finials
/// - Cream gathered linen curtains on both sides
/// - Wooden window sill with potted mini succulent
/// - Soft outdoor background plane suggesting warm daylight and greenery
@MainActor
final class RoomWindowEntity: Entity {
    
    required init() {
        super.init()
        self.name = "room_window_setup"
        buildWindow()
    }
    
    private func buildWindow() {
        let mats = RoomMaterials.shared
        
        let windowWidth: Float = 0.95
        let windowHeight: Float = 1.05
        let frameDepth: Float = 0.08
        
        // Window placed on the right wall (X = 1.30m), centered around Z = -0.45m, Y = 1.15m
        let windowCenterX: Float = RoomArchitectureEntity.roomSpanX * 0.5 - 0.05
        let windowCenterY: Float = 1.18
        let windowCenterZ: Float = -0.45
        
        // 1. Outer Wooden Window Frame Casing
        // Top frame
        let topFrame = ModelEntity(mesh: .generateBox(size: [frameDepth, 0.06, windowWidth + 0.08], cornerRadius: 0.008), materials: [mats.honeyOakWood])
        topFrame.position = [windowCenterX, windowCenterY + windowHeight * 0.5 + 0.03, windowCenterZ]
        addChild(topFrame)
        
        // Bottom frame / Window Sill
        let sill = ModelEntity(mesh: .generateBox(size: [frameDepth + 0.06, 0.05, windowWidth + 0.16], cornerRadius: 0.01), materials: [mats.honeyOakWood])
        sill.position = [windowCenterX - 0.02, windowCenterY - windowHeight * 0.5 - 0.025, windowCenterZ]
        sill.name = "window_sill"
        addChild(sill)
        
        // Left & Right frame posts
        let leftPost = ModelEntity(mesh: .generateBox(size: [frameDepth, windowHeight, 0.05], cornerRadius: 0.008), materials: [mats.honeyOakWood])
        leftPost.position = [windowCenterX, windowCenterY, windowCenterZ - windowWidth * 0.5 - 0.025]
        addChild(leftPost)
        
        let rightPost = ModelEntity(mesh: .generateBox(size: [frameDepth, windowHeight, 0.05], cornerRadius: 0.008), materials: [mats.honeyOakWood])
        rightPost.position = [windowCenterX, windowCenterY, windowCenterZ + windowWidth * 0.5 + 0.025]
        addChild(rightPost)
        
        // 2. Center Wooden Mullions (Cross)
        let verticalMullion = ModelEntity(mesh: .generateBox(size: [0.03, windowHeight, 0.03], cornerRadius: 0.005), materials: [mats.honeyOakWood])
        verticalMullion.position = [windowCenterX, windowCenterY, windowCenterZ]
        addChild(verticalMullion)
        
        let horizontalMullion = ModelEntity(mesh: .generateBox(size: [0.03, 0.03, windowWidth], cornerRadius: 0.005), materials: [mats.honeyOakWood])
        horizontalMullion.position = [windowCenterX, windowCenterY, windowCenterZ]
        addChild(horizontalMullion)
        
        // 3. Glass Panes (Translucent)
        let glassPane = ModelEntity(mesh: .generateBox(size: [0.008, windowHeight - 0.04, windowWidth - 0.04]), materials: [mats.windowGlass])
        glassPane.position = [windowCenterX, windowCenterY, windowCenterZ]
        glassPane.name = "window_glass"
        addChild(glassPane)
        
        // 4. Wooden Curtain Rod & Rings
        let rodLength: Float = windowWidth + 0.38
        let rod = ModelEntity(mesh: .generateCylinder(height: rodLength, radius: 0.012), materials: [mats.honeyOakWood])
        rod.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        rod.position = [windowCenterX - 0.08, windowCenterY + windowHeight * 0.5 + 0.12, windowCenterZ]
        addChild(rod)
        
        // Rod finials
        let finialMesh = MeshResource.generateSphere(radius: 0.02)
        let leftFinial = ModelEntity(mesh: finialMesh, materials: [mats.honeyOakWood])
        leftFinial.position = [windowCenterX - 0.08, windowCenterY + windowHeight * 0.5 + 0.12, windowCenterZ - rodLength * 0.5]
        addChild(leftFinial)
        
        let rightFinial = ModelEntity(mesh: finialMesh, materials: [mats.honeyOakWood])
        rightFinial.position = [windowCenterX - 0.08, windowCenterY + windowHeight * 0.5 + 0.12, windowCenterZ + rodLength * 0.5]
        addChild(rightFinial)
        
        // 5. Draped Cream Linen Curtains (Left & Right gathered sides)
        let curtainMesh = ProceduralMeshGenerator.generateCurtainMesh(width: 0.24, height: 1.15, folds: 3)
        
        let leftCurtain = ModelEntity(mesh: curtainMesh, materials: [mats.creamLinenFabric])
        // Positioned inside the room, aligned with the rod
        leftCurtain.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 1, 0])
        leftCurtain.position = [windowCenterX - 0.06, windowCenterY + windowHeight * 0.5 + 0.10, windowCenterZ - windowWidth * 0.5 + 0.04]
        leftCurtain.name = "left_curtain"
        addChild(leftCurtain)
        
        let rightCurtain = ModelEntity(mesh: curtainMesh, materials: [mats.creamLinenFabric])
        rightCurtain.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 1, 0])
        rightCurtain.position = [windowCenterX - 0.06, windowCenterY + windowHeight * 0.5 + 0.10, windowCenterZ + windowWidth * 0.5 - 0.04]
        rightCurtain.name = "right_curtain"
        addChild(rightCurtain)
        
        // 6. Window Sill Accents (Succulent in ceramic pot & tiny ceramic cat)
        let pot = ModelEntity(mesh: .generateCylinder(height: 0.06, radius: 0.035), materials: [mats.glazedWhiteCeramic])
        pot.position = [windowCenterX - 0.02, windowCenterY - windowHeight * 0.5 + 0.03, windowCenterZ + 0.22]
        let plant = ModelEntity(mesh: .generateSphere(radius: 0.032), materials: [mats.foliageLight])
        plant.position = [0, 0.035, 0]
        pot.addChild(plant)
        addChild(pot)
        
        let figurine = ModelEntity(mesh: .generateSphere(radius: 0.022), materials: [mats.glazedWhiteCeramic])
        figurine.position = [windowCenterX - 0.02, windowCenterY - windowHeight * 0.5 + 0.022, windowCenterZ - 0.22]
        addChild(figurine)
        
        // 7. Soft Outdoor Natural Environment Backdrop Plane
        buildOutdoorBackdrop(atX: windowCenterX + 0.25, centerY: windowCenterY, centerZ: windowCenterZ)
    }
    
    private func buildOutdoorBackdrop(atX: Float, centerY: Float, centerZ: Float) {
        let width = 512
        let height = 512
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Soft sunny sky gradient (warm golden daylight to gentle blue)
        let skyGradient = NSGradient(colors: [
            NSColor(red: 0.72, green: 0.82, blue: 0.90, alpha: 1.0),
            NSColor(red: 0.96, green: 0.92, blue: 0.82, alpha: 1.0)
        ])
        skyGradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
        
        // Soft blurred sun flare
        let sunFlare = NSBezierPath(ovalIn: NSRect(x: 280, y: 280, width: 140, height: 140))
        NSColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 0.45).setFill()
        sunFlare.fill()
        
        // Soft blurred green foliage clusters in the lower half
        NSColor(red: 0.48, green: 0.62, blue: 0.42, alpha: 0.75).setFill()
        let bush1 = NSBezierPath(ovalIn: NSRect(x: 40, y: 30, width: 220, height: 260))
        bush1.fill()
        
        NSColor(red: 0.38, green: 0.52, blue: 0.34, alpha: 0.85).setFill()
        let bush2 = NSBezierPath(ovalIn: NSRect(x: 180, y: 10, width: 260, height: 240))
        bush2.fill()
        
        NSColor(red: 0.55, green: 0.68, blue: 0.46, alpha: 0.80).setFill()
        let bush3 = NSBezierPath(ovalIn: NSRect(x: 320, y: 40, width: 200, height: 220))
        bush3.fill()
        
        image.unlockFocus()
        
        var mat = PhysicallyBasedMaterial()
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
            mat.emissiveColor = .init(texture: .init(tex))
            mat.emissiveIntensity = 0.6
        } else {
            mat.baseColor = .init(tint: NSColor(red: 0.72, green: 0.82, blue: 0.90, alpha: 1.0))
        }
        mat.roughness = .init(floatLiteral: 0.9)
        
        let backdropMesh = MeshResource.generatePlane(width: 1.8, depth: 1.8, cornerRadius: 0.05)
        let backdrop = ModelEntity(mesh: backdropMesh, materials: [mat])
        backdrop.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1]) * simd_quatf(angle: Float.pi * 0.5, axis: [0, 1, 0])
        backdrop.position = [atX, centerY, centerZ]
        backdrop.name = "outdoor_sky_plane"
        addChild(backdrop)
    }
}

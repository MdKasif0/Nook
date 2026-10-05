import RealityKit
import AppKit

/// Builds the wall decor matching the reference image:
/// 1. Back wall above bed headboard:
///    - Top: Framed botanical pine tree art print
///    - Bottom: Framed landscape art print
///    - Mini pinned card/polaroid
/// 2. Wall to the right of the window:
///    - Wooden wall sconce with angled brass arm and warm glowing bulb
///    - Framed botanical art print
///    - Two pinned mini polaroids below the art
@MainActor
final class WallDecorEntities: Entity {
    
    private(set) var sconceLight: PointLight?
    
    required init() {
        super.init()
        self.name = "wall_decor"
        buildWallDecor()
    }
    
    private func buildWallDecor() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        // Wall surface facing the room on the back wall
        let wallFrontZ: Float = -RoomArchitectureEntity.wallSpan * 0.5 + RoomArchitectureEntity.wallThickness * 0.5 + 0.005
        
        // -------------------------------------------------------------
        // SECTION 1: Wall Decor above the bed headboard (between bookcase & window)
        // Centered around X = 0.02, Z = wallFrontZ
        // -------------------------------------------------------------
        let frameWidth: Float = 0.13
        let frameHeight: Float = 0.17
        let frameDepth: Float = 0.012
        
        // 1a. Top Frame (Botanical Pine Tree Art)
        let topFrameBed = ModelEntity(
            mesh: .generateBox(size: [frameWidth, frameHeight, frameDepth], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        topFrameBed.position = [0.02, floorY + 1.34, wallFrontZ + frameDepth * 0.5]
        addChild(topFrameBed)
        
        let topArtBed = ModelEntity(
            mesh: .generatePlane(width: frameWidth - 0.025, depth: frameHeight - 0.025, cornerRadius: 0.002),
            materials: [mats.botanicalArt1Material]
        )
        topArtBed.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        topArtBed.position = [0, 0, frameDepth * 0.5 + 0.001]
        topFrameBed.addChild(topArtBed)
        
        // 1b. Bottom Frame (Landscape Art)
        let bottomFrameBed = ModelEntity(
            mesh: .generateBox(size: [frameWidth, frameHeight, frameDepth], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        bottomFrameBed.position = [0.02, floorY + 1.08, wallFrontZ + frameDepth * 0.5]
        addChild(bottomFrameBed)
        
        let bottomArtBed = ModelEntity(
            mesh: .generatePlane(width: frameWidth - 0.025, depth: frameHeight - 0.025, cornerRadius: 0.002),
            materials: [mats.botanicalArt2Material]
        )
        bottomArtBed.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        bottomArtBed.position = [0, 0, frameDepth * 0.5 + 0.001]
        bottomFrameBed.addChild(bottomArtBed)
        
        // 1c. Mini pinned note next to the bottom frame
        let miniNote = ModelEntity(
            mesh: .generateBox(size: [0.045, 0.055, 0.002], cornerRadius: 0.001),
            materials: [mats.creamLinenFabric]
        )
        miniNote.position = [0.11, floorY + 1.02, wallFrontZ + 0.002]
        miniNote.orientation = simd_quatf(angle: Float.pi * 0.04, axis: [0, 0, 1])
        addChild(miniNote)
        
        // -------------------------------------------------------------
        // SECTION 2: Wall Decor to the right of the window (X = 1.10)
        // -------------------------------------------------------------
        let rightWallX: Float = 1.10
        
        // 2a. Wall Sconce Lamp with Warm Glowing Exposed Bulb
        let sconceY: Float = floorY + 1.25
        let sconceRoot = Entity()
        sconceRoot.position = [rightWallX, sconceY, wallFrontZ]
        sconceRoot.name = "wall_sconce"
        addChild(sconceRoot)
        
        // Wooden wall mount plate
        let mountMesh = MeshResource.generateBox(size: [0.05, 0.07, 0.02], cornerRadius: 0.005)
        let mount = ModelEntity(mesh: mountMesh, materials: [mats.honeyOakWood])
        mount.position = [0, 0, 0.01]
        sconceRoot.addChild(mount)
        
        // Brass angled arm
        let armMesh = MeshResource.generateCylinder(height: 0.06, radius: 0.005)
        let arm = ModelEntity(mesh: armMesh, materials: [mats.warmBrass])
        arm.position = [0, 0, 0.04]
        arm.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        sconceRoot.addChild(arm)
        
        // Wooden / brass socket shade
        let shadeMesh = MeshResource.generateCylinder(height: 0.04, radius: 0.022)
        let shade = ModelEntity(mesh: shadeMesh, materials: [mats.honeyOakWood])
        shade.position = [0, -0.015, 0.07]
        sconceRoot.addChild(shade)
        
        // Warm glowing bulb
        var bulbMat = PhysicallyBasedMaterial()
        bulbMat.baseColor = .init(tint: NSColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0))
        bulbMat.emissiveColor = .init(color: .init(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0))
        bulbMat.emissiveIntensity = 2.0
        bulbMat.roughness = .init(floatLiteral: 0.1)
        
        let bulbMesh = MeshResource.generateSphere(radius: 0.018)
        let bulb = ModelEntity(mesh: bulbMesh, materials: [bulbMat])
        bulb.position = [0, -0.04, 0.07]
        sconceRoot.addChild(bulb)
        
        // Warm interior sconce point light
        let light = PointLight()
        light.light.color = .init(red: 1.0, green: 0.82, blue: 0.55, alpha: 1.0)
        light.light.intensity = 1100
        light.light.attenuationRadius = 2.0
        light.position = [0, -0.05, 0.10]
        light.name = "sconce_point_light"
        sconceRoot.addChild(light)
        self.sconceLight = light
        
        // 2b. Framed Botanical Art Print below sconce
        let rightFrame = ModelEntity(
            mesh: .generateBox(size: [frameWidth, frameHeight, frameDepth], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        rightFrame.position = [rightWallX, floorY + 0.88, wallFrontZ + frameDepth * 0.5]
        addChild(rightFrame)
        
        let rightArt = ModelEntity(
            mesh: .generatePlane(width: frameWidth - 0.025, depth: frameHeight - 0.025, cornerRadius: 0.002),
            materials: [mats.botanicalArt1Material]
        )
        rightArt.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        rightArt.position = [0, 0, frameDepth * 0.5 + 0.001]
        rightFrame.addChild(rightArt)
        
        // 2c. Two Mini Polaroids below the right frame
        let polaroidMesh = MeshResource.generateBox(size: [0.055, 0.065, 0.003], cornerRadius: 0.002)
        
        let p1 = ModelEntity(mesh: polaroidMesh, materials: [mats.creamLinenFabric])
        p1.position = [rightWallX - 0.035, floorY + 0.62, wallFrontZ + 0.003]
        p1.orientation = simd_quatf(angle: Float.pi * 0.05, axis: [0, 0, 1])
        addChild(p1)
        
        let p2 = ModelEntity(mesh: polaroidMesh, materials: [mats.creamLinenFabric])
        p2.position = [rightWallX + 0.035, floorY + 0.61, wallFrontZ + 0.003]
        p2.orientation = simd_quatf(angle: -Float.pi * 0.04, axis: [0, 0, 1])
        addChild(p2)
    }
    
    func setSconceEnabled(_ isEnabled: Bool) {
        sconceLight?.light.intensity = isEnabled ? 1100 : 0
    }
}

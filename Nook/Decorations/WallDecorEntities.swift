import RealityKit
import AppKit

/// Builds the right wall decor and wall sconce lamp matching the reference image:
/// - Wooden wall sconce with angled brass arm and warm glowing bulb
/// - 2 vertically stacked honey-oak framed botanical art prints
/// - 2 pinned mini polaroid prints below the art
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
        let wallX = RoomArchitectureEntity.roomSpanX * 0.5 - 0.05
        let floorY = RoomArchitectureEntity.upperFloorY
        
        // Wall decor placed on the right wall forward from the window (Z = +0.08m)
        let decorZ: Float = 0.08
        
        // 1. Wall Sconce Lamp with Warm Glowing Bulb
        let sconceY: Float = floorY + 1.25
        let sconceRoot = Entity()
        sconceRoot.position = [wallX, sconceY, decorZ]
        sconceRoot.name = "wall_sconce"
        addChild(sconceRoot)
        
        // Wooden wall mount block
        let mountMesh = MeshResource.generateBox(size: [0.02, 0.07, 0.05], cornerRadius: 0.005)
        let mount = ModelEntity(mesh: mountMesh, materials: [mats.honeyOakWood])
        mount.position = [-0.01, 0, 0]
        sconceRoot.addChild(mount)
        
        // Brass angled arm
        let armMesh = MeshResource.generateCylinder(height: 0.06, radius: 0.005)
        let arm = ModelEntity(mesh: armMesh, materials: [mats.warmBrass])
        arm.position = [-0.04, 0, 0]
        arm.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1])
        sconceRoot.addChild(arm)
        
        // Wooden / brass socket shade
        let shadeMesh = MeshResource.generateCylinder(height: 0.04, radius: 0.022)
        let shade = ModelEntity(mesh: shadeMesh, materials: [mats.honeyOakWood])
        shade.position = [-0.07, -0.015, 0]
        sconceRoot.addChild(shade)
        
        // Warm glowing exposed bulb
        var bulbMat = PhysicallyBasedMaterial()
        bulbMat.baseColor = .init(tint: NSColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1.0))
        bulbMat.emissiveColor = .init(color: .init(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0))
        bulbMat.emissiveIntensity = 2.0
        bulbMat.roughness = .init(floatLiteral: 0.1)
        
        let bulbMesh = MeshResource.generateSphere(radius: 0.02)
        let bulb = ModelEntity(mesh: bulbMesh, materials: [bulbMat])
        bulb.position = [-0.07, -0.042, 0]
        sconceRoot.addChild(bulb)
        
        // Warm interior sconce point light
        let light = PointLight()
        light.light.color = .init(red: 1.0, green: 0.82, blue: 0.55, alpha: 1.0)
        light.light.intensity = 1100
        light.light.attenuationRadius = 2.0
        light.position = [-0.10, -0.05, 0]
        light.name = "sconce_point_light"
        sconceRoot.addChild(light)
        self.sconceLight = light
        
        // 2. Two Vertically Stacked Framed Botanical Art Prints
        let frameWidth: Float = 0.14
        let frameHeight: Float = 0.18
        let frameDepth: Float = 0.015
        
        // Top Frame (Botanical Stem Art)
        let topFrame = ModelEntity(
            mesh: .generateBox(size: [frameDepth, frameHeight, frameWidth], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        topFrame.position = [wallX - 0.01, floorY + 0.98, decorZ]
        addChild(topFrame)
        
        let topArt = ModelEntity(
            mesh: .generatePlane(width: frameWidth - 0.025, depth: frameHeight - 0.025, cornerRadius: 0.002),
            materials: [mats.botanicalArt1Material]
        )
        topArt.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1]) * simd_quatf(angle: Float.pi * 0.5, axis: [0, 1, 0])
        topArt.position = [-0.009, 0, 0]
        topFrame.addChild(topArt)
        
        // Bottom Frame (Botanical Sun & Monstera Art)
        let bottomFrame = ModelEntity(
            mesh: .generateBox(size: [frameDepth, frameHeight, frameWidth], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        bottomFrame.position = [wallX - 0.01, floorY + 0.74, decorZ]
        addChild(bottomFrame)
        
        let bottomArt = ModelEntity(
            mesh: .generatePlane(width: frameWidth - 0.025, depth: frameHeight - 0.025, cornerRadius: 0.002),
            materials: [mats.botanicalArt2Material]
        )
        bottomArt.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1]) * simd_quatf(angle: Float.pi * 0.5, axis: [0, 1, 0])
        bottomArt.position = [-0.009, 0, 0]
        bottomFrame.addChild(bottomArt)
        
        // 3. Two Pinned Mini Polaroid Prints Below
        let polaroidMesh = MeshResource.generateBox(size: [0.004, 0.065, 0.055], cornerRadius: 0.002)
        
        let p1 = ModelEntity(mesh: polaroidMesh, materials: [mats.creamLinenFabric])
        p1.position = [wallX - 0.005, floorY + 0.58, decorZ - 0.035]
        p1.orientation = simd_quatf(angle: Float.pi * 0.05, axis: [1, 0, 0])
        addChild(p1)
        
        let p2 = ModelEntity(mesh: polaroidMesh, materials: [mats.creamLinenFabric])
        p2.position = [wallX - 0.005, floorY + 0.57, decorZ + 0.035]
        p2.orientation = simd_quatf(angle: -Float.pi * 0.04, axis: [1, 0, 0])
        addChild(p2)
    }
    
    func setSconceEnabled(_ isEnabled: Bool) {
        sconceLight?.light.intensity = isEnabled ? 1100 : 0
    }
}

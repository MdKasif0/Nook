import RealityKit
import AppKit

/// Builds a miniature tactile 3D yarn ball cat toy for Cookie to play with:
/// - Soft warm coral wool sphere with subtle ribbed surface wraps
/// - Intersecting yarn wrapping rings simulating spun yarn texture
/// - Loose curled yarn thread tail extending along the floor
/// - CollisionComponent and InputTargetComponent for dragging and interactive play
@MainActor
final class YarnBallEntity: Entity {
    
    static let defaultPos = SIMD3<Float>(-0.05, RoomArchitectureEntity.lowerFloorY + 0.024, 0.50)
    static let defaultRot = simd_quatf(angle: Float.pi * 0.12, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_yarn_ball"
        buildYarnBall()
    }
    
    private func buildYarnBall() {
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        // 1. Tactile Wool Material (Warm peach/coral yarn)
        var yarnMaterial = PhysicallyBasedMaterial()
        yarnMaterial.baseColor = .init(tint: NSColor(red: 0.94, green: 0.55, blue: 0.46, alpha: 1.0))
        yarnMaterial.roughness = .init(floatLiteral: 0.85)
        yarnMaterial.metallic = .init(floatLiteral: 0.0)
        yarnMaterial.specular = .init(floatLiteral: 0.15)
        
        var accentMaterial = PhysicallyBasedMaterial()
        accentMaterial.baseColor = .init(tint: NSColor(red: 0.90, green: 0.48, blue: 0.40, alpha: 1.0))
        accentMaterial.roughness = .init(floatLiteral: 0.88)
        
        let ballRadius: Float = 0.024
        
        // 2. Core Yarn Sphere
        let coreMesh = MeshResource.generateSphere(radius: ballRadius)
        let coreModel = ModelEntity(mesh: coreMesh, materials: [yarnMaterial])
        addChild(coreModel)
        
        // 3. Wrapping Strand Bands
        let bandMesh = MeshResource.generateBox(size: [ballRadius * 2.04, 0.005, ballRadius * 2.04], cornerRadius: 0.002)
        
        let band1 = ModelEntity(mesh: bandMesh, materials: [accentMaterial])
        band1.orientation = simd_quatf(angle: 0.35, axis: [1, 0, 0])
        addChild(band1)
        
        let band2 = ModelEntity(mesh: bandMesh, materials: [yarnMaterial])
        band2.orientation = simd_quatf(angle: -0.42, axis: [0, 0, 1]) * simd_quatf(angle: 0.3, axis: [0, 1, 0])
        addChild(band2)
        
        // 4. Loose Curled Yarn Strand Tail
        let tailStrandMesh = MeshResource.generateCylinder(height: 0.045, radius: 0.0025)
        let strand = ModelEntity(mesh: tailStrandMesh, materials: [accentMaterial])
        strand.orientation = simd_quatf(angle: Float.pi * 0.48, axis: [1, 0, 0]) * simd_quatf(angle: 0.25, axis: [0, 0, 1])
        strand.position = [0.018, -ballRadius + 0.003, 0.022]
        addChild(strand)
        
        // 5. Collision & Interactive Prop Configuration
        let colShape = ShapeResource.generateSphere(radius: ballRadius * 1.2)
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_yarn_ball",
            displayName: "Yarn Ball",
            accessibilityLabel: "Soft coral miniature yarn ball toy for Cookie",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.lowerFloorY
        ))
    }
}

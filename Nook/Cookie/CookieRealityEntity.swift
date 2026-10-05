import RealityKit
import AppKit

/// Builds the physical 3D sleeping Cookie the cat entity resting peacefully on the bed:
/// - Curved calico body with warm ginger and white patches
/// - Tucked head, tiny sleeping ears, closed eyes
/// - Curled tail wrapping along the body
/// - Gentle subtle procedural breathing idle animation
/// - Interactive hit-testing target for petting
@MainActor
final class CookieRealityEntity: Entity {
    
    private var bodyModel: ModelEntity?
    private var headModel: ModelEntity?
    private var isPurring: Bool = false
    
    required init() {
        super.init()
        self.name = "cookie_character"
        buildCookie()
        startBreathingAnimation()
    }
    
    private func buildCookie() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        let bedCenter = SIMD3<Float>(0.58, floorY, -0.45)
        let mattressTopY = floorY + BedEntity.frameHeight + 0.16
        
        // Cookie curled up sleeping right in the center of the bed
        // X = +0.58, Z = -0.38, Y = mattressTopY
        self.position = [bedCenter.x, mattressTopY + 0.045, -0.36]
        self.orientation = simd_quatf(angle: Float.pi * 0.25, axis: [0, 1, 0])
        
        // Calico ginger material
        var gingerMat = PhysicallyBasedMaterial()
        gingerMat.baseColor = .init(tint: NSColor(red: 0.88, green: 0.52, blue: 0.26, alpha: 1.0))
        gingerMat.roughness = .init(floatLiteral: 0.75)
        
        // White belly/chest material
        var whiteFurMat = PhysicallyBasedMaterial()
        whiteFurMat.baseColor = .init(tint: NSColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0))
        whiteFurMat.roughness = .init(floatLiteral: 0.75)
        
        // 1. Curled Sleeping Body (curved ellipsoid)
        let bodyMesh = MeshResource.generateBox(size: [0.18, 0.09, 0.13], cornerRadius: 0.045)
        let body = ModelEntity(mesh: bodyMesh, materials: [gingerMat])
        body.position = [0, 0, 0]
        addChild(body)
        self.bodyModel = body
        
        // White belly patch on one side
        let bellyMesh = MeshResource.generateBox(size: [0.12, 0.06, 0.05], cornerRadius: 0.025)
        let belly = ModelEntity(mesh: bellyMesh, materials: [whiteFurMat])
        belly.position = [0.02, -0.015, 0.05]
        body.addChild(belly)
        
        // 2. Sleeping Head (tucked into the front)
        let headMesh = MeshResource.generateSphere(radius: 0.052)
        let head = ModelEntity(mesh: headMesh, materials: [whiteFurMat])
        head.position = [-0.09, 0.01, 0.03]
        head.orientation = simd_quatf(angle: Float.pi * 0.1, axis: [0, 0, 1])
        addChild(head)
        self.headModel = head
        
        // Ginger ear patch
        let earMesh = MeshResource.generateBox(size: [0.022, 0.025, 0.014], cornerRadius: 0.003)
        let leftEar = ModelEntity(mesh: earMesh, materials: [gingerMat])
        leftEar.position = [-0.02, 0.045, -0.015]
        leftEar.orientation = simd_quatf(angle: Float.pi * 0.2, axis: [0, 0, 1])
        head.addChild(leftEar)
        
        let rightEar = ModelEntity(mesh: earMesh, materials: [whiteFurMat])
        rightEar.position = [0.025, 0.045, 0.01]
        rightEar.orientation = simd_quatf(angle: -Float.pi * 0.15, axis: [0, 0, 1])
        head.addChild(rightEar)
        
        // Closed sleeping eyes (drawn as subtle thin dark arcs)
        let eyeMesh = MeshResource.generateBox(size: [0.016, 0.003, 0.002], cornerRadius: 0.001)
        let leftEye = ModelEntity(mesh: eyeMesh, materials: [mats.vinylRecord])
        leftEye.position = [-0.035, 0.005, 0.045]
        head.addChild(leftEye)
        
        let rightEye = ModelEntity(mesh: eyeMesh, materials: [mats.vinylRecord])
        rightEye.position = [-0.005, 0.005, 0.05]
        head.addChild(rightEye)
        
        // Pink nose button
        var noseMat = PhysicallyBasedMaterial()
        noseMat.baseColor = .init(tint: NSColor(red: 0.95, green: 0.72, blue: 0.72, alpha: 1.0))
        let noseMesh = MeshResource.generateSphere(radius: 0.004)
        let nose = ModelEntity(mesh: noseMesh, materials: [noseMat])
        nose.position = [-0.02, -0.008, 0.052]
        head.addChild(nose)
        
        // 3. Curled Tail wrapping along body
        let tailMesh = MeshResource.generateCylinder(height: 0.14, radius: 0.016)
        let tail = ModelEntity(mesh: tailMesh, materials: [gingerMat])
        tail.orientation = simd_quatf(angle: Float.pi * 0.45, axis: [0, 0, 1]) * simd_quatf(angle: Float.pi * 0.35, axis: [0, 1, 0])
        tail.position = [0.08, -0.015, -0.05]
        addChild(tail)
        
        // White tail tip
        let tipMesh = MeshResource.generateSphere(radius: 0.018)
        let tip = ModelEntity(mesh: tipMesh, materials: [whiteFurMat])
        tip.position = [0, 0.07, 0]
        tail.addChild(tip)
        
        // 4. Input Target & Collision Component (for click / petting interaction)
        let collisionShape = ShapeResource.generateSphere(radius: 0.12)
        self.components.set(CollisionComponent(shapes: [collisionShape]))
        self.components.set(InputTargetComponent())
    }
    
    // Subtle procedural breathing animation (gentle scale pulsing on Y axis)
    private func startBreathingAnimation() {
        Task { @MainActor [weak self] in
            var t: Float = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // ~20fps animation loop
                guard let self = self, let body = self.bodyModel else { break }
                t += 0.05
                // Breathe in and out slowly every ~3.5 seconds
                let breathScale = 1.0 + sin(t * 1.8) * 0.035
                body.scale = [1.0, breathScale, 1.0]
            }
        }
    }
    
    /// Triggered when the user pets Cookie
    func pet() {
        guard !isPurring else { return }
        isPurring = true
        
        // Playful purr hop
        let originalY = self.position.y
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.position.y = originalY + 0.025
            try? await Task.sleep(nanoseconds: 180_000_000)
            self.position.y = originalY
            self.isPurring = false
        }
    }
}

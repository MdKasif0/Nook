import RealityKit
import AppKit

/// Builds the physical 3D sleeping Cookie the cat entity resting peacefully on the bed:
/// - Curved calico body with warm ginger and white patches
/// - Tucked head, tiny sleeping ears, closed eyes
/// - Curled tail wrapping along the body
/// - Gentle subtle procedural breathing idle animation
/// - Reactive curious look-at animation when room objects are moved
/// - Interactive hit-testing target for petting
@MainActor
final class CookieRealityEntity: Entity {
    
    private var bodyModel: ModelEntity?
    private var headModel: ModelEntity?
    private var isPurring: Bool = false
    private var isCuriousLooking: Bool = false
    
    static let defaultPos = SIMD3<Float>(0.48, RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16 + 0.045, -0.78)
    static let defaultRot = simd_quatf(angle: -Float.pi * 0.15, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_cookie"
        buildCookie()
        startBreathingAnimation()
    }
    
    private func buildCookie() {
        let mats = RoomMaterials.shared
        
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        var gingerMat = PhysicallyBasedMaterial()
        gingerMat.baseColor = .init(tint: NSColor(red: 0.88, green: 0.52, blue: 0.26, alpha: 1.0))
        gingerMat.roughness = .init(floatLiteral: 0.75)
        
        var whiteFurMat = PhysicallyBasedMaterial()
        whiteFurMat.baseColor = .init(tint: NSColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0))
        whiteFurMat.roughness = .init(floatLiteral: 0.75)
        
        // 1. Curled Sleeping Body
        let bodyMesh = MeshResource.generateBox(size: [0.18, 0.09, 0.13], cornerRadius: 0.045)
        let body = ModelEntity(mesh: bodyMesh, materials: [gingerMat])
        addChild(body)
        self.bodyModel = body
        
        let bellyMesh = MeshResource.generateBox(size: [0.12, 0.06, 0.05], cornerRadius: 0.025)
        let belly = ModelEntity(mesh: bellyMesh, materials: [whiteFurMat])
        belly.position = [0.02, -0.015, 0.05]
        body.addChild(belly)
        
        // 2. Sleeping Head
        let headMesh = MeshResource.generateSphere(radius: 0.052)
        let head = ModelEntity(mesh: headMesh, materials: [whiteFurMat])
        head.position = [-0.09, 0.01, 0.03]
        head.orientation = simd_quatf(angle: Float.pi * 0.1, axis: [0, 0, 1])
        addChild(head)
        self.headModel = head
        
        let earMesh = MeshResource.generateBox(size: [0.022, 0.025, 0.014], cornerRadius: 0.003)
        let leftEar = ModelEntity(mesh: earMesh, materials: [gingerMat])
        leftEar.position = [-0.02, 0.045, -0.015]
        leftEar.orientation = simd_quatf(angle: Float.pi * 0.2, axis: [0, 0, 1])
        head.addChild(leftEar)
        
        let rightEar = ModelEntity(mesh: earMesh, materials: [whiteFurMat])
        rightEar.position = [0.025, 0.045, 0.01]
        rightEar.orientation = simd_quatf(angle: -Float.pi * 0.15, axis: [0, 0, 1])
        head.addChild(rightEar)
        
        // Closed sleeping eyes
        let eyeMesh = MeshResource.generateBox(size: [0.016, 0.003, 0.002], cornerRadius: 0.001)
        let leftEye = ModelEntity(mesh: eyeMesh, materials: [mats.vinylRecord])
        leftEye.position = [-0.035, 0.005, 0.045]
        head.addChild(leftEye)
        
        let rightEye = ModelEntity(mesh: eyeMesh, materials: [mats.vinylRecord])
        rightEye.position = [-0.005, 0.005, 0.05]
        head.addChild(rightEye)
        
        var noseMat = PhysicallyBasedMaterial()
        noseMat.baseColor = .init(tint: NSColor(red: 0.95, green: 0.72, blue: 0.72, alpha: 1.0))
        let nose = ModelEntity(mesh: .generateSphere(radius: 0.004), materials: [noseMat])
        nose.position = [-0.02, -0.008, 0.052]
        head.addChild(nose)
        
        // 3. Curled Tail
        let tailMesh = MeshResource.generateCylinder(height: 0.14, radius: 0.016)
        let tail = ModelEntity(mesh: tailMesh, materials: [gingerMat])
        tail.orientation = simd_quatf(angle: Float.pi * 0.45, axis: [0, 0, 1]) * simd_quatf(angle: Float.pi * 0.35, axis: [0, 1, 0])
        tail.position = [0.08, -0.015, -0.05]
        addChild(tail)
        
        let tip = ModelEntity(mesh: .generateSphere(radius: 0.018), materials: [whiteFurMat])
        tip.position = [0, 0.07, 0]
        tail.addChild(tip)
        
        // 4. Interactive Collider and Input Target
        let collisionShape = ShapeResource.generateSphere(radius: 0.14)
        self.components.set(CollisionComponent(shapes: [collisionShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_cookie",
            displayName: "Cookie",
            accessibilityLabel: "Cookie the sleeping calico cat",
            category: .special,
            allowsDragging: false,
            allowsRotation: false,
            allowsScaling: false,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY + BedEntity.frameHeight + 0.16
        ))
    }
    
    private func startBreathingAnimation() {
        Task { @MainActor [weak self] in
            var t: Float = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard let self = self, let body = self.bodyModel else { break }
                t += 0.05
                let breathScale = 1.0 + sin(t * 1.8) * 0.035
                body.scale = [1.0, breathScale, 1.0]
            }
        }
    }
    
    func pet() {
        guard !isPurring else { return }
        isPurring = true
        let originalY = self.position.y
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.position.y = originalY + 0.025
            self.scale = [1.04, 1.04, 1.04]
            try? await Task.sleep(nanoseconds: 180_000_000)
            self.position.y = originalY
            self.scale = [1.0, 1.0, 1.0]
            try? await Task.sleep(nanoseconds: 200_000_000)
            self.isPurring = false
        }
    }
    
    /// Cookie reacts to moved objects in the room by turning head curiously
    func curiousLook(at targetPosition: SIMD3<Float>) {
        guard !isCuriousLooking, let head = headModel else { return }
        isCuriousLooking = true
        
        let delta = targetPosition - self.position
        let angleY = atan2(delta.x, delta.z)
        let clampedAngle = min(max(angleY * 0.35, -0.5), 0.5)
        
        Task { @MainActor [weak self] in
            guard let self = self, let head = self.headModel else { return }
            head.orientation = simd_quatf(angle: clampedAngle, axis: [0, 1, 0]) * simd_quatf(angle: Float.pi * 0.08, axis: [0, 0, 1])
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            head.orientation = simd_quatf(angle: Float.pi * 0.1, axis: [0, 0, 1])
            self.isCuriousLooking = false
        }
    }
}

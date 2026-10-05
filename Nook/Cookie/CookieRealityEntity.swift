import RealityKit
import AppKit

/// Builds the physical 3D Cookie the cat companion residing in the miniature room:
/// - Curved calico body with warm ginger and white patches
/// - Tucked head, tiny sleeping ears, closed eyes
/// - Curled tail wrapping along the body
/// - Gentle subtle procedural breathing idle animation
/// - Reactive curious look-at animation when room objects are placed or moved
/// - Smooth locomotion between bed and desk edge
/// - Interactive hit-testing target for petting with purr reactions
@MainActor
public final class CookieRealityEntity: Entity {
    
    private var bodyModel: ModelEntity?
    private var headModel: ModelEntity?
    private var tailModel: ModelEntity?
    private var isPurring: Bool = false
    private var isCuriousLooking: Bool = false
    private var isMoving: Bool = false
    
    // Sleeping spot on daybed (default reference position)
    public static let bedPerchPos = SIMD3<Float>(0.48, 0.28 + 0.28 + 0.16 + 0.045, -0.78)
    public static let bedPerchRot = simd_quatf(angle: -Float.pi * 0.15, axis: [0, 1, 0])
    
    // Alert sitting spot near the desk edge of the bed
    public static let deskObservingPos = SIMD3<Float>(-0.06, 0.28 + 0.28 + 0.16 + 0.045, -0.74)
    public static let deskObservingRot = simd_quatf(angle: Float.pi * 0.18, axis: [0, 1, 0])
    
    public required init() {
        super.init()
        self.name = "prop_cookie"
        buildCookie()
        startBreathingAnimation()
    }
    
    private func buildCookie() {
        let mats = RoomMaterials.shared
        
        self.position = Self.bedPerchPos
        self.orientation = Self.bedPerchRot
        
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
        self.tailModel = tail
        
        let tip = ModelEntity(mesh: .generateSphere(radius: 0.018), materials: [whiteFurMat])
        tip.position = [0, 0.07, 0]
        tail.addChild(tip)
        
        // 4. Interactive Collider and Input Target
        let collisionShape = ShapeResource.generateSphere(radius: 0.15)
        self.components.set(CollisionComponent(shapes: [collisionShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_cookie",
            displayName: "Cookie",
            accessibilityLabel: "Cookie the calico cat",
            category: .special,
            allowsDragging: false,
            allowsRotation: false,
            allowsScaling: false,
            defaultPosition: Self.bedPerchPos,
            defaultOrientation: Self.bedPerchRot,
            restingSurfaceY: Self.bedPerchPos.y
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
    
    // MARK: - Reactive Behaviors
    
    public func pet() {
        guard !isPurring else { return }
        isPurring = true
        let originalY = self.position.y
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Happy purr bounce
            self.position.y = originalY + 0.022
            self.scale = [1.05, 1.05, 1.05]
            try? await Task.sleep(nanoseconds: 180_000_000)
            self.position.y = originalY
            self.scale = [1.0, 1.0, 1.0]
            try? await Task.sleep(nanoseconds: 200_000_000)
            self.isPurring = false
        }
    }
    
    /// Cookie reacts to a newly created or moved object by turning head curiously toward it.
    public func curiousLook(at targetPosition: SIMD3<Float>) {
        guard !isCuriousLooking, let head = headModel else { return }
        isCuriousLooking = true
        
        let delta = targetPosition - self.position
        let angleY = atan2(delta.x, delta.z)
        let clampedAngle = min(max(angleY * 0.40, -0.6), 0.6)
        
        Task { @MainActor [weak self] in
            guard let self = self, let head = self.headModel else { return }
            head.orientation = simd_quatf(angle: clampedAngle, axis: [0, 1, 0]) * simd_quatf(angle: Float.pi * 0.06, axis: [0, 0, 1])
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            head.orientation = simd_quatf(angle: Float.pi * 0.1, axis: [0, 0, 1])
            self.isCuriousLooking = false
        }
    }
    
    /// Smoothly walks / shifts Cookie closer to observe recent activity.
    public func shiftTowardDesk() {
        guard !isMoving else { return }
        isMoving = true
        
        let startPos = self.position
        let targetPos = Self.deskObservingPos
        let targetRot = Self.deskObservingRot
        
        Task { @MainActor [weak self] in
            let steps = 16
            let interval = UInt64(30_000_000) // ~0.48s total
            
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: interval)
                guard let self = self else { return }
                let t = Float(i) / Float(steps)
                let ease = sin(t * Float.pi * 0.5)
                
                // Subtle walking bob
                let bob = sin(t * Float.pi * 4.0) * 0.012
                self.position = simd_mix(startPos, targetPos, SIMD3<Float>(ease, ease, ease))
                self.position.y += bob
                self.orientation = simd_slerp(Self.bedPerchRot, targetRot, ease)
            }
            
            self?.position = targetPos
            self?.orientation = targetRot
            self?.isMoving = false
        }
    }
    
    /// Returns Cookie peacefully to the sleeping corner on the bed.
    public func returnToBedCorner() {
        guard !isMoving else { return }
        isMoving = true
        
        let startPos = self.position
        let targetPos = Self.bedPerchPos
        let targetRot = Self.bedPerchRot
        
        Task { @MainActor [weak self] in
            let steps = 16
            let interval = UInt64(30_000_000)
            
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: interval)
                guard let self = self else { return }
                let t = Float(i) / Float(steps)
                let ease = sin(t * Float.pi * 0.5)
                let bob = sin(t * Float.pi * 4.0) * 0.012
                self.position = simd_mix(startPos, targetPos, SIMD3<Float>(ease, ease, ease))
                self.position.y += bob
                self.orientation = simd_slerp(targetRot, Self.bedPerchRot, ease)
            }
            
            self?.position = targetPos
            self?.orientation = targetRot
            self?.isMoving = false
        }
    }
    
    /// Briefly looks toward where an object was just deleted.
    public func lookAtDeleted(lastPosition: SIMD3<Float>) {
        curiousLook(at: lastPosition)
    }
    
    /// Cookie falls asleep comfortably in the bed corner when the room has been inactive.
    public func sleep() {
        guard !isMoving else { return }
        returnToBedCorner()
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            self?.headModel?.orientation = simd_quatf(angle: Float.pi * 0.14, axis: [0, 0, 1])
        }
    }
    
    /// Cookie wakes up and stretches slightly when the user returns.
    public func wake() {
        guard !isMoving else { return }
        Task { @MainActor [weak self] in
            self?.headModel?.orientation = simd_quatf(angle: Float.pi * 0.05, axis: [0, 0, 1])
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self?.headModel?.orientation = simd_quatf(angle: Float.pi * 0.1, axis: [0, 0, 1])
        }
    }
    
    /// Cookie celebrates happily when a thought or goal is completed.
    public func happy() {
        pet()
    }
}

// MARK: - Future AI Extension Point Architecture

/// Protocol defining the extension point where an optional AI module could later understand user activity.
/// Strictly local, non-networked in v1.
protocol CookieIntelligenceProvider: Sendable {
    func evaluateActivity(recentEvents: [RoomEvent], currentMood: CookieMood) -> CookieMood
}

/// Default local deterministic behavioral provider for Cookie. Zero cloud calls.
final class LocalDeterministicCookieIntelligence: CookieIntelligenceProvider {
    init() {}
    
    public func evaluateActivity(recentEvents: [RoomEvent], currentMood: CookieMood) -> CookieMood {
        let creations = recentEvents.filter {
            if case .itemCreated = $0 { return true }
            return false
        }.count
        
        if creations >= 3 {
            return .curious
        }
        return .idle
    }
}

import RealityKit
import AppKit
import Foundation

/// COOKIE: The miniature 3D companion cat living inside Nook's room diorama.
///
/// Designed to closely match the primary visual reference:
/// - Chibi silhouette with disproportionately large, smooth rounded mochi head
/// - Soft warm cream/off-white fur (#F7F0E8) with a velvety matte toy finish
/// - Two large glossy black bead eyes with subtle specular catchlights
/// - Cute iconic "ω" curved cat smile
/// - Soft diffused pink cheek blush integrated flush into cheek curvature
/// - Large rounded triangular ears with muted pink inner ear cavities
/// - Compact chubby sitting body with short limbs, front paws, and sitting feet
/// - Graceful curved tail with a soft rounded tip
/// - Warm subtle fill lighting for that cozy miniature toy glow
///
/// Hierarchical Anatomical Rig:
/// CookieRoot
/// ├── Body
/// │   └── BellyPuff
/// ├── Head
/// │   ├── LeftEar (Outer + Inner Pink)
/// │   ├── RightEar (Outer + Inner Pink)
/// │   ├── LeftEye (Glossy Bead + Catchlight)
/// │   ├── RightEye (Glossy Bead + Catchlight)
/// │   ├── Muzzle (Subtle Anchor)
/// │   ├── Mouth (ω Smile Curves)
/// │   ├── LeftCheek (Diffuse Blush)
/// │   └── RightCheek (Diffuse Blush)
/// ├── LeftFrontPaw (With Pointing Digit)
/// ├── RightFrontPaw
/// ├── LeftFoot (Sitting Haunch + Rounded Toes)
/// ├── RightFoot (Sitting Haunch + Rounded Toes)
/// └── Tail
///     ├── TailBase
///     ├── TailMid
///     └── TailTip
@MainActor
public final class CookieRealityEntity: Entity {
    
    // MARK: - Anatomical Rig References
    
    public private(set) var bodyModel: ModelEntity!
    public private(set) var bellyModel: ModelEntity!
    
    public private(set) var headModel: ModelEntity!
    public private(set) var leftEarModel: ModelEntity!
    public private(set) var leftInnerEarModel: ModelEntity!
    public private(set) var rightEarModel: ModelEntity!
    public private(set) var rightInnerEarModel: ModelEntity!
    
    public private(set) var leftEyeModel: ModelEntity!
    public private(set) var leftEyeGlintModel: ModelEntity!
    public private(set) var rightEyeModel: ModelEntity!
    public private(set) var rightEyeGlintModel: ModelEntity!
    
    public private(set) var muzzleModel: ModelEntity!
    public private(set) var mouthModel: Entity!
    public private(set) var leftLipModel: ModelEntity!
    public private(set) var rightLipModel: ModelEntity!
    public private(set) var leftCheekModel: ModelEntity!
    public private(set) var rightCheekModel: ModelEntity!
    
    public private(set) var leftFrontPawModel: ModelEntity!
    public private(set) var leftPawPointerModel: ModelEntity!
    public private(set) var rightFrontPawModel: ModelEntity!
    
    public private(set) var leftFootModel: ModelEntity!
    public private(set) var rightFootModel: ModelEntity!
    
    public private(set) var tailModel: Entity!
    public private(set) var tailBaseModel: ModelEntity!
    public private(set) var tailMidModel: ModelEntity!
    public private(set) var tailTipModel: ModelEntity!
    
    // MARK: - Controllers & Behavioral State
    
    public private(set) var animationController: CookieAnimationController?
    public private(set) var navigationController: CookieNavigationController?
    public private(set) var isSelected: Bool = false
    public private(set) var isHovered: Bool = false
    
    public var rotationAngleY: Float {
        let fwd = orientation.act(SIMD3<Float>(0, 0, 1))
        return atan2(fwd.x, fwd.z)
    }
    
    public private(set) var currentMoodRaw: String = CookieMood.idle.rawValue
    var currentMood: CookieMood = .idle {
        didSet { currentMoodRaw = currentMood.rawValue }
    }
    var currentPosture: CookiePosture = .sitting
    
    private var isPurring: Bool = false
    private var isCuriousLooking: Bool = false
    private var isMoving: Bool = false
    private var isBlinking: Bool = false
    private var isPointing: Bool = false
    
    private var breathingTask: Task<Void, Never>?
    private var blinkTask: Task<Void, Never>?
    private var tailTask: Task<Void, Never>?
    private var reduceMotionObserver: NSObjectProtocol?
    
    // MARK: - Diorama Anchor Positions
    
    /// Default perch position on the daybed mattress surface (comfortably centered)
    public static let bedPerchPos = SIMD3<Float>(0.48, 0.605, -0.66)
    public static let bedPerchRot = simd_quatf(angle: Float.pi * 0.20, axis: [0, 1, 0])
    
    /// Alert desk-observing position along the edge of the bed
    public static let deskObservingPos = SIMD3<Float>(-0.08, 0.605, -0.65)
    public static let deskObservingRot = simd_quatf(angle: Float.pi * 0.32, axis: [0, 1, 0])
    
    // MARK: - Initializer
    
    public required init() {
        super.init()
        self.name = "prop_cookie"
        
        buildCookieRig()
        setupInteractionComponents()
        setupReduceMotionObserver()
        
        let animCtrl = CookieAnimationController(entity: self)
        self.animationController = animCtrl
        let navCtrl = CookieNavigationController(entity: self)
        self.navigationController = navCtrl
        
        startBreathingAnimation()
        startBlinkAnimation()
        startTailAnimation()
    }
    
    isolated deinit {
        breathingTask?.cancel()
        blinkTask?.cancel()
        tailTask?.cancel()
        if let observer = reduceMotionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - 3D Rig Construction
    
    private func buildCookieRig() {
        // Restore deterministic local memory if available, or fall back to bed perch
        let saved = CookieMemoryStore.shared.load()
        let safePos = CookieNavigationController.clampToWalkable(saved.positionSIMD)
        self.position = safePos
        self.orientation = simd_quatf(angle: saved.rotationY, axis: [0, 1, 0])
        
        // --- 1. Materials Matching Visual Reference ---
        // Warm off-white / cream fur (#FAF4EE / #F7F0E8) - soft velvety matte toy finish
        var creamFurMat = PhysicallyBasedMaterial()
        creamFurMat.baseColor = .init(tint: NSColor(srgbRed: 0.985, green: 0.962, blue: 0.940, alpha: 1.0))
        creamFurMat.roughness = .init(floatLiteral: 0.74)
        creamFurMat.specular = .init(floatLiteral: 0.12)
        
        // Subtle lighter cream for belly puff
        var bellyFurMat = PhysicallyBasedMaterial()
        bellyFurMat.baseColor = .init(tint: NSColor(srgbRed: 0.992, green: 0.976, blue: 0.958, alpha: 1.0))
        bellyFurMat.roughness = .init(floatLiteral: 0.76)
        bellyFurMat.specular = .init(floatLiteral: 0.10)
        
        // Soft muted pastel pink inner ear cavity (#F6A8B4)
        var innerEarMat = PhysicallyBasedMaterial()
        innerEarMat.baseColor = .init(tint: NSColor(srgbRed: 0.975, green: 0.700, blue: 0.745, alpha: 1.0))
        innerEarMat.roughness = .init(floatLiteral: 0.80)
        innerEarMat.specular = .init(floatLiteral: 0.06)
        
        // Soft pastel peach-pink blush cheeks (#FFB6C1)
        var blushCheekMat = PhysicallyBasedMaterial()
        blushCheekMat.baseColor = .init(tint: NSColor(srgbRed: 0.995, green: 0.700, blue: 0.740, alpha: 0.82))
        blushCheekMat.roughness = .init(floatLiteral: 0.92)
        blushCheekMat.specular = .init(floatLiteral: 0.0)
        
        // Large glossy obsidian black eyes with pristine specular reflection
        var glossyEyeMat = PhysicallyBasedMaterial()
        glossyEyeMat.baseColor = .init(tint: NSColor(srgbRed: 0.02, green: 0.02, blue: 0.025, alpha: 1.0))
        glossyEyeMat.roughness = .init(floatLiteral: 0.01)
        glossyEyeMat.specular = .init(floatLiteral: 1.0)
        glossyEyeMat.clearcoat = .init(floatLiteral: 1.0)
        
        // Eye specular catchlight / glint
        var eyeGlintMat = PhysicallyBasedMaterial()
        eyeGlintMat.baseColor = .init(tint: NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        eyeGlintMat.roughness = .init(floatLiteral: 0.05)
        eyeGlintMat.emissiveColor = .init(color: NSColor(srgbRed: 0.98, green: 0.98, blue: 0.98, alpha: 1.0))
        
        // Soft charcoal brown mouth
        var mouthMat = PhysicallyBasedMaterial()
        mouthMat.baseColor = .init(tint: NSColor(srgbRed: 0.08, green: 0.06, blue: 0.06, alpha: 1.0))
        mouthMat.roughness = .init(floatLiteral: 0.60)
        
        // --- 2. Body (Compact Chubby Sitting Form with Wide Haunches) ---
        let bodyRoot = ModelEntity()
        bodyRoot.name = "Body"
        bodyRoot.position = [0, 0.044, 0]
        addChild(bodyRoot)
        self.bodyModel = bodyRoot
        
        // Upper torso sphere
        let upperTorsoMesh = MeshResource.generateSphere(radius: 0.050)
        let upperTorso = ModelEntity(mesh: upperTorsoMesh, materials: [creamFurMat])
        upperTorso.scale = [0.98, 1.06, 0.94]
        upperTorso.position = [0, 0.003, -0.004]
        bodyRoot.addChild(upperTorso)
        
        // Lower sitting haunches / base sphere
        let lowerHipsMesh = MeshResource.generateSphere(radius: 0.054)
        let lowerHips = ModelEntity(mesh: lowerHipsMesh, materials: [creamFurMat])
        lowerHips.scale = [1.10, 0.74, 1.06]
        lowerHips.position = [0, -0.022, 0]
        bodyRoot.addChild(lowerHips)
        
        // Left & Right Chubby Sitting Haunches (classic wide chibi teardrop base)
        let haunchMesh = MeshResource.generateSphere(radius: 0.032)
        let leftHaunch = ModelEntity(mesh: haunchMesh, materials: [creamFurMat])
        leftHaunch.scale = [0.92, 0.80, 1.08]
        leftHaunch.position = [-0.046, -0.024, 0.006]
        bodyRoot.addChild(leftHaunch)
        
        let rightHaunch = ModelEntity(mesh: haunchMesh, materials: [creamFurMat])
        rightHaunch.scale = [0.92, 0.80, 1.08]
        rightHaunch.position = [0.046, -0.024, 0.006]
        bodyRoot.addChild(rightHaunch)
        
        // Soft cream tummy puff
        let bellyMesh = MeshResource.generateSphere(radius: 0.040)
        let belly = ModelEntity(mesh: bellyMesh, materials: [bellyFurMat])
        belly.name = "BellyPuff"
        belly.scale = [0.88, 0.94, 0.38]
        belly.position = [0, -0.006, 0.036]
        bodyRoot.addChild(belly)
        self.bellyModel = belly
        
        // --- 3. Head (Disproportionately Large Chibi Head with Wide Rounded Cheeks) ---
        // Ultra-smooth squashed mochi sphere - width > height
        let headRoot = ModelEntity()
        headRoot.name = "Head"
        headRoot.position = [0, 0.100, 0.006]
        addChild(headRoot)
        self.headModel = headRoot
        
        let headSphereMesh = MeshResource.generateSphere(radius: 0.063)
        let headSphere = ModelEntity(mesh: headSphereMesh, materials: [creamFurMat])
        headSphere.scale = [1.25, 0.97, 1.06]
        headRoot.addChild(headSphere)
        
        // --- 4. Ears (Organic Rounded Triangular with Recessed Muted Pink Insets) ---
        // Smooth rounded wedge with dome apex cap and recessed inner pink cavity
        let earBaseMesh = MeshResource.generateBox(size: [0.036, 0.034, 0.012], cornerRadius: 0.008)
        let earApexMesh = MeshResource.generateSphere(radius: 0.010)
        let innerEarMesh = MeshResource.generateBox(size: [0.022, 0.020, 0.004], cornerRadius: 0.006)
        
        // Left Ear
        let leftEar = ModelEntity(mesh: earBaseMesh, materials: [creamFurMat])
        leftEar.name = "LeftEar"
        leftEar.position = [-0.046, 0.044, -0.008]
        leftEar.orientation = simd_quatf(angle: 0.52, axis: [0, 0, 1]) * simd_quatf(angle: -0.12, axis: [1, 0, 0]) * simd_quatf(angle: -0.08, axis: [0, 1, 0])
        headRoot.addChild(leftEar)
        self.leftEarModel = leftEar
        
        let leftEarApex = ModelEntity(mesh: earApexMesh, materials: [creamFurMat])
        leftEarApex.position = [0, 0.016, 0]
        leftEarApex.scale = [0.85, 0.90, 0.45]
        leftEar.addChild(leftEarApex)
        
        let leftInnerEar = ModelEntity(mesh: innerEarMesh, materials: [innerEarMat])
        leftInnerEar.name = "LeftInnerEar"
        leftInnerEar.position = [0, 0.002, 0.0045]
        leftEar.addChild(leftInnerEar)
        self.leftInnerEarModel = leftInnerEar
        
        // Right Ear
        let rightEar = ModelEntity(mesh: earBaseMesh, materials: [creamFurMat])
        rightEar.name = "RightEar"
        rightEar.position = [0.046, 0.044, -0.008]
        rightEar.orientation = simd_quatf(angle: -0.52, axis: [0, 0, 1]) * simd_quatf(angle: -0.12, axis: [1, 0, 0]) * simd_quatf(angle: 0.08, axis: [0, 1, 0])
        headRoot.addChild(rightEar)
        self.rightEarModel = rightEar
        
        let rightEarApex = ModelEntity(mesh: earApexMesh, materials: [creamFurMat])
        rightEarApex.position = [0, 0.016, 0]
        rightEarApex.scale = [0.85, 0.90, 0.45]
        rightEar.addChild(rightEarApex)
        
        let rightInnerEar = ModelEntity(mesh: innerEarMesh, materials: [innerEarMat])
        rightInnerEar.name = "RightInnerEar"
        rightInnerEar.position = [0, 0.002, 0.0045]
        rightEar.addChild(rightInnerEar)
        self.rightInnerEarModel = rightInnerEar
        
        // --- 5. Eyes (Large Glossy Black Beads with Dual Sparkling Catchlights) ---
        let eyeMesh = MeshResource.generateSphere(radius: 0.0135)
        let glintPrimaryMesh = MeshResource.generateSphere(radius: 0.0038)
        let glintSecondaryMesh = MeshResource.generateSphere(radius: 0.0018)
        
        // Left Eye (centered cute distance)
        let leftEye = ModelEntity(mesh: eyeMesh, materials: [glossyEyeMat])
        leftEye.name = "LeftEye"
        leftEye.position = [-0.032, 0.007, 0.058]
        headRoot.addChild(leftEye)
        self.leftEyeModel = leftEye
        
        let leftGlintPrimary = ModelEntity(mesh: glintPrimaryMesh, materials: [eyeGlintMat])
        leftGlintPrimary.position = [0.0042, 0.0048, 0.0116]
        leftEye.addChild(leftGlintPrimary)
        self.leftEyeGlintModel = leftGlintPrimary
        
        let leftGlintSecondary = ModelEntity(mesh: glintSecondaryMesh, materials: [eyeGlintMat])
        leftGlintSecondary.position = [0.0048, -0.0042, 0.0110]
        leftEye.addChild(leftGlintSecondary)
        
        // Right Eye (centered cute distance)
        let rightEye = ModelEntity(mesh: eyeMesh, materials: [glossyEyeMat])
        rightEye.name = "RightEye"
        rightEye.position = [0.032, 0.007, 0.058]
        headRoot.addChild(rightEye)
        self.rightEyeModel = rightEye
        
        let rightGlintPrimary = ModelEntity(mesh: glintPrimaryMesh, materials: [eyeGlintMat])
        rightGlintPrimary.position = [0.0042, 0.0048, 0.0116]
        rightEye.addChild(rightGlintPrimary)
        self.rightEyeGlintModel = rightGlintPrimary
        
        let rightGlintSecondary = ModelEntity(mesh: glintSecondaryMesh, materials: [eyeGlintMat])
        rightGlintSecondary.position = [0.0048, -0.0042, 0.0110]
        rightEye.addChild(rightGlintSecondary)
        
        // --- 6. Cheeks (Soft Diffused Pastel Pink Blush on Wide Outer Cheeks) ---
        // Soft rounded pink pill blush positioned on chubby outer cheeks
        let cheekMesh = MeshResource.generateSphere(radius: 0.0130)
        
        let leftCheek = ModelEntity(mesh: cheekMesh, materials: [blushCheekMat])
        leftCheek.name = "LeftCheek"
        leftCheek.scale = [1.10, 0.88, 0.16]
        leftCheek.position = [-0.046, -0.008, 0.054]
        leftCheek.orientation = simd_quatf(angle: -0.28, axis: [0, 1, 0])
        headRoot.addChild(leftCheek)
        self.leftCheekModel = leftCheek
        
        let rightCheek = ModelEntity(mesh: cheekMesh, materials: [blushCheekMat])
        rightCheek.name = "RightCheek"
        rightCheek.scale = [1.10, 0.88, 0.16]
        rightCheek.position = [0.046, -0.008, 0.054]
        rightCheek.orientation = simd_quatf(angle: 0.28, axis: [0, 1, 0])
        headRoot.addChild(rightCheek)
        self.rightCheekModel = rightCheek
        
        // --- 7. Muzzle & Mouth (True Sweet "ω" Cat Smile Clearly Visible on Face) ---
        let muzzleAnchor = ModelEntity()
        muzzleAnchor.name = "Muzzle"
        headRoot.addChild(muzzleAnchor)
        self.muzzleModel = muzzleAnchor
        
        let mouthContainer = Entity()
        mouthContainer.name = "Mouth"
        headRoot.addChild(mouthContainer)
        self.mouthModel = mouthContainer
        
        // Center cusp dot
        let noseMesh = MeshResource.generateSphere(radius: 0.0016)
        let nose = ModelEntity(mesh: noseMesh, materials: [mouthMat])
        nose.position = [0, -0.0068, 0.0668]
        mouthContainer.addChild(nose)
        
        // Two delicate upward-curving arcs forming the true "ω" cat smile
        let lipSegMesh = MeshResource.generateBox(size: [0.0048, 0.0022, 0.0020], cornerRadius: 0.001)
        
        // Left lip arc: inner segment dips down, outer segment curves up
        let leftLipInner = ModelEntity(mesh: lipSegMesh, materials: [mouthMat])
        leftLipInner.position = [-0.0024, -0.0082, 0.0665]
        leftLipInner.orientation = simd_quatf(angle: 0.52, axis: [0, 0, 1])
        mouthContainer.addChild(leftLipInner)
        self.leftLipModel = leftLipInner
        
        let leftLipOuter = ModelEntity(mesh: lipSegMesh, materials: [mouthMat])
        leftLipOuter.position = [-0.0064, -0.0070, 0.0658]
        leftLipOuter.orientation = simd_quatf(angle: -0.58, axis: [0, 0, 1])
        mouthContainer.addChild(leftLipOuter)
        
        // Right lip arc: inner segment dips down, outer segment curves up
        let rightLipInner = ModelEntity(mesh: lipSegMesh, materials: [mouthMat])
        rightLipInner.position = [0.0024, -0.0082, 0.0665]
        rightLipInner.orientation = simd_quatf(angle: -0.52, axis: [0, 0, 1])
        mouthContainer.addChild(rightLipInner)
        self.rightLipModel = rightLipInner
        
        let rightLipOuter = ModelEntity(mesh: lipSegMesh, materials: [mouthMat])
        rightLipOuter.position = [0.0064, -0.0070, 0.0658]
        rightLipOuter.orientation = simd_quatf(angle: 0.58, axis: [0, 0, 1])
        mouthContainer.addChild(rightLipOuter)
        
        // --- 8. Front Paws (Left with Raised Pointing Gesture, Right Seated Forward) ---
        let armMesh = MeshResource.generateBox(size: [0.022, 0.046, 0.022], cornerRadius: 0.010)
        let pawTipMesh = MeshResource.generateSphere(radius: 0.013)
        
        // Left Front Paw (Cookie's right arm, viewer's left - raised horizontal pointing pose matching reference art!)
        let leftPaw = ModelEntity(mesh: armMesh, materials: [creamFurMat])
        leftPaw.name = "LeftFrontPaw"
        leftPaw.position = [-0.042, 0.044, 0.028]
        // Rotated around Z by -1.48 so negative Y axis reaches out to -X (viewer's left), angled slightly forward
        leftPaw.orientation = simd_quatf(angle: -1.46, axis: [0, 0, 1]) * simd_quatf(angle: -0.28, axis: [0, 1, 0]) * simd_quatf(angle: 0.12, axis: [1, 0, 0])
        addChild(leftPaw)
        self.leftFrontPawModel = leftPaw
        
        let leftPawTip = ModelEntity(mesh: pawTipMesh, materials: [creamFurMat])
        leftPawTip.position = [0, -0.022, 0.002]
        leftPaw.addChild(leftPawTip)
        
        // Adorable rounded pointing digit extended along pointing direction (-X)
        let pointerMesh = MeshResource.generateBox(size: [0.010, 0.022, 0.010], cornerRadius: 0.004)
        let leftPointer = ModelEntity(mesh: pointerMesh, materials: [creamFurMat])
        leftPointer.position = [0, -0.034, 0.002]
        leftPaw.addChild(leftPointer)
        self.leftPawPointerModel = leftPointer
        
        // Right Front Paw (Cookie's left arm, viewer's right - resting comfortably down against side/thigh)
        let rightPaw = ModelEntity(mesh: armMesh, materials: [creamFurMat])
        rightPaw.name = "RightFrontPaw"
        rightPaw.position = [0.038, 0.028, 0.032]
        rightPaw.orientation = simd_quatf(angle: -0.22, axis: [1, 0, 0]) * simd_quatf(angle: -0.22, axis: [0, 0, 1])
        addChild(rightPaw)
        self.rightFrontPawModel = rightPaw
        
        let rightPawTip = ModelEntity(mesh: pawTipMesh, materials: [creamFurMat])
        rightPawTip.position = [0, -0.020, 0.004]
        rightPaw.addChild(rightPawTip)
        
        // --- 9. Hind Feet (Chubby Sitting Paws Visible in Front Lap) ---
        let footMesh = MeshResource.generateBox(size: [0.028, 0.018, 0.040], cornerRadius: 0.009)
        let toeMesh = MeshResource.generateSphere(radius: 0.0055)
        
        // Left Foot (sitting in lap)
        let leftFoot = ModelEntity(mesh: footMesh, materials: [creamFurMat])
        leftFoot.name = "LeftFoot"
        leftFoot.position = [-0.018, 0.010, 0.042]
        addChild(leftFoot)
        self.leftFootModel = leftFoot
        
        for toeIdx in [-1, 0, 1] {
            let toe = ModelEntity(mesh: toeMesh, materials: [creamFurMat])
            toe.position = [Float(toeIdx) * 0.0075, -0.002, 0.019]
            leftFoot.addChild(toe)
        }
        
        // Right Foot (sitting in lap)
        let rightFoot = ModelEntity(mesh: footMesh, materials: [creamFurMat])
        rightFoot.name = "RightFoot"
        rightFoot.position = [0.018, 0.010, 0.042]
        addChild(rightFoot)
        self.rightFootModel = rightFoot
        
        for toeIdx in [-1, 0, 1] {
            let toe = ModelEntity(mesh: toeMesh, materials: [creamFurMat])
            toe.position = [Float(toeIdx) * 0.0075, -0.002, 0.019]
            rightFoot.addChild(toe)
        }
        
        // --- 10. Tail (Smooth Articulated Upright Curved Hook Beside Body) ---
        let tailContainer = Entity()
        tailContainer.name = "Tail"
        addChild(tailContainer)
        self.tailModel = tailContainer
        
        let tailBaseMesh = MeshResource.generateCylinder(height: 0.040, radius: 0.013)
        let tailBase = ModelEntity(mesh: tailBaseMesh, materials: [creamFurMat])
        tailBase.name = "TailBase"
        tailBase.position = [0.046, 0.018, -0.015]
        tailBase.orientation = simd_quatf(angle: 0.55, axis: [1, 0, 0]) * simd_quatf(angle: 0.52, axis: [0, 0, 1])
        tailContainer.addChild(tailBase)
        self.tailBaseModel = tailBase
        
        let tailMidMesh = MeshResource.generateCylinder(height: 0.038, radius: 0.011)
        let tailMid = ModelEntity(mesh: tailMidMesh, materials: [creamFurMat])
        tailMid.name = "TailMid"
        tailMid.position = [0, 0.034, 0]
        tailMid.orientation = simd_quatf(angle: -0.44, axis: [1, 0, 0]) * simd_quatf(angle: -0.28, axis: [0, 0, 1])
        tailBase.addChild(tailMid)
        self.tailMidModel = tailMid
        
        let tailTipMesh = MeshResource.generateSphere(radius: 0.0125)
        let tailTip = ModelEntity(mesh: tailTipMesh, materials: [creamFurMat])
        tailTip.name = "TailTip"
        tailTip.position = [0, 0.034, 0]
        tailMid.addChild(tailTip)
        self.tailTipModel = tailTip
        
        // --- 11. Warm Silhouette Rim & Fill Light (Toy Glow) ---
        let cookieGlow = PointLight()
        cookieGlow.light.color = .init(red: 1.0, green: 0.94, blue: 0.86, alpha: 1.0)
        cookieGlow.light.intensity = 1100
        cookieGlow.light.attenuationRadius = 1.8
        cookieGlow.position = [-0.14, 0.18, 0.30]
        cookieGlow.name = "cookie_warm_glow"
        addChild(cookieGlow)
        
        let cookieRim = PointLight()
        cookieRim.light.color = .init(red: 1.0, green: 0.90, blue: 0.78, alpha: 1.0)
        cookieRim.light.intensity = 650
        cookieRim.light.attenuationRadius = 1.4
        cookieRim.position = [0.18, 0.14, -0.20]
        cookieRim.name = "cookie_rim_light"
        addChild(cookieRim)
    }
    
    private func setupInteractionComponents() {
        let collisionShape = ShapeResource.generateSphere(radius: 0.14)
        self.components.set(CollisionComponent(shapes: [collisionShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_cookie",
            displayName: "Cookie",
            accessibilityLabel: "Cookie the cream kitten",
            category: .special,
            allowsDragging: true,
            allowsRotation: true,
            allowsScaling: false,
            defaultPosition: Self.bedPerchPos,
            defaultOrientation: Self.bedPerchRot,
            restingSurfaceY: self.position.y
        ))
    }
    
    // MARK: - Reduce Motion Support
    
    private var shouldReduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    
    private func setupReduceMotionObserver() {
        reduceMotionObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.shouldReduceMotion {
                self.bodyModel?.scale = [1.0, 1.0, 1.0]
                self.resetFaceToRest()
            }
        }
    }
    
    // MARK: - Animation Loops
    
    /// Subtle, almost imperceptible breathing oscillation making Cookie feel alive
    private func startBreathingAnimation() {
        breathingTask?.cancel()
        breathingTask = Task { @MainActor [weak self] in
            var t: Float = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 40_000_000)
                guard let self = self, let body = self.bodyModel else { break }
                
                if self.shouldReduceMotion {
                    body.scale = [1.0, 1.0, 1.0]
                    continue
                }
                
                if self.isMoving || self.animationController?.isWalking == true || self.animationController?.isJumping == true || self.animationController?.isDragging == true {
                    continue
                }
                
                t += 0.06
                let breathRate: Float = (self.currentMood == .sleepy || self.currentMood == .resting) ? 0.9 : 1.5
                let breathAmp: Float = (self.currentMood == .sleepy || self.currentMood == .resting) ? 0.015 : 0.022
                let breath = sin(t * breathRate) * breathAmp
                
                body.scale = [1.0 + breath * 0.25, 1.0 + breath, 1.0 + breath * 0.25]
                self.headModel?.position.y = 0.100 + breath * 0.0012
            }
        }
    }
    
    /// Irregular, natural procedural blinking with occasional double-blinks
    private func startBlinkAnimation() {
        blinkTask?.cancel()
        blinkTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                // Irregular randomized interval between 2.2s and 5.5s
                let randomDelay = UInt64.random(in: 2_200_000_000...5_500_000_000)
                try? await Task.sleep(nanoseconds: randomDelay)
                guard let self = self else { break }
                
                guard !self.shouldReduceMotion,
                      self.currentMood != .sleepy,
                      self.currentMood != .resting else { continue }
                
                await self.performBlink()
                
                // 20% chance of a quick, sweet double blink
                if Float.random(in: 0...1) < 0.20 {
                    try? await Task.sleep(nanoseconds: 160_000_000)
                    await self.performBlink()
                }
            }
        }
    }
    
    /// Smooth procedural blink squash and release
    public func blink() {
        Task { @MainActor [weak self] in
            await self?.performBlink()
        }
    }
    
    private func performBlink() async {
        guard !isBlinking,
              let leftEye = leftEyeModel,
              let rightEye = rightEyeModel else { return }
        isBlinking = true
        
        let originalLeftScale = leftEye.scale
        let originalRightScale = rightEye.scale
        
        // Eyelid closing (~50ms)
        leftEye.scale = [originalLeftScale.x, 0.08, originalLeftScale.z]
        rightEye.scale = [originalRightScale.x, 0.08, originalRightScale.z]
        try? await Task.sleep(nanoseconds: 45_000_000)
        
        // Eyelid open (~65ms)
        leftEye.scale = originalLeftScale
        rightEye.scale = originalRightScale
        try? await Task.sleep(nanoseconds: 45_000_000)
        
        self.isBlinking = false
    }
    
    /// Subtle idle tail movement (periodic gentle sways, twitches, and curls)
    private func startTailAnimation() {
        tailTask?.cancel()
        tailTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                let interval = UInt64.random(in: 3_800_000_000...7_200_000_000)
                try? await Task.sleep(nanoseconds: interval)
                guard let self = self else { break }
                
                guard !self.shouldReduceMotion else { continue }
                await self.performTailMotion(.relaxed)
            }
        }
    }
    
/// Distinct tail motions communicating Cookie's emotional mood.
public enum CookieTailMotion: Sendable {
    case happy      // Gentle movement (slow, soft double sway)
    case curious    // Slight twitch (single quick flick)
    case relaxed    // Slow sway (calm sweeping wave)
    case excited    // Faster movement (energetic repeated swishes)
    case sleepy     // Mostly still (tiny subtle twitch or motionless)
}

    public func swishTail(_ motion: CookieTailMotion = .curious) {
        Task { @MainActor [weak self] in
            await self?.performTailMotion(motion)
        }
    }
    
    private func performTailMotion(_ motion: CookieTailMotion) async {
        guard let tailMid = tailMidModel, let tailTip = tailTipModel else { return }
        guard !shouldReduceMotion else { return }
        
        let baseMidRot = tailMid.orientation
        let baseTipRot = tailTip.orientation
        
        switch motion {
        case .sleepy:
            // Mostly still: tiny subtle twitch
            let targetMid = baseMidRot * simd_quatf(angle: 0.05, axis: [0, 1, 0])
            tailMid.orientation = targetMid
            try? await Task.sleep(nanoseconds: 120_000_000)
            tailMid.orientation = baseMidRot
            
        case .curious:
            // Single inquisitive flick
            let angle: Float = 0.22
            let targetMid = baseMidRot * simd_quatf(angle: angle, axis: [0, 1, 0])
            let targetTip = baseTipRot * simd_quatf(angle: angle * 1.3, axis: [0, 0, 1])
            
            let steps = 6
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: 20_000_000)
                let t = Float(i) / Float(steps)
                tailMid.orientation = simd_slerp(baseMidRot, targetMid, t)
                tailTip.orientation = simd_slerp(baseTipRot, targetTip, t)
            }
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: 22_000_000)
                let t = Float(i) / Float(steps)
                tailMid.orientation = simd_slerp(targetMid, baseMidRot, t)
                tailTip.orientation = simd_slerp(targetTip, baseTipRot, t)
            }
            tailMid.orientation = baseMidRot
            tailTip.orientation = baseTipRot
            
        case .relaxed:
            // Slow, calming sway
            let angle: Float = 0.14
            let targetMid = baseMidRot * simd_quatf(angle: angle, axis: [0, 1, 0])
            let steps = 10
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: 35_000_000)
                let t = Float(i) / Float(steps)
                tailMid.orientation = simd_slerp(baseMidRot, targetMid, t)
            }
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: 35_000_000)
                let t = Float(i) / Float(steps)
                tailMid.orientation = simd_slerp(targetMid, baseMidRot, t)
            }
            tailMid.orientation = baseMidRot
            
        case .happy:
            // Gentle double sway
            for cycle in 0..<2 {
                let sign: Float = (cycle % 2 == 0) ? 1.0 : -1.0
                let angle: Float = 0.16 * sign
                let targetMid = baseMidRot * simd_quatf(angle: angle, axis: [0, 1, 0])
                let steps = 6
                for i in 1...steps {
                    try? await Task.sleep(nanoseconds: 22_000_000)
                    let t = Float(i) / Float(steps)
                    tailMid.orientation = simd_slerp(baseMidRot, targetMid, t)
                }
                for i in 1...steps {
                    try? await Task.sleep(nanoseconds: 22_000_000)
                    let t = Float(i) / Float(steps)
                    tailMid.orientation = simd_slerp(targetMid, baseMidRot, t)
                }
            }
            tailMid.orientation = baseMidRot
            
        case .excited:
            // Faster, rhythmic swishes
            for cycle in 0..<3 {
                let sign: Float = (cycle % 2 == 0) ? 1.0 : -1.0
                let angle: Float = 0.28 * sign
                let targetMid = baseMidRot * simd_quatf(angle: angle, axis: [0, 1, 0])
                let targetTip = baseTipRot * simd_quatf(angle: angle * 1.2, axis: [0, 0, 1])
                let steps = 4
                for i in 1...steps {
                    try? await Task.sleep(nanoseconds: 14_000_000)
                    let t = Float(i) / Float(steps)
                    tailMid.orientation = simd_slerp(baseMidRot, targetMid, t)
                    tailTip.orientation = simd_slerp(baseTipRot, targetTip, t)
                }
                for i in 1...steps {
                    try? await Task.sleep(nanoseconds: 14_000_000)
                    let t = Float(i) / Float(steps)
                    tailMid.orientation = simd_slerp(targetMid, baseMidRot, t)
                    tailTip.orientation = simd_slerp(targetTip, baseTipRot, t)
                }
            }
            tailMid.orientation = baseMidRot
            tailTip.orientation = baseTipRot
        }
    }
    
    // MARK: - Emotional & Facial States
    
    /// Sets Cookie's emotional mood with subtle, expressive facial changes.
    func setMood(_ mood: CookieMood, animated: Bool = true) {
        self.currentMood = mood
        
        guard let leftEye = leftEyeModel,
              let rightEye = rightEyeModel,
              let leftCheek = leftCheekModel,
              let rightCheek = rightCheekModel,
              let mouth = mouthModel,
              let leftEar = leftEarModel,
              let rightEar = rightEarModel,
              let head = headModel else { return }
        
        let baseEarLeft = simd_quatf(angle: 0.48, axis: [0, 0, 1]) * simd_quatf(angle: -0.10, axis: [1, 0, 0]) * simd_quatf(angle: -0.08, axis: [0, 1, 0])
        let baseEarRight = simd_quatf(angle: -0.48, axis: [0, 0, 1]) * simd_quatf(angle: -0.10, axis: [1, 0, 0]) * simd_quatf(angle: 0.08, axis: [0, 1, 0])
        
        switch mood {
        case .idle: // Neutral
            leftEye.scale = [1.0, 1.0, 1.0]
            rightEye.scale = [1.0, 1.0, 1.0]
            leftCheek.scale = [1.15, 0.85, 0.12]
            rightCheek.scale = [1.15, 0.85, 0.12]
            mouth.scale = [1.0, 1.0, 1.0]
            leftEar.orientation = baseEarLeft
            rightEar.orientation = baseEarRight
            head.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            
        case .happy:
            // Sweet crescent squint smile & blooming blush
            leftEye.scale = [1.08, 0.38, 1.0]
            rightEye.scale = [1.08, 0.38, 1.0]
            leftCheek.scale = [1.32, 1.05, 0.15]
            rightCheek.scale = [1.32, 1.05, 0.15]
            mouth.scale = [1.15, 1.15, 1.0]
            leftEar.orientation = baseEarLeft * simd_quatf(angle: 0.08, axis: [0, 0, 1])
            rightEar.orientation = baseEarRight * simd_quatf(angle: -0.08, axis: [0, 0, 1])
            
        case .curious:
            // Alert open eyes with classic inquisitive head tilt
            leftEye.scale = [1.08, 1.08, 1.08]
            rightEye.scale = [1.08, 1.08, 1.08]
            leftCheek.scale = [1.15, 0.85, 0.12]
            rightCheek.scale = [1.15, 0.85, 0.12]
            mouth.scale = [1.0, 1.0, 1.0]
            head.orientation = simd_quatf(angle: 0.18, axis: [0, 0, 1]) * simd_quatf(angle: 0.10, axis: [0, 1, 0])
            leftEar.orientation = baseEarLeft * simd_quatf(angle: 0.12, axis: [1, 0, 0])
            
        case .sleepy, .resting:
            // Relaxed sleepy slits & head gently lowered
            leftEye.scale = [1.0, 0.16, 1.0]
            rightEye.scale = [1.0, 0.16, 1.0]
            leftCheek.scale = [0.90, 0.70, 0.10]
            rightCheek.scale = [0.90, 0.70, 0.10]
            mouth.scale = [0.92, 0.92, 1.0]
            head.orientation = simd_quatf(angle: 0.12, axis: [1, 0, 0])
            leftEar.orientation = baseEarLeft * simd_quatf(angle: -0.10, axis: [1, 0, 0])
            rightEar.orientation = baseEarRight * simd_quatf(angle: -0.10, axis: [1, 0, 0])
            
        case .excited:
            // Big sparkly eyes, bright blush, perked posture
            leftEye.scale = [1.16, 1.16, 1.16]
            rightEye.scale = [1.16, 1.16, 1.16]
            leftCheek.scale = [1.35, 1.10, 0.16]
            rightCheek.scale = [1.35, 1.10, 0.16]
            mouth.scale = [1.20, 1.25, 1.0]
            head.orientation = simd_quatf(angle: -0.06, axis: [1, 0, 0])
            setPosture(.pointing, animated: true)
            
        case .surprised:
            // Wide round eyes and small rounded mouth
            leftEye.scale = [1.22, 1.22, 1.22]
            rightEye.scale = [1.22, 1.22, 1.22]
            leftCheek.scale = [1.10, 0.85, 0.12]
            rightCheek.scale = [1.10, 0.85, 0.12]
            mouth.scale = [0.85, 1.30, 1.0]
            head.orientation = simd_quatf(angle: -0.10, axis: [1, 0, 0])
            leftEar.orientation = baseEarLeft * simd_quatf(angle: -0.14, axis: [1, 0, 0])
            rightEar.orientation = baseEarRight * simd_quatf(angle: -0.14, axis: [1, 0, 0])
            
        case .sad:
            // Drooping eyes and soft lowered ears
            leftEye.scale = [0.92, 0.82, 1.0]
            rightEye.scale = [0.92, 0.82, 1.0]
            leftCheek.scale = [0.80, 0.70, 0.10]
            rightCheek.scale = [0.80, 0.70, 0.10]
            mouth.scale = [0.90, 0.80, 1.0]
            head.orientation = simd_quatf(angle: 0.16, axis: [1, 0, 0])
            leftEar.orientation = baseEarLeft * simd_quatf(angle: -0.18, axis: [0, 0, 1])
            rightEar.orientation = baseEarRight * simd_quatf(angle: 0.18, axis: [0, 0, 1])
            
        case .playful, .thinking:
            // Lively gaze and alert ears
            leftEye.scale = [1.10, 1.05, 1.08]
            rightEye.scale = [1.10, 1.05, 1.08]
            leftCheek.scale = [1.25, 0.95, 0.14]
            rightCheek.scale = [1.25, 0.95, 0.14]
            mouth.scale = [1.10, 1.10, 1.0]
            head.orientation = simd_quatf(angle: -0.12, axis: [0, 0, 1]) * simd_quatf(angle: 0.08, axis: [0, 1, 0])
        }
    }
    
    private func resetFaceToRest() {
        setMood(.idle, animated: false)
    }
    
    // MARK: - Posture & Movement Rig Control
    
    /// Adjusts Cookie's physical posture across sitting, pointing, standing, walking, curled, and jumping.
    func setPosture(_ posture: CookiePosture, animated: Bool = true) {
        self.currentPosture = posture
        
        guard let leftPaw = leftFrontPawModel,
              let rightPaw = rightFrontPawModel,
              let leftFoot = leftFootModel,
              let rightFoot = rightFootModel,
              let tailBase = tailBaseModel,
              let body = bodyModel else { return }
        
        switch posture {
        case .sitting, .pointing:
            // The signature reference pose! Left front arm raised, pointing forward!
            leftPaw.position = [-0.042, 0.044, 0.028]
            leftPaw.orientation = simd_quatf(angle: -1.46, axis: [0, 0, 1]) * simd_quatf(angle: -0.28, axis: [0, 1, 0]) * simd_quatf(angle: 0.12, axis: [1, 0, 0])
            rightPaw.position = [0.038, 0.028, 0.032]
            rightPaw.orientation = simd_quatf(angle: -0.22, axis: [1, 0, 0]) * simd_quatf(angle: -0.22, axis: [0, 0, 1])
            leftFoot.position = [-0.018, 0.010, 0.042]
            rightFoot.position = [0.018, 0.010, 0.042]
            body.position = [0, 0.044, 0]
            tailBase.orientation = simd_quatf(angle: 0.55, axis: [1, 0, 0]) * simd_quatf(angle: 0.52, axis: [0, 0, 1])
            
        case .standing:
            body.position = [0, 0.054, 0]
            leftPaw.position = [-0.034, 0.024, 0.026]
            leftPaw.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
            rightPaw.position = [0.034, 0.024, 0.026]
            rightPaw.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
            
        case .curled:
            body.position = [0, 0.038, 0]
            leftPaw.position = [-0.028, 0.022, 0.028]
            leftPaw.orientation = simd_quatf(angle: -0.10, axis: [1, 0, 0])
            rightPaw.position = [0.028, 0.022, 0.028]
            tailBase.orientation = simd_quatf(angle: 0.85, axis: [1, 0, 0]) * simd_quatf(angle: 0.65, axis: [0, 0, 1])
            
        case .stretching:
            body.position = [0, 0.038, -0.015]
            leftPaw.position = [-0.034, 0.018, 0.055]
            rightPaw.position = [0.034, 0.018, 0.055]
            
        case .cleaningPaw:
            leftPaw.position = [-0.022, 0.068, 0.046]
            leftPaw.orientation = simd_quatf(angle: -Float.pi * 0.55, axis: [1, 0, 0])
            
        case .walking:
            body.position = [0, 0.048, 0]
            
        case .jumping:
            body.position = [0, 0.075, 0]
            leftPaw.orientation = simd_quatf(angle: -0.45, axis: [1, 0, 0])
            rightPaw.orientation = simd_quatf(angle: -0.45, axis: [1, 0, 0])
        }
    }
    
    // MARK: - Reactive Behaviors
    
    /// Petting reaction: Happy purr bounce, sweet crescent eyes, ear wiggle, and blooming blush
    public func pet() {
        guard !isPurring else { return }
        isPurring = true
        let originalY = self.position.y
        
        setMood(.happy, animated: true)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            if !self.shouldReduceMotion {
                // Tactile purr bounce
                self.position.y = originalY + 0.024
                self.scale = [1.06, 1.06, 1.06]
                try? await Task.sleep(nanoseconds: 160_000_000)
                
                self.position.y = originalY
                self.scale = [1.0, 1.0, 1.0]
                try? await Task.sleep(nanoseconds: 140_000_000)
                
                // Second mini bounce
                self.position.y = originalY + 0.012
                try? await Task.sleep(nanoseconds: 120_000_000)
                self.position.y = originalY
            }
            
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self.setMood(.idle, animated: true)
            self.isPurring = false
        }
    }
    
    /// Cookie reacts to a newly created or moved object by turning head curiously toward it.
    public func curiousLook(at targetPosition: SIMD3<Float>) {
        guard !isCuriousLooking, let head = headModel else { return }
        isCuriousLooking = true
        
        let delta = targetPosition - self.position
        let angleY = atan2(delta.x, delta.z)
        let clampedAngle = min(max(angleY * 0.40, -0.65), 0.65)
        
        setMood(.curious, animated: true)
        
        Task { @MainActor [weak self] in
            guard let self = self, let head = self.headModel else { return }
            
            if !self.shouldReduceMotion {
                head.orientation = simd_quatf(angle: clampedAngle, axis: [0, 1, 0]) * simd_quatf(angle: 0.16, axis: [0, 0, 1])
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                head.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            } else {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
            
            self.setMood(.idle, animated: true)
            self.isCuriousLooking = false
        }
    }
    
    /// Raises Cookie's left paw and points directly toward an object (matching the reference image!).
    public func pointAt(target: SIMD3<Float>) {
        guard !isPointing else { return }
        isPointing = true
        
        setPosture(.pointing, animated: true)
        setMood(.curious, animated: true)
        
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard let self = self else { return }
            self.setPosture(.sitting, animated: true)
            self.setMood(.idle, animated: true)
            self.isPointing = false
        }
    }
    
    /// Smoothly walks / shifts Cookie closer to observe recent activity at the desk.
    public func shiftTowardDesk() {
        guard !isMoving else { return }
        isMoving = true
        
        let startPos = self.position
        let targetPos = Self.deskObservingPos
        let targetRot = Self.deskObservingRot
        
        setMood(.curious, animated: true)
        setPosture(.walking, animated: true)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            if self.shouldReduceMotion {
                self.position = targetPos
                self.orientation = targetRot
                self.setPosture(.sitting, animated: false)
                self.isMoving = false
                return
            }
            
            let steps = 16
            let interval = UInt64(30_000_000) // ~0.48s total
            
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: interval)
                let t = Float(i) / Float(steps)
                let ease = sin(t * Float.pi * 0.5)
                
                // Subtle walking bob
                let bob = sin(t * Float.pi * 4.0) * 0.012
                self.position = simd_mix(startPos, targetPos, SIMD3<Float>(ease, ease, ease))
                self.position.y += bob
                self.orientation = simd_slerp(Self.bedPerchRot, targetRot, ease)
            }
            
            self.position = targetPos
            self.orientation = targetRot
            self.setPosture(.sitting, animated: true)
            self.isMoving = false
        }
    }
    
    /// Returns Cookie peacefully to the sleeping corner on the bed.
    public func returnToBedCorner() {
        guard !isMoving else { return }
        isMoving = true
        
        let startPos = self.position
        let targetPos = Self.bedPerchPos
        let targetRot = Self.bedPerchRot
        
        setPosture(.walking, animated: true)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            if self.shouldReduceMotion {
                self.position = targetPos
                self.orientation = targetRot
                self.setPosture(.sitting, animated: false)
                self.isMoving = false
                return
            }
            
            let steps = 16
            let interval = UInt64(30_000_000)
            
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: interval)
                let t = Float(i) / Float(steps)
                let ease = sin(t * Float.pi * 0.5)
                let bob = sin(t * Float.pi * 4.0) * 0.012
                self.position = simd_mix(startPos, targetPos, SIMD3<Float>(ease, ease, ease))
                self.position.y += bob
                self.orientation = simd_slerp(targetRot, Self.bedPerchRot, ease)
            }
            
            self.position = targetPos
            self.orientation = targetRot
            self.setPosture(.sitting, animated: true)
            self.isMoving = false
        }
    }
    
    /// Briefly looks toward where an object was just deleted.
    public func lookAtDeleted(lastPosition: SIMD3<Float>) {
        curiousLook(at: lastPosition)
    }
    
    /// Cookie curls down into a comfortable sleep when the room has been inactive.
    public func sleep() {
        guard !isMoving else { return }
        returnToBedCorner()
        
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            self?.setPosture(.curled, animated: true)
            self?.setMood(.sleepy, animated: true)
        }
    }
    
    /// Cookie wakes up, stretches, and greets the returning user.
    public func wake() {
        guard !isMoving else { return }
        setPosture(.stretching, animated: true)
        
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard let self = self else { return }
            self.setPosture(.sitting, animated: true)
            self.setMood(.happy, animated: true)
            await self.performBlink()
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self.setMood(.idle, animated: true)
        }
    }
    
    /// Cookie celebrates happily when a thought or goal is completed.
    public func happy() {
        setMood(.happy, animated: true)
        setPosture(.pointing, animated: true)
        pet()
    }
    
    // MARK: - Autonomous Room Navigation & Interaction API
    
    /// Calls Cookie toward a target room coordinate.
    @discardableResult
    public func callCookie(to target: SIMD3<Float>) async -> Bool {
        return await navigationController?.navigateTo(destination: target) ?? false
    }
    
    /// Cookie walks to the daybed, jumps up if needed, and lounges comfortably.
    public func goToBed() async {
        await navigationController?.navigateTo(destination: RoomNavZone.daybed.defaultSpot)
        await settleOnBed()
    }
    
    /// Cookie approaches the desk and explores the tabletop.
    public func goToDesk() async {
        await navigationController?.navigateTo(destination: RoomNavZone.desk.defaultSpot)
        await settleOnDesk()
    }
    
    /// Cookie walks toward the window ledge to gaze outdoors.
    public func goToWindow() async {
        await navigationController?.navigateTo(destination: RoomNavZone.windowLedge.defaultSpot)
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.headModel?.orientation = simd_quatf(angle: Float.pi * 0.90, axis: [0, 1, 0])
            self.setMood(.curious, animated: true)
        }
    }
    
    /// Cookie walks to the sunken lounge floor platform.
    public func goToSunkenLounge() async {
        await navigationController?.navigateTo(destination: RoomNavZone.lowerFloor.defaultSpot)
        animationController?.playSettleReaction()
    }
    
    /// Playful hop, one ear cute rotation, excited tail swish, and bouncy landing.
    public func play() {
        animationController?.state.transitionToActivity(.playing)
        setMood(.happy, animated: true)
        
        let baseEarRight = simd_quatf(angle: -0.48, axis: [0, 0, 1]) * simd_quatf(angle: -0.10, axis: [1, 0, 0]) * simd_quatf(angle: 0.08, axis: [0, 1, 0])
        rightEarModel?.orientation = baseEarRight * simd_quatf(angle: 0.22, axis: [0, 1, 0])
        
        swishTail(.excited)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let cur = self.position
            let hopPeak = cur + SIMD3<Float>(0, 0.05, 0)
            await self.animationController?.playJumpSequence(from: cur, to: hopPeak)
            self.position = cur
            self.rightEarModel?.orientation = baseEarRight
            self.setPosture(.sitting, animated: true)
            self.animationController?.state.transitionToActivity(.sitting)
        }
    }
    
    /// Saves current location as Cookie's favorite spot.
    public func stayHere() {
        let curZone = CookieNavigationController.zone(for: position)
        CookieMemoryStore.shared.updatePosition(position, rotationY: rotationAngleY, zone: curZone.rawValue)
        blink()
        swishTail()
    }
    
    /// Applies subtle elevation, soft shadow expansion, and warm highlight without blue outline.
    public func setSelected(_ selected: Bool) {
        guard isSelected != selected else { return }
        self.isSelected = selected
        
        let targetIntensity: Float = selected ? 1800 : 1100
        if let glow = findEntity(named: "cookie_warm_glow") as? PointLight {
            glow.light.intensity = targetIntensity
        }
        
        let deltaY: Float = selected ? 0.012 : -0.012
        self.position.y += deltaY
        
        if selected {
            // Attentive ears
            leftEarModel?.orientation = simd_quatf(angle: 0.60, axis: [0, 0, 1])
            rightEarModel?.orientation = simd_quatf(angle: -0.60, axis: [0, 0, 1])
        } else {
            leftEarModel?.orientation = simd_quatf(angle: 0.52, axis: [0, 0, 1])
            rightEarModel?.orientation = simd_quatf(angle: -0.52, axis: [0, 0, 1])
        }
    }
    
    /// Subtle hover response: perked ears and attentive glance.
    public func setHovered(_ hovered: Bool) {
        guard isHovered != hovered else { return }
        self.isHovered = hovered
        
        if hovered && !isSelected {
            leftEarModel?.orientation = simd_quatf(angle: 0.58, axis: [0, 0, 1])
            rightEarModel?.orientation = simd_quatf(angle: -0.58, axis: [0, 0, 1])
            blink()
        } else if !isSelected {
            leftEarModel?.orientation = simd_quatf(angle: 0.52, axis: [0, 0, 1])
            rightEarModel?.orientation = simd_quatf(angle: -0.52, axis: [0, 0, 1])
        }
    }
    
    /// Settles comfortably onto the bed: turns around, sits, and eventually curls up to lie down.
    public func settleOnBed() async {
        // Face forward towards room center
        let forwardRot = simd_quatf(angle: Float.pi * 0.20, axis: [0, 1, 0])
        self.orientation = forwardRot
        setPosture(.sitting, animated: true)
        blink()
        
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        setPosture(.curled, animated: true)
        setMood(.resting, animated: true)
        animationController?.state.transitionToActivity(.sleeping)
        CookieMemoryStore.shared.recordSleep()
    }
    
    /// Settles on the desk: sits, looks at monitor, sniffs notebook, looks at user, curls up.
    public func settleOnDesk() async {
        setPosture(.sitting, animated: true)
        setMood(.curious, animated: true)
        
        // 1. Look toward monitor
        headModel?.orientation = simd_quatf(angle: -0.32, axis: [0, 1, 0])
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // 2. Sniff notebook (head tilts downward)
        headModel?.orientation = simd_quatf(angle: 0.15, axis: [1, 0, 0])
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 3. Look at user camera
        headModel?.orientation = simd_quatf(angle: 0.10, axis: [0, 1, 0])
        blink()
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Reset head and settle
        headModel?.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        setPosture(.curled, animated: true)
        setMood(.idle, animated: true)
        animationController?.state.transitionToActivity(.sitting)
    }
}

// MARK: - Future AI Extension Point Architecture

/// Clean extension point protocol for a future, optional AI intelligence module.
///
/// In the future, a purely local (e.g. CoreML / Apple Intelligence on-device) module could
/// analyze user thoughts, recurring themes, or interaction preferences to subtly adjust Cookie's demeanor.
///
/// ⚠️ Strict v1 Constraints:
/// - 100% deterministic and local.
/// - NO network requests, NO analytics, NO tracking, NO cloud processing, NO external AI API.
/// - Zero user data leaves this Mac.
protocol CookieIntelligenceProvider: Sendable {
    /// Evaluates recent room events and determines if Cookie should alter mood or demeanor.
    func evaluateActivity(recentEvents: [RoomEvent], currentMood: CookieMood) -> CookieMood
    
    /// Optional future hook: Suggests an autonomous activity based on recurring themes or user preferences.
    func suggestAutonomousActivity(hourOfDay: Int, userPreferences: [String: String]) -> CookieActivity?
    
    /// Optional future hook: Evaluates sentiment or themes in user thought titles (without sending text off-device).
    func evaluateThoughtThemes(_ titles: [String]) -> CookieMood?
}

/// Default local deterministic behavioral provider for Cookie.
/// 100% local, offline, deterministic.
final class LocalDeterministicCookieIntelligence: CookieIntelligenceProvider {
    init() {}
    
    func evaluateActivity(recentEvents: [RoomEvent], currentMood: CookieMood) -> CookieMood {
        let creations = recentEvents.filter {
            if case .itemCreated = $0 { return true }
            if case .thoughtCreated = $0 { return true }
            return false
        }.count
        
        if creations >= 3 {
            return .excited
        }
        return .idle
    }
    
    public func suggestAutonomousActivity(hourOfDay: Int, userPreferences: [String: String]) -> CookieActivity? {
        if hourOfDay >= 22 || hourOfDay < 7 {
            return .sleeping
        }
        return nil
    }
    
    public func evaluateThoughtThemes(_ titles: [String]) -> CookieMood? {
        // v1: Deterministic local rule - no external AI calls
        return nil
    }
}

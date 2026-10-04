import SceneKit
import SwiftUI
import QuartzCore

/// 3D SceneKit character representing Cookie, Nook's tiny companion cat.
///
/// Crafted to match the soft, chubby, warm aesthetic from the character design:
/// - Soft cream/off-white porcelain fur
/// - Rosy blush cheeks and delicate pink inner ears
/// - Expressive glossy button eyes with white specular catchlight highlights
/// - Adorable feline :3 muzzle
/// - Chubby paws capable of pointing towards the desk, cleaning paws, and resting
/// - Smooth head tracking, blinking, breathing, and posture transitions
@MainActor
final class CookieNode: SCNNode {
    
    // MARK: - Subnodes for Hierarchy & Animation
    
    private var bodyRootNode: SCNNode!
    private var bodySphereNode: SCNNode!
    private var headNode: SCNNode!
    private var leftEarNode: SCNNode!
    private var rightEarNode: SCNNode!
    private var leftEyeNode: SCNNode!
    private var rightEyeNode: SCNNode!
    private var leftEyelidNode: SCNNode!
    private var rightEyelidNode: SCNNode!
    private var rightArmNode: SCNNode!
    private var leftArmNode: SCNNode!
    private var tailNode: SCNNode!
    private var shadowPlateNode: SCNNode!
    private var leftSleepArcNode: SCNNode!
    private var rightSleepArcNode: SCNNode!
    private var leftEyeSphere: SCNNode!
    private var rightEyeSphere: SCNNode!
    private var leftCatchlight: SCNNode!
    private var rightCatchlight: SCNNode!
    
    // MARK: - State Tracking
    
    private(set) var isSleeping: Bool = false
    private(set) var isPointing: Bool = false
    private var _reduceMotion: Bool = false
    var reduceMotion: Bool {
        get { _reduceMotion || PreferencesManager.shared.reduceMotion }
        set { _reduceMotion = newValue }
    }
    
    // Base resting transforms
    private let defaultHeadRotation = SCNVector3(0, 0, 0)
    private let defaultRightArmRotation = SCNVector3(0.15, 0, -0.08)
    private let pointingRightArmRotation = SCNVector3(-0.65, 0.45, 0.35)
    
    override init() {
        super.init()
        self.name = "cookie_character"
        setupModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 3D Character Construction
    
    private func setupModel() {
        // Master body container
        bodyRootNode = SCNNode()
        bodyRootNode.name = "cookie_body_root"
        bodyRootNode.position = SCNVector3(0, 0.02, 0)
        addChildNode(bodyRootNode)
        
        // Materials matching character art:
        // 1. Soft cream/off-white fur
        let furMat = SCNMaterial()
        furMat.diffuse.contents = NSColor(red: 0.975, green: 0.965, blue: 0.945, alpha: 1.0)
        furMat.roughness.contents = 0.82 // Matte, soft porcelain/velvet feel
        furMat.specular.contents = NSColor(white: 0.12, alpha: 1.0)
        furMat.lightingModel = .lambert
        
        // 2. Warm ginger/caramel tabby patches (matching reference photo)
        let gingerMat = SCNMaterial()
        gingerMat.diffuse.contents = NSColor(red: 0.86, green: 0.54, blue: 0.30, alpha: 1.0)
        gingerMat.roughness.contents = 0.82
        gingerMat.specular.contents = NSColor(white: 0.10, alpha: 1.0)
        gingerMat.lightingModel = .lambert
        
        // 3. Soft pastel pink for inner ears & blush
        let innerEarMat = SCNMaterial()
        innerEarMat.diffuse.contents = NSColor(red: 0.96, green: 0.74, blue: 0.71, alpha: 1.0)
        innerEarMat.roughness.contents = 0.85
        
        let blushMat = SCNMaterial()
        blushMat.diffuse.contents = NSColor(red: 0.96, green: 0.65, blue: 0.70, alpha: 0.85)
        blushMat.roughness.contents = 0.90
        blushMat.lightingModel = .constant
        
        // 4. Deep glossy obsidian black for button eyes
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = NSColor(red: 0.08, green: 0.07, blue: 0.07, alpha: 1.0)
        eyeMat.roughness.contents = 0.08
        eyeMat.specular.contents = NSColor.white
        eyeMat.metalness.contents = 0.1
        
        // 5. Pure white enamel catchlight highlights
        let catchlightMat = SCNMaterial()
        catchlightMat.diffuse.contents = NSColor.white
        catchlightMat.lightingModel = .constant
        
        // 6. Soft warm charcoal/brown for :3 mouth and sleeping eye arcs
        let mouthMat = SCNMaterial()
        mouthMat.diffuse.contents = NSColor(red: 0.22, green: 0.18, blue: 0.16, alpha: 1.0)
        mouthMat.roughness.contents = 0.80
        mouthMat.lightingModel = .constant
        
        // --- A. TORSO / BODY ---
        let bodyGeo = SCNSphere(radius: 0.15)
        bodyGeo.materials = [furMat]
        bodySphereNode = SCNNode(geometry: bodyGeo)
        bodySphereNode.scale = SCNVector3(1.05, 1.15, 1.10)
        bodySphereNode.position = SCNVector3(0, 0.12, 0)
        bodyRootNode.addChildNode(bodySphereNode)
        
        // Ginger saddle patch on back
        let backGingerGeo = SCNSphere(radius: 0.151)
        backGingerGeo.materials = [gingerMat]
        let backGingerNode = SCNNode(geometry: backGingerGeo)
        backGingerNode.scale = SCNVector3(0.98, 0.82, 0.92)
        backGingerNode.position = SCNVector3(0.01, 0.035, -0.045)
        bodySphereNode.addChildNode(backGingerNode)
        
        // Chubby cream tummy bulge
        let tummyGeo = SCNSphere(radius: 0.13)
        let tummyMat = SCNMaterial()
        tummyMat.diffuse.contents = NSColor(red: 0.985, green: 0.978, blue: 0.960, alpha: 1.0)
        tummyMat.roughness.contents = 0.85
        tummyGeo.materials = [tummyMat]
        let tummyNode = SCNNode(geometry: tummyGeo)
        tummyNode.scale = SCNVector3(0.95, 0.95, 1.05)
        tummyNode.position = SCNVector3(0, 0.10, 0.035)
        bodyRootNode.addChildNode(tummyNode)
        
        // --- B. HEAD & ADORABLE CHUBBY CHEEKS ---
        headNode = SCNNode()
        headNode.name = "cookie_head"
        headNode.position = SCNVector3(0, 0.26, 0.03)
        bodyRootNode.addChildNode(headNode)
        
        // Main head sphere (chubby squircle)
        let headGeo = SCNSphere(radius: 0.145)
        headGeo.materials = [furMat]
        let headBase = SCNNode(geometry: headGeo)
        headBase.scale = SCNVector3(1.18, 1.00, 1.05)
        headNode.addChildNode(headBase)
        
        // Ginger patch across crown and right side of head
        let headGingerGeo = SCNSphere(radius: 0.146)
        headGingerGeo.materials = [gingerMat]
        let headGingerNode = SCNNode(geometry: headGingerGeo)
        headGingerNode.scale = SCNVector3(0.72, 0.65, 0.85)
        headGingerNode.position = SCNVector3(0.035, 0.045, -0.02)
        headNode.addChildNode(headGingerNode)
        
        // Left & Right chubby cheek bulges (softened for adorable chibi cheeks)
        for (cx, side) in [(-0.075, "left"), (0.075, "right")] {
            let cheekGeo = SCNSphere(radius: 0.062)
            cheekGeo.materials = [furMat]
            let cheekNode = SCNNode(geometry: cheekGeo)
            cheekNode.name = "cheek_\(side)"
            cheekNode.position = SCNVector3(cx, -0.032, 0.052)
            cheekNode.scale = SCNVector3(1.1, 0.85, 0.85)
            headNode.addChildNode(cheekNode)
        }
        
        // --- C. EARS ---
        // Left Ear
        leftEarNode = SCNNode()
        leftEarNode.position = SCNVector3(-0.095, 0.125, 0.01)
        leftEarNode.eulerAngles = SCNVector3(-0.12, 0, 0.32)
        buildEarGeometry(in: leftEarNode, outerMat: furMat, innerMat: innerEarMat)
        headNode.addChildNode(leftEarNode)
        
        // Right Ear (warm ginger ear)
        rightEarNode = SCNNode()
        rightEarNode.position = SCNVector3(0.095, 0.125, 0.01)
        rightEarNode.eulerAngles = SCNVector3(-0.12, 0, -0.32)
        buildEarGeometry(in: rightEarNode, outerMat: gingerMat, innerMat: innerEarMat)
        headNode.addChildNode(rightEarNode)
        
        // --- D. EYES WITH SPECULAR HIGHLIGHTS & BLUSH ---
        for (eyeX, blushX, isLeft) in [(-0.062, -0.092, true), (0.062, 0.092, false)] {
            // Eye container
            let eyeContainer = SCNNode()
            eyeContainer.position = SCNVector3(eyeX, 0.012, 0.139)
            
            // Glossy black pupil sphere
            let eyeSphere = SCNSphere(radius: 0.024)
            eyeSphere.materials = [eyeMat]
            let eyeNode = SCNNode(geometry: eyeSphere)
            eyeNode.scale = SCNVector3(1.0, 1.10, 0.6)
            eyeContainer.addChildNode(eyeNode)
            
            // Specular catchlight reflection highlight (top-right of pupil)
            let catchlight = SCNSphere(radius: 0.0078)
            catchlight.materials = [catchlightMat]
            let catchlightNode = SCNNode(geometry: catchlight)
            catchlightNode.position = SCNVector3(0.006, 0.008, 0.013)
            eyeContainer.addChildNode(catchlightNode)
            
            // Eyelid for blinking
            let eyelidGeo = SCNSphere(radius: 0.027)
            eyelidGeo.materials = [furMat]
            let eyelidNode = SCNNode(geometry: eyelidGeo)
            eyelidNode.scale = SCNVector3(1.05, 1.05, 0.65)
            eyelidNode.position = SCNVector3(0, 0.035, 0.004) // Raised out of view
            eyelidNode.opacity = 0.0
            eyeContainer.addChildNode(eyelidNode)
            
            // Peaceful sleeping eye curved arc (sweet `︶` shape)
            let sleepArcGeo = SCNTorus(ringRadius: 0.018, pipeRadius: 0.0032)
            sleepArcGeo.materials = [mouthMat]
            let sleepArcNode = SCNNode(geometry: sleepArcGeo)
            sleepArcNode.scale = SCNVector3(1.0, 0.50, 0.40)
            sleepArcNode.position = SCNVector3(0, -0.005, 0.009)
            sleepArcNode.eulerAngles = SCNVector3(0.65, 0, 0)
            sleepArcNode.opacity = 0.0
            eyeContainer.addChildNode(sleepArcNode)
            
            if isLeft {
                leftEyeNode = eyeContainer
                leftEyelidNode = eyelidNode
                leftEyeSphere = eyeNode
                leftCatchlight = catchlightNode
                leftSleepArcNode = sleepArcNode
            } else {
                rightEyeNode = eyeContainer
                rightEyelidNode = eyelidNode
                rightEyeSphere = eyeNode
                rightCatchlight = catchlightNode
                rightSleepArcNode = sleepArcNode
            }
            headNode.addChildNode(eyeContainer)
            
            // Rosy Cheek Blush Discs (vibrant soft pink exactly like reference art)
            let blushGeo = SCNCylinder(radius: 0.028, height: 0.004)
            blushGeo.materials = [blushMat]
            let blushNode = SCNNode(geometry: blushGeo)
            blushNode.position = SCNVector3(blushX, -0.024, 0.124)
            blushNode.eulerAngles = SCNVector3(1.3, isLeft ? -0.35 : 0.35, 0)
            headNode.addChildNode(blushNode)
        }
        
        // --- E. FELINE :3 MOUTH ---
        let mouthMatRefined = SCNMaterial()
        mouthMatRefined.diffuse.contents = NSColor(red: 0.18, green: 0.14, blue: 0.12, alpha: 1.0)
        mouthMatRefined.lightingModel = .constant
        
        let lipTorus = SCNTorus(ringRadius: 0.014, pipeRadius: 0.0032)
        lipTorus.materials = [mouthMatRefined]
        
        // Left loop of :3
        let leftLip = SCNNode(geometry: lipTorus)
        leftLip.position = SCNVector3(-0.011, -0.016, 0.145)
        leftLip.eulerAngles = SCNVector3(0.35, 0, 0.22)
        leftLip.scale = SCNVector3(0.9, 0.75, 0.45)
        headNode.addChildNode(leftLip)
        
        // Right loop of :3
        let rightLip = SCNNode(geometry: lipTorus)
        rightLip.position = SCNVector3(0.011, -0.016, 0.145)
        rightLip.eulerAngles = SCNVector3(0.35, 0, -0.22)
        rightLip.scale = SCNVector3(0.9, 0.75, 0.45)
        headNode.addChildNode(rightLip)
        
        // Tiny dark nose point
        let noseGeo = SCNSphere(radius: 0.004)
        noseGeo.materials = [mouthMatRefined]
        let noseNode = SCNNode(geometry: noseGeo)
        noseNode.position = SCNVector3(0, -0.005, 0.148)
        headNode.addChildNode(noseNode)
        
        // --- F. FRONT PAWS / ARMS ---
        // Right Arm
        rightArmNode = SCNNode()
        rightArmNode.name = "cookie_right_arm"
        rightArmNode.position = SCNVector3(0.09, 0.12, 0.08)
        rightArmNode.eulerAngles = defaultRightArmRotation
        buildArmGeometry(in: rightArmNode, mat: furMat)
        bodyRootNode.addChildNode(rightArmNode)
        
        // Left Arm
        leftArmNode = SCNNode()
        leftArmNode.name = "cookie_left_arm"
        leftArmNode.position = SCNVector3(-0.09, 0.12, 0.08)
        leftArmNode.eulerAngles = SCNVector3(0.15, 0, 0.08)
        buildArmGeometry(in: leftArmNode, mat: furMat)
        bodyRootNode.addChildNode(leftArmNode)
        
        // --- G. HIND LEGS / SITTING HAUNCHES ---
        for (hx, isRight) in [(-0.11, false), (0.11, true)] {
            let haunchGeo = SCNSphere(radius: 0.09)
            haunchGeo.materials = [isRight ? gingerMat : furMat]
            let haunch = SCNNode(geometry: haunchGeo)
            haunch.scale = SCNVector3(0.9, 0.8, 1.25)
            haunch.position = SCNVector3(hx, 0.06, 0.02)
            bodyRootNode.addChildNode(haunch)
            
            // Rounded little toe paw pad resting in front
            let pawPadGeo = SCNSphere(radius: 0.042)
            pawPadGeo.materials = [furMat]
            let pawPad = SCNNode(geometry: pawPadGeo)
            pawPad.scale = SCNVector3(1.1, 0.65, 1.3)
            pawPad.position = SCNVector3(hx * 0.75, 0.025, 0.14)
            bodyRootNode.addChildNode(pawPad)
        }
        
        // --- H. CURLED TAIL (Ginger with white cream tip) ---
        tailNode = SCNNode()
        tailNode.name = "cookie_tail"
        tailNode.position = SCNVector3(0.12, 0.04, -0.09)
        buildTailGeometry(in: tailNode, bodyMat: gingerMat, tipMat: furMat)
        bodyRootNode.addChildNode(tailNode)
        
        // --- I. SOFT CONTACT SHADOW ---
        let shadowGeo = SCNPlane(width: 0.50, height: 0.44)
        shadowGeo.cornerRadius = 0.22
        let shadowMat = SCNMaterial()
        shadowMat.diffuse.contents = NSColor(white: 0.08, alpha: 0.28)
        shadowMat.lightingModel = .constant
        shadowMat.writesToDepthBuffer = false
        shadowGeo.materials = [shadowMat]
        
        shadowPlateNode = SCNNode(geometry: shadowGeo)
        shadowPlateNode.eulerAngles.x = -.pi / 2
        shadowPlateNode.position = SCNVector3(0, 0.005, 0.02)
        addChildNode(shadowPlateNode)
        
        // Start subtle gentle breathing loop if allowed
        startSubtleBreathing()
    }
    
    // MARK: - Geometry Helpers
    
    private func buildEarGeometry(in node: SCNNode, outerMat: SCNMaterial, innerMat: SCNMaterial) {
        // Outer ear cone
        let earGeo = SCNCone(topRadius: 0.005, bottomRadius: 0.046, height: 0.075)
        earGeo.materials = [outerMat]
        let outerNode = SCNNode(geometry: earGeo)
        outerNode.scale = SCNVector3(1.1, 1.0, 0.6)
        node.addChildNode(outerNode)
        
        // Inner pink ear facet
        let innerGeo = SCNCone(topRadius: 0.002, bottomRadius: 0.032, height: 0.055)
        innerGeo.materials = [innerMat]
        let innerNode = SCNNode(geometry: innerGeo)
        innerNode.scale = SCNVector3(1.0, 1.0, 0.5)
        innerNode.position = SCNVector3(0, -0.006, 0.012)
        node.addChildNode(innerNode)
    }
    
    private func buildArmGeometry(in node: SCNNode, mat: SCNMaterial) {
        // Chubby little front arm smooth capsule (seamless rounded shoulder and elbow)
        let armGeo = SCNCapsule(capRadius: 0.035, height: 0.13)
        armGeo.materials = [mat]
        let armNode = SCNNode(geometry: armGeo)
        armNode.position = SCNVector3(0, -0.05, 0.03)
        armNode.eulerAngles.x = 0.35
        node.addChildNode(armNode)
        
        // Cute rounded paw tip with tiny toe indentations
        let pawGeo = SCNSphere(radius: 0.040)
        pawGeo.materials = [mat]
        let pawNode = SCNNode(geometry: pawGeo)
        pawNode.scale = SCNVector3(1.0, 0.8, 1.2)
        pawNode.position = SCNVector3(0, -0.10, 0.065)
        node.addChildNode(pawNode)
    }
    
    private func buildTailGeometry(in node: SCNNode, bodyMat: SCNMaterial, tipMat: SCNMaterial) {
        // Curving tail segment 1 (ginger)
        let seg1 = SCNCylinder(radius: 0.026, height: 0.12)
        seg1.materials = [bodyMat]
        let n1 = SCNNode(geometry: seg1)
        n1.position = SCNVector3(0.04, 0.04, 0)
        n1.eulerAngles = SCNVector3(0.2, 0, -0.7)
        node.addChildNode(n1)
        
        // Curving tail segment 2 (ginger)
        let seg2 = SCNCylinder(radius: 0.022, height: 0.10)
        seg2.materials = [bodyMat]
        let n2 = SCNNode(geometry: seg2)
        n2.position = SCNVector3(0.09, 0.11, 0.01)
        n2.eulerAngles = SCNVector3(0.1, 0, -0.15)
        node.addChildNode(n2)
        
        // Rounded white cream tip (matching reference photo)
        let tip = SCNSphere(radius: 0.024)
        tip.materials = [tipMat]
        let tipNode = SCNNode(geometry: tip)
        tipNode.position = SCNVector3(0.09, 0.16, 0.01)
        node.addChildNode(tipNode)
    }
    
    // MARK: - Postures & Animation Methods
    
    /// Starts the slow, calm breathing loop.
    func startSubtleBreathing() {
        guard !reduceMotion else { return }
        
        let breatheIn = SCNAction.scale(to: 1.025, duration: 2.6)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SCNAction.scale(to: 0.985, duration: 2.6)
        breatheOut.timingMode = .easeInEaseOut
        let breathing = SCNAction.repeatForever(SCNAction.sequence([breatheIn, breatheOut]))
        bodySphereNode.runAction(breathing, forKey: "cookie_breathing")
    }
    
    /// Smoothly rotates head to look toward a target 3D world coordinate (e.g. the desk).
    func lookTowards(worldPoint: SCNVector3) {
        guard !isSleeping else { return }
        
        // Convert world target to local coordinate space of head
        let localPoint = convertPosition(worldPoint, from: nil)
        let dx = localPoint.x
        let dz = localPoint.z
        let dy = localPoint.y - 0.25
        
        let targetYaw = CGFloat(atan2(dx, dz)).clamped(to: -0.65...0.65)
        let targetPitch = CGFloat(-atan2(dy, sqrt(dx*dx + dz*dz))).clamped(to: -0.35...0.35)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.45
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        headNode.eulerAngles = SCNVector3(targetPitch, targetYaw, 0)
        SCNTransaction.commit()
    }
    
    /// Resets head rotation smoothly back to facing front.
    func resetHead() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.40
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        headNode.eulerAngles = defaultHeadRotation
        SCNTransaction.commit()
    }
    
    /// Raises right paw pointing toward desk (as depicted in reference character image).
    func pointAtDesk() {
        guard !isSleeping else { return }
        isPointing = true
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.35
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        rightArmNode.eulerAngles = pointingRightArmRotation
        SCNTransaction.commit()
    }
    
    /// Lowers front paws back to neutral resting pose.
    func restPaws() {
        isPointing = false
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.30
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        rightArmNode.eulerAngles = defaultRightArmRotation
        SCNTransaction.commit()
    }
    
    /// Quick natural eyelid blink.
    func blink() {
        guard !isSleeping, !reduceMotion else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.08
        leftEyelidNode.position.y = 0.008
        rightEyelidNode.position.y = 0.008
        leftEyelidNode.opacity = 1.0
        rightEyelidNode.opacity = 1.0
        SCNTransaction.completionBlock = { [weak self] in
            guard let self else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.12
            self.leftEyelidNode.position.y = 0.035
            self.rightEyelidNode.position.y = 0.035
            self.leftEyelidNode.opacity = 0.0
            self.rightEyelidNode.opacity = 0.0
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }
    
    /// Happy ear wiggle reaction.
    func wiggleEars() {
        guard !reduceMotion else { return }
        
        let twitchLeft = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0, z: 0.12, duration: 0.08),
            SCNAction.rotateBy(x: 0, y: 0, z: -0.24, duration: 0.12),
            SCNAction.rotateBy(x: 0, y: 0, z: 0.12, duration: 0.08)
        ])
        let twitchRight = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0, z: -0.12, duration: 0.08),
            SCNAction.rotateBy(x: 0, y: 0, z: 0.24, duration: 0.12),
            SCNAction.rotateBy(x: 0, y: 0, z: -0.12, duration: 0.08)
        ])
        leftEarNode.runAction(twitchLeft)
        rightEarNode.runAction(twitchRight)
    }
    
    /// Subtle tail swish.
    func swishTail() {
        guard !reduceMotion else { return }
        
        let swish = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0.18, z: 0, duration: 0.25),
            SCNAction.rotateBy(x: 0, y: -0.36, z: 0, duration: 0.40),
            SCNAction.rotateBy(x: 0, y: 0.18, z: 0, duration: 0.25)
        ])
        tailNode.runAction(swish)
    }
    
    /// Paw cleaning idle behavior.
    func cleanPaw() {
        guard !isSleeping, !reduceMotion else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.30
        rightArmNode.eulerAngles = SCNVector3(-0.55, 0.20, 0.15)
        headNode.eulerAngles = SCNVector3(0.20, 0.15, 0.05)
        SCNTransaction.commit()
        
        // Subtle paw rub
        let rub = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.015, z: 0, duration: 0.18),
            SCNAction.moveBy(x: 0, y: -0.015, z: 0, duration: 0.18),
            SCNAction.moveBy(x: 0, y: 0.015, z: 0, duration: 0.18),
            SCNAction.moveBy(x: 0, y: -0.015, z: 0, duration: 0.18)
        ])
        rightArmNode.runAction(rub)
    }
    
    /// Gentle stretching behavior.
    func stretch() {
        guard !isSleeping, !reduceMotion else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.45
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        bodyRootNode.position.y = -0.01
        headNode.position.y = 0.22
        rightArmNode.eulerAngles = SCNVector3(-0.4, 0, 0.1)
        leftArmNode.eulerAngles = SCNVector3(-0.4, 0, -0.1)
        SCNTransaction.commit()
    }
    
    /// Relaxes after stretching back to upright sitting.
    func relaxStretch() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.45
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        bodyRootNode.position.y = 0.02
        headNode.position.y = 0.26
        restPaws()
        SCNTransaction.commit()
    }
    
    /// Puts Cookie into sleep posture: curls down, closes eyes with sweet sleeping arcs, breathes slowly.
    func sleep() {
        isSleeping = true
        restPaws()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.75
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Display sweet sleeping eye arcs and hide open pupils
        leftSleepArcNode?.opacity = 1.0
        rightSleepArcNode?.opacity = 1.0
        leftEyeSphere?.opacity = 0.0
        rightEyeSphere?.opacity = 0.0
        leftCatchlight?.opacity = 0.0
        rightCatchlight?.opacity = 0.0
        
        // Curled body position: head rests lower and angles into paws
        bodyRootNode.position.y = -0.01
        headNode.position = SCNVector3(-0.02, 0.18, 0.08)
        headNode.eulerAngles = SCNVector3(0.35, 0.32, -0.12)
        
        // Front paws tuck underneath
        rightArmNode.eulerAngles = SCNVector3(0.55, 0.15, -0.25)
        leftArmNode.eulerAngles = SCNVector3(0.55, -0.15, 0.25)
        
        // Tail wraps snugly around body
        tailNode.position = SCNVector3(0.08, 0.02, -0.04)
        tailNode.eulerAngles = SCNVector3(0.12, 0.55, -0.85)
        
        // Deeper, slower breathing loop for peaceful sleep
        bodySphereNode.removeAction(forKey: "cookie_breathing")
        if !reduceMotion {
            let breatheIn = SCNAction.scale(to: 1.035, duration: 3.2)
            breatheIn.timingMode = .easeInEaseOut
            let breatheOut = SCNAction.scale(to: 0.975, duration: 3.2)
            breatheOut.timingMode = .easeInEaseOut
            let sleepBreathing = SCNAction.repeatForever(SCNAction.sequence([breatheIn, breatheOut]))
            bodySphereNode.runAction(sleepBreathing, forKey: "cookie_breathing")
        }
        
        SCNTransaction.commit()
    }
    
    /// Wakes Cookie up gradually: blinks eyes open, raises head.
    func wakeUp() {
        guard isSleeping else { return }
        isSleeping = false
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Restore open pupils and hide sleeping arcs
        leftSleepArcNode?.opacity = 0.0
        rightSleepArcNode?.opacity = 0.0
        leftEyeSphere?.opacity = 1.0
        rightEyeSphere?.opacity = 1.0
        leftCatchlight?.opacity = 1.0
        rightCatchlight?.opacity = 1.0
        
        // Head returns to normal upright
        bodyRootNode.position.y = 0.02
        headNode.position = SCNVector3(0, 0.26, 0.03)
        headNode.eulerAngles = defaultHeadRotation
        
        // Restore tail to resting posture
        tailNode.position = SCNVector3(0.12, 0.04, -0.09)
        tailNode.eulerAngles = SCNVector3(0, 0, 0)
        
        // Restore normal breathing
        bodySphereNode.removeAction(forKey: "cookie_breathing")
        startSubtleBreathing()
        
        SCNTransaction.commit()
    }
}

// MARK: - Clamping Helper

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

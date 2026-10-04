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
    
    // MARK: - State Tracking
    
    private(set) var isSleeping: Bool = false
    private(set) var isPointing: Bool = false
    var reduceMotion: Bool = false
    
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
        
        // 2. Soft pastel pink for inner ears & blush
        let innerEarMat = SCNMaterial()
        innerEarMat.diffuse.contents = NSColor(red: 0.96, green: 0.74, blue: 0.71, alpha: 1.0)
        innerEarMat.roughness.contents = 0.85
        
        let blushMat = SCNMaterial()
        blushMat.diffuse.contents = NSColor(red: 0.96, green: 0.65, blue: 0.70, alpha: 0.85)
        blushMat.roughness.contents = 0.90
        blushMat.lightingModel = .constant
        
        // 3. Deep glossy obsidian black for button eyes
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = NSColor(red: 0.08, green: 0.07, blue: 0.07, alpha: 1.0)
        eyeMat.roughness.contents = 0.08
        eyeMat.specular.contents = NSColor.white
        eyeMat.metalness.contents = 0.1
        
        // 4. Pure white enamel catchlight highlights
        let catchlightMat = SCNMaterial()
        catchlightMat.diffuse.contents = NSColor.white
        catchlightMat.lightingModel = .constant
        
        // 5. Soft warm charcoal/brown for :3 mouth
        let mouthMat = SCNMaterial()
        mouthMat.diffuse.contents = NSColor(red: 0.22, green: 0.18, blue: 0.16, alpha: 1.0)
        mouthMat.roughness.contents = 0.80
        
        // --- A. TORSO / BODY ---
        let bodyGeo = SCNSphere(radius: 0.15)
        bodyGeo.materials = [furMat]
        bodySphereNode = SCNNode(geometry: bodyGeo)
        bodySphereNode.scale = SCNVector3(1.05, 1.15, 1.10)
        bodySphereNode.position = SCNVector3(0, 0.12, 0)
        bodyRootNode.addChildNode(bodySphereNode)
        
        // Chubby tummy bulge
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
        
        // Left & Right chubby cheek bulges
        for (cx, side) in [(-0.08, "left"), (0.08, "right")] {
            let cheekGeo = SCNSphere(radius: 0.075)
            cheekGeo.materials = [furMat]
            let cheekNode = SCNNode(geometry: cheekGeo)
            cheekNode.name = "cheek_\(side)"
            cheekNode.position = SCNVector3(cx, -0.02, 0.065)
            cheekNode.scale = SCNVector3(1.0, 0.9, 0.9)
            headNode.addChildNode(cheekNode)
        }
        
        // --- C. EARS ---
        // Left Ear
        leftEarNode = SCNNode()
        leftEarNode.position = SCNVector3(-0.09, 0.12, 0.01)
        leftEarNode.eulerAngles = SCNVector3(-0.10, 0, 0.28)
        buildEarGeometry(in: leftEarNode, outerMat: furMat, innerMat: innerEarMat)
        headNode.addChildNode(leftEarNode)
        
        // Right Ear
        rightEarNode = SCNNode()
        rightEarNode.position = SCNVector3(0.09, 0.12, 0.01)
        rightEarNode.eulerAngles = SCNVector3(-0.10, 0, -0.28)
        buildEarGeometry(in: rightEarNode, outerMat: furMat, innerMat: innerEarMat)
        headNode.addChildNode(rightEarNode)
        
        // --- D. EYES WITH SPECULAR HIGHLIGHTS & BLUSH ---
        for (eyeX, blushX, isLeft) in [(-0.062, -0.095, true), (0.062, 0.095, false)] {
            // Eye container
            let eyeContainer = SCNNode()
            eyeContainer.position = SCNVector3(eyeX, 0.015, 0.138)
            
            // Glossy black pupil sphere
            let eyeSphere = SCNSphere(radius: 0.023)
            eyeSphere.materials = [eyeMat]
            let eyeNode = SCNNode(geometry: eyeSphere)
            eyeNode.scale = SCNVector3(1.0, 1.08, 0.6)
            eyeContainer.addChildNode(eyeNode)
            
            // Specular catchlight reflection highlight (top-right of pupil)
            let catchlight = SCNSphere(radius: 0.0075)
            catchlight.materials = [catchlightMat]
            let catchlightNode = SCNNode(geometry: catchlight)
            catchlightNode.position = SCNVector3(0.006, 0.008, 0.012)
            eyeContainer.addChildNode(catchlightNode)
            
            // Eyelid for blinking / sleeping (retracted by default)
            let eyelidGeo = SCNSphere(radius: 0.026)
            eyelidGeo.materials = [furMat]
            let eyelidNode = SCNNode(geometry: eyelidGeo)
            eyelidNode.scale = SCNVector3(1.05, 1.05, 0.65)
            eyelidNode.position = SCNVector3(0, 0.035, 0.004) // Raised out of view
            eyelidNode.opacity = 0.0
            eyeContainer.addChildNode(eyelidNode)
            
            if isLeft {
                leftEyeNode = eyeContainer
                leftEyelidNode = eyelidNode
            } else {
                rightEyeNode = eyeContainer
                rightEyelidNode = eyelidNode
            }
            headNode.addChildNode(eyeContainer)
            
            // Rosy Cheek Blush
            let blushGeo = SCNPlane(width: 0.048, height: 0.034)
            blushGeo.cornerRadius = 0.017
            blushGeo.materials = [blushMat]
            let blushNode = SCNNode(geometry: blushGeo)
            blushNode.position = SCNVector3(blushX, -0.022, 0.128)
            blushNode.eulerAngles.y = isLeft ? -0.32 : 0.32
            headNode.addChildNode(blushNode)
        }
        
        // --- E. FELINE :3 MOUTH ---
        let mouthGeo = SCNTorus(ringRadius: 0.016, pipeRadius: 0.0035)
        mouthGeo.materials = [mouthMat]
        
        // Left curve of :3
        let leftLip = SCNNode(geometry: mouthGeo)
        leftLip.position = SCNVector3(-0.013, -0.018, 0.144)
        leftLip.eulerAngles = SCNVector3(0.2, 0, 0)
        leftLip.scale = SCNVector3(1.0, 0.85, 0.5)
        headNode.addChildNode(leftLip)
        
        // Right curve of :3
        let rightLip = SCNNode(geometry: mouthGeo)
        rightLip.position = SCNVector3(0.013, -0.018, 0.144)
        rightLip.eulerAngles = SCNVector3(0.2, 0, 0)
        rightLip.scale = SCNVector3(1.0, 0.85, 0.5)
        headNode.addChildNode(rightLip)
        
        // Tiny dark nose point
        let noseGeo = SCNSphere(radius: 0.0045)
        noseGeo.materials = [mouthMat]
        let noseNode = SCNNode(geometry: noseGeo)
        noseNode.position = SCNVector3(0, -0.006, 0.148)
        headNode.addChildNode(noseNode)
        
        // --- F. FRONT PAWS / ARMS ---
        // Right Arm (can point at desk, like in the reference art!)
        rightArmNode = SCNNode()
        rightArmNode.name = "cookie_right_arm"
        rightArmNode.position = SCNVector3(0.09, 0.12, 0.08)
        rightArmNode.eulerAngles = defaultRightArmRotation
        buildArmGeometry(in: rightArmNode, mat: furMat)
        bodyRootNode.addChildNode(rightArmNode)
        
        // Left Arm (rests on floor)
        leftArmNode = SCNNode()
        leftArmNode.name = "cookie_left_arm"
        leftArmNode.position = SCNVector3(-0.09, 0.12, 0.08)
        leftArmNode.eulerAngles = SCNVector3(0.15, 0, 0.08)
        buildArmGeometry(in: leftArmNode, mat: furMat)
        bodyRootNode.addChildNode(leftArmNode)
        
        // --- G. HIND LEGS / SITTING HAUNCHES ---
        for (hx, _) in [(-0.11, true), (0.11, false)] {
            let haunchGeo = SCNSphere(radius: 0.09)
            haunchGeo.materials = [furMat]
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
        
        // --- H. CURLED TAIL ---
        tailNode = SCNNode()
        tailNode.name = "cookie_tail"
        tailNode.position = SCNVector3(0.12, 0.04, -0.09)
        buildTailGeometry(in: tailNode, mat: furMat)
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
        // Chubby little front arm cylinder
        let armGeo = SCNCylinder(radius: 0.038, height: 0.13)
        armGeo.materials = [mat]
        let armCyl = SCNNode(geometry: armGeo)
        armCyl.position = SCNVector3(0, -0.05, 0.03)
        armCyl.eulerAngles.x = 0.35
        node.addChildNode(armCyl)
        
        // Cute rounded paw tip with tiny toe indentations
        let pawGeo = SCNSphere(radius: 0.042)
        pawGeo.materials = [mat]
        let pawNode = SCNNode(geometry: pawGeo)
        pawNode.scale = SCNVector3(1.0, 0.8, 1.2)
        pawNode.position = SCNVector3(0, -0.10, 0.065)
        node.addChildNode(pawNode)
    }
    
    private func buildTailGeometry(in node: SCNNode, mat: SCNMaterial) {
        // Curving tail segment 1
        let seg1 = SCNCylinder(radius: 0.026, height: 0.12)
        seg1.materials = [mat]
        let n1 = SCNNode(geometry: seg1)
        n1.position = SCNVector3(0.04, 0.04, 0)
        n1.eulerAngles = SCNVector3(0.2, 0, -0.7)
        node.addChildNode(n1)
        
        // Curving tail segment 2 (upward tip as in picture)
        let seg2 = SCNCylinder(radius: 0.022, height: 0.10)
        seg2.materials = [mat]
        let n2 = SCNNode(geometry: seg2)
        n2.position = SCNVector3(0.09, 0.11, 0.01)
        n2.eulerAngles = SCNVector3(0.1, 0, -0.15)
        node.addChildNode(n2)
        
        // Rounded tip
        let tip = SCNSphere(radius: 0.024)
        tip.materials = [mat]
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
        rightArmNode.runAction(rub) { [weak self] in
            self?.restPaws()
            self?.resetHead()
        }
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
        
        SCNTransaction.completionBlock = { [weak self] in
            guard let self else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.45
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            self.bodyRootNode.position.y = 0.02
            self.headNode.position.y = 0.26
            self.restPaws()
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }
    
    /// Puts Cookie into sleep posture: curls down, closes eyes, breathes slowly.
    func sleep() {
        isSleeping = true
        restPaws()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.8
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Close eyelids
        leftEyelidNode.position.y = 0.008
        rightEyelidNode.position.y = 0.008
        leftEyelidNode.opacity = 1.0
        rightEyelidNode.opacity = 1.0
        
        // Head rests down
        headNode.position = SCNVector3(0, 0.21, 0.06)
        headNode.eulerAngles = SCNVector3(0.25, 0.12, 0)
        
        // Deeper breathing loop for sleep
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
    
    /// Wakes Cookie up gradually: blinks eyes open, raises head, stretches.
    func wakeUp() {
        guard isSleeping else { return }
        isSleeping = false
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Open eyelids
        leftEyelidNode.position.y = 0.035
        rightEyelidNode.position.y = 0.035
        leftEyelidNode.opacity = 0.0
        rightEyelidNode.opacity = 0.0
        
        // Head returns to normal upright
        headNode.position = SCNVector3(0, 0.26, 0.03)
        headNode.eulerAngles = defaultHeadRotation
        
        // Restore normal breathing
        bodySphereNode.removeAction(forKey: "cookie_breathing")
        startSubtleBreathing()
        
        SCNTransaction.commit()
        
        // Gentle waking stretch after short delay
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self?.stretch()
        }
    }
}

// MARK: - Clamping Helper

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

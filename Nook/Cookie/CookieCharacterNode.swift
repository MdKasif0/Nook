import SceneKit
import AppKit
import SwiftUI

/// 3D SceneKit representation of Cookie, Nook's companion cat.
///
/// Designed with soft cream/off-white fur, subtle warm brown markings,
/// expressive eyes, tiny paws, and gentle lifelike postures.
final class CookieCharacterNode: SCNNode {
    
    // MARK: - Subnodes
    
    private let bodyRoot = SCNNode()
    private let torsoNode = SCNNode()
    private let chestNode = SCNNode()
    private let headNode = SCNNode()
    private let muzzleNode = SCNNode()
    
    private let leftEarNode = SCNNode()
    private let rightEarNode = SCNNode()
    
    private let leftEyeNode = SCNNode()
    private let rightEyeNode = SCNNode()
    private let leftLidNode = SCNNode()
    private let rightLidNode = SCNNode()
    
    private let frontLeftPawNode = SCNNode()
    private let frontRightPawNode = SCNNode()
    private let backLeftPawNode = SCNNode()
    private let backRightPawNode = SCNNode()
    
    private let tailRootNode = SCNNode()
    private let tailSegmentNode = SCNNode()
    
    private var speechBubbleNode: SCNNode?
    
    // MARK: - State
    
    private(set) var currentMood: CookieMood = .idle
    private(set) var isSleeping: Bool = false
    var reduceMotion: Bool = false
    
    // Default home position (on the woven rug)
    static let homeRugPosition = SCNVector3(-0.95, 0.03, 0.70)
    static let nearDeskPosition = SCNVector3(-0.48, 0.03, 0.45)
    static let nearChairPosition = SCNVector3(-0.55, 0.03, 0.85)
    static let nearWindowPosition = SCNVector3(-0.92, 0.03, 0.05)
    
    override init() {
        super.init()
        self.name = "cookie_character"
        self.position = Self.homeRugPosition
        
        setupMaterialsAndGeometry()
        applyPosture(for: .idle, animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Materials & Geometry Setup
    
    private func setupMaterialsAndGeometry() {
        addChildNode(bodyRoot)
        
        // 1. Materials
        // Soft cream off-white fur
        let creamFurMat = SCNMaterial()
        creamFurMat.diffuse.contents = NSColor(red: 0.98, green: 0.965, blue: 0.935, alpha: 1.0)
        creamFurMat.roughness.contents = 0.85
        creamFurMat.specular.contents = NSColor(white: 0.05, alpha: 1.0)
        
        // Subtle warm toasted cinnamon/caramel brown marking
        let brownMarkingMat = SCNMaterial()
        brownMarkingMat.diffuse.contents = NSColor(red: 0.72, green: 0.54, blue: 0.38, alpha: 1.0)
        brownMarkingMat.roughness.contents = 0.85
        brownMarkingMat.specular.contents = NSColor(white: 0.05, alpha: 1.0)
        
        // Inner ear warm soft blush
        let innerEarMat = SCNMaterial()
        innerEarMat.diffuse.contents = NSColor(red: 0.92, green: 0.82, blue: 0.78, alpha: 1.0)
        innerEarMat.roughness.contents = 0.90
        
        // Eyes: Espresso amber brown
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = NSColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1.0)
        eyeMat.roughness.contents = 0.30
        eyeMat.specular.contents = NSColor(white: 0.6, alpha: 1.0)
        
        // Nose: Delicate soft terracotta pink
        let noseMat = SCNMaterial()
        noseMat.diffuse.contents = NSColor(red: 0.86, green: 0.64, blue: 0.60, alpha: 1.0)
        noseMat.roughness.contents = 0.75
        
        // 2. Torso (Soft rounded body)
        let bodyGeo = SCNSphere(radius: 0.14)
        bodyGeo.materials = [creamFurMat]
        torsoNode.geometry = bodyGeo
        torsoNode.scale = SCNVector3(1.05, 0.88, 1.35)
        torsoNode.position = SCNVector3(0, 0.11, 0)
        bodyRoot.addChildNode(torsoNode)
        
        // Back Marking Patch (Warm brown saddle patch)
        let patchGeo = SCNSphere(radius: 0.10)
        patchGeo.materials = [brownMarkingMat]
        let patchNode = SCNNode(geometry: patchGeo)
        patchNode.scale = SCNVector3(0.95, 0.70, 0.95)
        patchNode.position = SCNVector3(0.02, 0.06, -0.02)
        torsoNode.addChildNode(patchNode)
        
        // Chest & Bib (Plumper front)
        let chestGeo = SCNSphere(radius: 0.11)
        chestGeo.materials = [creamFurMat]
        chestNode.geometry = chestGeo
        chestNode.scale = SCNVector3(0.95, 0.95, 0.95)
        chestNode.position = SCNVector3(0, 0.13, 0.10)
        bodyRoot.addChildNode(chestNode)
        
        // 3. Head & Face
        let headGeo = SCNSphere(radius: 0.10)
        headGeo.materials = [creamFurMat]
        headNode.geometry = headGeo
        headNode.position = SCNVector3(0, 0.19, 0.16)
        bodyRoot.addChildNode(headNode)
        
        // Muzzle
        let muzzleGeo = SCNSphere(radius: 0.045)
        muzzleGeo.materials = [creamFurMat]
        muzzleNode.geometry = muzzleGeo
        muzzleNode.scale = SCNVector3(1.2, 0.8, 0.9)
        muzzleNode.position = SCNVector3(0, -0.025, 0.08)
        headNode.addChildNode(muzzleNode)
        
        // Tiny nose
        let noseGeo = SCNSphere(radius: 0.012)
        noseGeo.materials = [noseMat]
        let noseNode = SCNNode(geometry: noseGeo)
        noseNode.scale = SCNVector3(1.2, 0.9, 0.9)
        noseNode.position = SCNVector3(0, 0.012, 0.04)
        muzzleNode.addChildNode(noseNode)
        
        // Ears
        setupEar(leftEarNode, isLeft: true, furMat: brownMarkingMat, innerMat: innerEarMat)
        setupEar(rightEarNode, isLeft: false, furMat: creamFurMat, innerMat: innerEarMat)
        headNode.addChildNode(leftEarNode)
        headNode.addChildNode(rightEarNode)
        
        // Eyes
        setupEye(leftEyeNode, lidNode: leftLidNode, isLeft: true, eyeMat: eyeMat, creamMat: creamFurMat)
        setupEye(rightEyeNode, lidNode: rightLidNode, isLeft: false, eyeMat: eyeMat, creamMat: creamFurMat)
        headNode.addChildNode(leftEyeNode)
        headNode.addChildNode(rightEyeNode)
        
        // 4. Paws
        let pawGeo = SCNSphere(radius: 0.036)
        pawGeo.materials = [creamFurMat]
        
        frontLeftPawNode.geometry = pawGeo
        frontLeftPawNode.scale = SCNVector3(0.9, 0.6, 1.2)
        frontLeftPawNode.position = SCNVector3(-0.065, 0.02, 0.14)
        bodyRoot.addChildNode(frontLeftPawNode)
        
        frontRightPawNode.geometry = pawGeo
        frontRightPawNode.scale = SCNVector3(0.9, 0.6, 1.2)
        frontRightPawNode.position = SCNVector3(0.065, 0.02, 0.14)
        bodyRoot.addChildNode(frontRightPawNode)
        
        backLeftPawNode.geometry = pawGeo
        backLeftPawNode.scale = SCNVector3(1.1, 0.7, 1.3)
        backLeftPawNode.position = SCNVector3(-0.09, 0.02, -0.06)
        bodyRoot.addChildNode(backLeftPawNode)
        
        backRightPawNode.geometry = pawGeo
        backRightPawNode.scale = SCNVector3(1.1, 0.7, 1.3)
        backRightPawNode.position = SCNVector3(0.09, 0.02, -0.06)
        bodyRoot.addChildNode(backRightPawNode)
        
        // 5. Tail
        let tailBaseGeo = SCNCylinder(radius: 0.024, height: 0.14)
        tailBaseGeo.materials = [creamFurMat]
        tailRootNode.geometry = tailBaseGeo
        tailRootNode.position = SCNVector3(0, 0.06, -0.14)
        tailRootNode.eulerAngles.x = -.pi / 3.5
        
        let tailTipGeo = SCNCylinder(radius: 0.020, height: 0.12)
        tailTipGeo.materials = [brownMarkingMat] // Toasted tip!
        tailSegmentNode.geometry = tailTipGeo
        tailSegmentNode.position = SCNVector3(0, 0.11, 0)
        tailSegmentNode.eulerAngles.x = 0.35
        tailRootNode.addChildNode(tailSegmentNode)
        
        bodyRoot.addChildNode(tailRootNode)
    }
    
    private func setupEar(_ earNode: SCNNode, isLeft: Bool, furMat: SCNMaterial, innerMat: SCNMaterial) {
        let xOffset: CGFloat = isLeft ? -0.055 : 0.055
        let zAngle: CGFloat = isLeft ? 0.22 : -0.22
        
        let earCone = SCNCone(topRadius: 0.003, bottomRadius: 0.038, height: 0.065)
        earCone.materials = [furMat]
        earNode.geometry = earCone
        earNode.position = SCNVector3(xOffset, 0.085, 0.015)
        earNode.eulerAngles.z = zAngle
        earNode.eulerAngles.x = -0.15
        
        let innerCone = SCNCone(topRadius: 0.002, bottomRadius: 0.026, height: 0.050)
        innerCone.materials = [innerMat]
        let innerNode = SCNNode(geometry: innerCone)
        innerNode.position = SCNVector3(0, 0, 0.008)
        earNode.addChildNode(innerNode)
    }
    
    private func setupEye(_ eyeNode: SCNNode, lidNode: SCNNode, isLeft: Bool, eyeMat: SCNMaterial, creamMat: SCNMaterial) {
        let xOffset: CGFloat = isLeft ? -0.045 : 0.045
        
        let eyeGeo = SCNSphere(radius: 0.015)
        eyeGeo.materials = [eyeMat]
        eyeNode.geometry = eyeGeo
        eyeNode.scale = SCNVector3(0.9, 1.0, 0.8)
        eyeNode.position = SCNVector3(xOffset, 0.012, 0.082)
        
        // Eyelid for sleeping / happy expressions
        let lidGeo = SCNSphere(radius: 0.016)
        lidGeo.materials = [creamMat]
        lidNode.geometry = lidGeo
        lidNode.position = SCNVector3(0, 0.018, 0) // Initially retracted above eye
        lidNode.scale = SCNVector3(1.05, 1.05, 1.05)
        eyeNode.addChildNode(lidNode)
    }
    
    // MARK: - Posture & Expression Engine
    
    /// Applies a physical posture, ear orientation, eye shape, and breathing rate for a mood.
    func applyPosture(for mood: CookieMood, animated: Bool = true) {
        self.currentMood = mood
        self.isSleeping = (mood == .resting)
        
        let duration = animated && !reduceMotion ? 0.45 : 0.0
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        switch mood {
        case .idle:
            // Relaxed sitting/loaf posture on rug
            headNode.position = SCNVector3(0, 0.19, 0.16)
            headNode.eulerAngles = SCNVector3(0, 0, 0)
            torsoNode.scale = SCNVector3(1.05, 0.88, 1.35)
            torsoNode.position = SCNVector3(0, 0.11, 0)
            
            leftEarNode.eulerAngles.z = 0.22
            rightEarNode.eulerAngles.z = -0.22
            leftLidNode.position.y = 0.018 // Eyes open
            rightLidNode.position.y = 0.018
            
            tailRootNode.eulerAngles = SCNVector3(-0.6, 0.2, 0)
            tailSegmentNode.eulerAngles = SCNVector3(0.3, 0.1, 0)
            
            startBreathingAnimation(cycleDuration: 2.6, amplitude: 1.025)
            
        case .curious:
            // Head tilted, ears forward, body attentive
            headNode.position = SCNVector3(0.01, 0.21, 0.17)
            headNode.eulerAngles = SCNVector3(-0.10, 0.18, 0.14) // Curious tilt
            torsoNode.scale = SCNVector3(1.0, 0.92, 1.30)
            
            leftEarNode.eulerAngles.x = 0.15 // Ears forward
            rightEarNode.eulerAngles.x = 0.15
            leftLidNode.position.y = 0.022 // Wide alert eyes
            rightLidNode.position.y = 0.022
            
            tailRootNode.eulerAngles = SCNVector3(-0.25, 0.35, 0.2)
            tailSegmentNode.eulerAngles = SCNVector3(0.5, 0.2, 0.3)
            
            startBreathingAnimation(cycleDuration: 2.0, amplitude: 1.03)
            
        case .happy:
            // Serene squinting smiling eyes, relaxed outward ears, purring posture
            headNode.position = SCNVector3(0, 0.18, 0.16)
            headNode.eulerAngles = SCNVector3(0.06, 0, 0)
            
            leftEarNode.eulerAngles.z = 0.35 // Outward relaxed ears
            rightEarNode.eulerAngles.z = -0.35
            leftLidNode.position.y = 0.005 // Half closed happy eyes
            rightLidNode.position.y = 0.005
            
            tailRootNode.eulerAngles = SCNVector3(-0.35, -0.2, 0)
            tailSegmentNode.eulerAngles = SCNVector3(0.4, -0.3, 0)
            
            startPurrVibration()
            
        case .sleepy:
            // Head lowering, eyelids drooping, ears slightly flat
            headNode.position = SCNVector3(0, 0.14, 0.16)
            headNode.eulerAngles = SCNVector3(0.18, 0, 0)
            torsoNode.scale = SCNVector3(1.10, 0.82, 1.38)
            
            leftEarNode.eulerAngles.z = 0.38
            rightEarNode.eulerAngles.z = -0.38
            leftLidNode.position.y = 0.003 // Almost closed
            rightLidNode.position.y = 0.003
            
            tailRootNode.eulerAngles = SCNVector3(-0.8, 0.1, 0)
            
            startBreathingAnimation(cycleDuration: 3.2, amplitude: 1.02)
            
        case .excited:
            // Upright posture, tail up, ears alert
            headNode.position = SCNVector3(0, 0.22, 0.17)
            headNode.eulerAngles = SCNVector3(-0.15, 0, 0)
            torsoNode.scale = SCNVector3(0.98, 0.94, 1.28)
            
            leftEarNode.eulerAngles.z = 0.12
            rightEarNode.eulerAngles.z = -0.12
            leftEarNode.eulerAngles.x = 0.20
            rightEarNode.eulerAngles.x = 0.20
            leftLidNode.position.y = 0.022
            rightLidNode.position.y = 0.022
            
            tailRootNode.eulerAngles = SCNVector3(0.2, 0, 0) // Tail high
            tailSegmentNode.eulerAngles = SCNVector3(0.4, 0.2, 0)
            
            startBreathingAnimation(cycleDuration: 1.6, amplitude: 1.035)
            
        case .thinking:
            // Head tilted upward, looking toward window/sky, tail tip twitch
            headNode.position = SCNVector3(0.02, 0.21, 0.15)
            headNode.eulerAngles = SCNVector3(-0.25, 0.35, 0.10)
            
            leftEarNode.eulerAngles.z = 0.20
            rightEarNode.eulerAngles.z = -0.15
            leftLidNode.position.y = 0.015
            rightLidNode.position.y = 0.015
            
            tailRootNode.eulerAngles = SCNVector3(-0.5, 0.4, 0)
            tailSegmentNode.eulerAngles = SCNVector3(0.2, 0.5, 0)
            
            startBreathingAnimation(cycleDuration: 2.8, amplitude: 1.02)
            
        case .resting:
            // Fully curled up into a soft spherical loaf, eyes closed, deep sleep
            headNode.position = SCNVector3(0.08, 0.10, 0.12)
            headNode.eulerAngles = SCNVector3(0.25, 0.45, 0.10) // Head tucked near paws
            torsoNode.scale = SCNVector3(1.18, 0.78, 1.42) // Flatter resting loaf
            torsoNode.position = SCNVector3(0, 0.09, 0)
            
            leftEarNode.eulerAngles.z = 0.42
            rightEarNode.eulerAngles.z = -0.42
            leftLidNode.position.y = -0.002 // Fully closed sleeping eyes
            rightLidNode.position.y = -0.002
            
            // Tail wrapped around body
            tailRootNode.eulerAngles = SCNVector3(-1.1, 0.8, 0)
            tailSegmentNode.eulerAngles = SCNVector3(0.6, 0.8, 0)
            
            startBreathingAnimation(cycleDuration: 3.4, amplitude: 1.03)
        }
        
        SCNTransaction.commit()
    }
    
    // MARK: - Animations
    
    /// Smooth slow breathing animation on Cookie's torso and chest.
    private func startBreathingAnimation(cycleDuration: TimeInterval, amplitude: CGFloat) {
        bodyRoot.removeAction(forKey: "cookie_breathing")
        guard !reduceMotion else { return }
        
        let half = cycleDuration / 2.0
        let breatheIn = SCNAction.scale(to: amplitude, duration: half)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SCNAction.scale(to: 1.0, duration: half)
        breatheOut.timingMode = .easeInEaseOut
        
        let breathingLoop = SCNAction.repeatForever(SCNAction.sequence([breatheIn, breatheOut]))
        bodyRoot.runAction(breathingLoop, forKey: "cookie_breathing")
    }
    
    /// Subtle micro-vibration purr when happy or petted.
    private func startPurrVibration() {
        guard !reduceMotion else { return }
        
        let purrWiggle = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.004, z: 0, duration: 0.12),
            SCNAction.moveBy(x: 0, y: -0.004, z: 0, duration: 0.12)
        ])
        torsoNode.runAction(SCNAction.repeat(purrWiggle, count: 6), forKey: "cookie_purr")
    }
    
    // MARK: - Specific Behaviors
    
    /// Looks smoothly toward a 3D point in the room (e.g., a newly placed item on the desk).
    func lookToward(worldPosition target: SCNVector3) {
        guard !isSleeping else { return }
        
        let dx = target.x - position.x
        let dz = target.z - position.z
        let targetAngle = atan2(dx, dz)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0.0 : 0.65
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        headNode.eulerAngles.y = targetAngle - eulerAngles.y
        headNode.eulerAngles.x = -0.12 // Slight gaze upward toward desk
        
        SCNTransaction.commit()
        
        // Reset gaze back to natural position after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            guard let self, self.currentMood != .curious else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            self.headNode.eulerAngles = SCNVector3(0, 0, 0)
            SCNTransaction.commit()
        }
    }
    
    /// Cookie stretches front paws and arches back gently.
    func performStretch(completion: (() -> Void)? = nil) {
        guard !reduceMotion else {
            completion?()
            return
        }
        
        let stretchDown = SCNAction.group([
            SCNAction.moveBy(x: 0, y: -0.03, z: 0.04, duration: 0.8),
            SCNAction.rotateBy(x: 0.22, y: 0, z: 0, duration: 0.8)
        ])
        stretchDown.timingMode = .easeInEaseOut
        
        let stretchHold = SCNAction.wait(duration: 0.4)
        
        let stretchUp = SCNAction.group([
            SCNAction.moveBy(x: 0, y: 0.03, z: -0.04, duration: 0.8),
            SCNAction.rotateBy(x: -0.22, y: 0, z: 0, duration: 0.8)
        ])
        stretchUp.timingMode = .easeInEaseOut
        
        let sequence = SCNAction.sequence([stretchDown, stretchHold, stretchUp])
        bodyRoot.runAction(sequence) {
            completion?()
        }
    }
    
    /// Cookie cleans its paw by raising it to the muzzle twice.
    func performCleanPaw(completion: (() -> Void)? = nil) {
        guard !reduceMotion else {
            completion?()
            return
        }
        
        let liftPaw = SCNAction.group([
            SCNAction.moveBy(x: 0, y: 0.06, z: 0.02, duration: 0.4),
            SCNAction.rotateBy(x: 0.4, y: 0, z: 0, duration: 0.4)
        ])
        liftPaw.timingMode = .easeOut
        
        let headBob = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: -0.015, z: 0.01, duration: 0.2),
            SCNAction.moveBy(x: 0, y: 0.015, z: -0.01, duration: 0.2)
        ])
        
        let lowerPaw = SCNAction.group([
            SCNAction.moveBy(x: 0, y: -0.06, z: -0.02, duration: 0.4),
            SCNAction.rotateBy(x: -0.4, y: 0, z: 0, duration: 0.4)
        ])
        lowerPaw.timingMode = .easeInEaseOut
        
        frontRightPawNode.runAction(SCNAction.sequence([liftPaw, SCNAction.repeat(headBob, count: 2), lowerPaw])) {
            completion?()
        }
    }
    
    /// Cookie walks naturally from current position to a new position.
    func walkTo(target: SCNVector3, completion: (() -> Void)? = nil) {
        let dx = target.x - position.x
        let dz = target.z - position.z
        let distance = hypot(dx, dz)
        guard distance > 0.05 else {
            completion?()
            return
        }
        
        if reduceMotion {
            self.position = target
            completion?()
            return
        }
        
        let targetAngle = atan2(dx, dz)
        let walkDuration = max(1.2, TimeInterval(distance * 2.8))
        
        // 1. Turn towards destination
        let turn = SCNAction.rotateTo(x: 0, y: targetAngle, z: 0, duration: 0.35, usesShortestPath: true)
        turn.timingMode = .easeOut
        
        // 2. Walk forward with gentle body step bob
        let move = SCNAction.move(to: target, duration: walkDuration)
        move.timingMode = .easeInEaseOut
        
        let stepCycle = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.012, z: 0, duration: 0.22),
            SCNAction.moveBy(x: 0, y: -0.012, z: 0, duration: 0.22)
        ])
        let stepCount = Int(walkDuration / 0.44)
        let steps = SCNAction.repeat(stepCycle, count: max(1, stepCount))
        
        runAction(SCNAction.sequence([
            turn,
            SCNAction.group([move, steps])
        ])) {
            completion?()
        }
    }
    
    /// Cookie curls up and settles down into sleep on the rug.
    func performCurlUp(completion: (() -> Void)? = nil) {
        applyPosture(for: .sleepy, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.applyPosture(for: .resting, animated: true)
            completion?()
        }
    }
    
    /// Cookie gradually wakes up from sleep with a slow blink and stretch.
    func performWakeUp(completion: (() -> Void)? = nil) {
        applyPosture(for: .sleepy, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.applyPosture(for: .idle, animated: true)
            self?.performStretch {
                completion?()
            }
        }
    }
    
    // MARK: - Speech / Expression Bubble
    
    /// Displays a tiny, elegant floating speech bubble above Cookie.
    func showSpeechBubble(text: String, duration: TimeInterval = 3.0) {
        speechBubbleNode?.removeFromParentNode()
        
        let bubblePlane = SCNPlane(width: 0.36, height: 0.16)
        bubblePlane.cornerRadius = 0.08
        
        let bubbleMat = SCNMaterial()
        bubbleMat.diffuse.contents = renderSpeechBubbleImage(text: text)
        bubbleMat.lightingModel = .constant
        bubbleMat.isDoubleSided = true
        bubblePlane.materials = [bubbleMat]
        
        let bubbleNode = SCNNode(geometry: bubblePlane)
        bubbleNode.position = SCNVector3(0, 0.42, 0)
        bubbleNode.constraints = [SCNBillboardConstraint()] // Always faces camera!
        bubbleNode.opacity = 0.0
        bubbleNode.scale = SCNVector3(0.5, 0.5, 0.5)
        
        addChildNode(bubbleNode)
        self.speechBubbleNode = bubbleNode
        
        // Pop in animation
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        bubbleNode.opacity = 0.95
        bubbleNode.scale = SCNVector3(1.0, 1.0, 1.0)
        SCNTransaction.commit()
        
        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak bubbleNode] in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.45
            bubbleNode?.opacity = 0.0
            bubbleNode?.scale = SCNVector3(0.8, 0.8, 0.8)
            SCNTransaction.commit()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bubbleNode?.removeFromParentNode()
            }
        }
    }
    
    /// Renders a tiny text graphic for the speech bubble.
    private func renderSpeechBubbleImage(text: String) -> NSImage {
        let size = CGSize(width: 256, height: 110)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Cream rounded background
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
        let path = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
        NSColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 0.95).setFill()
        path.fill()
        
        NSColor(red: 0.85, green: 0.82, blue: 0.77, alpha: 0.7).setStroke()
        path.lineWidth = 2
        path.stroke()
        
        // Text
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 32, weight: .medium),
            .foregroundColor: NSColor(red: 0.28, green: 0.24, blue: 0.20, alpha: 1.0)
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let strSize = str.size()
        let strRect = CGRect(
            x: (size.width - strSize.width) / 2,
            y: (size.height - strSize.height) / 2,
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: strRect)
        
        image.unlockFocus()
        return image
    }
}

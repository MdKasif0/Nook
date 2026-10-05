import Foundation
import RealityKit
import AppKit
import simd

/// Centralized animation controller for Cookie the miniature cat companion.
///
/// Responsibilities:
/// - Coordinating procedural multi-limb walking waddles (alternating paws, body roll, head bob)
/// - Physically believable 5-stage jumping (crouch, push-off, airborne parabola, landing squash, recovery)
/// - Multi-variant idle behavior scheduler (10 distinct behaviors: sitting, look around, blink, tail twitch, grooming, stretching, look at user, lie down, curl up, head tilt)
/// - Live drag-and-drop feedback (attentive lift, ear reactions, motion tilt, gentle landing squash)
/// - Petting purr reactions
/// - Accessibility Reduce Motion compliance
@MainActor
public final class CookieAnimationController {
    
    public weak var entity: CookieRealityEntity?
    public let state: CookieState
    
    // Active async animation tasks
    private var walkTask: Task<Void, Never>?
    private var idleLoopTask: Task<Void, Never>?
    private var activeActionTask: Task<Void, Never>?
    
    public private(set) var isWalking: Bool = false
    public private(set) var isJumping: Bool = false
    public private(set) var isDragging: Bool = false
    
    public init(entity: CookieRealityEntity? = nil, state: CookieState = CookieState()) {
        self.entity = entity
        self.state = state
        startIdleScheduler()
    }
    
    isolated deinit {
        walkTask?.cancel()
        idleLoopTask?.cancel()
        activeActionTask?.cancel()
    }
    
    private var shouldReduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    
    // MARK: - 1. Walking Animation (Alternating Paws, Body Roll, Head Bob)
    
    public func startWalking() {
        guard !isWalking else { return }
        isWalking = true
        state.transitionToActivity(.walking)
        
        walkTask?.cancel()
        walkTask = Task { @MainActor [weak self] in
            var t: Float = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000) // ~50 fps
                guard let self = self, let entity = self.entity, self.isWalking else { break }
                
                if self.shouldReduceMotion {
                    continue
                }
                
                t += 0.16
                let strideFreq: Float = 1.0
                let pawSwing: Float = 0.016
                let pawLift: Float = 0.007
                
                let phase = t * strideFreq
                let leftCos = cos(phase)
                let rightCos = -leftCos
                
                // Alternating front paws
                entity.leftFrontPawModel?.position.z = 0.028 + leftCos * pawSwing
                entity.leftFrontPawModel?.position.y = 0.044 + max(0, sin(phase)) * pawLift
                
                entity.rightFrontPawModel?.position.z = 0.032 + rightCos * pawSwing
                entity.rightFrontPawModel?.position.y = 0.028 + max(0, -sin(phase)) * pawLift
                
                // Alternating hind feet
                entity.leftFootModel?.position.z = 0.042 + rightCos * (pawSwing * 0.8)
                entity.rightFootModel?.position.z = 0.042 + leftCos * (pawSwing * 0.8)
                
                // Cute rhythmic body waddle (roll) and gentle bounce
                let rollAngle = sin(phase) * 0.035
                entity.bodyModel?.orientation = simd_quatf(angle: rollAngle, axis: [0, 0, 1])
                entity.bodyModel?.position.y = 0.044 + abs(sin(phase * 2.0)) * 0.0018
                
                // Head bob
                entity.headModel?.position.y = 0.100 + abs(sin(phase * 2.0)) * 0.0014
                
                // Tail sway
                let tailSway = sin(phase * 0.75) * 0.14
                entity.tailBaseModel?.orientation = simd_quatf(angle: 0.55, axis: [1, 0, 0]) * simd_quatf(angle: 0.52 + tailSway, axis: [0, 0, 1])
            }
        }
    }
    
    public func stopWalking() {
        isWalking = false
        walkTask?.cancel()
        walkTask = nil
        
        // Return limbs smoothly to comfortable resting posture
        Task { @MainActor [weak self] in
            guard let self = self, let entity = self.entity else { return }
            entity.setPosture(.sitting, animated: true)
            self.state.transitionToActivity(.sitting)
        }
    }
    
    // MARK: - 2. Believable 5-Stage Jump
    
    public func playJumpSequence(from start: SIMD3<Float>, to end: SIMD3<Float>) async {
        guard let entity = self.entity else { return }
        isJumping = true
        state.transitionToActivity(.jumping)
        
        // Stage 1: Crouch Anticipation (0.10s)
        entity.bodyModel?.scale = [1.06, 0.82, 1.06]
        entity.headModel?.position.y = 0.090
        entity.leftFrontPawModel?.position.y = 0.038
        entity.rightFrontPawModel?.position.y = 0.024
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Stage 2: Push-off Extension (0.06s)
        entity.bodyModel?.scale = [0.94, 1.18, 0.94]
        entity.headModel?.position.y = 0.106
        entity.leftFrontPawModel?.position.y = 0.052
        entity.rightFrontPawModel?.position.y = 0.036
        try? await Task.sleep(nanoseconds: 60_000_000)
        
        // Stage 3: Airborne Ballistic Parabolic Arc (0.36s)
        let flightSteps = 16
        let flightDt = 0.36 / Double(flightSteps)
        let deltaY = end.y - start.y
        let peakBonus: Float = max(0.12, abs(deltaY) * 0.5 + 0.08)
        
        for i in 1...flightSteps {
            try? await Task.sleep(nanoseconds: UInt64(flightDt * 1_000_000_000))
            let progress = Float(i) / Float(flightSteps)
            
            // Linear horizontal progress + parabolic vertical arc
            let curX = start.x + (end.x - start.x) * progress
            let curZ = start.z + (end.z - start.z) * progress
            let baseCurY = start.y + deltaY * progress
            let arcY = 4.0 * peakBonus * progress * (1.0 - progress)
            
            entity.position = [curX, baseCurY + arcY, curZ]
            
            // Dynamic mid-air body pitch
            let pitchProgress = (progress - 0.5) * 2.0 // -1 to +1
            entity.bodyModel?.orientation = simd_quatf(angle: -pitchProgress * 0.18, axis: [1, 0, 0])
        }
        
        entity.position = end
        
        // Stage 4: Landing Squash (0.10s)
        entity.bodyModel?.scale = [1.12, 0.82, 1.12]
        entity.headModel?.position.y = 0.092
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Stage 5: Recovery to Natural Sitting (0.14s)
        entity.bodyModel?.scale = [1.0, 1.0, 1.0]
        entity.headModel?.position.y = 0.100
        entity.bodyModel?.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
        entity.setPosture(.sitting, animated: true)
        
        isJumping = false
        state.transitionToActivity(.sitting)
    }
    
    // MARK: - 3. Multi-Variant Idle Behavior Scheduler
    
    private func startIdleScheduler() {
        idleLoopTask?.cancel()
        idleLoopTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                // Wait randomized idle interval (3.5s - 7.5s)
                let delay = UInt64.random(in: 3_500_000_000...7_500_000_000)
                try? await Task.sleep(nanoseconds: delay)
                guard let self = self, let entity = self.entity else { break }
                
                // Do not interrupt active locomotive or interactive states
                guard !self.isWalking, !self.isJumping, !self.isDragging, !self.shouldReduceMotion else { continue }
                
                await self.executeRandomIdleVariant()
            }
        }
    }
    
    private func executeRandomIdleVariant() async {
        guard let entity = self.entity else { return }
        
        // 10 distinct idle animations matching prompt:
        // 1. Sitting
        // 2. Looking around
        // 3. Blinking
        // 4. Tail twitch
        // 5. Paw grooming
        // 6. Stretching
        // 7. Looking at the user
        // 8. Lying down
        // 9. Curling up
        // 10. Small head tilt
        let roll = Int.random(in: 1...10)
        
        switch roll {
        case 1: // 1. Sitting Contentment
            state.transitionToActivity(.sitting)
            entity.setMood(.idle, animated: true)
            
        case 2: // 2. Looking Around (Glance left, glance right, settle)
            state.transitionToActivity(.lookingAround)
            entity.headModel?.orientation = simd_quatf(angle: 0.24, axis: [0, 1, 0])
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            entity.headModel?.orientation = simd_quatf(angle: -0.20, axis: [0, 1, 0])
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            state.transitionToActivity(.sitting)
            
        case 3: // 3. Irregular Double Blink
            entity.blink()
            try? await Task.sleep(nanoseconds: 180_000_000)
            entity.blink()
            
        case 4: // 4. Playful Tail Twitch
            entity.swishTail()
            
        case 5: // 5. Paw Grooming
            state.transitionToActivity(.grooming)
            entity.setPosture(.cleaningPaw, animated: true)
            entity.headModel?.position.y = 0.092
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            entity.headModel?.position.y = 0.100
            entity.setPosture(.sitting, animated: true)
            state.transitionToActivity(.sitting)
            
        case 6: // 6. Gentle Cat Stretch
            state.transitionToActivity(.idle)
            entity.setPosture(.stretching, animated: true)
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            entity.setPosture(.sitting, animated: true)
            state.transitionToActivity(.sitting)
            
        case 7: // 7. Looking Directly at User Camera
            state.transitionToActivity(.curious)
            entity.setMood(.curious, animated: true)
            entity.headModel?.orientation = simd_quatf(angle: -0.15, axis: [0, 1, 0]) * simd_quatf(angle: 0.10, axis: [1, 0, 0])
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            entity.setMood(.idle, animated: true)
            state.transitionToActivity(.sitting)
            
        case 8: // 8. Lying Down
            state.transitionToActivity(.lyingDown)
            entity.setPosture(.curled, animated: true)
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            entity.setPosture(.sitting, animated: true)
            state.transitionToActivity(.sitting)
            
        case 9: // 9. Curling Up (Mochi Nap Ball)
            state.transitionToActivity(.sleeping)
            entity.setMood(.sleepy, animated: true)
            entity.setPosture(.curled, animated: true)
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            entity.setMood(.idle, animated: true)
            entity.setPosture(.sitting, animated: true)
            state.transitionToActivity(.sitting)
            
        case 10: // 10. Inquisitive Head Tilt
            state.transitionToActivity(.curious)
            entity.headModel?.orientation = simd_quatf(angle: 0.18, axis: [0, 0, 1])
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 0, 1])
            state.transitionToActivity(.sitting)
            
        default:
            break
        }
    }
    
    // MARK: - 4. Live Drag Reactions
    
    public func onDragStart() {
        isDragging = true
        state.transitionToActivity(.beingDragged)
        
        guard let entity = self.entity else { return }
        // Attentive posture: ears perk, eyes widen, tail wraps upward
        entity.setMood(.curious, animated: true)
        entity.leftEarModel?.orientation = simd_quatf(angle: 0.65, axis: [0, 0, 1])
        entity.rightEarModel?.orientation = simd_quatf(angle: -0.65, axis: [0, 0, 1])
        entity.tailBaseModel?.orientation = simd_quatf(angle: 0.75, axis: [1, 0, 0])
        
        // Soft elevation glow
        if let glow = entity.findEntity(named: "cookie_warm_glow") as? PointLight {
            glow.light.intensity = 1500
        }
    }
    
    public func onDragUpdate(velocity: SIMD2<Float>) {
        guard isDragging, let entity = self.entity else { return }
        
        // Dynamic tilt based on drag motion
        let tiltRoll = min(max(velocity.x * 0.04, -0.15), 0.15)
        let tiltPitch = min(max(velocity.y * 0.04, -0.12), 0.12)
        entity.bodyModel?.orientation = simd_quatf(angle: tiltRoll, axis: [0, 0, 1]) * simd_quatf(angle: tiltPitch, axis: [1, 0, 0])
    }
    
    public func onDragEnd(at finalPos: SIMD3<Float>) {
        isDragging = false
        guard let entity = self.entity else { return }
        
        // Settle glow
        if let glow = entity.findEntity(named: "cookie_warm_glow") as? PointLight {
            glow.light.intensity = 1100
        }
        
        // Gentle landing squash and shake recovery
        Task { @MainActor [weak self] in
            entity.bodyModel?.scale = [1.08, 0.88, 1.08]
            try? await Task.sleep(nanoseconds: 80_000_000)
            
            // Soft ruffle shake
            entity.bodyModel?.scale = [1.0, 1.0, 1.0]
            entity.headModel?.orientation = simd_quatf(angle: 0.10, axis: [0, 1, 0])
            try? await Task.sleep(nanoseconds: 100_000_000)
            entity.headModel?.orientation = simd_quatf(angle: -0.10, axis: [0, 1, 0])
            try? await Task.sleep(nanoseconds: 100_000_000)
            entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            
            entity.setPosture(.sitting, animated: true)
            entity.setMood(.idle, animated: true)
            self?.state.transitionToActivity(.sitting)
        }
    }
    
    public func playSettleReaction() {
        guard let entity = self.entity else { return }
        Task { @MainActor in
            entity.setPosture(.sitting, animated: true)
            entity.blink()
        }
    }
    
    // MARK: - 5. Petting Purr Reaction
    
    public func playPettingReaction() {
        guard let entity = self.entity else { return }
        state.transitionToActivity(.happy)
        entity.pet()
        CookieMemoryStore.shared.recordPet()
    }
}

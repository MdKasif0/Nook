import Foundation
import RealityKit
import SwiftUI
import simd
import os

/// Dedicated behavioral engine that gives Cookie a believable, living personality.
///
/// Cookie is NOT an AI chatbot. Cookie communicates primarily through:
/// - Locomotion and destination choices
/// - Anatomical facial expressions (eyes, cheeks, ω smile)
/// - Ears and tail movement
/// - Dynamic postures (sitting, pointing, stretching, curled)
/// - Soft native audio vocalizations and subtle purring
/// - Natural context-driven reactions to room events
///
/// 100% local, deterministic, and privacy-respecting.
@MainActor
@Observable
public final class CookieBehaviorController {
    
    public let state: CookieState
    public weak var entity: CookieRealityEntity?
    public let audio = CookieAudioController.shared
    
    private static let logger = Logger(subsystem: "com.nook.app", category: "CookieBehavior")
    
    // Subscriptions and tasks
    private var eventSubscriptionToken: UUID?
    private var ambientLoopTask: Task<Void, Never>?
    private var activeReactionTask: Task<Void, Never>?
    
    // Cooldown and rate-limiting trackers
    private var lastReactionTime: Date = .distantPast
    private var lastCursorLookTime: Date = .distantPast
    private var lastObjectMoveReactionTime: Date = .distantPast
    private var lastClickReactionTime: Date = .distantPast
    private var lastClickReactionIndex: Int = -1
    private var recentCreationTimestamps: [Date] = []
    
    // Preferred Rest & Exploration Anchor Locations
    public static let bedRestLocation = RoomNavZone.daybed.defaultSpot
    public static let deskExploreLocation = RoomNavZone.desk.defaultSpot
    public static let windowLedgeLocation = RoomNavZone.windowLedge.defaultSpot
    public static let loungeLocation = RoomNavZone.lowerFloor.defaultSpot
    public static let poufLocation = SIMD3<Float>(0.20, 0.020, 0.65)
    public static let chairRestLocation = SIMD3<Float>(-0.42, 0.160, -0.20)
    public static let plantInspectLocation = SIMD3<Float>(-0.28, 0.160, -0.05)
    
    @MainActor
    public enum PreferredRestLocation: String, CaseIterable, Sendable {
        case bed = "Bed"
        case catCushion = "Cat Cushion"
        case deskChair = "Desk Chair"
        case windowArea = "Window Area"
        
        public var spot: SIMD3<Float> {
            switch self {
            case .bed:        return CookieBehaviorController.bedRestLocation
            case .catCushion: return CookieBehaviorController.poufLocation
            case .deskChair:  return CookieBehaviorController.chairRestLocation
            case .windowArea: return CookieBehaviorController.windowLedgeLocation
            }
        }
    }
    
    private var lastRestLocation: PreferredRestLocation?
    
    public func choosePreferredRestLocation(at date: Date = Date()) -> PreferredRestLocation {
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 22 || hour < 7 {
            lastRestLocation = .bed
            return .bed
        }
        var candidateLocations = PreferredRestLocation.allCases
        if let last = lastRestLocation, candidateLocations.count > 1 {
            candidateLocations.removeAll { $0 == last }
        }
        let chosen: PreferredRestLocation
        if hour >= 12 && hour < 17 {
            let afternoonPool: [PreferredRestLocation] = candidateLocations.contains(.windowArea) ? [.windowArea, .catCushion, .bed] : candidateLocations
            chosen = afternoonPool.randomElement() ?? .bed
        } else {
            chosen = candidateLocations.randomElement() ?? .bed
        }
        lastRestLocation = chosen
        return chosen
    }
    
    public init(state: CookieState = CookieState()) {
        self.state = state
        setupEventSubscription()
        startAmbientBehaviorLoop()
    }
    
    isolated deinit {
        ambientLoopTask?.cancel()
        activeReactionTask?.cancel()
    }
    
    public func bind(entity: CookieRealityEntity) {
        self.entity = entity
    }
    
    func bind(node: CookieNode) {
        // Backward compatibility stub for SceneKit prototype view
    }
    
    // MARK: - Room Event Subscription
    
    private func setupEventSubscription() {
        eventSubscriptionToken = RoomEventBus.shared.subscribe { [weak self] event in
            guard let self else { return }
            self.handleEvent(event)
        }
    }
    
    // MARK: - Event Dispatching & Natural Personality Reactions
    
    func handleEvent(_ event: RoomEvent) {
        guard PreferencesManager.shared.cookieReactionsEnabled else { return }
        state.lastInteraction = .now
        
        switch event {
        case .roomOpened(let wasAwayDuration):
            handleRoomOpened(awayDuration: wasAwayDuration)
            
        case .roomClosed:
            handleRoomClosed()
            
        case .itemCreated(let title, let itemType, let objectType, let position):
            let worldPos = SIMD3<Float>(
                -0.70 + (Float(position.x) - 0.5) * 0.40,
                RoomNavZone.desk.surfaceY,
                -0.15 + (Float(position.y) - 0.5) * 0.40
            )
            handleThoughtCreated(title: title, itemType: itemType, objectType: objectType, position: worldPos)
            
        case .thoughtCreated(let title, let itemType, let objectType, let position):
            handleThoughtCreated(title: title, itemType: itemType, objectType: objectType, position: position)
            
        case .thoughtOpened(let id):
            handleThoughtOpened(id: id)
            
        case .thoughtEdited(let id):
            handleThoughtEdited(id: id)
            
        case .itemDeleted:
            handleThoughtDeleted(lastPosition: nil)
            
        case .thoughtDeleted(_, let lastPos):
            handleThoughtDeleted(lastPosition: lastPos)
            
        case .itemCompleted(let title):
            handleItemCompleted(title: title)
            
        case .thoughtCaptured(let title, let objectType):
            let defaultDeskPos = RoomNavZone.desk.defaultSpot
            handleThoughtCreated(title: title, itemType: .idea, objectType: objectType, position: defaultDeskPos)
            
        case .objectMoved(let id, let position):
            handleObjectMoved(id: id, position: position)
            
        case .objectDropped(let id, let position):
            handleObjectDropped(id: id, position: position)
            
        case .searchPerformed(let query):
            handleSearchPerformed(query: query)
            
        case .userIdle(let duration):
            handleUserIdle(duration: duration)
            
        case .longIdle:
            handleUserIdle(duration: 60.0)
            
        case .userReturned:
            handleUserReturned()
            
        case .cookieClicked:
            handleCookieClicked()
            
        case .cookiePetted:
            handleCookiePetted()
            
        case .cookieDragged(let start, let end):
            handleCookieDragged(start: start, end: end)
            
        case .cookieCalled(let target):
            handleCookieCalled(target: target)
        }
    }
    
    // MARK: - Thought Lifecycle Reactions
    
    private func handleThoughtCreated(title: String, itemType: NookItemType, objectType: NookObjectType, position: SIMD3<Float>) {
        let now = Date()
        recentCreationTimestamps.append(now)
        // Keep creations within last 60 seconds
        recentCreationTimestamps.removeAll { now.timeIntervalSince($0) > 60.0 }
        
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self, let entity = self.entity else { return }
            
            // 1. Check if user is in a creative flow with multiple rapid thoughts!
            if self.recentCreationTimestamps.count >= 3 {
                // Excited reaction!
                entity.setMood(.happy, animated: true)
                entity.setPosture(.pointing, animated: true)
                entity.swishTail()
                self.audio.play(.happyMeow, force: true)
                
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                entity.setPosture(.sitting, animated: true)
                entity.setMood(.idle, animated: true)
                return
            }
            
            // 2. Cooldown check for individual thought creation reactions
            let elapsed = now.timeIntervalSince(self.lastReactionTime)
            guard elapsed > 4.0 else { return }
            self.lastReactionTime = now
            
            // If sleeping, subtle ear perk or gentle stretch
            if self.state.isSleeping {
                entity.leftEarModel?.orientation = simd_quatf(angle: 0.62, axis: [0, 0, 1])
                try? await Task.sleep(nanoseconds: 600_000_000)
                entity.blink()
                return
            }
            
            // Stop current activity and notice the new object
            entity.setMood(.curious, animated: true)
            entity.curiousLook(at: position)
            self.audio.play(.curiousChirp, force: false)
            
            // Differentiated reactions based on type:
            switch itemType {
            case .idea:
                // Idea: Cookie walks closer if accessible, tilts head, and observes
                let curPos = entity.position
                let dist = simd_distance(curPos, position)
                if dist > 0.35 && dist < 1.10 {
                    let intermediate = curPos + (position - curPos) * 0.40
                    let safeApproach = CookieNavigationController.clampToWalkable(intermediate)
                    await entity.callCookie(to: safeApproach)
                }
                entity.setPosture(.pointing, animated: true)
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                
            case .photo:
                // Photo / Polaroid: Inspect with head tilt
                entity.headModel?.orientation = simd_quatf(angle: 0.18, axis: [0, 0, 1])
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
            case .reminder, .thought, .link:
                // Reminder: Brief look, ear twitch, returns to calm resting
                entity.swishTail()
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                
            case .note, .quote:
                // Note: Sniff toward object
                entity.headModel?.orientation = simd_quatf(angle: 0.16, axis: [1, 0, 0])
                try? await Task.sleep(nanoseconds: 1_400_000_000)
            }
            
            entity.setPosture(.sitting, animated: true)
            entity.setMood(.idle, animated: true)
        }
    }
    
    private func handleThoughtOpened(id: UUID) {
        guard !state.isSleeping, let entity = self.entity else { return }
        let now = Date()
        guard now.timeIntervalSince(lastReactionTime) > 3.0 else { return }
        lastReactionTime = now
        
        entity.blink()
        entity.headModel?.orientation = simd_quatf(angle: -0.12, axis: [0, 1, 0])
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        }
    }
    
    private func handleThoughtEdited(id: UUID) {
        guard !state.isSleeping, let entity = self.entity else { return }
        entity.swishTail()
    }
    
    private func handleThoughtDeleted(lastPosition: SIMD3<Float>?) {
        guard let entity = self.entity else { return }
        recentCreationTimestamps.removeAll()
        
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor in
            entity.setMood(.thinking, animated: true)
            if let pos = lastPosition {
                entity.curiousLook(at: pos)
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            entity.setMood(.idle, animated: true)
        }
    }
    
    private func handleItemCompleted(title: String) {
        guard let entity = self.entity else { return }
        
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            entity.happy()
            self.audio.playHappyReaction()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            entity.setMood(.idle, animated: true)
            entity.setPosture(.sitting, animated: true)
        }
    }
    
    // MARK: - Object Dragging & Movement Awareness
    
    private func handleObjectMoved(id: String, position: SIMD3<Float>) {
        guard !state.isSleeping, let entity = self.entity else { return }
        let now = Date()
        guard now.timeIntervalSince(lastObjectMoveReactionTime) > 2.0 else { return }
        
        let dist = simd_distance(entity.position, position)
        
        // Check if object is a toy or yarn ball
        if id == "prop_yarn_ball" || id.lowercased().contains("toy") {
            if dist < 0.55 {
                lastObjectMoveReactionTime = now
                handleToyMoved(position: position)
                return
            }
        }
        
        if dist < 0.38 {
            lastObjectMoveReactionTime = now
            entity.curiousLook(at: position)
            
            // If moved uncomfortably close (< 14cm), take a subtle cute step back
            if dist < 0.14 {
                let awayDir = simd_normalize(entity.position - position)
                let nudge = entity.position + SIMD3<Float>(awayDir.x * 0.04, 0, awayDir.z * 0.04)
                let safeNudge = CookieNavigationController.clampToWalkable(nudge)
                entity.position = safeNudge
            }
        }
    }
    
    // MARK: - Play Behavior with Toys & Props
    
    private func handleToyMoved(position: SIMD3<Float>) {
        guard !state.isSleeping, let entity = self.entity else { return }
        
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // 1. Look
            entity.setMood(.curious, animated: true)
            entity.curiousLook(at: position)
            self.audio.play(.curiousChirp, force: true)
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            // 2. Approach
            let cur = entity.position
            let delta = position - cur
            let approachSpot = position - simd_normalize(delta) * 0.10
            let safeSpot = CookieNavigationController.clampToWalkable(approachSpot)
            await entity.callCookie(to: safeSpot)
            
            // 3. Paw at toy
            entity.setPosture(.pointing, animated: true)
            entity.swishTail(.excited)
            try? await Task.sleep(nanoseconds: 700_000_000)
            
            // 4. Chase slightly (tiny playful hop)
            entity.play()
            self.audio.play(.happyMeow, force: true)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            
            // 5. Sit
            entity.setPosture(.sitting, animated: true)
            entity.setMood(.idle, animated: true)
            self.state.transitionToActivity(.sitting)
        }
    }
    
    private func handleObjectDropped(id: String, position: SIMD3<Float>) {
        guard !state.isSleeping, let entity = self.entity else { return }
        let dist = simd_distance(entity.position, position)
        if dist < 0.40 {
            entity.headModel?.orientation = simd_quatf(angle: 0.14, axis: [1, 0, 0])
            entity.blink()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                entity.headModel?.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
            }
        }
    }
    
    private func handleSearchPerformed(query: String) {
        guard !state.isSleeping, let entity = self.entity else { return }
        entity.setMood(.curious, animated: true)
        entity.headModel?.orientation = simd_quatf(angle: 0.15, axis: [0, 0, 1])
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            entity.setMood(.idle, animated: true)
        }
    }
    
    // MARK: - User Presence, Absence & Wake Sequences
    
    private func handleUserIdle(duration: TimeInterval) {
        guard !state.isSleeping, duration >= 45.0, let entity = self.entity else { return }
        
        // Natural settling sequence:
        // walking -> looking around -> yawn -> walk to bed/rest spot -> curl up -> sleep
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // 1. Walking slightly toward open area
            self.state.transitionToActivity(.walking)
            let curPos = entity.position
            let wanderTarget = curPos + SIMD3<Float>(0.06, 0, 0.04)
            let safeWander = CookieNavigationController.clampToWalkable(wanderTarget)
            await entity.callCookie(to: safeWander)
            
            // 2. Looking around
            self.state.transitionToActivity(.lookingAround)
            entity.headModel?.orientation = simd_quatf(angle: 0.22, axis: [0, 1, 0])
            entity.blink()
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            entity.headModel?.orientation = simd_quatf(angle: -0.18, axis: [0, 1, 0])
            try? await Task.sleep(nanoseconds: 900_000_000)
            entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            
            // 3. Yawn / sleepy murmur
            entity.headModel?.orientation = simd_quatf(angle: 0.14, axis: [1, 0, 0])
            self.audio.playSleepyMurmur()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // 4. Walk to preferred rest location (bed, cat cushion, chair, or window)
            let chosenRest = self.choosePreferredRestLocation()
            await entity.callCookie(to: chosenRest.spot)
            
            // 5. Curl up
            entity.setPosture(.curled, animated: true)
            entity.setMood(.resting, animated: true)
            
            // 6. Sleep with occasional subtle purr
            self.state.transitionToActivity(.sleeping)
            self.audio.startPurring()
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            self.audio.stopPurring()
        }
    }
    
    private func handleUserReturned() {
        guard state.isSleeping, let entity = self.entity else { return }
        
        // Natural wake sequence without teleporting:
        // ear twitch -> slight movement -> stretch -> yawn -> stand -> look around
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // 1. Ear twitch
            entity.leftEarModel?.orientation = simd_quatf(angle: 0.62, axis: [0, 0, 1])
            try? await Task.sleep(nanoseconds: 350_000_000)
            
            // 2. Slight movement
            entity.bodyModel?.position = [0, 0.042, 0]
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // 3. Stretch
            entity.setPosture(.stretching, animated: true)
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            // 4. Yawn
            entity.headModel?.orientation = simd_quatf(angle: 0.12, axis: [1, 0, 0])
            self.audio.playSleepyMurmur()
            try? await Task.sleep(nanoseconds: 700_000_000)
            
            // 5. Stand & soft meow
            entity.setPosture(.standing, animated: true)
            self.audio.play(.softMeow, force: true)
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            // 6. Look around & sit
            entity.headModel?.orientation = simd_quatf(angle: 0.20, axis: [0, 1, 0])
            entity.blink()
            try? await Task.sleep(nanoseconds: 600_000_000)
            entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            entity.setPosture(.sitting, animated: true)
            entity.setMood(.idle, animated: true)
            self.state.transitionToActivity(.sitting)
        }
    }
    
    private func handleRoomOpened(awayDuration: TimeInterval) {
        if awayDuration > 30.0 || state.isSleeping {
            handleUserReturned()
        } else {
            entity?.blink()
            audio.play(.tinyMeow, force: false)
        }
    }
    
    private func handleRoomClosed() {
        audio.stopAll()
        if let pos = entity?.position, let rot = entity?.rotationAngleY {
            let zone = CookieNavigationController.zone(for: pos)
            CookieMemoryStore.shared.updatePosition(pos, rotationY: rot, zone: zone.rawValue)
        }
    }
    
    // MARK: - Direct User Interactions (Click, Pet, Drag, Call)
    
    private func handleCookieClicked() {
        guard let entity = self.entity else { return }
        let now = Date()
        guard now.timeIntervalSince(lastClickReactionTime) > 0.8 else { return }
        lastClickReactionTime = now
        
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // If sleeping, wake up pleasantly
            if self.state.isSleeping {
                self.handleUserReturned()
                return
            }
            
            // Select next reaction ensuring it does not repeat the previous one
            var candidates = [0, 1, 2, 3] // 0: happy, 1: curious, 2: sleepy, 3: playful
            if self.lastClickReactionIndex >= 0 {
                candidates.removeAll { $0 == self.lastClickReactionIndex }
            }
            let choice = candidates.randomElement() ?? 0
            self.lastClickReactionIndex = choice
            
            switch choice {
            case 0: // Happy
                entity.setMood(.happy, animated: true)
                entity.swishTail(.happy)
                self.audio.play(.happyMeow, force: true)
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                entity.setMood(.idle, animated: true)
                
            case 1: // Curious
                entity.setMood(.curious, animated: true)
                entity.headModel?.orientation = simd_quatf(angle: 0.16, axis: [0, 0, 1])
                entity.swishTail(.curious)
                self.audio.play(.curiousChirp, force: true)
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                entity.headModel?.orientation = simd_quatf(angle: 0, axis: [0, 0, 1])
                entity.setMood(.idle, animated: true)
                
            case 2: // Sleepy
                entity.setMood(.sleepy, animated: true)
                entity.setPosture(.stretching, animated: true)
                self.audio.playSleepyMurmur()
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                entity.setPosture(.sitting, animated: true)
                entity.setMood(.idle, animated: true)
                
            default: // Playful
                entity.play()
                self.audio.play(.tinyMeow, force: true)
            }
            
            CookieMemoryStore.shared.recordPet()
        }
    }
    
    private func handleCookiePetted() {
        guard let entity = self.entity else { return }
        
        self.state.transition(to: .happy, posture: .sitting)
        
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            entity.setMood(.happy, animated: true)
            entity.setPosture(.sitting, animated: true)
            
            // Eyes gently close, ears relax, purr starts
            entity.leftEyeModel?.scale = [1.08, 0.20, 1.0]
            entity.rightEyeModel?.scale = [1.08, 0.20, 1.0]
            self.audio.startPurring()
            entity.swishTail(.happy)
            
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            
            self.audio.stopPurring()
            entity.setMood(.idle, animated: true)
            self.state.transition(to: .idle, posture: .sitting)
            CookieMemoryStore.shared.recordPet()
        }
    }
    
    private func handleCookieDragged(start: SIMD3<Float>, end: SIMD3<Float>) {
        audio.stopPurring()
        state.transitionToActivity(.beingDragged)
    }
    
    private func handleCookieCalled(target: SIMD3<Float>) {
        guard let entity = self.entity else { return }
        
        activeReactionTask?.cancel()
        activeReactionTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // 1. Notice user
            if self.state.isSleeping {
                self.handleUserReturned()
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            
            entity.setMood(.curious, animated: true)
            self.audio.play(.tinyMeow, force: true)
            
            // 2. Walk toward target
            let safeTarget = CookieNavigationController.clampToWalkable(target)
            await entity.callCookie(to: safeTarget)
            
            // 3. Stop near position, look at user, sit
            entity.setPosture(.sitting, animated: true)
            entity.blink()
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            entity.setMood(.idle, animated: true)
        }
    }
    
    // MARK: - User-Cursor Proximity Awareness
    
    /// Called when the user's cursor moves within the 3D room.
    public func handleCursorHover(at roomPosition: SIMD3<Float>) {
        guard !state.isSleeping,
              let entity = self.entity,
              entity.animationController?.isWalking == false,
              entity.animationController?.isJumping == false,
              entity.animationController?.isDragging == false else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastCursorLookTime) > 3.8 else { return }
        
        let dist = simd_distance(entity.position, roomPosition)
        if dist < 0.28 {
            lastCursorLookTime = now
            entity.curiousLook(at: roomPosition)
        }
    }
    
    // MARK: - Ambient Autonomous Behavior Loop
    
    private func startAmbientBehaviorLoop() {
        ambientLoopTask?.cancel()
        ambientLoopTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                // Wait randomized interval: 14s to 24s
                let delay = UInt64.random(in: 14_000_000_000...24_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
                guard let self = self, let entity = self.entity else { break }
                
                // Do not interrupt active locomotive, dragging, or modal interactions
                guard entity.animationController?.isWalking == false,
                      entity.animationController?.isJumping == false,
                      entity.animationController?.isDragging == false else { continue }
                
                await self.performContextualAmbientAction()
            }
        }
    }
    
    private func performContextualAmbientAction() async {
        guard let entity = self.entity else { return }
        
        // Determine time-of-day context
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isNight = (currentHour >= 22 || currentHour < 7)
        
        // If night and already sleeping, stay asleep with occasional soft purr or ear twitch
        if isNight && state.isSleeping {
            entity.leftEarModel?.orientation = simd_quatf(angle: 0.60, axis: [0, 0, 1])
            try? await Task.sleep(nanoseconds: 300_000_000)
            entity.leftEarModel?.orientation = simd_quatf(angle: 0.52, axis: [0, 0, 1])
            return
        }
        
        // Weighted random selection of natural cat behaviors
        let roll = Int.random(in: 1...100)
        
        if isNight {
            // Night: 70% chance of bed lounging / sleep
            if roll <= 70 {
                await entity.goToBed()
            } else if roll <= 85 {
                entity.setPosture(.curled, animated: true)
                audio.playSleepyMurmur()
            } else {
                entity.setPosture(.stretching, animated: true)
            }
        } else {
            // Daytime: Exploration, window gazing, plant sniffing, desk perched, grooming
            if roll <= 22 {
                // 1. Gaze outdoors from window sill
                await entity.goToWindow()
                audio.playAutonomousGreeting()
            } else if roll <= 44 {
                // 2. Approach desk to observe diorama
                await entity.goToDesk()
            } else if roll <= 60 {
                // 3. Inspect floor plant / succulent
                await entity.callCookie(to: Self.plantInspectLocation)
                entity.headModel?.orientation = simd_quatf(angle: 0.16, axis: [1, 0, 0])
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                entity.headModel?.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
            } else if roll <= 75 {
                // 4. Paw grooming
                entity.setPosture(.cleaningPaw, animated: true)
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                entity.setPosture(.sitting, animated: true)
            } else if roll <= 88 {
                // 5. Gentle cat stretch
                entity.setPosture(.stretching, animated: true)
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                entity.setPosture(.sitting, animated: true)
            } else {
                // 6. Play with toy / happy bounce
                entity.play()
                audio.playAutonomousGreeting()
            }
        }
    }
}

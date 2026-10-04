import SceneKit
import SwiftUI

/// Coordinates Cookie's state transitions, idle loops, locomotion, and event reactions.
///
/// Implements a state-driven architecture that responds to user actions without
/// hard-coding behavior into views or crowding the 3D scene controller.
@MainActor
@Observable
final class CookieBehaviorController {
    
    let state: CookieState
    weak var cookieNode: CookieNode?
    
    // Positions in diorama
    static let rugHomePosition = SCNVector3(-0.95, 0.03, 0.70)
    static let nearDeskPosition = SCNVector3(-0.45, 0.03, 0.55)
    
    private var eventSubscriptionToken: UUID?
    private var idleLoopTask: Task<Void, Never>?
    private var isExecutingBehavior: Bool = false
    
    init(state: CookieState = CookieState()) {
        self.state = state
        setupEventSubscription()
        startIdleMonitoring()
    }
    
    isolated deinit {
        idleLoopTask?.cancel()
    }
    
    func bind(node: CookieNode) {
        self.cookieNode = node
    }
    
    // MARK: - Event Subscription
    
    private func setupEventSubscription() {
        eventSubscriptionToken = RoomEventBus.shared.subscribe { [weak self] event in
            guard let self else { return }
            self.handleEvent(event)
        }
    }
    
    // MARK: - Event Reactions
    
    private func handleEvent(_ event: RoomEvent) {
        state.lastInteraction = .now
        
        Task { @MainActor in
            switch event {
            case .itemCreated(_, _, _, let position):
                state.consecutiveThoughtsCount += 1
                if PreferencesManager.shared.cookieReactionsEnabled {
                    await handleNewItemCreated(at: position)
                }
                
            case .itemDeleted:
                state.consecutiveThoughtsCount = max(0, state.consecutiveThoughtsCount - 1)
                if PreferencesManager.shared.cookieReactionsEnabled {
                    await execute(ObjectDeletedReactionBehavior())
                }
                
            case .itemCompleted:
                if PreferencesManager.shared.cookieReactionsEnabled {
                    await execute(HappyCelebrationBehavior())
                }
                
            case .thoughtCaptured(_, _):
                state.consecutiveThoughtsCount += 1
                guard PreferencesManager.shared.cookieReactionsEnabled else { break }
                if let node = cookieNode {
                    if node.isSleeping {
                        await execute(WakeUpBehavior())
                    }
                    let deskWorldPos = SCNVector3(0, 0.95, 0)
                    await execute(NoticeNewObjectBehavior(targetWorldPos: deskWorldPos))
                }
                
            case .roomOpened(let duration):
                if duration > 45 && state.isSleeping {
                    await execute(WakeUpBehavior())
                }
                
            case .roomClosed:
                break
                
            case .longIdle:
                if !state.isSleeping {
                    await execute(SleepBehavior())
                }
                
            case .cookiePetted:
                if state.isSleeping {
                    await execute(WakeUpBehavior())
                }
                await execute(PettedReactionBehavior())
            }
        }
    }
    
    private func handleNewItemCreated(at position: RoomPosition) async {
        guard let node = cookieNode else { return }
        
        // Wake up first if sleeping
        if node.isSleeping {
            await execute(WakeUpBehavior())
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        
        // If user created several thoughts in a row, walk closer to desk to observe curiously!
        if state.consecutiveThoughtsCount >= 3 && node.position.x < Self.nearDeskPosition.x {
            await walk(to: Self.nearDeskPosition)
        }
        
        let deskX = RoomDioramaBuilder.deskPosition.x
        let deskZ = RoomDioramaBuilder.deskPosition.z
        let surfaceY = RoomDioramaBuilder.deskSurfaceY
        let targetWorldPos = SCNVector3(
            deskX + (CGFloat(position.x) - 0.5) * RoomSceneController.deskWidthSpan,
            surfaceY,
            deskZ + (CGFloat(position.y) - 0.5) * RoomSceneController.deskDepthSpan
        )
        
        await execute(NoticeNewObjectBehavior(targetWorldPos: targetWorldPos))
    }
    
    // MARK: - Behavior Execution
    
    func execute(_ behavior: CookieBehavior) async {
        guard let node = cookieNode, !isExecutingBehavior else { return }
        isExecutingBehavior = true
        await behavior.execute(node: node, state: state)
        isExecutingBehavior = false
    }
    
    // MARK: - Idle State Loop
    
    private func startIdleMonitoring() {
        idleLoopTask?.cancel()
        idleLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                // Sleep for ~12-18 seconds between idle checks
                let idleDelay = UInt64.random(in: 12_000_000_000...18_000_000_000)
                try? await Task.sleep(nanoseconds: idleDelay)
                guard !Task.isCancelled, let self else { break }
                
                await self.performPeriodicIdleCheck()
            }
        }
    }
    
    private func performPeriodicIdleCheck() async {
        guard let node = cookieNode, !isExecutingBehavior else { return }
        
        let secondsSinceInteraction = Date.now.timeIntervalSince(state.lastInteraction)
        
        // Long idle (45+ seconds): Cookie finds a comfortable place and goes to sleep
        if secondsSinceInteraction > 45.0 {
            if !state.isSleeping {
                // If Cookie was standing near the desk, walk back to the warm woven rug first
                if abs(node.position.x - Self.rugHomePosition.x) > 0.15 {
                    await walk(to: Self.rugHomePosition)
                }
                await execute(SleepBehavior())
            }
            return
        }
        
        // If sleeping, stay sleeping peacefully
        guard !state.isSleeping else { return }
        
        // Subtle periodic idle behaviors when awake
        let randomChoice = Int.random(in: 0...4)
        switch randomChoice {
        case 0:
            await execute(IdleLookAroundBehavior())
        case 1:
            await execute(CleanPawBehavior())
        case 2:
            await execute(StretchBehavior())
        case 3:
            node.swishTail()
            node.blink()
        default:
            node.blink()
        }
    }
    
    // MARK: - Locomotion (Walking)
    
    /// Smoothly walks Cookie to a new position across the room floor with subtle bobbing.
    private func walk(to target: SCNVector3) async {
        guard let node = cookieNode else { return }
        state.transition(to: .curious, posture: .walking)
        
        let start = node.position
        let dx = target.x - start.x
        let dz = target.z - start.z
        let distance = sqrt(dx*dx + dz*dz)
        let duration = max(0.8, Double(distance) * 1.6)
        
        // Face moving direction
        let angle = atan2(dx, dz)
        node.eulerAngles.y = angle
        
        // Subtle walking bob
        let stepCount = max(2, Int(duration * 3))
        let stepDuration = duration / Double(stepCount * 2)
        let bobAction = SCNAction.repeat(
            SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.02, z: 0, duration: stepDuration),
                SCNAction.moveBy(x: 0, y: -0.02, z: 0, duration: stepDuration)
            ]),
            count: stepCount
        )
        await node.runAction(bobAction, forKey: "walk_bob")
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        node.position = target
        SCNTransaction.commit()
        
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        // Face back toward room center
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        node.eulerAngles.y = 0.4
        SCNTransaction.commit()
        
        state.transition(to: .curious, posture: .sitting)
    }
}

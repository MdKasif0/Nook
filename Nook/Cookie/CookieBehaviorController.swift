import SceneKit
import SwiftUI
import Foundation

/// Coordinates Cookie's state transitions, idle lifecycle, sleep patterns,
/// and reactive behaviors to user actions in Nook.
///
/// Designed as a state-driven behavior engine decoupled from the UI.
@MainActor
@Observable
final class CookieBehaviorController {
    
    let state = CookieState()
    weak var characterNode: CookieCharacterNode?
    
    private var eventSubscriptionToken: UUID?
    private var idleLoopTask: Task<Void, Never>?
    private var resetCreationCountTask: Task<Void, Never>?
    
    private var lastUserActivity: Date = .now
    private(set) var recentCreationCount: Int = 0
    
    var reduceMotion: Bool = false {
        didSet {
            characterNode?.reduceMotion = reduceMotion
        }
    }
    
    init(characterNode: CookieCharacterNode? = nil) {
        self.characterNode = characterNode
    }
    
    // MARK: - Lifecycle
    
    func start() {
        stop()
        
        // Subscribe to internal Nook events
        eventSubscriptionToken = NookEventBus.shared.subscribe { [weak self] event in
            self?.handleEvent(event)
        }
        
        startIdleLoop()
    }
    
    func stop() {
        if let token = eventSubscriptionToken {
            NookEventBus.shared.unsubscribe(token)
            eventSubscriptionToken = nil
        }
        idleLoopTask?.cancel()
        idleLoopTask = nil
        resetCreationCountTask?.cancel()
        resetCreationCountTask = nil
    }
    
    // MARK: - Event Dispatcher
    
    func handleEvent(_ event: NookEvent) {
        lastUserActivity = .now
        state.touch()
        
        guard let character = characterNode else { return }
        
        switch event {
        case .itemCreated(_, let position):
            handleItemCreated(position: position, character: character)
            
        case .thoughtCaptured:
            wakeIfNeeded(character: character) { [weak self] in
                self?.execute(InspectItemBehavior(targetWorldPos: CookieCharacterNode.nearDeskPosition))
            }
            
        case .itemDeleted:
            wakeIfNeeded(character: character) { [weak self] in
                self?.execute(DeleteReactionBehavior())
            }
            
        case .itemCompleted:
            wakeIfNeeded(character: character) { [weak self] in
                self?.execute(HappyPurrBehavior(bubbleText: "purr..."))
            }
            
        case .cookiePetted:
            wakeIfNeeded(character: character) { [weak self] in
                let messages = ["purr...", "♥", "🐾", "*nuzzle*"]
                self?.execute(HappyPurrBehavior(bubbleText: messages.randomElement()))
            }
            
        case .roomOpened:
            if character.isSleeping {
                execute(WakeUpBehavior())
            }
            
        case .roomClosed:
            if !character.isSleeping {
                execute(SleepBehavior())
            }
            
        case .longIdle:
            if !character.isSleeping {
                execute(SleepBehavior())
            }
        }
    }
    
    private func handleItemCreated(position: RoomPosition, character: CookieCharacterNode) {
        recentCreationCount += 1
        resetCreationCountTask?.cancel()
        resetCreationCountTask = Task {
            try? await Task.sleep(nanoseconds: 20_000_000_000) // 20s window
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                self?.recentCreationCount = 0
                // If Cookie walked near the desk, walk back to the rug
                if let char = self?.characterNode {
                    let dist = hypot(
                        char.position.x - CookieCharacterNode.homeRugPosition.x,
                        char.position.z - CookieCharacterNode.homeRugPosition.z
                    )
                    if dist > 0.15 {
                        self?.execute(ReturnToRugBehavior())
                    }
                }
            }
        }
        
        let deskX = RoomDioramaBuilder.deskPosition.x
        let deskZ = RoomDioramaBuilder.deskPosition.z
        let surfaceY = RoomDioramaBuilder.deskSurfaceY
        let offsetX = (CGFloat(position.x) - 0.5) * RoomSceneController.deskWidthSpan
        let offsetZ = (CGFloat(position.y) - 0.5) * RoomSceneController.deskDepthSpan
        let itemWorldPos = SCNVector3(deskX + offsetX, surfaceY, deskZ + offsetZ)
        
        wakeIfNeeded(character: character) { [weak self] in
            guard let self else { return }
            if self.recentCreationCount >= 2 {
                // When multiple thoughts are created, Cookie becomes curious and walks closer to the desk
                self.execute(InvestigateDeskBehavior())
            } else {
                // Cookie turns head to look toward the newly materialized object
                self.execute(InspectItemBehavior(targetWorldPos: itemWorldPos))
            }
        }
    }
    
    private func wakeIfNeeded(character: CookieCharacterNode, completion: @escaping () -> Void) {
        if character.isSleeping {
            execute(WakeUpBehavior())
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                completion()
            }
        } else {
            completion()
        }
    }
    
    // MARK: - Execute Behavior
    
    func execute(_ behavior: CookieBehavior) {
        guard let character = characterNode else { return }
        state.transition(to: behavior.targetMood)
        behavior.execute(on: character, controller: self)
    }
    
    // MARK: - Idle & Sleep Loop
    
    private func startIdleLoop() {
        idleLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                // Random natural delay between 18 and 30 seconds
                let delaySeconds = Double.random(in: 18...30)
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                guard !Task.isCancelled else { break }
                
                await MainActor.run {
                    self?.performPeriodicIdleCheck()
                }
            }
        }
    }
    
    private func performPeriodicIdleCheck() {
        guard let character = characterNode else { return }
        let idleSeconds = Date.now.timeIntervalSince(lastUserActivity)
        
        // 1. Long idle: Put Cookie to sleep on rug
        if idleSeconds >= 75.0 {
            if !character.isSleeping {
                execute(SleepBehavior())
            }
            return
        }
        
        // 2. Getting sleepy
        if idleSeconds >= 45.0 && !character.isSleeping {
            character.applyPosture(for: .sleepy, animated: true)
            return
        }
        
        // 3. Subtle idle behaviors when user is inactive but not long enough to sleep
        if !character.isSleeping {
            let roll = Double.random(in: 0...1)
            if roll < 0.40 {
                // Sits quietly and observes room
                execute(IdleObserveBehavior())
            } else if roll < 0.65 {
                // Gentle paw cleaning
                execute(CleanPawBehavior())
            } else if roll < 0.85 {
                // Natural cat yoga stretch
                execute(StretchBehavior())
            } else {
                // Ponders window / daylight
                execute(PonderBehavior())
            }
        }
    }
}

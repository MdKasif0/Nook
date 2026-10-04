import SceneKit
import Foundation

/// Defines a pluggable, state-driven behavior for Cookie.
@MainActor
protocol CookieBehavior: Sendable {
    var name: String { get }
    var mood: CookieMood { get }
    var posture: CookiePosture { get }
    func execute(node: CookieNode, state: CookieState) async
}

// MARK: - 1. Idle Behaviors

/// Cookie sits calmly, looking around the room before settling forward.
struct IdleLookAroundBehavior: CookieBehavior {
    let name = "lookAround"
    let mood: CookieMood = .idle
    let posture: CookiePosture = .sitting
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .idle, posture: .sitting)
        node.blink()
        
        // Glance towards the left window
        node.lookTowards(worldPoint: SCNVector3(-2.0, 1.2, 0.5))
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        
        // Glance towards bookshelf
        node.lookTowards(worldPoint: SCNVector3(1.2, 1.5, -1.0))
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        
        node.resetHead()
        node.blink()
    }
}

/// Cookie cleans its front paw.
struct CleanPawBehavior: CookieBehavior {
    let name = "cleanPaw"
    let mood: CookieMood = .idle
    let posture: CookiePosture = .cleaningPaw
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .idle, posture: .cleaningPaw)
        node.cleanPaw()
        try? await Task.sleep(nanoseconds: 2_200_000_000)
        state.transition(to: .idle, posture: .sitting)
    }
}

/// Cookie stretches gently.
struct StretchBehavior: CookieBehavior {
    let name = "stretch"
    let mood: CookieMood = .idle
    let posture: CookiePosture = .stretching
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .idle, posture: .stretching)
        node.stretch()
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        state.transition(to: .idle, posture: .sitting)
    }
}

// MARK: - 2. Reactive Behaviors

/// Cookie notices a new thought object placed on the desk.
struct NoticeNewObjectBehavior: CookieBehavior {
    let targetWorldPos: SCNVector3
    let name = "noticeNewObject"
    let mood: CookieMood = .curious
    let posture: CookiePosture = .pointing
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .curious, posture: .pointing)
        
        // Look toward the object
        node.lookTowards(worldPoint: targetWorldPos)
        node.pointAtDesk()
        node.swishTail()
        
        try? await Task.sleep(nanoseconds: 2_400_000_000)
        
        node.restPaws()
        node.resetHead()
        state.transition(to: .idle, posture: .sitting)
    }
}

/// Cookie reacts happily when an item is completed or celebrated.
struct HappyCelebrationBehavior: CookieBehavior {
    let name = "happyCelebration"
    let mood: CookieMood = .happy
    let posture: CookiePosture = .sitting
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .happy, posture: .sitting)
        node.wiggleEars()
        node.swishTail()
        state.showSpeechBubble("*purr...*")
        
        try? await Task.sleep(nanoseconds: 2_200_000_000)
        state.showSpeechBubble(nil)
        state.transition(to: .idle, posture: .sitting)
    }
}

/// Cookie reacts to an object deletion with brief curious/thinking contemplation.
struct ObjectDeletedReactionBehavior: CookieBehavior {
    let name = "objectDeleted"
    let mood: CookieMood = .thinking
    let posture: CookiePosture = .sitting
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .thinking, posture: .sitting)
        node.lookTowards(worldPoint: SCNVector3(0, 1.0, 0))
        node.wiggleEars()
        
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        node.resetHead()
        state.transition(to: .idle, posture: .sitting)
    }
}

/// Cookie is petted or clicked directly by the user.
struct PettedReactionBehavior: CookieBehavior {
    let name = "petted"
    let mood: CookieMood = .happy
    let posture: CookiePosture = .sitting
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .happy, posture: .sitting)
        node.wiggleEars()
        node.swishTail()
        
        let happySounds = ["*purr...*", "*soft nuzzle*", "meow~", "♥"]
        state.showSpeechBubble(happySounds.randomElement())
        
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        state.showSpeechBubble(nil)
        state.transition(to: .idle, posture: .sitting)
    }
}

// MARK: - 3. Sleep & Wake Behaviors

/// Cookie settles in for a peaceful nap.
struct SleepBehavior: CookieBehavior {
    let name = "sleep"
    let mood: CookieMood = .resting
    let posture: CookiePosture = .curled
    
    func execute(node: CookieNode, state: CookieState) async {
        state.transition(to: .resting, posture: .curled)
        node.sleep()
        state.showSpeechBubble("*zzz*")
        
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        state.showSpeechBubble(nil)
    }
}

/// Cookie wakes up after a nap.
struct WakeUpBehavior: CookieBehavior {
    let name = "wakeUp"
    let mood: CookieMood = .idle
    let posture: CookiePosture = .sitting
    
    func execute(node: CookieNode, state: CookieState) async {
        node.wakeUp()
        state.transition(to: .idle, posture: .sitting)
    }
}

import Foundation

/// The emotional and mental state of Cookie, the companion cat.
///
/// Implements all required states:
/// neutral/idle, curious, happy, sleepy, excited, thinking, resting, surprised, sad, playful.
public enum CookieMood: String, CaseIterable, Identifiable, Sendable {
    case idle
    case curious
    case happy
    case sleepy
    case excited
    case thinking
    case resting
    case surprised
    case sad
    case playful
    
    public static var neutral: CookieMood { .idle }
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .idle:      return "Neutral"
        case .curious:   return "Curious"
        case .happy:     return "Happy"
        case .sleepy:    return "Sleepy"
        case .excited:   return "Excited"
        case .thinking:  return "Thinking"
        case .resting:   return "Resting"
        case .surprised: return "Surprised"
        case .sad:       return "Sad"
        case .playful:   return "Playful"
        }
    }
    
    public var iconName: String {
        switch self {
        case .idle:      return "cat"
        case .curious:   return "eyes"
        case .happy:     return "cat.fill"
        case .sleepy:    return "moon.zzz"
        case .excited:   return "sparkles"
        case .thinking:  return "brain"
        case .resting:   return "powersleep"
        case .surprised: return "exclamationmark.bubble"
        case .sad:       return "cloud.rain"
        case .playful:   return "pawprint.fill"
        }
    }
}

/// The physical posture/stance of Cookie in the 3D diorama room.
public enum CookiePosture: String, CaseIterable, Identifiable, Sendable {
    case sitting      // Upright cute sitting posture matching reference
    case pointing     // Cute raised paw pointing towards object (reference art!)
    case standing     // Standing upright on paws
    case curled       // Curled tightly asleep
    case stretching   // Gentle cat stretch
    case cleaningPaw  // Paw raised to mouth/face
    case walking      // Moving toward or away from desk
    case jumping      // Joyful little hop
    
    public var id: String { rawValue }
}

/// The deterministic activity states of Cookie inside the miniature room diorama.
public enum CookieActivity: String, CaseIterable, Identifiable, Codable, Sendable {
    case idle
    case walking
    case running
    case curious
    case happy
    case sleepy
    case sleeping
    case playing
    case beingDragged
    case jumping
    case sitting
    case lyingDown
    case grooming
    case lookingAround
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .idle:          return "Idle"
        case .walking:       return "Walking"
        case .running:       return "Running"
        case .curious:       return "Curious"
        case .happy:         return "Happy"
        case .sleepy:        return "Sleepy"
        case .sleeping:      return "Sleeping"
        case .playing:       return "Playing"
        case .beingDragged:  return "Being Dragged"
        case .jumping:       return "Jumping"
        case .sitting:       return "Sitting"
        case .lyingDown:     return "Lying Down"
        case .grooming:      return "Grooming"
        case .lookingAround: return "Looking Around"
        }
    }
}

/// Deterministic state machine governing valid, non-contradictory transitions for Cookie.
public struct CookieStateMachine: Sendable {
    
    /// Returns whether transitioning from `current` to `target` is a valid, logical transition.
    public static func canTransition(from current: CookieActivity, to target: CookieActivity) -> Bool {
        if current == target { return true }
        
        // Dragging can be initiated from any awake state or sleeping state (wakes up immediately)
        if target == .beingDragged { return true }
        
        switch current {
        case .idle:
            // Idle can branch into any active, observational, or resting state
            return [
                .walking, .running, .curious, .happy, .sleepy, .playing,
                .beingDragged, .jumping, .sitting, .lyingDown, .grooming, .lookingAround
            ].contains(target)
            
        case .walking:
            // While walking, Cookie can stop, jump an obstacle, sprint, become curious, or be picked up
            return [.idle, .sitting, .jumping, .running, .curious, .beingDragged].contains(target)
            
        case .running:
            // While running, can slow to a walk, jump, sit, or stop
            return [.walking, .jumping, .sitting, .idle, .beingDragged].contains(target)
            
        case .curious:
            // In curious mode, can look around, approach (walk), sit, or return to idle
            return [.lookingAround, .walking, .sitting, .idle, .beingDragged].contains(target)
            
        case .happy:
            // When happy, can play, sit, purr/idle
            return [.playing, .sitting, .idle, .beingDragged].contains(target)
            
        case .sleepy:
            // When sleepy, transitions down to lying down, sleeping, or snaps back awake
            return [.sleeping, .lyingDown, .sitting, .idle, .beingDragged].contains(target)
            
        case .sleeping:
            // Sleeping can only wake up to sleepy, sitting, or idle (or forced drag)
            return [.sleepy, .idle, .sitting, .beingDragged].contains(target)
            
        case .playing:
            // Playing can hop/jump, walk, celebrate happy, or settle to sitting/idle
            return [.jumping, .happy, .walking, .sitting, .idle, .beingDragged].contains(target)
            
        case .beingDragged:
            // Once user drops Cookie, Cookie transitions to landing settle, sitting, jumping, or idle
            return [.jumping, .sitting, .idle, .lookingAround].contains(target)
            
        case .jumping:
            // After ballistic airborne arc, Cookie always lands into sitting, walking, or idle
            return [.sitting, .walking, .idle, .beingDragged].contains(target)
            
        case .sitting:
            // From sitting posture, Cookie can idle, look around, groom, sleep, stretch, walk, or play
            return [
                .idle, .walking, .running, .curious, .sleepy, .sleeping, .lyingDown,
                .grooming, .lookingAround, .playing, .beingDragged
            ].contains(target)
            
        case .lyingDown:
            // From lying down, Cookie can curl up into sleep, sit up, or return to idle
            return [.sleeping, .sitting, .idle, .sleepy, .beingDragged].contains(target)
            
        case .grooming:
            // While grooming paws, finishes and settles to sitting or idle
            return [.sitting, .idle, .lookingAround, .beingDragged].contains(target)
            
        case .lookingAround:
            // Finished looking around settles to sitting, walking toward focus, or idle
            return [.sitting, .curious, .walking, .idle, .beingDragged].contains(target)
        }
    }
}

/// Observable state holder for Cookie, coordinating behavior and reactions.
@Observable
public final class CookieState {
    
    public var mood: CookieMood = .idle
    public var posture: CookiePosture = .sitting
    public var activity: CookieActivity = .idle
    public var speechBubble: String?
    public var isSleeping: Bool = false
    public var consecutiveThoughtsCount: Int = 0
    public var lastInteraction: Date = .now
    
    public init() {}
    
    /// Checks if a transition to a new activity is valid under deterministic state rules.
    public func canTransition(to newActivity: CookieActivity) -> Bool {
        CookieStateMachine.canTransition(from: activity, to: newActivity)
    }
    
    /// Deterministically transitions Cookie's activity, returning false if the transition is contradictory.
    @discardableResult
    public func transitionToActivity(_ newActivity: CookieActivity) -> Bool {
        guard canTransition(to: newActivity) else { return false }
        self.activity = newActivity
        
        switch newActivity {
        case .idle:
            self.mood = .idle
        case .walking, .running:
            self.posture = .walking
        case .jumping:
            self.posture = .jumping
        case .sitting:
            self.posture = .sitting
        case .curious:
            self.mood = .curious
        case .happy:
            self.mood = .happy
        case .sleepy:
            self.mood = .sleepy
        case .sleeping:
            self.mood = .resting
            self.posture = .curled
            self.isSleeping = true
        case .playing:
            self.mood = .playful
        case .beingDragged:
            self.isSleeping = false
        case .lyingDown:
            self.posture = .curled
        case .grooming:
            self.posture = .cleaningPaw
        case .lookingAround:
            self.mood = .curious
        }
        
        self.lastInteraction = .now
        return true
    }
    
    /// Transition Cookie's mood and posture.
    public func transition(to newMood: CookieMood, posture newPosture: CookiePosture? = nil) {
        self.mood = newMood
        if let newPosture {
            self.posture = newPosture
        }
        self.isSleeping = (newMood == .resting || newMood == .sleepy && newPosture == .curled)
        self.lastInteraction = .now
    }
    
    /// Sets a temporary speech bubble that automatically clears.
    public func showSpeechBubble(_ text: String?) {
        self.speechBubble = text
    }
}

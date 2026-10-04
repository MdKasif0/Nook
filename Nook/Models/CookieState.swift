import Foundation

/// The emotional and mental state of Cookie, the companion cat.
///
/// Implements all 7 required states:
/// idle, curious, happy, sleepy, excited, thinking, resting.
enum CookieMood: String, CaseIterable, Identifiable, Sendable {
    case idle
    case curious
    case happy
    case sleepy
    case excited
    case thinking
    case resting
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .idle:     return "Idle"
        case .curious:  return "Curious"
        case .happy:    return "Happy"
        case .sleepy:   return "Sleepy"
        case .excited:  return "Excited"
        case .thinking: return "Thinking"
        case .resting:  return "Resting"
        }
    }
    
    var iconName: String {
        switch self {
        case .idle:     return "cat"
        case .curious:  return "eyes"
        case .happy:    return "cat.fill"
        case .sleepy:   return "moon.zzz"
        case .excited:  return "sparkles"
        case .thinking: return "brain"
        case .resting:  return "powersleep"
        }
    }
}

/// The physical posture/stance of Cookie in the 3D diorama room.
enum CookiePosture: String, CaseIterable, Identifiable, Sendable {
    case sitting      // Upright sitting on round rug
    case pointing     // Cute raised paw pointing towards desk (as seen in reference art)
    case curled       // Curled tightly on rug asleep
    case stretching   // Gentle cat stretch
    case cleaningPaw  // Paw raised to mouth/face
    case walking      // Moving toward or away from desk
    
    var id: String { rawValue }
}

/// Observable state holder for Cookie, coordinating behavior and reactions.
@Observable
final class CookieState {
    
    var mood: CookieMood = .idle
    var posture: CookiePosture = .sitting
    var speechBubble: String?
    var isSleeping: Bool = false
    var consecutiveThoughtsCount: Int = 0
    var lastInteraction: Date = .now
    
    /// Transition Cookie's mood and posture.
    func transition(to newMood: CookieMood, posture newPosture: CookiePosture? = nil) {
        self.mood = newMood
        if let newPosture {
            self.posture = newPosture
        }
        self.isSleeping = (newMood == .resting || newMood == .sleepy && newPosture == .curled)
        self.lastInteraction = .now
    }
    
    /// Sets a temporary speech bubble that automatically clears.
    func showSpeechBubble(_ text: String?) {
        self.speechBubble = text
    }
}

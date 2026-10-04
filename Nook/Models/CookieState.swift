import Foundation

/// The emotional and physical state of Cookie, Nook's companion cat.
///
/// Implements the states required by Nook's behavioral model:
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
    
    /// A human-readable label.
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
    
    /// SF Symbol associated with this state.
    var iconName: String {
        switch self {
        case .idle:     return "cat"
        case .curious:  return "eyes"
        case .happy:    return "heart.fill"
        case .sleepy:   return "moon.zzz"
        case .excited:  return "sparkles"
        case .thinking: return "brain"
        case .resting:  return "bed.double.fill"
        }
    }
    
    var isSleepingState: Bool {
        self == .resting
    }
}

/// Observable state holder for Cookie.
///
/// Separated from AppState so Cookie's state-driven architecture
/// can be reasoned about independently.
@Observable
final class CookieState {
    var mood: CookieMood = .idle
    var isSleeping: Bool = false
    var lastInteraction: Date = .now
    var recentCreationCount: Int = 0
    var currentSpeechBubble: String?
    
    func transition(to newMood: CookieMood) {
        mood = newMood
        isSleeping = (newMood == .resting)
    }
    
    func touch() {
        lastInteraction = .now
    }
}

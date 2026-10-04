import Foundation

/// The emotional state of Cookie, the companion cat.
///
/// Cookie lives in the Nook room and reacts to user behavior.
/// The full Cookie implementation will come later — this model
/// reserves the architecture and state machine.
enum CookieMood: String, CaseIterable, Identifiable, Sendable {
    case idle
    case happy
    case curious
    case sleepy
    case excited
    case thinking
    
    var id: String { rawValue }
    
    /// A human-readable label.
    var displayName: String {
        switch self {
        case .idle:     return "Idle"
        case .happy:    return "Happy"
        case .curious:  return "Curious"
        case .sleepy:   return "Sleepy"
        case .excited:  return "Excited"
        case .thinking: return "Thinking"
        }
    }
    
    /// The SF Symbol associated with this mood (placeholder visuals).
    var iconName: String {
        switch self {
        case .idle:     return "cat"
        case .happy:    return "cat.fill"
        case .curious:  return "eyes"
        case .sleepy:   return "moon.zzz"
        case .excited:  return "sparkles"
        case .thinking: return "brain"
        }
    }
}

/// Observable state holder for Cookie.
///
/// Separated from `AppState` so Cookie's logic can grow
/// independently without bloating the global state.
@Observable
final class CookieState {
    var mood: CookieMood = .idle
    var lastInteraction: Date = .now
    
    /// Transition Cookie's mood (placeholder for future behavior tree).
    func transition(to newMood: CookieMood) {
        mood = newMood
        lastInteraction = .now
    }
}

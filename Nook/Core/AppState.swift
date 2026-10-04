import SwiftUI

/// Observable application-wide state.
///
/// Shared across windows to coordinate global behaviors
/// such as sidebar visibility and the active navigation section.
@Observable
final class AppState {
    
    /// The currently selected section in the sidebar.
    var selectedSection: SidebarSection? = .room
    
    /// Whether the sidebar is currently visible.
    var isSidebarVisible: Bool = true
    
    /// The current state of Cookie, the companion cat.
    var cookieState: CookieMood = .idle
}

/// The top-level navigation sections available in the sidebar.
enum SidebarSection: String, CaseIterable, Identifiable {
    case room = "Room"
    case thoughts = "Thoughts"
    case ideas = "Ideas"
    case notes = "Notes"
    case reminders = "Reminders"
    case quotes = "Quotes"
    case links = "Links"
    case photos = "Photos"
    case archive = "Archive"
    
    var id: String { rawValue }
    
    /// The SF Symbol name associated with each section.
    var iconName: String {
        switch self {
        case .room:      return "house"
        case .thoughts:  return "cloud"
        case .ideas:     return "lightbulb"
        case .notes:     return "note.text"
        case .reminders: return "bell"
        case .quotes:    return "quote.opening"
        case .links:     return "link"
        case .photos:    return "photo"
        case .archive:   return "archivebox"
        }
    }
    
    /// Maps sidebar sections to their corresponding item type, if applicable.
    var itemType: NookItemType? {
        switch self {
        case .room:      return nil
        case .thoughts:  return .thought
        case .ideas:     return .idea
        case .notes:     return .note
        case .reminders: return .reminder
        case .quotes:    return .quote
        case .links:     return .link
        case .photos:    return .photo
        case .archive:   return nil
        }
    }
}

import SwiftUI

/// Observable application-wide state.
///
/// Shared across windows and menu bar utility to coordinate navigation,
/// contextual search (Command+K), quick thought creation, and room object focusing.
@Observable
final class AppState {
    
    /// The currently selected section in the sidebar.
    var selectedSection: SidebarSection? = .room
    
    /// Whether the sidebar is currently visible.
    var isSidebarVisible: Bool = true
    
    /// The current state of Cookie, the companion cat.
    var cookieState: CookieMood = .idle
    
    /// Whether the Command + K Spotlight search palette is currently displayed.
    var isSearchOpen: Bool = false
    
    /// Current search query in the search palette.
    var searchQuery: String = ""
    
    /// Whether the "Place Thought" modal sheet is open in the main room (triggered via Command + N).
    var isShowingNewThoughtSheet: Bool = false
    
    /// A focused item ID to highlight and move the camera toward in the 3D room.
    var focusedItemID: UUID? = nil
    
    // MARK: - Actions
    
    func openSearch() {
        withAnimation(NookDesign.Animation.springy) {
            self.isSearchOpen = true
            self.searchQuery = ""
        }
    }
    
    func closeSearch() {
        withAnimation(NookDesign.Animation.gentle) {
            self.isSearchOpen = false
            self.searchQuery = ""
        }
    }
    
    func toggleSearch() {
        if isSearchOpen {
            closeSearch()
        } else {
            openSearch()
        }
    }
    
    func focusItemInRoom(id: UUID) {
        self.selectedSection = .room
        self.focusedItemID = id
        closeSearch()
    }
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

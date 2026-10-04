import Foundation

/// The category of a Nook item.
///
/// Stored as a raw string in SwiftData so new types can be added
/// without a data migration — unknown raw values simply fall through
/// to `.thought` via the failable initializer.
enum NookItemType: String, CaseIterable, Identifiable, Codable, Sendable {
    case thought
    case idea
    case reminder
    case quote
    case link
    case photo
    case note
    
    var id: String { rawValue }
    
    /// A human-readable display name.
    var displayName: String {
        switch self {
        case .thought:  return "Thought"
        case .idea:     return "Idea"
        case .reminder: return "Reminder"
        case .quote:    return "Quote"
        case .link:     return "Link"
        case .photo:    return "Photo"
        case .note:     return "Note"
        }
    }
    
    /// The SF Symbol associated with this type.
    var iconName: String {
        switch self {
        case .thought:  return "cloud"
        case .idea:     return "lightbulb"
        case .reminder: return "bell"
        case .quote:    return "quote.opening"
        case .link:     return "link"
        case .photo:    return "photo"
        case .note:     return "note.text"
        }
    }
    
    /// The accent color for this type, drawn from the Nook palette.
    var accentColor: NookAccentColor {
        switch self {
        case .thought:  return .sage
        case .idea:     return .olive
        case .reminder: return .terracotta
        case .quote:    return .woodBrown
        case .link:     return .olive
        case .photo:    return .sage
        case .note:     return .taupe
        }
    }
}

/// Maps item types to named design-token colors.
///
/// This avoids importing SwiftUI in the model layer.
enum NookAccentColor: String, Sendable {
    case sage
    case olive
    case terracotta
    case woodBrown
    case taupe
}

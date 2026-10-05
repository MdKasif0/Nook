import SwiftUI

/// The physical representation of a thought inside the miniature Nook room.
///
/// In Nook, thoughts become tactile physical objects resting naturally
/// on the wooden desk, shelves, or room surfaces.
enum NookObjectType: String, CaseIterable, Identifiable, Codable, Sendable {
    case pebble = "pebble"
    case paperNote = "paperNote"
    case stickyNote = "stickyNote"
    case card = "card"
    case polaroid = "polaroid"
    case bookmark = "bookmark"
    
    var id: String { rawValue }
    
    /// User-facing display name.
    var displayName: String {
        switch self {
        case .pebble:     return "Pebble"
        case .paperNote:  return "Paper Note"
        case .stickyNote: return "Sticky Note"
        case .card:       return "Small Card"
        case .polaroid:   return "Polaroid"
        case .bookmark:   return "Bookmark"
        }
    }
    
    /// Short evocative subtitle.
    var subtitle: String {
        switch self {
        case .pebble:     return "A smooth, grounding river stone"
        case .paperNote:  return "Folded warm cream parchment"
        case .stickyNote: return "Buttery note with curled corner"
        case .card:       return "Heavy watercolor cardstock"
        case .polaroid:   return "Miniature framed photo print"
        case .bookmark:   return "Woven ribbon with tassel cord"
        }
    }
    
    /// SF Symbol icon name.
    var iconName: String {
        switch self {
        case .pebble:     return "circle.circle.fill"
        case .paperNote:  return "doc.plaintext"
        case .stickyNote: return "note.text"
        case .card:       return "rectangle.portrait"
        case .polaroid:   return "photo"
        case .bookmark:   return "bookmark.fill"
        }
    }
    
    /// The primary accent tint.
    var tintColor: Color {
        switch self {
        case .pebble:     return NookDesign.Colors.woodBrown
        case .paperNote:  return NookDesign.Colors.taupe
        case .stickyNote: return Color(hex: 0xD4C47A) // Warm buttery ochre
        case .card:       return NookDesign.Colors.olive
        case .polaroid:   return NookDesign.Colors.terracotta
        case .bookmark:   return NookDesign.Colors.sage
        }
    }
    
    /// Natural default rotation angle in degrees for room placement.
    var defaultRotation: Double {
        switch self {
        case .pebble:     return Double.random(in: -30...30)
        case .paperNote:  return 8.0
        case .stickyNote: return -6.0
        case .card:       return 0.0
        case .polaroid:   return 12.0
        case .bookmark:   return -15.0
        }
    }
}

import Foundation

/// Defines intelligent placement zones within the room diorama.
///
/// Initially focuses on the desk surface, with accessible zone selection
/// for keyboard/voice-over users and natural item distribution.
enum PlacementZone: String, CaseIterable, Identifiable, Sendable {
    case deskCenter = "Center of Desk"
    case deskLeft = "Left Blotter"
    case deskRight = "Right Drawers"
    case deskFront = "Front Edge"
    case recordBench = "Vinyl Bench"
    case bookshelf = "Bookshelf"
    case nightstand = "Nightstand"
    case floorLounge = "Lounge Floor"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .deskCenter:  return "square.inset.filled"
        case .deskLeft:    return "arrow.left.to.line"
        case .deskRight:   return "arrow.right.to.line"
        case .deskFront:   return "arrow.down.to.line"
        case .recordBench: return "opticaldisc"
        case .bookshelf:   return "books.vertical"
        case .nightstand:  return "bed.double"
        case .floorLounge: return "sofa"
        }
    }
    
    /// Returns a normalized room position within this zone with slight natural variation.
    var basePosition: RoomPosition {
        switch self {
        case .deskCenter:
            return RoomPosition(x: 0.50, y: 0.50, z: 0.5)
        case .deskLeft:
            return RoomPosition(x: 0.28, y: 0.42, z: 0.5)
        case .deskRight:
            return RoomPosition(x: 0.74, y: 0.42, z: 0.5)
        case .deskFront:
            return RoomPosition(x: 0.50, y: 0.72, z: 0.5)
        case .recordBench:
            return RoomPosition(x: 0.82, y: 0.75, z: 0.5)
        case .bookshelf:
            return RoomPosition(x: 0.22, y: 0.20, z: 0.5)
        case .nightstand:
            return RoomPosition(x: 0.68, y: 0.25, z: 0.5)
        case .floorLounge:
            return RoomPosition(x: 0.52, y: 0.88, z: 0.5)
        }
    }
    
    /// Generates a natural position with subtle organic jitter so objects don't stack directly on top of each other.
    func naturalPosition(existingCount: Int = 0) -> RoomPosition {
        let base = basePosition
        let jitterX = Double.random(in: -0.06...0.06)
        let jitterY = Double.random(in: -0.05...0.05)
        
        return RoomPosition(
            x: min(0.85, max(0.20, base.x + jitterX)),
            y: min(0.80, max(0.25, base.y + jitterY)),
            z: 0.5
        )
    }
}

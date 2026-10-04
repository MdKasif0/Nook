import SwiftUI

/// Protocol that defines a visual representation of a NookItem inside the room.
///
/// This abstraction decouples item rendering from any specific
/// rendering technology (2D Canvas, SceneKit, RealityKit).
protocol RoomObject: Identifiable {
    /// The underlying data item.
    var item: NookItem { get }
    
    /// Current position in normalized room coordinates.
    var position: RoomPosition { get set }
    
    /// Rotation angle in degrees.
    var rotation: Double { get set }
    
    /// Whether the object is currently selected.
    var isSelected: Bool { get set }
}

/// A concrete 2D room object for the initial flat-room implementation.
@Observable
final class FlatRoomObject: RoomObject, Identifiable {
    let id: UUID
    let item: NookItem
    var position: RoomPosition
    var rotation: Double
    var isSelected: Bool
    
    init(item: NookItem) {
        self.id = item.id
        self.item = item
        self.position = item.roomPosition
        self.rotation = item.rotation
        self.isSelected = false
    }
}

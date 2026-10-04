import Foundation

/// A rendering-agnostic position within the Nook room.
///
/// All coordinates are normalized to the 0…1 range so they are
/// independent of any specific rendering technology (2D canvas,
/// SceneKit, RealityKit, etc.).
struct RoomPosition: Codable, Sendable, Equatable {
    /// Horizontal position (0 = left edge, 1 = right edge).
    var x: Double
    
    /// Vertical position (0 = bottom, 1 = top).
    var y: Double
    
    /// Depth / layer (0 = back wall, 1 = front).
    var z: Double
    
    /// The center of the room.
    static let center = RoomPosition(x: 0.5, y: 0.5, z: 0.5)
    
    /// A random position for initial placement.
    static var random: RoomPosition {
        RoomPosition(
            x: Double.random(in: 0.15...0.85),
            y: Double.random(in: 0.15...0.85),
            z: Double.random(in: 0.3...0.7)
        )
    }
}

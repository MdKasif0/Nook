import RealityKit
import SwiftUI
import Foundation

/// Defines the category and interaction permissions for a 3D object in Nook.
public enum PropCategory: String, Codable, Sendable {
    /// Structural objects that cannot be moved or deleted (walls, floor, window, trim)
    case immovable
    /// Furniture and decorative items that can be picked up, moved, rotated, and reset
    case movable
    /// Special interactive companions (Cookie the cat) or user thought items
    case special
}

/// A RealityKit component attached to every interactive entity in the Nook diorama.
///
/// Stores metadata including human-readable accessibility label, movement constraints,
/// default reset transform, and interaction flags.
public struct InteractivePropComponent: Component, Codable {
    
    /// Unique identifier for this prop (e.g., "desk_lamp", "skateboard", "daisy_pillow")
    public var propId: String
    
    /// User-facing display name (e.g., "Desk Lamp", "Skateboard", "Daisy Pillow")
    public var displayName: String
    
    /// Accessibility description read by VoiceOver
    public var accessibilityLabel: String
    
    /// Category controlling allowed interactions
    public var category: PropCategory
    
    /// Whether the object can be physically dragged across surfaces
    public var allowsDragging: Bool
    
    /// Whether the object can be rotated around the Y-axis
    public var allowsRotation: Bool
    
    /// Whether the object can be subtly scaled
    public var allowsScaling: Bool
    
    /// Whether the object can be deleted from the room (true for user thoughts)
    public var allowsDeletion: Bool
    
    /// Default local position in room space for position reset
    public var defaultPosition: SIMD3<Float>
    
    /// Default local orientation for orientation reset
    public var defaultOrientation: simd_quatf
    
    /// Default scale
    public var defaultScale: SIMD3<Float>
    
    /// Target resting surface Y coordinate (e.g., floor, desk surface, shelf)
    public var restingSurfaceY: Float
    
    /// Minimum allowed bounds [minX, minY, minZ] inside the room
    public var minBounds: SIMD3<Float>
    
    /// Maximum allowed bounds [maxX, maxY, maxZ] inside the room
    public var maxBounds: SIMD3<Float>
    
    public init(
        propId: String,
        displayName: String,
        accessibilityLabel: String? = nil,
        category: PropCategory = .movable,
        allowsDragging: Bool = true,
        allowsRotation: Bool = true,
        allowsScaling: Bool = false,
        allowsDeletion: Bool = false,
        defaultPosition: SIMD3<Float>,
        defaultOrientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        defaultScale: SIMD3<Float> = [1, 1, 1],
        restingSurfaceY: Float = 0.16,
        minBounds: SIMD3<Float> = [-1.15, 0.02, -1.15],
        maxBounds: SIMD3<Float> = [1.15, 1.85, 1.05]
    ) {
        self.propId = propId
        self.displayName = displayName
        self.accessibilityLabel = accessibilityLabel ?? displayName
        self.category = category
        self.allowsDragging = allowsDragging
        self.allowsRotation = allowsRotation
        self.allowsScaling = allowsScaling
        self.allowsDeletion = allowsDeletion
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        self.defaultScale = defaultScale
        self.restingSurfaceY = restingSurfaceY
        self.minBounds = minBounds
        self.maxBounds = maxBounds
    }
}

/// Codable persistent transform representation stored in SwiftData.
public struct RoomPropTransform: Codable, Equatable, Sendable {
    public var propId: String
    public var posX: Float
    public var posY: Float
    public var posZ: Float
    public var rotX: Float
    public var rotY: Float
    public var rotZ: Float
    public var rotW: Float
    public var scaleX: Float
    public var scaleY: Float
    public var scaleZ: Float
    public var isCustomized: Bool
    
    public var position: SIMD3<Float> {
        get { [posX, posY, posZ] }
        set {
            posX = newValue.x
            posY = newValue.y
            posZ = newValue.z
        }
    }
    
    public var orientation: simd_quatf {
        get { simd_quatf(ix: rotX, iy: rotY, iz: rotZ, r: rotW) }
        set {
            rotX = newValue.imag.x
            rotY = newValue.imag.y
            rotZ = newValue.imag.z
            rotW = newValue.real
        }
    }
    
    public var scale: SIMD3<Float> {
        get { [scaleX, scaleY, scaleZ] }
        set {
            scaleX = newValue.x
            scaleY = newValue.y
            scaleZ = newValue.z
        }
    }
    
    public init(
        propId: String,
        position: SIMD3<Float>,
        orientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        scale: SIMD3<Float> = [1, 1, 1],
        isCustomized: Bool = true
    ) {
        self.propId = propId
        self.posX = position.x
        self.posY = position.y
        self.posZ = position.z
        self.rotX = orientation.imag.x
        self.rotY = orientation.imag.y
        self.rotZ = orientation.imag.z
        self.rotW = orientation.real
        self.scaleX = scale.x
        self.scaleY = scale.y
        self.scaleZ = scale.z
        self.isCustomized = isCustomized
    }
}

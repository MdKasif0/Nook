import Foundation
import SwiftData

/// The primary data model for every item stored in Nook.
///
/// A NookItem represents a single thought, idea, note, reminder, quote,
/// link, or photo — anything the user captures and places in their room.
@Model
final class NookItem {
    
    /// Unique identifier.
    @Attribute(.unique)
    var id: UUID
    
    /// Short title or label for the item.
    var title: String
    
    /// The main text content of the item.
    var content: String
    
    /// When the item was created.
    var createdAt: Date
    
    /// When the item was last modified.
    var updatedAt: Date
    
    /// The category/type of this item.
    var itemTypeRaw: String
    
    /// The physical object representation in the 3D room.
    var objectTypeRaw: String = NookObjectType.pebble.rawValue
    
    /// X position within the room (normalized 0…1).
    var positionX: Double
    
    /// Y position within the room (normalized 0…1).
    var positionY: Double
    
    /// Z position within the room (normalized 0…1, for depth/layers).
    var positionZ: Double
    
    /// Rotation angle in degrees for the room object.
    var rotation: Double
    
    /// Whether the item has been archived (hidden from the room).
    var isArchived: Bool
    
    /// An optional color/style tag for visual differentiation.
    var styleTag: String?
    
    /// Freeform metadata dictionary stored as JSON data for future expansion.
    var metadataJSON: Data?
    
    // MARK: - Computed Properties
    
    /// The typed item type.
    var itemType: NookItemType {
        get { NookItemType(rawValue: itemTypeRaw) ?? .thought }
        set { itemTypeRaw = newValue.rawValue }
    }
    
    /// The typed physical object representation.
    var objectType: NookObjectType {
        get { NookObjectType(rawValue: objectTypeRaw) ?? .pebble }
        set { objectTypeRaw = newValue.rawValue }
    }
    
    /// The room position as a `RoomPosition`.
    var roomPosition: RoomPosition {
        get { RoomPosition(x: positionX, y: positionY, z: positionZ) }
        set {
            let validX = newValue.x.isFinite ? max(0.0, min(1.0, newValue.x)) : 0.5
            let validY = newValue.y.isFinite ? max(0.0, min(1.0, newValue.y)) : 0.5
            let validZ = newValue.z.isFinite ? max(0.0, min(1.0, newValue.z)) : 0.5
            positionX = validX
            positionY = validY
            positionZ = validZ
        }
    }
    
    // MARK: - Initializer
    
    init(
        title: String,
        content: String = "",
        itemType: NookItemType = .thought,
        objectType: NookObjectType = .pebble,
        position: RoomPosition = .random,
        rotation: Double? = nil,
        styleTag: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = .now
        self.updatedAt = .now
        self.itemTypeRaw = itemType.rawValue
        self.objectTypeRaw = objectType.rawValue
        self.positionX = position.x
        self.positionY = position.y
        self.positionZ = position.z
        self.rotation = rotation ?? objectType.defaultRotation
        self.isArchived = false
        self.styleTag = styleTag
        self.metadataJSON = nil
    }
}

// MARK: - Metadata Helpers

extension NookItem {
    
    /// Decode the freeform metadata dictionary.
    func metadata() -> [String: String] {
        guard let data = metadataJSON else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
    
    /// Encode and store freeform metadata.
    func setMetadata(_ dict: [String: String]) {
        metadataJSON = try? JSONEncoder().encode(dict)
    }
    
    /// Touch the `updatedAt` timestamp.
    func touch() {
        updatedAt = .now
    }
}

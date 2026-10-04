import Foundation
import SwiftData

/// Represents a serializable snapshot of a Nook item for backup, export, and native undo.
struct NookItemDTO: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var itemType: String
    var objectType: String
    var positionX: Double
    var positionY: Double
    var positionZ: Double
    var rotation: Double
    var isArchived: Bool
    var styleTag: String?
    var metadata: [String: String]?
    
    init(from item: NookItem) {
        self.id = item.id
        self.title = item.title
        self.content = item.content
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
        self.itemType = item.itemTypeRaw
        self.objectType = item.objectTypeRaw
        self.positionX = item.positionX
        self.positionY = item.positionY
        self.positionZ = item.positionZ
        self.rotation = item.rotation
        self.isArchived = item.isArchived
        self.styleTag = item.styleTag
        self.metadata = item.metadata()
    }
}

/// Represents a serializable snapshot of the room and Cookie companion state.
struct RoomStateDTO: Codable, Sendable, Equatable {
    var timeOfDay: String
    var isDeskLampOn: Bool
    var isWallSconceOn: Bool
    var isRecordSpinning: Bool
    var cookieFavoriteSpot: String
    var cookiePetCount: Int
    var cookieLastInteractedAt: Date?
    var cookieLastKnownPosture: String
    var propPositions: [String: [Double]]?
    
    init(from state: RoomState) {
        self.timeOfDay = state.timeOfDayRaw
        self.isDeskLampOn = state.isDeskLampOn
        self.isWallSconceOn = state.isWallSconceOn
        self.isRecordSpinning = state.isRecordSpinning
        self.cookieFavoriteSpot = state.cookieFavoriteSpot
        self.cookiePetCount = state.cookiePetCount
        self.cookieLastInteractedAt = state.cookieLastInteractedAt
        self.cookieLastKnownPosture = state.cookiePostureRaw
        if let data = state.customPropPositionsJSON,
           let dict = try? JSONDecoder().decode([String: [Double]].self, from: data) {
            self.propPositions = dict
        } else {
            self.propPositions = nil
        }
    }
}

/// Complete local-first Nook backup payload.
struct NookBackupPayload: Codable, Sendable {
    static let schemaVersion = 1
    
    var version: Int
    var appIdentifier: String
    var exportedAt: Date
    var items: [NookItemDTO]
    var roomState: RoomStateDTO?
    
    init(items: [NookItem], roomState: RoomState? = nil) {
        self.version = Self.schemaVersion
        self.appIdentifier = "com.nook.app"
        self.exportedAt = .now
        self.items = items.map { NookItemDTO(from: $0) }
        self.roomState = roomState.map { RoomStateDTO(from: $0) }
    }
}

// MARK: - Extension on NookItem for DTOs

extension NookItem {
    
    /// Recreates a `NookItem` from its serialized DTO snapshot.
    convenience init(dto: NookItemDTO) {
        self.init(
            title: dto.title,
            content: dto.content,
            itemType: NookItemType(rawValue: dto.itemType) ?? .thought,
            objectType: NookObjectType(rawValue: dto.objectType) ?? .pebble,
            position: RoomPosition(x: dto.positionX, y: dto.positionY, z: dto.positionZ),
            rotation: dto.rotation,
            styleTag: dto.styleTag
        )
        self.id = dto.id
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.isArchived = dto.isArchived
        if let meta = dto.metadata {
            self.setMetadata(meta)
        }
    }
    
    /// Converts to a DTO snapshot for undo or backup.
    func toDTO() -> NookItemDTO {
        NookItemDTO(from: self)
    }
}

// MARK: - Backup & Restore Service

enum NookBackupError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidData
    case corruptedPayload(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            return "This backup was created with a newer version of Nook (version \(v))."
        case .invalidData:
            return "The selected file is not a valid Nook backup."
        case .corruptedPayload(let detail):
            return "Failed to restore backup: \(detail)"
        }
    }
}

/// Handles JSON-based offline backup export and restoration without external dependencies.
final class NookBackupService: Sendable {
    
    static let shared = NookBackupService()
    
    /// Generates a standardized JSON backup payload.
    func exportBackup(items: [NookItem], roomState: RoomState? = nil) throws -> Data {
        let payload = NookBackupPayload(items: items, roomState: roomState)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }
    
    /// Restores items and room state from a JSON backup.
    @MainActor
    func importBackup(from data: Data, into context: ModelContext) throws -> (itemsImported: Int, roomRestored: Bool) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let payload = try? decoder.decode(NookBackupPayload.self, from: data) else {
            throw NookBackupError.invalidData
        }
        
        guard payload.version <= NookBackupPayload.schemaVersion else {
            throw NookBackupError.unsupportedVersion(payload.version)
        }
        
        var importedCount = 0
        
        // Fetch existing items to prevent duplicates by ID
        let descriptor = FetchDescriptor<NookItem>()
        let existingItems = (try? context.fetch(descriptor)) ?? []
        let existingIDs = Set(existingItems.map { $0.id })
        
        for itemDTO in payload.items {
            if !existingIDs.contains(itemDTO.id) {
                let newItem = NookItem(dto: itemDTO)
                context.insert(newItem)
                importedCount += 1
            }
        }
        
        var roomRestored = false
        if let roomDTO = payload.roomState {
            let roomDescriptor = FetchDescriptor<RoomState>()
            let existingRooms = (try? context.fetch(roomDescriptor)) ?? []
            let room: RoomState
            if let first = existingRooms.first {
                room = first
            } else {
                room = RoomState()
                context.insert(room)
            }
            
            room.timeOfDayRaw = roomDTO.timeOfDay
            room.isDeskLampOn = roomDTO.isDeskLampOn
            room.isWallSconceOn = roomDTO.isWallSconceOn
            room.isRecordSpinning = roomDTO.isRecordSpinning
            room.cookieFavoriteSpot = roomDTO.cookieFavoriteSpot
            room.cookiePetCount = roomDTO.cookiePetCount
            room.cookieLastInteractedAt = roomDTO.cookieLastInteractedAt
            room.cookiePostureRaw = roomDTO.cookieLastKnownPosture
            if let props = roomDTO.propPositions {
                room.customPropPositionsJSON = try? JSONEncoder().encode(props)
            }
            room.updatedAt = .now
            roomRestored = true
        }
        
        try context.save()
        return (importedCount, roomRestored)
    }
}

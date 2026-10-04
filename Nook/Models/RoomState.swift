import Foundation
import SwiftData

/// Persists room environment settings, lighting states, custom prop coordinates,
/// and Cookie's permanent companion preferences.
///
/// Designed for local-first reliability. Does NOT persist temporary animation states.
@Model
final class RoomState {
    
    /// Unique identifier for the primary room state.
    @Attribute(.unique)
    var id: String = "primary_room"
    
    /// User's selected time of day environment.
    var timeOfDayRaw: String
    
    /// Whether the desk lamp is turned on.
    var isDeskLampOn: Bool
    
    /// Whether the wall sconce lamp is turned on.
    var isWallSconceOn: Bool
    
    /// Whether the vinyl record player is currently spinning.
    var isRecordSpinning: Bool
    
    /// Cookie's favorite resting spot in the room (e.g., "bed", "pouf", "desk", "rug").
    var cookieFavoriteSpot: String
    
    /// Total number of times Cookie has been petted.
    var cookiePetCount: Int
    
    /// Timestamp of the last interaction with Cookie.
    var cookieLastInteractedAt: Date?
    
    /// Cookie's persistent resting posture ("sleeping", "resting", "observing").
    /// Note: Does NOT store temporary animation keyframes.
    var cookiePostureRaw: String
    
    /// Custom 3D coordinates for movable room props (JSON dictionary of propName -> [x, y, z]).
    var customPropPositionsJSON: Data?
    
    /// When the room state was last modified.
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    var timeOfDay: RoomTimeOfDay {
        get { RoomTimeOfDay(rawValue: timeOfDayRaw) ?? .morning }
        set { 
            timeOfDayRaw = newValue.rawValue
            updatedAt = .now
        }
    }
    
    // MARK: - Initializer
    
    init(
        id: String = "primary_room",
        timeOfDay: RoomTimeOfDay = .morning,
        isDeskLampOn: Bool = false,
        isWallSconceOn: Bool = false,
        isRecordSpinning: Bool = true,
        cookieFavoriteSpot: String = "bed",
        cookiePetCount: Int = 0,
        cookieLastInteractedAt: Date? = nil,
        cookiePosture: String = "sleeping"
    ) {
        self.id = id
        self.timeOfDayRaw = timeOfDay.rawValue
        self.isDeskLampOn = isDeskLampOn
        self.isWallSconceOn = isWallSconceOn
        self.isRecordSpinning = isRecordSpinning
        self.cookieFavoriteSpot = cookieFavoriteSpot
        self.cookiePetCount = cookiePetCount
        self.cookieLastInteractedAt = cookieLastInteractedAt
        self.cookiePostureRaw = cookiePosture
        self.customPropPositionsJSON = nil
        self.updatedAt = .now
    }
}

// MARK: - Custom Prop Coordinates Helpers

extension RoomState {
    
    /// Returns stored custom coordinates for a movable prop, if any.
    func propPosition(for name: String) -> (x: Double, y: Double, z: Double)? {
        guard let data = customPropPositionsJSON,
              let dict = try? JSONDecoder().decode([String: [Double]].self, from: data),
              let coords = dict[name], coords.count >= 3 else {
            return nil
        }
        return (coords[0], coords[1], coords[2])
    }
    
    /// Stores or updates custom coordinates for a movable prop.
    func setPropPosition(name: String, x: Double, y: Double, z: Double) {
        var dict: [String: [Double]] = [:]
        if let data = customPropPositionsJSON,
           let existing = try? JSONDecoder().decode([String: [Double]].self, from: data) {
            dict = existing
        }
        dict[name] = [x, y, z]
        customPropPositionsJSON = try? JSONEncoder().encode(dict)
        updatedAt = .now
    }
    
    /// Clears all custom prop coordinates back to default layout.
    func resetPropPositions() {
        customPropPositionsJSON = nil
        updatedAt = .now
    }
}

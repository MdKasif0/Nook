import Foundation
import simd

/// Simple, local-only memory persistence for Cookie.
///
/// Stores:
/// - Current room position and orientation
/// - Favorite room location (e.g. Daybed, Desk, Sunken Lounge)
/// - Last interaction timestamp
/// - Current emotional mood & activity
/// - Total petting and sleep counts
///
/// 100% deterministic and local (UserDefaults). No AI, no cloud dependencies.
public struct CookieMemoryData: Codable, Sendable, Equatable {
    public var positionX: Float
    public var positionY: Float
    public var positionZ: Float
    public var rotationY: Float
    public var favoriteZone: String
    public var lastInteractionDate: Date
    public var currentMood: String
    public var currentActivity: String
    public var petCount: Int
    public var sleepCount: Int
    
    public init(
        positionX: Float = 0.48,
        positionY: Float = 0.605,
        positionZ: Float = -0.66,
        rotationY: Float = Float.pi * 0.20,
        favoriteZone: String = "Daybed",
        lastInteractionDate: Date = Date(),
        currentMood: String = CookieMood.idle.rawValue,
        currentActivity: String = CookieActivity.idle.rawValue,
        petCount: Int = 0,
        sleepCount: Int = 0
    ) {
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.rotationY = rotationY
        self.favoriteZone = favoriteZone
        self.lastInteractionDate = lastInteractionDate
        self.currentMood = currentMood
        self.currentActivity = currentActivity
        self.petCount = petCount
        self.sleepCount = sleepCount
    }
    
    public var positionSIMD: SIMD3<Float> {
        SIMD3<Float>(positionX, positionY, positionZ)
    }
}

@MainActor
public final class CookieMemoryStore {
    public static let shared = CookieMemoryStore()
    private let storageKey = "nook_cookie_memory_v1"
    private let defaults: UserDefaults
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    /// Loads Cookie's persisted memory from disk.
    public func load() -> CookieMemoryData {
        guard let data = defaults.data(forKey: storageKey),
              let memory = try? JSONDecoder().decode(CookieMemoryData.self, from: data) else {
            return CookieMemoryData()
        }
        return memory
    }
    
    /// Persists Cookie's updated memory to disk.
    public func save(_ memory: CookieMemoryData) {
        if let encoded = try? JSONEncoder().encode(memory) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    /// Updates Cookie's current position and orientation.
    public func updatePosition(_ pos: SIMD3<Float>, rotationY: Float, zone: String? = nil) {
        var mem = load()
        mem.positionX = pos.x
        mem.positionY = pos.y
        mem.positionZ = pos.z
        mem.rotationY = rotationY
        if let zone {
            mem.favoriteZone = zone
        }
        mem.lastInteractionDate = Date()
        save(mem)
    }
    
    /// Records a petting interaction.
    public func recordPet() {
        var mem = load()
        mem.petCount += 1
        mem.lastInteractionDate = Date()
        mem.currentMood = CookieMood.happy.rawValue
        mem.currentActivity = CookieActivity.happy.rawValue
        save(mem)
    }
    
    /// Records a sleep session.
    public func recordSleep() {
        var mem = load()
        mem.sleepCount += 1
        mem.currentMood = CookieMood.resting.rawValue
        mem.currentActivity = CookieActivity.sleeping.rawValue
        save(mem)
    }
    
    /// Resets memory back to defaults.
    public func reset() {
        defaults.removeObject(forKey: storageKey)
    }
}

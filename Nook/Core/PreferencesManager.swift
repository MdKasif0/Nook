import SwiftUI
import ServiceManagement
import SwiftData

/// Manages application-wide user preferences using UserDefaults and native macOS APIs.
@MainActor
@Observable
final class PreferencesManager {
    static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let reduceMotion = "nook_reduce_motion"
        static let launchAtLogin = "nook_launch_at_login"
        static let soundEffects = "nook_sound_effects"
        static let cookieReactions = "nook_cookie_reactions"
    }
    
    // MARK: - Settings Properties
    
    /// Whether reduced motion is explicitly forced by the user in Nook preferences.
    var reduceMotion: Bool {
        didSet {
            defaults.set(reduceMotion, forKey: Keys.reduceMotion)
        }
    }
    
    /// Whether Nook should launch at system login via SMAppService.
    var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin(launchAtLogin)
        }
    }
    
    /// Whether tactile sound effects are enabled.
    var soundEffectsEnabled: Bool {
        didSet {
            defaults.set(soundEffectsEnabled, forKey: Keys.soundEffects)
        }
    }
    
    /// Whether Cookie actively reacts to user events (new thoughts, completions, deletions).
    var cookieReactionsEnabled: Bool {
        didSet {
            defaults.set(cookieReactionsEnabled, forKey: Keys.cookieReactions)
        }
    }
    
    private init() {
        self.reduceMotion = defaults.bool(forKey: Keys.reduceMotion)
        
        // Sound effects must be OFF by default per user specification
        if defaults.object(forKey: Keys.soundEffects) != nil {
            self.soundEffectsEnabled = defaults.bool(forKey: Keys.soundEffects)
        } else {
            self.soundEffectsEnabled = false
        }
        
        if defaults.object(forKey: Keys.cookieReactions) != nil {
            self.cookieReactionsEnabled = defaults.bool(forKey: Keys.cookieReactions)
        } else {
            self.cookieReactionsEnabled = true
        }
        
        // Launch at login status from SMAppService if available
        if #available(macOS 13.0, *) {
            self.launchAtLogin = (SMAppService.mainApp.status == .enabled)
        } else {
            self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        }
    }
    
    // MARK: - Launch At Login Implementation
    
    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("[PreferencesManager] Launch at login registration failed: \(error)")
            }
        }
    }
    
    // MARK: - Reset Room Layout
    
    /// Rearranges all active physical items on the desk back into natural placement clusters.
    @MainActor
    func resetRoomLayout(modelContext: ModelContext, items: [NookItem]) {
        let zones = PlacementZone.allCases
        for (index, item) in items.enumerated() {
            let zone = zones[index % zones.count]
            let naturalPos = zone.naturalPosition(existingCount: index / zones.count)
            item.roomPosition = naturalPos
            item.touch()
        }
        
        try? modelContext.save()
        
        // Notify the room scene and Cookie
        RoomEventBus.shared.publish(.roomOpened(wasAwayForDuration: 0))
    }
}

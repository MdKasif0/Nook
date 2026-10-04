import AppKit

/// Provides subtle, tactile audio feedback for room interactions, respecting user sound preferences.
@MainActor
final class AudioManager {
    static let shared = AudioManager()
    
    private init() {}
    
    /// Subtle click when a physical object is picked up or selected.
    func playObjectSelected() {
        guard PreferencesManager.shared.soundEffectsEnabled else { return }
        NSSound(named: "Pop")?.play()
    }
    
    /// Gentle soft click when an object is placed or a thought is materialized on the desk.
    func playObjectPlaced() {
        guard PreferencesManager.shared.soundEffectsEnabled else { return }
        NSSound(named: "Tink")?.play()
    }
    
    /// Pleasant chime when a thought/task is completed or archived.
    func playCompleted() {
        guard PreferencesManager.shared.soundEffectsEnabled else { return }
        NSSound(named: "Hero")?.play()
    }
    
    /// Subtle tactile tap when deleting an object.
    func playDeleted() {
        guard PreferencesManager.shared.soundEffectsEnabled else { return }
        NSSound(named: "Basso")?.play()
    }
    
    /// Gentle purr reaction sound when petting Cookie.
    func playPurr() {
        guard PreferencesManager.shared.soundEffectsEnabled else { return }
        NSSound(named: "Blow")?.play()
    }
}

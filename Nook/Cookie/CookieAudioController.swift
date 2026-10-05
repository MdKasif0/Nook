import Foundation
import AVFoundation
import os

/// Distinct vocalization types for Cookie the companion kitten.
public enum CookieVocalization: String, CaseIterable, Sendable {
    case softMeow = "cookie_soft_meow"
    case tinyMeow = "cookie_tiny_meow"
    case curiousChirp = "cookie_curious_chirp"
    case happyMeow = "cookie_happy_meow"
    case sleepyMurmur = "cookie_sleepy_murmur"
    case purr = "cookie_purr"
    
    public var filename: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .softMeow:     return "Soft Meow"
        case .tinyMeow:     return "Tiny Meow"
        case .curiousChirp: return "Curious Chirp"
        case .happyMeow:    return "Happy Meow"
        case .sleepyMurmur: return "Sleepy Murmur"
        case .purr:         return "Purr"
        }
    }
}

/// Native audio controller managing Cookie's cute, gentle cat vocalizations and subtle purring.
///
/// Features:
/// - 100% local, native AVFoundation audio playback
/// - Bundled audio assets (soft meow, tiny meow, curious chirp, happy meow, sleepy murmur, purr)
/// - Seamless background purr looping when petted or sleeping
/// - Cooldown enforcement preventing repetitive or annoying sounds
/// - Low default volume (~0.35) and master mute toggle support
@MainActor
public final class CookieAudioController {
    
    public static let shared = CookieAudioController()
    private static let logger = Logger(subsystem: "com.nook.app", category: "CookieAudio")
    
    // Players
    private var vocalizationPlayer: AVAudioPlayer?
    private var purrPlayer: AVAudioPlayer?
    
    // Cooldown state
    private var lastVocalizationTime: Date = .distantPast
    private var minAutonomousCooldown: TimeInterval = 12.0
    private var minDebounce: TimeInterval = 0.8
    
    public init() {
        preloadPurrPlayer()
    }
    
    /// Resets all internal vocalization cooldowns (useful for clean test isolation or modal transitions).
    public func resetCooldowns() {
        lastVocalizationTime = .distantPast
    }
    
    // MARK: - Resource Resolution
    
    private func audioURL(for vocalization: CookieVocalization) -> URL? {
        // 1. Look in app bundle resources
        if let url = Bundle.main.url(forResource: vocalization.filename, withExtension: "wav") {
            return url
        }
        if let url = Bundle.main.url(forResource: vocalization.filename, withExtension: "wav", subdirectory: "Audio") {
            return url
        }
        
        // 2. Fallback to direct development / test workspace resources path
        let devAudioPath = "/Users/mdkasifuddin/Developer/macOS/Nook/Nook/Resources/Audio/\(vocalization.filename).wav"
        if FileManager.default.fileExists(atPath: devAudioPath) {
            return URL(fileURLWithPath: devAudioPath)
        }
        
        return nil
    }
    
    // MARK: - Vocalization Playback
    
    /// Plays a specific cat vocalization with optional cooldown bypass for explicit user interactions.
    @discardableResult
    public func play(_ vocalization: CookieVocalization, force: Bool = false, bypassDebounce: Bool = false) -> Bool {
        guard PreferencesManager.shared.cookieSoundEnabled else { return false }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(lastVocalizationTime)
        
        if force {
            if !bypassDebounce {
                guard elapsed >= minDebounce else { return false }
            }
        } else {
            guard elapsed >= minAutonomousCooldown else { return false }
        }
        
        guard let url = audioURL(for: vocalization) else {
            Self.logger.debug("Audio asset not found for \(vocalization.rawValue)")
            return false
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = PreferencesManager.shared.cookieSoundVolume
            player.prepareToPlay()
            player.play()
            
            self.vocalizationPlayer = player
            self.lastVocalizationTime = now
            return true
        } catch {
            Self.logger.error("Failed to play vocalization \(vocalization.rawValue): \(error.localizedDescription)")
            return false
        }
    }
    
    /// Plays an autonomous gentle meow (soft, tiny, or chirp) respecting randomized cooldowns.
    @discardableResult
    public func playAutonomousGreeting() -> Bool {
        let greetings: [CookieVocalization] = [.softMeow, .tinyMeow, .curiousChirp]
        guard let sound = greetings.randomElement() else { return false }
        return play(sound, force: false)
    }
    
    /// Plays a happy celebration sound when a thought is completed or Cookie is petted.
    public func playHappyReaction() {
        let happySounds: [CookieVocalization] = [.happyMeow, .curiousChirp, .softMeow]
        if let sound = happySounds.randomElement() {
            play(sound, force: true)
        }
    }
    
    /// Plays a soft sleepy sound when resting or curling up.
    public func playSleepyMurmur() {
        play(.sleepyMurmur, force: false)
    }
    
    // MARK: - Purring Loop
    
    private func preloadPurrPlayer() {
        guard let url = audioURL(for: .purr) else { return }
        try? purrPlayer = AVAudioPlayer(contentsOf: url)
        purrPlayer?.numberOfLoops = -1 // Infinite seamless loop
    }
    
    /// Starts very subtle, soothing purr loop while Cookie is petted or sleeping peacefully.
    public func startPurring() {
        guard PreferencesManager.shared.cookieSoundEnabled else { return }
        
        if purrPlayer == nil {
            preloadPurrPlayer()
        }
        
        guard let player = purrPlayer, !player.isPlaying else { return }
        // Purring is extra gentle (-60% of base vocalization volume)
        player.volume = min(0.18, PreferencesManager.shared.cookieSoundVolume * 0.45)
        player.currentTime = 0
        player.play()
    }
    
    /// Stops the purring loop.
    public func stopPurring() {
        guard let player = purrPlayer, player.isPlaying else { return }
        player.stop()
    }
    
    /// Stops all currently active sounds.
    public func stopAll() {
        vocalizationPlayer?.stop()
        purrPlayer?.stop()
    }
}

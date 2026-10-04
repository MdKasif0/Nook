import SwiftUI
import SceneKit

/// Represents the time of day and atmospheric conditions inside the Nook room.
///
/// Controls sunlight angles, sky appearance outside the window,
/// ambient room warmth, and desk lamp state.
enum RoomTimeOfDay: String, CaseIterable, Identifiable, Sendable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case sunset = "Golden Hour"
    case night = "Cozy Night"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .morning:   return "sun.and.horizon"
        case .afternoon: return "sun.max.fill"
        case .sunset:    return "sunset.fill"
        case .night:     return "moon.stars.fill"
        }
    }
    
    /// The primary directional sunlight color.
    var sunlightColor: NSColor {
        switch self {
        case .morning:
            return NSColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1.0) // Soft warm morning daylight
        case .afternoon:
            return NSColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1.0) // Crisp natural daylight
        case .sunset:
            return NSColor(red: 1.0, green: 0.78, blue: 0.58, alpha: 1.0) // Warm amber golden hour
        case .night:
            return NSColor(red: 0.45, green: 0.48, blue: 0.60, alpha: 1.0) // Soft cool moonlight
        }
    }
    
    /// Directional sunlight intensity.
    var sunlightIntensity: CGFloat {
        switch self {
        case .morning:   return 1100
        case .afternoon: return 1200
        case .sunset:    return 950
        case .night:     return 220
        }
    }
    
    /// Ambient fill light color so shadows remain soft and gentle.
    var ambientColor: NSColor {
        switch self {
        case .morning:
            return NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
        case .afternoon:
            return NSColor(red: 0.94, green: 0.93, blue: 0.90, alpha: 1.0)
        case .sunset:
            return NSColor(red: 0.95, green: 0.88, blue: 0.82, alpha: 1.0)
        case .night:
            return NSColor(red: 0.35, green: 0.38, blue: 0.48, alpha: 1.0)
        }
    }
    
    /// Ambient light intensity.
    var ambientIntensity: CGFloat {
        switch self {
        case .morning:   return 500
        case .afternoon: return 550
        case .sunset:    return 480
        case .night:     return 320
        }
    }
    
    /// Sky top gradient color for outside the window.
    var skyTopColor: NSColor {
        switch self {
        case .morning:
            return NSColor(red: 0.68, green: 0.82, blue: 0.94, alpha: 1.0)
        case .afternoon:
            return NSColor(red: 0.52, green: 0.75, blue: 0.95, alpha: 1.0)
        case .sunset:
            return NSColor(red: 0.92, green: 0.55, blue: 0.42, alpha: 1.0)
        case .night:
            return NSColor(red: 0.10, green: 0.12, blue: 0.22, alpha: 1.0)
        }
    }
    
    /// Sky horizon color for outside the window.
    var skyHorizonColor: NSColor {
        switch self {
        case .morning:
            return NSColor(red: 0.98, green: 0.92, blue: 0.82, alpha: 1.0)
        case .afternoon:
            return NSColor(red: 0.88, green: 0.94, blue: 0.98, alpha: 1.0)
        case .sunset:
            return NSColor(red: 0.98, green: 0.80, blue: 0.50, alpha: 1.0)
        case .night:
            return NSColor(red: 0.22, green: 0.26, blue: 0.38, alpha: 1.0)
        }
    }
    
    /// Whether the cozy desk lamp should be illuminated by default.
    var isDeskLampDefaultOn: Bool {
        switch self {
        case .morning, .afternoon: return false
        case .sunset, .night:     return true
        }
    }
}

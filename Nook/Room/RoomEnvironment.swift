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
            return NSColor(red: 1.0, green: 0.94, blue: 0.86, alpha: 1.0) // Soft warm morning daylight
        case .afternoon:
            return NSColor(red: 1.0, green: 0.98, blue: 0.93, alpha: 1.0) // Neutral warm daylight
        case .sunset:
            return NSColor(red: 1.0, green: 0.74, blue: 0.50, alpha: 1.0) // Warm golden light
        case .night:
            // Strictly warm amber/cream interior light — NO blue nighttime lighting
            return NSColor(red: 0.96, green: 0.82, blue: 0.64, alpha: 1.0)
        }
    }
    
    /// Directional sunlight intensity.
    var sunlightIntensity: CGFloat {
        switch self {
        case .morning:   return 1150
        case .afternoon: return 1250
        case .sunset:    return 1000
        case .night:     return 160 // Very soft warm amber moon/ambient filter
        }
    }
    
    /// Ambient fill light color so shadows remain soft and gentle.
    var ambientColor: NSColor {
        switch self {
        case .morning:
            return NSColor(red: 0.96, green: 0.93, blue: 0.88, alpha: 1.0)
        case .afternoon:
            return NSColor(red: 0.95, green: 0.94, blue: 0.91, alpha: 1.0)
        case .sunset:
            return NSColor(red: 0.96, green: 0.86, blue: 0.78, alpha: 1.0)
        case .night:
            // Warm dim amber/cream interior ambient glow — completely non-blue
            return NSColor(red: 0.58, green: 0.48, blue: 0.38, alpha: 1.0)
        }
    }
    
    /// Ambient light intensity.
    var ambientIntensity: CGFloat {
        switch self {
        case .morning:   return 520
        case .afternoon: return 560
        case .sunset:    return 480
        case .night:     return 360 // Cozy warm ambient fill from lamps
        }
    }
    
    /// Sky top gradient color for outside the window (muted, non-saturated).
    var skyTopColor: NSColor {
        switch self {
        case .morning:
            return NSColor(red: 0.72, green: 0.80, blue: 0.86, alpha: 1.0) // Soft morning sky
        case .afternoon:
            return NSColor(red: 0.60, green: 0.74, blue: 0.85, alpha: 1.0) // Bright gentle daylight
        case .sunset:
            return NSColor(red: 0.82, green: 0.58, blue: 0.48, alpha: 1.0) // Warm sunset terracotta
        case .night:
            // Dark neutral sky with subtle warmth — NO saturated blue
            return NSColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1.0)
        }
    }
    
    /// Sky horizon color for outside the window.
    var skyHorizonColor: NSColor {
        switch self {
        case .morning:
            return NSColor(red: 0.95, green: 0.92, blue: 0.86, alpha: 1.0)
        case .afternoon:
            return NSColor(red: 0.88, green: 0.92, blue: 0.95, alpha: 1.0)
        case .sunset:
            return NSColor(red: 0.95, green: 0.76, blue: 0.56, alpha: 1.0)
        case .night:
            return NSColor(red: 0.18, green: 0.17, blue: 0.18, alpha: 1.0)
        }
    }
    
    /// Whether interior cozy lamps (desk lamp & wall sconce) should be on by default.
    var isDeskLampDefaultOn: Bool {
        switch self {
        case .morning, .afternoon: return false
        case .sunset, .night:     return true
        }
    }
}

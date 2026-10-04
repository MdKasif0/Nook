import SwiftUI

/// Identifies the different windows in the Nook application.
enum NookWindow: String, Identifiable {
    case main = "nook-main"
    case quickCapture = "nook-quick-capture"
    
    var id: String { rawValue }
}

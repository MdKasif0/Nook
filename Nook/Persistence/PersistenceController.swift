import Foundation
import SwiftData

/// Manages the SwiftData model container for the Nook application.
///
/// Uses a singleton so the same container is shared across all windows.
final class PersistenceController: Sendable {
    
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            NookItem.self
        ])
        
        let configuration = ModelConfiguration(
            "NookStore",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create Nook model container: \(error.localizedDescription)")
        }
    }
}

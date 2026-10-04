import Foundation

/// Events emitted within Nook to which Cookie and other systems can react.
///
/// Enables a clean, decoupled reactive architecture without third-party frameworks.
enum NookEvent: Sendable {
    case itemCreated(itemID: UUID, position: RoomPosition)
    case itemDeleted(itemID: UUID)
    case itemCompleted(itemID: UUID)
    case roomOpened
    case roomClosed
    case longIdle
    case thoughtCaptured(title: String)
    case cookiePetted
}

/// A lightweight, thread-safe native event bus for internal Nook communication.
@MainActor
final class NookEventBus {
    static let shared = NookEventBus()
    
    typealias Handler = (NookEvent) -> Void
    private var handlers: [UUID: Handler] = [:]
    
    private init() {}
    
    /// Subscribes to events. Returns a token for later unregistering.
    @discardableResult
    func subscribe(_ handler: @escaping Handler) -> UUID {
        let token = UUID()
        handlers[token] = handler
        return token
    }
    
    /// Unsubscribes from events using the subscription token.
    func unsubscribe(_ token: UUID) {
        handlers.removeValue(forKey: token)
    }
    
    /// Broadcasts an event to all active subscribers.
    func publish(_ event: NookEvent) {
        for handler in handlers.values {
            handler(event)
        }
    }
}

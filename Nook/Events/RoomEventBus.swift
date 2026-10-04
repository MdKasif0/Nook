import Foundation

/// Defines all meaningful domain events that occur within the Nook room.
///
/// Cookie and other room components subscribe to these events to react
/// naturally without tight coupling to the user interface.
enum RoomEvent: Sendable {
    /// A new item was placed inside the room diorama.
    case itemCreated(title: String, itemType: NookItemType, objectType: NookObjectType, position: RoomPosition)
    
    /// An existing item was removed or deleted.
    case itemDeleted(title: String)
    
    /// An item was archived or marked completed.
    case itemCompleted(title: String)
    
    /// The user captured a thought via Quick Thought (⌘⇧Space).
    case thoughtCaptured(title: String, objectType: NookObjectType)
    
    /// The user opened or focused the Nook window after being away.
    case roomOpened(wasAwayForDuration: TimeInterval)
    
    /// The Nook window closed or lost focus.
    case roomClosed
    
    /// The user has been inactive for a prolonged period.
    case longIdle
    
    /// The user clicked or petted Cookie directly.
    case cookiePetted
}

/// A lightweight, native Swift event bus for publishing and subscribing to room events.
///
/// Avoids external third-party dependencies by using native Swift closures and concurrency.
@MainActor
final class RoomEventBus {
    
    static let shared = RoomEventBus()
    
    private var subscribers: [UUID: @MainActor (RoomEvent) -> Void] = [:]
    
    private init() {}
    
    /// Subscribes a listener to room events. Returns a cancellation token.
    @discardableResult
    func subscribe(_ handler: @escaping @MainActor (RoomEvent) -> Void) -> UUID {
        let token = UUID()
        subscribers[token] = handler
        return token
    }
    
    /// Unsubscribes a listener by token.
    func unsubscribe(_ token: UUID) {
        subscribers.removeValue(forKey: token)
    }
    
    /// Publishes an event to all active subscribers.
    func publish(_ event: RoomEvent) {
        for handler in subscribers.values {
            handler(event)
        }
    }
}

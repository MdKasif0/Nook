import Foundation

/// Defines all meaningful domain events that occur within the Nook room.
///
/// Cookie and other room components subscribe to these events to react
/// naturally without tight coupling to the user interface.
enum RoomEvent: Sendable {
    // 1. Room & Window Lifecycle
    case roomOpened(wasAwayForDuration: TimeInterval)
    case roomClosed
    
    // 2. Thought/Item Lifecycle
    case itemCreated(title: String, itemType: NookItemType, objectType: NookObjectType, position: RoomPosition)
    case thoughtCreated(title: String, itemType: NookItemType, objectType: NookObjectType, position: SIMD3<Float>)
    case thoughtOpened(id: UUID)
    case thoughtEdited(id: UUID)
    case itemDeleted(title: String)
    case thoughtDeleted(id: UUID, lastPosition: SIMD3<Float>)
    case itemCompleted(title: String)
    case thoughtCaptured(title: String, objectType: NookObjectType)
    
    // 3. Physical Diorama Object Manipulation
    case objectMoved(id: String, position: SIMD3<Float>)
    case objectDropped(id: String, position: SIMD3<Float>)
    
    // 4. User Presence & Activity
    case searchPerformed(query: String)
    case userIdle(duration: TimeInterval)
    case userReturned
    case longIdle
    
    // 5. Direct Cookie Interaction
    case cookieClicked
    case cookiePetted
    case cookieDragged(startPosition: SIMD3<Float>, endPosition: SIMD3<Float>)
    case cookieCalled(targetPosition: SIMD3<Float>)
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

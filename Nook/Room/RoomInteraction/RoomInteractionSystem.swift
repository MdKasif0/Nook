import RealityKit
import SwiftUI
import AppKit

/// Handles user interactions in the 3D diorama:
/// - Selecting thought objects (pebbles, notes, stickies, polaroids, cards, bookmarks)
/// - Dragging thought objects across surfaces with plane snapping
/// - Toggling desk lamp on/off
/// - Petting Cookie the cat
/// - Toggling vinyl record playback
@MainActor
final class RoomInteractionSystem {
    
    weak var coordinator: RoomSceneCoordinator?
    
    init(coordinator: RoomSceneCoordinator? = nil) {
        self.coordinator = coordinator
    }
    
    /// Evaluates a click / tap on an entity in the scene
    func handleEntityTap(_ entity: Entity) {
        // 1. Check if user clicked Cookie
        if entity.name == "cookie_character" || entity.findAncestor(named: "cookie_character") != nil {
            coordinator?.petCookie()
            return
        }
        
        // 2. Check if user clicked the desk lamp
        if entity.name == "desk_lamp" || entity.findAncestor(named: "desk_lamp") != nil {
            coordinator?.toggleDeskLamp()
            return
        }
        
        // 3. Check if user clicked the record player
        if entity.name == "record_player" || entity.findAncestor(named: "record_player") != nil {
            coordinator?.toggleRecordPlayer()
            return
        }
        
        // 4. Check if user clicked a thought item
        if let thoughtEntity = entity.findAncestor(prefix: "thought_") {
            let idStr = String(thoughtEntity.name.dropFirst("thought_".count))
            if let uuid = UUID(uuidString: idStr) {
                coordinator?.selectItem(uuid)
                return
            }
        }
        
        // Clicked outside / empty space -> clear selection
        coordinator?.selectItem(nil)
    }
    
    /// Handles moving a thought object to a new 3D location
    func handleItemDrag(id: UUID, newPosition: SIMD3<Float>) {
        coordinator?.updateItemPosition(id: id, position: newPosition)
    }
}

// MARK: - Entity Hierarchy Traversal Helpers

extension Entity {
    func findAncestor(named targetName: String) -> Entity? {
        var cur: Entity? = self
        while let node = cur {
            if node.name == targetName {
                return node
            }
            cur = node.parent
        }
        return nil
    }
    
    func findAncestor(prefix: String) -> Entity? {
        var cur: Entity? = self
        while let node = cur {
            if node.name.hasPrefix(prefix) {
                return node
            }
            cur = node.parent
        }
        return nil
    }
}

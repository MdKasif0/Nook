import Foundation
import SwiftData
import SwiftUI

/// Centralized service for local-first item actions with native macOS `UndoManager` integration.
///
/// Implements undo/redo for:
/// - Deleting an item (with full state restoration from snapshot DTO)
/// - Changing item content (title, content, object type)
/// - Moving an item (position coordinates and rotation)
/// - Archiving and unarchiving
@MainActor
final class NookActionService {
    
    static let shared = NookActionService()
    
    private init() {}
    
    // MARK: - 1. Deletion & Native Undo
    
    /// Deletes a Nook item with native macOS undo capability.
    ///
    /// Captures a complete snapshot DTO before deleting.
    /// Registering with `UndoManager` allows the user to press ⌘Z at any time
    /// to seamlessly restore the thought right back into their room.
    func deleteItem(
        _ item: NookItem,
        in context: ModelContext,
        undoManager: UndoManager?,
        appState: AppState? = nil
    ) {
        let snapshot = item.toDTO()
        let itemTitle = item.title
        
        context.delete(item)
        PersistenceController.shared.safeSave(context: context, appState: appState)
        
        RoomEventBus.shared.publish(.itemDeleted(title: itemTitle))
        
        // Native macOS Undo Registration
        undoManager?.registerUndo(withTarget: context) { [weak self] targetContext in
            guard let self else { return }
            self.restoreItem(from: snapshot, in: targetContext, undoManager: undoManager, appState: appState)
        }
        undoManager?.setActionName("Delete “\(itemTitle)”")
        
        // Surface transient undo toast for tactile feedback
        appState?.showUndoToast(message: "Deleted “\(itemTitle)”") {
            undoManager?.undo()
        }
    }
    
    /// Restores a previously deleted item from its snapshot DTO.
    private func restoreItem(
        from snapshot: NookItemDTO,
        in context: ModelContext,
        undoManager: UndoManager?,
        appState: AppState?
    ) {
        let restoredItem = NookItem(dto: snapshot)
        context.insert(restoredItem)
        PersistenceController.shared.safeSave(context: context, appState: appState)
        
        RoomEventBus.shared.publish(.itemCreated(
            title: restoredItem.title,
            itemType: restoredItem.itemType,
            objectType: restoredItem.objectType,
            position: restoredItem.roomPosition
        ))
        
        // Redo registration: re-deleting
        undoManager?.registerUndo(withTarget: context) { [weak self] targetContext in
            guard let self else { return }
            self.deleteItem(restoredItem, in: targetContext, undoManager: undoManager, appState: appState)
        }
        undoManager?.setActionName("Delete “\(restoredItem.title)”")
        
        appState?.showUndoToast(message: "Restored “\(restoredItem.title)”") {
            undoManager?.redo()
        }
    }
    
    // MARK: - 2. Content Changes & Native Undo
    
    /// Updates item title, content, or object type with native undo support.
    func updateItem(
        _ item: NookItem,
        title newTitle: String,
        content newContent: String,
        objectType newObjectType: NookObjectType,
        in context: ModelContext,
        undoManager: UndoManager?,
        appState: AppState? = nil
    ) {
        let oldTitle = item.title
        let oldContent = item.content
        let oldObjectType = item.objectType
        
        guard oldTitle != newTitle || oldContent != newContent || oldObjectType != newObjectType else {
            return
        }
        
        item.title = newTitle
        item.content = newContent
        item.objectType = newObjectType
        item.touch()
        
        PersistenceController.shared.safeSave(context: context, appState: appState)
        
        undoManager?.registerUndo(withTarget: item) { [weak self] targetItem in
            guard let self else { return }
            self.updateItem(
                targetItem,
                title: oldTitle,
                content: oldContent,
                objectType: oldObjectType,
                in: context,
                undoManager: undoManager,
                appState: appState
            )
        }
        undoManager?.setActionName("Edit Thought")
    }
    
    // MARK: - 3. Movement & Native Undo
    
    /// Moves an item to a new room position with native undo support.
    func moveItem(
        _ item: NookItem,
        to newPosition: RoomPosition,
        in context: ModelContext,
        undoManager: UndoManager?,
        appState: AppState? = nil
    ) {
        let oldPosition = item.roomPosition
        guard abs(oldPosition.x - newPosition.x) > 0.001 ||
              abs(oldPosition.y - newPosition.y) > 0.001 ||
              abs(oldPosition.z - newPosition.z) > 0.001 else {
            return
        }
        
        item.roomPosition = newPosition
        item.touch()
        
        PersistenceController.shared.safeSave(context: context, appState: appState)
        
        undoManager?.registerUndo(withTarget: item) { [weak self] targetItem in
            guard let self else { return }
            self.moveItem(
                targetItem,
                to: oldPosition,
                in: context,
                undoManager: undoManager,
                appState: appState
            )
        }
        undoManager?.setActionName("Move Thought")
    }
    
    // MARK: - 4. Archive & Unarchive with Native Undo
    
    /// Archives an item from the room with native undo support.
    func archiveItem(
        _ item: NookItem,
        in context: ModelContext,
        undoManager: UndoManager?,
        appState: AppState? = nil
    ) {
        item.isArchived = true
        item.touch()
        
        PersistenceController.shared.safeSave(context: context, appState: appState)
        RoomEventBus.shared.publish(.itemCompleted(title: item.title))
        
        undoManager?.registerUndo(withTarget: item) { [weak self] targetItem in
            guard let self else { return }
            self.unarchiveItem(targetItem, in: context, undoManager: undoManager, appState: appState)
        }
        undoManager?.setActionName("Archive Thought")
        
        appState?.showUndoToast(message: "Archived “\(item.title)”") {
            undoManager?.undo()
        }
    }
    
    /// Unarchives an item back into the room with native undo support.
    func unarchiveItem(
        _ item: NookItem,
        in context: ModelContext,
        undoManager: UndoManager?,
        appState: AppState? = nil
    ) {
        item.isArchived = false
        item.touch()
        
        PersistenceController.shared.safeSave(context: context, appState: appState)
        
        undoManager?.registerUndo(withTarget: item) { [weak self] targetItem in
            guard let self else { return }
            self.archiveItem(targetItem, in: context, undoManager: undoManager, appState: appState)
        }
        undoManager?.setActionName("Unarchive Thought")
        
        appState?.showUndoToast(message: "Restored to room: “\(item.title)”") {
            undoManager?.undo()
        }
    }
}

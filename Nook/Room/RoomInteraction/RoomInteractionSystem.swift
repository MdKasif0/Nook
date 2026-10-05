import RealityKit
import SwiftUI
import AppKit

/// Handles physical and contextual user interactions across the 3D miniature diorama:
/// - Entity hit-testing and selection states (subtle elevation and soft emphasis)
/// - Physical drag manipulation:
///   1. Pick-up lift (+4cm) and tactile 1.03x scale
///   2. Movement clamped to room boundaries and usable surfaces (desk, bed, upper/lower floor)
///   3. Physical drop settling animation
///   4. State persistence to SwiftData
///   5. Native UndoManager (⌘Z) integration
/// - Smooth 45° rotation and position reset
/// - Contextual triggers (toggling desk lamp, spinning turntable, petting Cookie)
@MainActor
final class RoomInteractionSystem {
    
    weak var coordinator: RoomSceneCoordinator?
    
    // Active interaction state
    private(set) var selectedPropId: String?
    private(set) var hoveredPropId: String?
    
    // Drag state tracking
    private var draggingEntity: Entity?
    private var dragStartTransform: RoomPropTransform?
    private var dragOriginalScale: SIMD3<Float> = [1, 1, 1]
    private var dragOriginalRot: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    
    init(coordinator: RoomSceneCoordinator? = nil) {
        self.coordinator = coordinator
    }
    
    // MARK: - Surface Detection & Room Bounds
    
    static let minRoomX: Float = -1.08
    static let maxRoomX: Float = 1.08
    static let minRoomZ: Float = -1.05
    static let maxRoomZ: Float = 0.95
    
    /// Computes the usable physical resting surface height Y at any (x, z) coordinate in the room
    static func surfaceHeight(at x: Float, z: Float) -> Float {
        let upperFloor = RoomArchitectureEntity.upperFloorY // 0.16
        let lowerFloor = RoomArchitectureEntity.lowerFloorY // 0.02
        
        // 1. Desk tabletop surface (Left side)
        if x <= -0.52 && z <= 0.32 {
            return upperFloor + DeskEntity.deskHeight // 0.88m
        }
        
        // 2. Bed mattress surface (Back-right side)
        if x >= -0.15 && z <= -0.30 {
            return upperFloor + BedEntity.frameHeight + 0.16 // 0.60m
        }
        
        // 3. Audio lounge record bench
        if x >= 0.55 && z >= -0.45 && z <= 0.10 {
            return upperFloor + RecordBenchEntity.benchHeight // 0.38m
        }
        
        // 4. Upper main floor platform
        if z < 0.20 {
            return upperFloor // 0.16m
        }
        
        // 5. Lower sunken lounge platform
        return lowerFloor // 0.02m
    }
    
    // MARK: - Tap & Click Interaction
    
    func handleEntityTap(_ entity: Entity) {
        // 1. Check if user clicked Cookie
        if entity.name == "prop_cookie" || entity.findAncestor(named: "prop_cookie") != nil ||
           entity.name == "cookie_character" || entity.findAncestor(named: "cookie_character") != nil {
            coordinator?.petCookie()
            selectProp(id: "prop_cookie")
            return
        }
        
        // 2. Check if user clicked desk lamp
        if entity.name == "prop_desk_lamp" || entity.findAncestor(named: "prop_desk_lamp") != nil {
            coordinator?.toggleDeskLamp()
            selectProp(id: "prop_lamp")
            return
        }
        
        // 3. Check if user clicked record player
        if entity.name == "prop_record_player" || entity.findAncestor(named: "prop_record_player") != nil {
            coordinator?.toggleRecordPlayer()
            selectProp(id: "prop_record_player")
            return
        }
        
        // 4. Check if user clicked a thought item
        if let thoughtEntity = entity.findAncestor(prefix: "thought_") {
            let idStr = String(thoughtEntity.name.dropFirst("thought_".count))
            if let uuid = UUID(uuidString: idStr) {
                clearPropSelection()
                coordinator?.selectItem(uuid)
                return
            }
        }
        
        // 5. Check if user clicked a movable room prop
        if let (target, propComp) = entity.findInteractiveProp() {
            coordinator?.selectItem(nil)
            if propComp.category != .immovable {
                selectProp(id: propComp.propId)
            } else {
                clearPropSelection()
            }
            return
        }
        
        // Clicked outside / architecture -> clear selection
        clearPropSelection()
        coordinator?.selectItem(nil)
    }
    
    // MARK: - Selection Management
    
    func selectProp(id: String?) {
        // Restore previously selected entity visual emphasis
        if let prevId = selectedPropId, let prevEntity = coordinator?.findPropEntity(id: prevId) {
            applySelectionVisual(to: prevEntity, isSelected: false)
        }
        
        self.selectedPropId = id
        
        // Apply subtle elevation and soft emphasis to selected entity
        if let newId = id, let newEntity = coordinator?.findPropEntity(id: newId) {
            applySelectionVisual(to: newEntity, isSelected: true)
        }
        
        coordinator?.onPropSelected?(id)
    }
    
    func clearPropSelection() {
        selectProp(id: nil)
    }
    
    private func applySelectionVisual(to entity: Entity, isSelected: Bool) {
        guard let prop = entity.components[InteractivePropComponent.self],
              prop.category == .movable else { return }
        
        if isSelected {
            // Subtle elevation (+1.2cm) and soft scale pop (1.02x)
            entity.position.y = entity.position.y + 0.012
            entity.scale = prop.defaultScale * 1.02
        } else {
            // Return to resting surface elevation
            entity.position.y = max(entity.position.y - 0.012, prop.restingSurfaceY)
            entity.scale = prop.defaultScale
        }
    }
    
    // MARK: - Drag Manipulation
    
    func canDragEntity(_ entity: Entity) -> Bool {
        if entity.name.hasPrefix("thought_") || entity.findAncestor(prefix: "thought_") != nil {
            return true
        }
        if let (_, prop) = entity.findInteractiveProp() {
            return prop.allowsDragging
        }
        return false
    }
    
    func handleDragStart(for entity: Entity) -> Entity? {
        // Resolve the top interactive node
        let target: Entity
        if let thought = entity.findAncestor(prefix: "thought_") {
            target = thought
        } else if let (propNode, _) = entity.findInteractiveProp() {
            target = propNode
        } else {
            return nil
        }
        
        self.draggingEntity = target
        self.dragOriginalScale = target.scale
        self.dragOriginalRot = target.orientation
        
        let propId = target.components[InteractivePropComponent.self]?.propId ?? target.name
        self.dragStartTransform = RoomPropTransform(
            propId: propId,
            position: target.position,
            orientation: target.orientation,
            scale: target.scale
        )
        
        // Physical pick-up feedback:
        // 1. Visually lift slightly (+4cm)
        // 2. Tactile 1.03x scale
        // 3. Motion tilt
        target.position.y += 0.04
        target.scale = dragOriginalScale * 1.03
        
        return target
    }
    
    func handleDragUpdate(target: Entity, translation: CGSize, startPos: SIMD3<Float>) {
        // Isometric coordinate projection mapping
        let deltaX = Float(translation.width) * 0.0022
        let deltaZ = Float(translation.height) * 0.0022
        
        let newX = startPos.x + (deltaX - deltaZ) * 0.7071
        let newZ = startPos.z + (deltaX + deltaZ) * 0.7071
        
        // Clamping to room boundaries (prevent passing through walls / leaving room)
        let clampedX = min(max(newX, Self.minRoomX), Self.maxRoomX)
        let clampedZ = min(max(newZ, Self.minRoomZ), Self.maxRoomZ)
        
        // Dynamic resting surface height based on diorama zones
        let currentSurfaceY = Self.surfaceHeight(at: clampedX, z: clampedZ)
        
        // In-air lifted height (+4cm)
        target.position = [clampedX, currentSurfaceY + 0.04, clampedZ]
        
        // Subtle dynamic tilt based on drag motion
        let tiltAngle = min(max(deltaX * 0.04, -0.06), 0.06)
        target.orientation = dragOriginalRot * simd_quatf(angle: tiltAngle, axis: [0, 0, 1])
        
        // Cookie companion notices object movement
        coordinator?.cookie?.curiousLook(at: target.position)
    }
    
    func handleDragEnd(target: Entity, undoManager: UndoManager?) {
        guard let startTransform = self.dragStartTransform else { return }
        
        // Physical drop settling
        let restingY = Self.surfaceHeight(at: target.position.x, z: target.position.z)
        target.scale = dragOriginalScale
        target.orientation = dragOriginalRot
        
        // Smoothly settle down to resting surface
        target.position.y = restingY
        
        let newTransform = RoomPropTransform(
            propId: startTransform.propId,
            position: target.position,
            orientation: target.orientation,
            scale: target.scale
        )
        
        // Check if item is a thought
        if target.name.hasPrefix("thought_") {
            let idStr = String(target.name.dropFirst("thought_".count))
            if let uuid = UUID(uuidString: idStr) {
                let finalPos = target.position
                coordinator?.updateItemPosition(id: uuid, position: finalPos)
            }
        } else {
            // Movable diorama room prop:
            // Register Undo with native macOS UndoManager
            undoManager?.registerUndo(withTarget: coordinator!) { [weak coordinator] coord in
                coord?.applyPropTransform(startTransform, animated: true)
            }
            
            // Persist transform in SwiftData RoomState
            coordinator?.savePropTransform(newTransform)
        }
        
        self.draggingEntity = nil
        self.dragStartTransform = nil
    }
    
    // MARK: - Rotation & Nudging
    
    func rotateProp(id: String, angleDegrees: Float = 45.0, undoManager: UndoManager?) {
        guard let entity = coordinator?.findPropEntity(id: id),
              let prop = entity.components[InteractivePropComponent.self],
              prop.allowsRotation else { return }
        
        let oldTransform = RoomPropTransform(
            propId: id,
            position: entity.position,
            orientation: entity.orientation,
            scale: entity.scale
        )
        
        let rotDelta = simd_quatf(angle: angleDegrees * .pi / 180.0, axis: [0, 1, 0])
        entity.orientation = entity.orientation * rotDelta
        
        let newTransform = RoomPropTransform(
            propId: id,
            position: entity.position,
            orientation: entity.orientation,
            scale: entity.scale
        )
        
        undoManager?.registerUndo(withTarget: coordinator!) { [weak coordinator] coord in
            coord?.applyPropTransform(oldTransform, animated: true)
        }
        
        coordinator?.savePropTransform(newTransform)
    }
    
    func nudgeProp(id: String, deltaX: Float, deltaZ: Float, undoManager: UndoManager?) {
        guard let entity = coordinator?.findPropEntity(id: id),
              let prop = entity.components[InteractivePropComponent.self],
              prop.allowsDragging else { return }
        
        let oldTransform = RoomPropTransform(
            propId: id,
            position: entity.position,
            orientation: entity.orientation,
            scale: entity.scale
        )
        
        let targetX = min(max(entity.position.x + deltaX, Self.minRoomX), Self.maxRoomX)
        let targetZ = min(max(entity.position.z + deltaZ, Self.minRoomZ), Self.maxRoomZ)
        let restingY = Self.surfaceHeight(at: targetX, z: targetZ)
        
        entity.position = [targetX, restingY, targetZ]
        
        let newTransform = RoomPropTransform(
            propId: id,
            position: entity.position,
            orientation: entity.orientation,
            scale: entity.scale
        )
        
        undoManager?.registerUndo(withTarget: coordinator!) { [weak coordinator] coord in
            coord?.applyPropTransform(oldTransform, animated: true)
        }
        
        coordinator?.savePropTransform(newTransform)
    }
    
    func resetPropPosition(id: String, undoManager: UndoManager?) {
        guard let entity = coordinator?.findPropEntity(id: id),
              let prop = entity.components[InteractivePropComponent.self] else { return }
        
        let oldTransform = RoomPropTransform(
            propId: id,
            position: entity.position,
            orientation: entity.orientation,
            scale: entity.scale
        )
        
        prop.applyDefaultTransform(to: entity)
        
        let defaultTransform = RoomPropTransform(
            propId: id,
            position: prop.defaultPosition,
            orientation: prop.defaultOrientation,
            scale: prop.defaultScale,
            isCustomized: false
        )
        
        undoManager?.registerUndo(withTarget: coordinator!) { [weak coordinator] coord in
            coord?.applyPropTransform(oldTransform, animated: true)
        }
        
        coordinator?.resetPropTransform(id: id)
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
    
    func findInteractiveProp() -> (Entity, InteractivePropComponent)? {
        var cur: Entity? = self
        while let node = cur {
            if let comp = node.components[InteractivePropComponent.self] {
                return (node, comp)
            }
            cur = node.parent
        }
        return nil
    }
}

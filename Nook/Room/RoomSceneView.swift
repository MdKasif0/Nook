import SwiftUI
import SceneKit
import AppKit

/// SwiftUI wrapper around an `SCNView` hosting the Nook 3D miniature room.
///
/// Handles hover tracking, physical item dragging, click selection,
/// desk lamp toggling, Cookie petting, and bounded isometric camera control.
struct RoomSceneView: NSViewRepresentable {
    
    let controller: RoomSceneController
    let onSelectItem: ((UUID?) -> Void)?
    let onItemMoved: ((UUID, RoomPosition) -> Void)?
    let onOpenItem: ((UUID) -> Void)?
    let onToggleLamp: (() -> Void)?
    let onPetCookie: (() -> Void)?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func makeNSView(context: Context) -> NookSCNView {
        let view = NookSCNView(controller: controller)
        view.scene = controller.scene
        view.backgroundColor = NSColor(red: 0.988, green: 0.98, blue: 0.965, alpha: 1.0)
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = false
        view.rendersContinuously = true
        view.onItemMoved = onItemMoved
        view.onOpenItem = onOpenItem
        view.delegate = context.coordinator
        
        context.coordinator.parent = self
        context.coordinator.scnView = view
        
        return view
    }
    
    func updateNSView(_ nsView: NookSCNView, context: Context) {
        context.coordinator.parent = self
        nsView.controller = controller
        nsView.onItemMoved = onItemMoved
        nsView.onOpenItem = onOpenItem
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        var parent: RoomSceneView
        weak var scnView: NookSCNView?
        
        init(_ parent: RoomSceneView) {
            self.parent = parent
        }
    }
}

// MARK: - Custom SCNView for Native macOS Gestures, Dragging & Hover

final class NookSCNView: SCNView {
    
    var controller: RoomSceneController
    var onItemMoved: ((UUID, RoomPosition) -> Void)?
    var onOpenItem: ((UUID) -> Void)?
    
    private var trackingAreaRef: NSTrackingArea?
    
    // Dragging item state
    private var draggedItemNode: RoomItemNode?
    private var dragStartMousePoint: CGPoint = .zero
    private var isDraggingItem: Bool = false
    
    // Camera gesture state
    private var lastCameraMousePoint: CGPoint = .zero
    private var isDraggingCamera: Bool = false
    
    // Initial camera angles
    private var cameraBaseY: CGFloat = 5.0
    private var currentOrbitAngle: CGFloat = 0.0 // Horizontal orbit offset
    private var currentPitchAngle: CGFloat = 0.0 // Vertical pitch offset
    
    init(controller: RoomSceneController) {
        self.controller = controller
        super.init(frame: .zero, options: [
            SCNView.Option.preferredRenderingAPI.rawValue: NSNumber(value: SCNRenderingAPI.metal.rawValue)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tracking Area for Hover
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let existing = trackingAreaRef {
            removeTrackingArea(existing)
        }
        
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .mouseEnteredAndExited,
            .activeInKeyWindow,
            .inVisibleRect
        ]
        
        let newArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(newArea)
        self.trackingAreaRef = newArea
    }
    
    // MARK: - Mouse Hover Hit-Testing
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        let hits = hitTest(location, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        
        var foundItem: UUID?
        var foundInteractive = false
        
        for hit in hits {
            var current: SCNNode? = hit.node
            while let node = current {
                if let name = node.name {
                    if name.hasPrefix("item_"), let uuid = UUID(uuidString: String(name.dropFirst(5))) {
                        foundItem = uuid
                        foundInteractive = true
                        break
                    } else if name == "desk_lamp" || name == "cookie_character" {
                        foundInteractive = true
                        break
                    }
                }
                current = node.parent
            }
            if foundInteractive { break }
        }
        
        if foundInteractive {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.arrow.set()
        }
        
        if controller.hoveredItemID != foundItem {
            controller.hoveredItemID = foundItem
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
        controller.hoveredItemID = nil
    }
    
    // MARK: - Mouse Down
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        let hits = hitTest(location, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        
        var hitNode: RoomItemNode?
        for hit in hits {
            var current: SCNNode? = hit.node
            while let node = current {
                if let itemNode = node as? RoomItemNode {
                    hitNode = itemNode
                    break
                }
                current = node.parent
            }
            if hitNode != nil { break }
        }
        
        if let itemNode = hitNode {
            // Initiating click on an item (may become drag if moved)
            self.draggedItemNode = itemNode
            self.dragStartMousePoint = location
            self.isDraggingItem = false
            self.isDraggingCamera = false
        } else {
            // Initiating camera drag or background click
            self.draggedItemNode = nil
            self.lastCameraMousePoint = location
            self.isDraggingItem = false
            self.isDraggingCamera = false
        }
    }
    
    // MARK: - Mouse Dragged (Physical Item Drag or Camera Orbit)
    
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        if let node = draggedItemNode {
            // Check distance threshold to distinguish click from drag
            let dist = hypot(point.x - dragStartMousePoint.x, point.y - dragStartMousePoint.y)
            if dist > 3.0 {
                if !isDraggingItem {
                    isDraggingItem = true
                    node.isBeingDragged = true
                }
                
                // Ray-plane intersection with horizontal desk plane (Y = deskSurfaceY)
                let near = unprojectPoint(SCNVector3(point.x, point.y, 0))
                let far = unprojectPoint(SCNVector3(point.x, point.y, 1))
                let dy = far.y - near.y
                
                if abs(dy) > 0.0001 {
                    let t = (RoomDioramaBuilder.deskSurfaceY - near.y) / dy
                    let worldX = near.x + t * (far.x - near.x)
                    let worldZ = near.z + t * (far.z - near.z)
                    
                    let deskX = RoomDioramaBuilder.deskPosition.x
                    let deskZ = RoomDioramaBuilder.deskPosition.z
                    let halfW = RoomSceneController.deskWidthSpan * 0.48
                    let halfD = RoomSceneController.deskDepthSpan * 0.48
                    
                    let clampedX = max(deskX - halfW, min(deskX + halfW, worldX))
                    let clampedZ = max(deskZ - halfD, min(deskZ + halfD, worldZ))
                    
                    node.position.x = clampedX
                    node.position.z = clampedZ
                }
            }
        } else {
            // Camera Orbit Dragging
            let deltaX = point.x - lastCameraMousePoint.x
            let deltaY = point.y - lastCameraMousePoint.y
            lastCameraMousePoint = point
            
            if abs(deltaX) > 1.5 || abs(deltaY) > 1.5 {
                isDraggingCamera = true
            }
            
            let sensitivity: CGFloat = 0.005
            currentOrbitAngle = max(-0.35, min(0.35, currentOrbitAngle - deltaX * sensitivity))
            currentPitchAngle = max(-0.25, min(0.25, currentPitchAngle + deltaY * sensitivity))
            
            updateCameraPosition()
        }
    }
    
    // MARK: - Mouse Up
    
    override func mouseUp(with event: NSEvent) {
        if isDraggingItem, let node = draggedItemNode {
            // Completed physical drag of item
            node.isBeingDragged = false
            let newPos = controller.roomPosition(from: node.position)
            
            // Persist the new position through SwiftData
            onItemMoved?(node.itemID, newPos)
            
            // Keep selected
            controller.selectedItemID = node.itemID
            
            self.draggedItemNode = nil
            self.isDraggingItem = false
            return
        }
        
        if let node = draggedItemNode {
            // User clicked the item without dragging
            controller.selectedItemID = (controller.selectedItemID == node.itemID) ? nil : node.itemID
            self.draggedItemNode = nil
            return
        }
        
        if isDraggingCamera {
            // Finished camera drag
            self.isDraggingCamera = false
            return
        }
        
        // Handle background or fixture clicks (Lamp, Cookie)
        let location = convert(event.locationInWindow, from: nil)
        let hits = hitTest(location, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        
        var hitHandled = false
        for hit in hits {
            var current: SCNNode? = hit.node
            while let node = current {
                if let name = node.name {
                    if name == "desk_lamp" {
                        controller.toggleDeskLamp()
                        hitHandled = true
                        break
                    } else if name == "cookie_character" {
                        controller.petCookie()
                        hitHandled = true
                        break
                    }
                }
                current = node.parent
            }
            if hitHandled { break }
        }
        
        if !hitHandled {
            // Clicked empty background
            controller.selectedItemID = nil
        }
    }
    
    // MARK: - Scroll Wheel Zoom (Dolly)
    
    override func scrollWheel(with event: NSEvent) {
        guard let cameraNode = scene?.rootNode.childNode(withName: "main_room_camera", recursively: true) else { return }
        
        let zoomDelta = event.deltaY * 0.08
        let currentDist = sqrt(
            cameraNode.position.x * cameraNode.position.x +
            cameraNode.position.y * cameraNode.position.y +
            cameraNode.position.z * cameraNode.position.z
        )
        
        let newDist = max(6.5, min(12.5, currentDist - zoomDelta))
        let factor = newDist / currentDist
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        cameraNode.position = SCNVector3(
            cameraNode.position.x * factor,
            cameraNode.position.y * factor,
            cameraNode.position.z * factor
        )
        SCNTransaction.commit()
    }
    
    private func updateCameraPosition() {
        guard let cameraNode = scene?.rootNode.childNode(withName: "main_room_camera", recursively: true) else { return }
        
        let radius: CGFloat = 8.5
        let baseAngle: CGFloat = .pi / 4 // 45 deg
        let angle = baseAngle + currentOrbitAngle
        let y = cameraBaseY + currentPitchAngle * 2.5
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        cameraNode.position = SCNVector3(
            cos(angle) * radius,
            y,
            sin(angle) * radius
        )
        SCNTransaction.commit()
    }
}

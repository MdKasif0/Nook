import SwiftUI
import SceneKit
import AppKit

/// SwiftUI wrapper around an `SCNView` hosting the Nook 3D miniature room.
///
/// Handles hover tracking, hit-testing for physical items, desk lamp clicks,
/// Cookie petting, and gentle isometric camera control.
struct RoomSceneView: NSViewRepresentable {
    
    let controller: RoomSceneController
    let onSelectItem: ((UUID?) -> Void)?
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
        view.delegate = context.coordinator
        
        context.coordinator.parent = self
        context.coordinator.scnView = view
        
        return view
    }
    
    func updateNSView(_ nsView: NookSCNView, context: Context) {
        context.coordinator.parent = self
        nsView.controller = controller
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

// MARK: - Custom SCNView for Native macOS Gestures & Hover

final class NookSCNView: SCNView {
    
    var controller: RoomSceneController
    private var trackingAreaRef: NSTrackingArea?
    
    // Camera gesture state
    private var lastMousePoint: CGPoint = .zero
    private var isDraggingCamera: Bool = false
    
    // Initial camera angles
    private var cameraBaseX: CGFloat = 5.2
    private var cameraBaseY: CGFloat = 5.0
    private var cameraBaseZ: CGFloat = 5.8
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
    
    // MARK: - Mouse Click Handling
    
    override func mouseDown(with event: NSEvent) {
        lastMousePoint = convert(event.locationInWindow, from: nil)
        isDraggingCamera = false
    }
    
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let deltaX = point.x - lastMousePoint.x
        let deltaY = point.y - lastMousePoint.y
        lastMousePoint = point
        
        if abs(deltaX) > 1.5 || abs(deltaY) > 1.5 {
            isDraggingCamera = true
        }
        
        // Gentle, bounded orbit camera
        let sensitivity: CGFloat = 0.005
        currentOrbitAngle = max(-0.35, min(0.35, currentOrbitAngle - deltaX * sensitivity))
        currentPitchAngle = max(-0.25, min(0.25, currentPitchAngle + deltaY * sensitivity))
        
        updateCameraPosition()
    }
    
    override func mouseUp(with event: NSEvent) {
        // Only trigger click selection if the user wasn't dragging the camera
        guard !isDraggingCamera else {
            isDraggingCamera = false
            return
        }
        
        let location = convert(event.locationInWindow, from: nil)
        let hits = hitTest(location, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        
        var hitHandled = false
        
        for hit in hits {
            var current: SCNNode? = hit.node
            while let node = current {
                if let name = node.name {
                    if name.hasPrefix("item_"), let uuid = UUID(uuidString: String(name.dropFirst(5))) {
                        controller.selectedItemID = (controller.selectedItemID == uuid) ? nil : uuid
                        hitHandled = true
                        break
                    } else if name == "desk_lamp" {
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
            // Deselect item when clicking on background or empty floor
            controller.selectedItemID = nil
        }
    }
    
    // MARK: - Scroll Wheel Zoom (Dolly)
    
    override func scrollWheel(with event: NSEvent) {
        guard let cameraNode = scene?.rootNode.childNode(withName: "main_room_camera", recursively: true) else { return }
        
        // Subtle dolly zoom with boundaries
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

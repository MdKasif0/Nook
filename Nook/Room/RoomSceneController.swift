import SceneKit
import SwiftUI
import SwiftData

/// Coordinates the 3D scene state, item node synchronization,
/// lighting adjustments, camera positioning, and interactions.
@MainActor
@Observable
final class RoomSceneController {
    
    let scene = SCNScene()
    
    private(set) var itemNodes: [UUID: RoomItemNode] = [:]
    private var sunLight: SCNLight?
    private var ambientLight: SCNLight?
    private var lampLight: SCNLight?
    private var outdoorSkyNode: SCNNode?
    
    var timeOfDay: RoomTimeOfDay = .morning {
        didSet {
            applyTimeOfDay(timeOfDay)
        }
    }
    
    var isDeskLampOn: Bool = false {
        didSet {
            updateLampLighting()
        }
    }
    
    var selectedItemID: UUID? {
        didSet {
            updateItemSelection()
        }
    }
    
    var hoveredItemID: UUID? {
        didSet {
            updateItemHover()
        }
    }
    
    var hoveredNodeName: String?
    
    // Cookie State-Driven Behavior Engine
    let cookieController = CookieBehaviorController()
    
    init() {
        setupScene()
    }
    
    // MARK: - Scene Initialization
    
    private func setupScene() {
        // Build miniature room diorama
        let lights = RoomDioramaBuilder.buildDiorama(in: scene, environment: timeOfDay)
        self.lampLight = lights.lampLight
        self.sunLight = lights.sunLight
        self.ambientLight = lights.ambientLight
        self.outdoorSkyNode = lights.outdoorSkyNode
        
        self.isDeskLampOn = timeOfDay.isDeskLampDefaultOn
        
        // Bind Cookie character node to behavior controller
        if let cat = scene.rootNode.childNode(withName: "cookie_character", recursively: true) as? CookieNode {
            cookieController.bind(node: cat)
        }
    }
    
    // MARK: - Dimensions for Desk Surface Item Placement
    
    static let deskWidthSpan: CGFloat = 1.6
    static let deskDepthSpan: CGFloat = 0.85
    
    // MARK: - Item Synchronization
    
    /// Syncs SwiftData items with 3D nodes in the room.
    func syncItems(_ items: [NookItem]) {
        let currentItemIDs = Set(items.map { $0.id })
        
        // Remove nodes for deleted/archived items
        for (id, node) in itemNodes where !currentItemIDs.contains(id) {
            node.removeFromParentNode()
            itemNodes.removeValue(forKey: id)
        }
        
        // Add or update items
        for item in items {
            if let existingNode = itemNodes[item.id] {
                // Update object type if edited
                if existingNode.objectType != item.objectType {
                    existingNode.updateObjectType(item.objectType)
                }
                
                // Update position if needed (when not currently being dragged)
                if !existingNode.isBeingDragged {
                    let targetPos = worldPosition(for: item.roomPosition)
                    if abs(existingNode.position.x - targetPos.x) > 0.01 || abs(existingNode.position.z - targetPos.z) > 0.01 {
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 0.35
                        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                        existingNode.position = targetPos
                        SCNTransaction.commit()
                    }
                }
            } else {
                // Create new 3D item node on the desk
                let pos = worldPosition(for: item.roomPosition)
                let node = RoomItemNode(item: item, position: pos, rotationY: CGFloat(item.rotation * .pi / 180.0))
                scene.rootNode.addChildNode(node)
                itemNodes[item.id] = node
                
                // Spawn animation
                node.scale = SCNVector3(0.01, 0.01, 0.01)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.35
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                node.scale = SCNVector3(1.0, 1.0, 1.0)
                SCNTransaction.commit()
            }
        }
    }
    
    /// Converts a normalized RoomPosition (0...1) to 3D world coordinates on the desk.
    func worldPosition(for roomPos: RoomPosition) -> SCNVector3 {
        let deskX = RoomDioramaBuilder.deskPosition.x
        let deskZ = RoomDioramaBuilder.deskPosition.z
        let surfaceY = RoomDioramaBuilder.deskSurfaceY
        
        let offsetX = (CGFloat(roomPos.x) - 0.5) * Self.deskWidthSpan
        let offsetZ = (CGFloat(roomPos.y) - 0.5) * Self.deskDepthSpan
        
        return SCNVector3(
            deskX + offsetX,
            surfaceY,
            deskZ + offsetZ
        )
    }
    
    /// Converts 3D world coordinates on the desk to a normalized RoomPosition (0...1).
    func roomPosition(from worldPos: SCNVector3) -> RoomPosition {
        let deskX = RoomDioramaBuilder.deskPosition.x
        let deskZ = RoomDioramaBuilder.deskPosition.z
        
        let normX = Double((worldPos.x - deskX) / Self.deskWidthSpan + 0.5)
        let normY = Double((worldPos.z - deskZ) / Self.deskDepthSpan + 0.5)
        
        return RoomPosition(
            x: min(0.95, max(0.05, normX)),
            y: min(0.95, max(0.05, normY)),
            z: 0.5
        )
    }
    
    /// Smoothly animates an item to a new room position.
    func moveItem(_ id: UUID, to position: RoomPosition) {
        guard let node = itemNodes[id] else { return }
        let target = worldPosition(for: position)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.40
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        node.position = target
        SCNTransaction.commit()
    }
    
    // MARK: - Time of Day & Lighting
    
    func setTimeOfDay(_ newTime: RoomTimeOfDay) {
        withAnimation(NookDesign.Animation.gentle) {
            self.timeOfDay = newTime
        }
    }
    
    private func applyTimeOfDay(_ tod: RoomTimeOfDay) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.8
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        sunLight?.color = tod.sunlightColor
        sunLight?.intensity = tod.sunlightIntensity
        ambientLight?.color = tod.ambientColor
        ambientLight?.intensity = tod.ambientIntensity
        
        outdoorSkyNode?.geometry?.firstMaterial?.diffuse.contents = tod.skyTopColor
        
        // Auto-turn on desk lamp during Golden Hour and Night
        self.isDeskLampOn = tod.isDeskLampDefaultOn
        
        SCNTransaction.commit()
    }
    
    func toggleDeskLamp() {
        isDeskLampOn.toggle()
    }
    
    private func updateLampLighting() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        lampLight?.intensity = isDeskLampOn ? 950 : 0
        SCNTransaction.commit()
    }
    
    // MARK: - Selection & Hover
    
    private func updateItemSelection() {
        for (id, node) in itemNodes {
            node.isItemSelected = (id == selectedItemID)
        }
    }
    
    private func updateItemHover() {
        for (id, node) in itemNodes {
            node.isHovered = (id == hoveredItemID)
        }
    }
    
    // MARK: - Cookie Petting & Interaction
    
    func petCookie() {
        RoomEventBus.shared.publish(.cookiePetted)
    }
    
    // MARK: - Object Focus & Camera Framing
    
    /// Focuses an object in the room: selects it, levitates/highlights it,
    /// moves the camera smoothly toward it, and prompts Cookie to look toward it.
    func focusItem(id: UUID) {
        selectedItemID = id
        
        guard let node = itemNodes[id] else { return }
        
        // Frame camera toward the item on the desk
        guard let cameraNode = scene.rootNode.childNode(withName: "main_room_camera", recursively: true) else { return }
        
        let targetX = node.position.x * 0.35 + 4.9
        let targetY: CGFloat = 4.25
        let targetZ = node.position.z * 0.35 + 5.3
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = PreferencesManager.shared.reduceMotion ? 0.0 : 0.65
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = SCNVector3(targetX, targetY, targetZ)
        SCNTransaction.commit()
    }
    
    /// Resets camera framing back to natural room overview.
    func resetCameraFraming() {
        guard let cameraNode = scene.rootNode.childNode(withName: "main_room_camera", recursively: true) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = PreferencesManager.shared.reduceMotion ? 0.0 : 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        cameraNode.position = SCNVector3(6.0, 5.0, 6.0)
        SCNTransaction.commit()
    }
}

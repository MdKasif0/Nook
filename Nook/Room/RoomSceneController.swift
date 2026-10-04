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
    
    // Cookie interaction feedback state
    var cookieMessage: String?
    var isPettingCookie: Bool = false
    
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
    }
    
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
        for (index, item) in items.enumerated() {
            if let existingNode = itemNodes[item.id] {
                // Node already exists, update position if needed
                let targetPos = positionForItem(item, atIndex: index, totalCount: items.count)
                if existingNode.position.x != targetPos.x || existingNode.position.z != targetPos.z {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.3
                    existingNode.position = targetPos
                    SCNTransaction.commit()
                }
            } else {
                // Create new 3D item node on the desk
                let pos = positionForItem(item, atIndex: index, totalCount: items.count)
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
    
    /// Computes the 3D coordinates for an item on the wooden desk surface.
    private func positionForItem(_ item: NookItem, atIndex index: Int, totalCount: Int) -> SCNVector3 {
        let deskX = RoomDioramaBuilder.deskPosition.x
        let deskZ = RoomDioramaBuilder.deskPosition.z
        let surfaceY = RoomDioramaBuilder.deskSurfaceY
        
        // If user customized normalized position, map to desk surface bounds
        // Desk blotter & writing area: X in [-0.75, 0.45], Z in [-0.35, 0.35]
        let widthSpan: CGFloat = 1.2
        let depthSpan: CGFloat = 0.65
        
        let offsetX = (CGFloat(item.positionX) - 0.5) * widthSpan
        let offsetZ = (CGFloat(item.positionY) - 0.5) * depthSpan
        
        return SCNVector3(
            deskX + offsetX,
            surfaceY,
            deskZ + offsetZ
        )
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
        guard let cookieNode = scene.rootNode.childNode(withName: "cookie_character", recursively: true) else { return }
        
        isPettingCookie = true
        
        // Happy bounce & purr wiggle
        let purrWiggle = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.04, z: 0, duration: 0.18),
            SCNAction.rotateBy(x: 0, y: 0.15, z: 0, duration: 0.12),
            SCNAction.rotateBy(x: 0, y: -0.30, z: 0, duration: 0.12),
            SCNAction.rotateBy(x: 0, y: 0.15, z: 0, duration: 0.12),
            SCNAction.moveBy(x: 0, y: -0.04, z: 0, duration: 0.18)
        ])
        
        cookieNode.runAction(purrWiggle) {
            Task { @MainActor [weak self] in
                self?.isPettingCookie = false
            }
        }
        
        let messages = [
            "Cookie is purring softly...",
            "Cookie nudged your hand warmly.",
            "Cookie curls tighter into a cozy ball.",
            "Cookie appreciates the gentle company."
        ]
        cookieMessage = messages.randomElement()
    }
}

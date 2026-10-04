import SceneKit
import SwiftUI
import QuartzCore

/// 3D SceneKit representation of a `NookItem` inside the miniature room.
///
/// Implements Nook's core philosophy: "Thoughts become physical objects."
/// Renders thoughts as tactile objects: Smooth Pebble (default), Paper Note,
/// Sticky Note, Small Card, Polaroid, and Bookmark.
final class RoomItemNode: SCNNode {
    
    let itemID: UUID
    private(set) var objectType: NookObjectType
    var itemTitle: String
    
    private var visualNode: SCNNode!
    private var shadowPlateNode: SCNNode?
    
    var isHovered: Bool = false {
        didSet {
            guard oldValue != isHovered else { return }
            updateHoverState()
        }
    }
    
    var isItemSelected: Bool = false {
        didSet {
            guard oldValue != isItemSelected else { return }
            updateSelectedState()
        }
    }
    
    var isBeingDragged: Bool = false {
        didSet {
            guard oldValue != isBeingDragged else { return }
            updateDragState()
        }
    }
    
    init(item: NookItem, position: SCNVector3, rotationY: CGFloat = 0) {
        self.itemID = item.id
        self.objectType = item.objectType
        self.itemTitle = item.title
        
        super.init()
        
        self.name = "item_\(item.id.uuidString)"
        self.position = position
        self.eulerAngles.y = rotationY
        
        setupGeometry()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Rebuilds the visual node if the user edits the object type.
    func updateObjectType(_ newType: NookObjectType) {
        guard newType != self.objectType else { return }
        self.objectType = newType
        
        visualNode?.removeFromParentNode()
        shadowPlateNode?.removeFromParentNode()
        
        setupGeometry()
        updateSelectedState()
    }
    
    // MARK: - Geometry Setup
    
    private func setupGeometry() {
        visualNode = SCNNode()
        visualNode.name = "visual_root"
        
        switch objectType {
        case .pebble:
            buildPebbleGeometry(in: visualNode)
        case .paperNote:
            buildPaperNoteGeometry(in: visualNode)
        case .stickyNote:
            buildStickyNoteGeometry(in: visualNode)
        case .card:
            buildSmallCardGeometry(in: visualNode)
        case .polaroid:
            buildPolaroidGeometry(in: visualNode)
        case .bookmark:
            buildBookmarkGeometry(in: visualNode)
        }
        
        addChildNode(visualNode)
        
        // Soft contact shadow plate underneath
        let plate = SCNPlane(width: 0.30, height: 0.30)
        plate.cornerRadius = 0.12
        let plateMat = SCNMaterial()
        plateMat.diffuse.contents = NSColor(white: 0.08, alpha: 0.22)
        plateMat.lightingModel = .constant
        plateMat.writesToDepthBuffer = false
        plate.materials = [plateMat]
        
        let plateNode = SCNNode(geometry: plate)
        plateNode.eulerAngles.x = -.pi / 2
        plateNode.position = SCNVector3(0, 0.002, 0)
        plateNode.name = "shadow_plate"
        self.shadowPlateNode = plateNode
        addChildNode(plateNode)
    }
    
    // MARK: - 1. PEBBLE (Default Tactile River Stone)
    
    /// Constructs a smooth, organic river stone with natural variation.
    private func buildPebbleGeometry(in parent: SCNNode) {
        let hash = abs(itemID.hashValue)
        
        // Deterministic organic variation between pebbles
        let scaleX: CGFloat = 1.15 + CGFloat(hash % 10) * 0.025
        let scaleY: CGFloat = 0.38 + CGFloat((hash / 10) % 6) * 0.015
        let scaleZ: CGFloat = 1.35 + CGFloat((hash / 100) % 8) * 0.02
        
        // Natural muted warm river stone colors
        let stoneColors: [NSColor] = [
            NSColor(red: 0.54, green: 0.51, blue: 0.46, alpha: 1.0), // Warm River Basalt
            NSColor(red: 0.59, green: 0.56, blue: 0.50, alpha: 1.0), // Soft River Flint
            NSColor(red: 0.64, green: 0.58, blue: 0.51, alpha: 1.0), // Sand Taupe
            NSColor(red: 0.48, green: 0.45, blue: 0.40, alpha: 1.0)  // Deep River Slate
        ]
        let baseColor = stoneColors[hash % stoneColors.count]
        
        // Main pebble body (flattened organic river stone)
        let stone = SCNSphere(radius: 0.085)
        let stoneMat = SCNMaterial()
        stoneMat.diffuse.contents = baseColor
        stoneMat.roughness.contents = 0.88 // Very matte, tactile river stone
        stoneMat.specular.contents = NSColor(white: 0.08, alpha: 1.0)
        stoneMat.metalness.contents = 0.0
        stone.materials = [stoneMat]
        
        let stoneNode = SCNNode(geometry: stone)
        stoneNode.scale = SCNVector3(scaleX, scaleY, scaleZ)
        stoneNode.position = SCNVector3(0, 0.030, 0)
        stoneNode.eulerAngles.y = CGFloat(hash % 30) * 0.02
        parent.addChildNode(stoneNode)
        
        // Secondary subtle facet for organic silhouette
        let facet = SCNSphere(radius: 0.065)
        let facetMat = SCNMaterial()
        facetMat.diffuse.contents = baseColor.blended(withFraction: 0.08, of: .white) ?? baseColor
        facetMat.roughness.contents = 0.90
        facet.materials = [facetMat]
        
        let facetNode = SCNNode(geometry: facet)
        facetNode.scale = SCNVector3(scaleX * 0.9, scaleY * 0.85, scaleZ * 0.85)
        facetNode.position = SCNVector3(0.015, 0.034, 0.01)
        parent.addChildNode(facetNode)
    }
    
    // MARK: - 2. Paper Note
    
    /// Constructs a folded warm cream linen parchment with subtle crease.
    private func buildPaperNoteGeometry(in parent: SCNNode) {
        let paper = SCNBox(width: 0.24, height: 0.012, length: 0.28, chamferRadius: 0.005)
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.965, green: 0.945, blue: 0.91, alpha: 1.0) // Linen parchment
        mat.roughness.contents = 0.92
        paper.materials = [mat]
        let node = SCNNode(geometry: paper)
        node.position = SCNVector3(0, 0.006, 0)
        parent.addChildNode(node)
        
        // Folded top-right corner crease
        let fold = SCNBox(width: 0.06, height: 0.015, length: 0.06, chamferRadius: 0.002)
        let foldMat = SCNMaterial()
        foldMat.diffuse.contents = NSColor(red: 0.91, green: 0.89, blue: 0.84, alpha: 1.0)
        fold.materials = [foldMat]
        let foldNode = SCNNode(geometry: fold)
        foldNode.position = SCNVector3(0.09, 0.012, -0.11)
        foldNode.eulerAngles.y = .pi / 4
        parent.addChildNode(foldNode)
        
        // Small wooden pencil resting beside note
        let pencil = SCNCylinder(radius: 0.007, height: 0.20)
        let pMat = SCNMaterial()
        pMat.diffuse.contents = NSColor(red: 0.72, green: 0.54, blue: 0.38, alpha: 1.0)
        pencil.materials = [pMat]
        let pencilNode = SCNNode(geometry: pencil)
        pencilNode.eulerAngles.z = .pi / 2
        pencilNode.eulerAngles.y = 0.25
        pencilNode.position = SCNVector3(0.02, 0.018, 0.02)
        parent.addChildNode(pencilNode)
    }
    
    // MARK: - 3. Sticky Note
    
    /// Constructs a buttery pastel sticky note with curled corner.
    private func buildStickyNoteGeometry(in parent: SCNNode) {
        let note = SCNBox(width: 0.24, height: 0.012, length: 0.24, chamferRadius: 0.008)
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.98, green: 0.95, blue: 0.76, alpha: 1.0) // Warm butter yellow
        mat.roughness.contents = 0.85
        note.materials = [mat]
        let node = SCNNode(geometry: note)
        node.position = SCNVector3(0, 0.006, 0)
        parent.addChildNode(node)
        
        // Curled bottom edge
        let curl = SCNBox(width: 0.22, height: 0.016, length: 0.05, chamferRadius: 0.004)
        curl.materials = [mat]
        let curlNode = SCNNode(geometry: curl)
        curlNode.position = SCNVector3(0, 0.012, 0.10)
        curlNode.eulerAngles.x = 0.12
        parent.addChildNode(curlNode)
        
        // Miniature terracotta pin at top center
        let pin = SCNCylinder(radius: 0.018, height: 0.028)
        let pinMat = SCNMaterial()
        pinMat.diffuse.contents = NSColor(red: 0.78, green: 0.54, blue: 0.40, alpha: 1.0)
        pin.materials = [pinMat]
        let pinNode = SCNNode(geometry: pin)
        pinNode.position = SCNVector3(0, 0.020, -0.09)
        parent.addChildNode(pinNode)
    }
    
    // MARK: - 4. Small Card
    
    /// Constructs a thick watercolor cardstock token with debossed border.
    private func buildSmallCardGeometry(in parent: SCNNode) {
        let card = SCNBox(width: 0.26, height: 0.016, length: 0.17, chamferRadius: 0.006)
        let cardMat = SCNMaterial()
        cardMat.diffuse.contents = NSColor(red: 0.95, green: 0.93, blue: 0.89, alpha: 1.0) // Heavy cream cardstock
        cardMat.roughness.contents = 0.80
        card.materials = [cardMat]
        let cardNode = SCNNode(geometry: card)
        cardNode.position = SCNVector3(0, 0.008, 0)
        parent.addChildNode(cardNode)
        
        // Fine debossed inner frame
        let frame = SCNBox(width: 0.22, height: 0.018, length: 0.13, chamferRadius: 0.003)
        let frameMat = SCNMaterial()
        frameMat.diffuse.contents = NSColor(red: 0.88, green: 0.85, blue: 0.80, alpha: 1.0)
        frame.materials = [frameMat]
        let frameNode = SCNNode(geometry: frame)
        frameNode.position = SCNVector3(0, 0.009, 0)
        parent.addChildNode(frameNode)
    }
    
    // MARK: - 5. Polaroid
    
    /// Constructs a classic miniature square photo print with wide bottom margin.
    private func buildPolaroidGeometry(in parent: SCNNode) {
        // White photo border
        let border = SCNBox(width: 0.22, height: 0.014, length: 0.26, chamferRadius: 0.004)
        let borderMat = SCNMaterial()
        borderMat.diffuse.contents = NSColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0)
        borderMat.roughness.contents = 0.70
        border.materials = [borderMat]
        let borderNode = SCNNode(geometry: border)
        borderNode.position = SCNVector3(0, 0.007, 0)
        parent.addChildNode(borderNode)
        
        // Photo image area (offset towards top, leaving wide bottom label margin)
        let photo = SCNBox(width: 0.18, height: 0.016, length: 0.18, chamferRadius: 0.002)
        let photoMat = SCNMaterial()
        photoMat.diffuse.contents = NSColor(red: 0.74, green: 0.68, blue: 0.60, alpha: 1.0) // Vintage sepia
        photoMat.roughness.contents = 0.50
        photo.materials = [photoMat]
        let photoNode = SCNNode(geometry: photo)
        photoNode.position = SCNVector3(0, 0.009, -0.022)
        parent.addChildNode(photoNode)
    }
    
    // MARK: - 6. Bookmark
    
    /// Constructs a slender patterned woven bookmark with a delicate tassel cord.
    private func buildBookmarkGeometry(in parent: SCNNode) {
        let ribbon = SCNBox(width: 0.11, height: 0.010, length: 0.32, chamferRadius: 0.004)
        let ribbonMat = SCNMaterial()
        ribbonMat.diffuse.contents = NSColor(red: 0.55, green: 0.60, blue: 0.50, alpha: 1.0) // Muted sage woven fabric
        ribbonMat.roughness.contents = 0.90
        ribbon.materials = [ribbonMat]
        let ribbonNode = SCNNode(geometry: ribbon)
        ribbonNode.position = SCNVector3(0, 0.005, 0)
        parent.addChildNode(ribbonNode)
        
        // Tassel cord extending from top
        let cord = SCNCylinder(radius: 0.005, height: 0.08)
        let cordMat = SCNMaterial()
        cordMat.diffuse.contents = NSColor(red: 0.88, green: 0.82, blue: 0.72, alpha: 1.0)
        cord.materials = [cordMat]
        let cordNode = SCNNode(geometry: cord)
        cordNode.position = SCNVector3(0, 0.006, -0.19)
        cordNode.eulerAngles.x = .pi / 2
        parent.addChildNode(cordNode)
    }
    
    // MARK: - State & Animation Updates
    
    private func updateHoverState() {
        guard !isBeingDragged else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        if isHovered && !isItemSelected {
            visualNode.position.y = 0.035
            shadowPlateNode?.scale = SCNVector3(1.18, 1.18, 1.18)
        } else if !isItemSelected {
            visualNode.position.y = 0.0
            shadowPlateNode?.scale = SCNVector3(1.0, 1.0, 1.0)
        }
        
        SCNTransaction.commit()
    }
    
    private func updateSelectedState() {
        guard !isBeingDragged else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        if isItemSelected {
            visualNode.position.y = 0.075
            shadowPlateNode?.scale = SCNVector3(1.25, 1.25, 1.25)
            visualNode.runAction(
                SCNAction.repeatForever(
                    SCNAction.sequence([
                        SCNAction.moveBy(x: 0, y: 0.012, z: 0, duration: 1.3),
                        SCNAction.moveBy(x: 0, y: -0.012, z: 0, duration: 1.3)
                    ])
                ),
                forKey: "levitate"
            )
        } else {
            visualNode.removeAction(forKey: "levitate")
            visualNode.position.y = isHovered ? 0.035 : 0.0
            shadowPlateNode?.scale = isHovered ? SCNVector3(1.18, 1.18, 1.18) : SCNVector3(1.0, 1.0, 1.0)
        }
        
        SCNTransaction.commit()
    }
    
    private func updateDragState() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        if isBeingDragged {
            visualNode.removeAction(forKey: "levitate")
            visualNode.position.y = 0.09
            visualNode.scale = SCNVector3(1.12, 1.12, 1.12)
            shadowPlateNode?.scale = SCNVector3(1.4, 1.4, 1.4)
            shadowPlateNode?.opacity = 0.14
        } else {
            visualNode.position.y = isItemSelected ? 0.075 : 0.0
            visualNode.scale = SCNVector3(1.0, 1.0, 1.0)
            shadowPlateNode?.scale = SCNVector3(1.0, 1.0, 1.0)
            shadowPlateNode?.opacity = 0.22
            if isItemSelected {
                updateSelectedState()
            }
        }
        
        SCNTransaction.commit()
    }
}

import SceneKit
import SwiftUI

/// 3D SceneKit representation of a `NookItem` inside the miniature room.
///
/// Converts abstract thoughts, notes, and ideas into tactile,
/// physical objects resting on the desk, shelves, or floor.
final class RoomItemNode: SCNNode {
    
    let itemID: UUID
    let itemType: NookItemType
    let itemTitle: String
    
    private var visualNode: SCNNode!
    private var shadowPlateNode: SCNNode?
    private var basePosition: SCNVector3
    
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
    
    init(item: NookItem, position: SCNVector3, rotationY: CGFloat = 0) {
        self.itemID = item.id
        self.itemType = item.itemType
        self.itemTitle = item.title
        self.basePosition = position
        
        super.init()
        
        self.name = "item_\(item.id.uuidString)"
        self.position = position
        self.eulerAngles.y = rotationY
        
        setupGeometry()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Geometry Setup
    
    private func setupGeometry() {
        visualNode = SCNNode()
        
        switch itemType {
        case .thought:
            buildThoughtGeometry(in: visualNode)
        case .idea:
            buildIdeaGeometry(in: visualNode)
        case .note:
            buildNoteGeometry(in: visualNode)
        case .reminder:
            buildReminderGeometry(in: visualNode)
        case .quote:
            buildQuoteGeometry(in: visualNode)
        case .link:
            buildLinkGeometry(in: visualNode)
        case .photo:
            buildPhotoGeometry(in: visualNode)
        }
        
        addChildNode(visualNode)
        
        // Add subtle ground shadow contact plate
        let plate = SCNPlane(width: 0.28, height: 0.28)
        plate.cornerRadius = 0.08
        let plateMat = SCNMaterial()
        plateMat.diffuse.contents = NSColor(white: 0.1, alpha: 0.18)
        plateMat.lightingModel = .constant
        plateMat.writesToDepthBuffer = false
        plate.materials = [plateMat]
        
        let plateNode = SCNNode(geometry: plate)
        plateNode.eulerAngles.x = -.pi / 2
        plateNode.position = SCNVector3(0, 0.002, 0)
        self.shadowPlateNode = plateNode
        addChildNode(plateNode)
    }
    
    // MARK: - Specific Item Geometries
    
    /// Thought: A pastel sticky note with a curled top and cream lines.
    private func buildThoughtGeometry(in parent: SCNNode) {
        let note = SCNBox(width: 0.24, height: 0.015, length: 0.24, chamferRadius: 0.01)
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.98, green: 0.95, blue: 0.78, alpha: 1.0) // Soft buttery cream
        mat.roughness.contents = 0.85
        mat.specular.contents = NSColor(white: 0.1, alpha: 1.0)
        note.materials = [mat]
        
        let node = SCNNode(geometry: note)
        node.position = SCNVector3(0, 0.008, 0)
        parent.addChildNode(node)
        
        // Small miniature pin or paperclip at the corner
        let pin = SCNCylinder(radius: 0.018, height: 0.03)
        let pinMat = SCNMaterial()
        pinMat.diffuse.contents = NSColor(red: 0.78, green: 0.58, blue: 0.42, alpha: 1.0) // Terracotta pin
        pin.materials = [pinMat]
        let pinNode = SCNNode(geometry: pin)
        pinNode.position = SCNVector3(0.08, 0.02, -0.08)
        parent.addChildNode(pinNode)
    }
    
    /// Idea: A miniature warm brass Edison bulb with luminous filament.
    private func buildIdeaGeometry(in parent: SCNNode) {
        // Base socket
        let base = SCNCylinder(radius: 0.038, height: 0.04)
        let baseMat = SCNMaterial()
        baseMat.diffuse.contents = NSColor(red: 0.82, green: 0.70, blue: 0.45, alpha: 1.0) // Brushed brass
        baseMat.metalness.contents = 0.6
        baseMat.roughness.contents = 0.35
        base.materials = [baseMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.02, 0)
        parent.addChildNode(baseNode)
        
        // Glass bulb sphere
        let bulb = SCNSphere(radius: 0.065)
        let bulbMat = SCNMaterial()
        bulbMat.diffuse.contents = NSColor(red: 1.0, green: 0.94, blue: 0.80, alpha: 0.88)
        bulbMat.emission.contents = NSColor(red: 1.0, green: 0.86, blue: 0.50, alpha: 0.45)
        bulbMat.roughness.contents = 0.15
        bulb.materials = [bulbMat]
        let bulbNode = SCNNode(geometry: bulb)
        bulbNode.position = SCNVector3(0, 0.08, 0)
        parent.addChildNode(bulbNode)
        
        // Filament inner glow
        let filament = SCNCylinder(radius: 0.01, height: 0.04)
        let filMat = SCNMaterial()
        filMat.diffuse.contents = NSColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
        filMat.emission.contents = NSColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 0.9)
        filament.materials = [filMat]
        let filNode = SCNNode(geometry: filament)
        filNode.position = SCNVector3(0, 0.08, 0)
        parent.addChildNode(filNode)
    }
    
    /// Note: A folded textured parchment booklet or neat stack of papers.
    private func buildNoteGeometry(in parent: SCNNode) {
        let paper = SCNBox(width: 0.22, height: 0.03, length: 0.28, chamferRadius: 0.005)
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0) // Warm linen paper
        mat.roughness.contents = 0.9
        paper.materials = [mat]
        let node = SCNNode(geometry: paper)
        node.position = SCNVector3(0, 0.015, 0)
        parent.addChildNode(node)
        
        // Tiny pencil resting across the notebook
        let pencil = SCNCylinder(radius: 0.008, height: 0.22)
        let pMat = SCNMaterial()
        pMat.diffuse.contents = NSColor(red: 0.72, green: 0.55, blue: 0.38, alpha: 1.0) // Cedar wood pencil
        pencil.materials = [pMat]
        let pencilNode = SCNNode(geometry: pencil)
        pencilNode.eulerAngles.z = .pi / 2
        pencilNode.eulerAngles.y = 0.35
        pencilNode.position = SCNVector3(0, 0.038, 0)
        parent.addChildNode(pencilNode)
    }
    
    /// Reminder: A miniature vintage brass desk clock.
    private func buildReminderGeometry(in parent: SCNNode) {
        // Base
        let stand = SCNBox(width: 0.16, height: 0.02, length: 0.12, chamferRadius: 0.006)
        let standMat = SCNMaterial()
        standMat.diffuse.contents = NSColor(red: 0.48, green: 0.36, blue: 0.26, alpha: 1.0) // Dark walnut
        stand.materials = [standMat]
        let standNode = SCNNode(geometry: stand)
        standNode.position = SCNVector3(0, 0.01, 0)
        parent.addChildNode(standNode)
        
        // Clock face cylinder
        let clock = SCNCylinder(radius: 0.062, height: 0.035)
        let clockMat = SCNMaterial()
        clockMat.diffuse.contents = NSColor(red: 0.88, green: 0.78, blue: 0.52, alpha: 1.0) // Warm brass
        clockMat.metalness.contents = 0.55
        clock.materials = [clockMat]
        let clockNode = SCNNode(geometry: clock)
        clockNode.eulerAngles.x = .pi / 2.2
        clockNode.position = SCNVector3(0, 0.075, 0)
        parent.addChildNode(clockNode)
        
        // Small dial face
        let dial = SCNCylinder(radius: 0.048, height: 0.036)
        let dialMat = SCNMaterial()
        dialMat.diffuse.contents = NSColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        dial.materials = [dialMat]
        let dialNode = SCNNode(geometry: dial)
        dialNode.eulerAngles.x = .pi / 2.2
        dialNode.position = SCNVector3(0, 0.075, 0.005)
        parent.addChildNode(dialNode)
    }
    
    /// Quote: An open miniature hardcover book with delicate bookmark ribbon.
    private func buildQuoteGeometry(in parent: SCNNode) {
        // Left page
        let leftPage = SCNBox(width: 0.13, height: 0.02, length: 0.19, chamferRadius: 0.004)
        let pageMat = SCNMaterial()
        pageMat.diffuse.contents = NSColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1.0)
        leftPage.materials = [pageMat]
        let leftNode = SCNNode(geometry: leftPage)
        leftNode.position = SCNVector3(-0.065, 0.01, 0)
        leftNode.eulerAngles.z = 0.08
        parent.addChildNode(leftNode)
        
        // Right page
        let rightPage = SCNBox(width: 0.13, height: 0.02, length: 0.19, chamferRadius: 0.004)
        rightPage.materials = [pageMat]
        let rightNode = SCNNode(geometry: rightPage)
        rightNode.position = SCNVector3(0.065, 0.01, 0)
        rightNode.eulerAngles.z = -0.08
        parent.addChildNode(rightNode)
        
        // Sage fabric spine cover underneath
        let cover = SCNBox(width: 0.28, height: 0.008, length: 0.20, chamferRadius: 0.004)
        let coverMat = SCNMaterial()
        coverMat.diffuse.contents = NSColor(red: 0.52, green: 0.58, blue: 0.48, alpha: 1.0) // Muted sage cloth
        cover.materials = [coverMat]
        let coverNode = SCNNode(geometry: cover)
        coverNode.position = SCNVector3(0, 0.004, 0)
        parent.addChildNode(coverNode)
    }
    
    /// Link: A sealed miniature wax-stamp envelope or paper airplane.
    private func buildLinkGeometry(in parent: SCNNode) {
        let envelope = SCNBox(width: 0.26, height: 0.018, length: 0.18, chamferRadius: 0.008)
        let envMat = SCNMaterial()
        envMat.diffuse.contents = NSColor(red: 0.92, green: 0.88, blue: 0.82, alpha: 1.0) // Kraft paper
        envMat.roughness.contents = 0.8
        envelope.materials = [envMat]
        let envNode = SCNNode(geometry: envelope)
        envNode.position = SCNVector3(0, 0.01, 0)
        parent.addChildNode(envNode)
        
        // Red terracotta wax seal
        let seal = SCNCylinder(radius: 0.028, height: 0.01)
        let sealMat = SCNMaterial()
        sealMat.diffuse.contents = NSColor(red: 0.72, green: 0.32, blue: 0.24, alpha: 1.0) // Terracotta wax
        seal.materials = [sealMat]
        let sealNode = SCNNode(geometry: seal)
        sealNode.position = SCNVector3(0, 0.02, 0)
        parent.addChildNode(sealNode)
    }
    
    /// Photo: A tiny framed miniature photograph on a stand.
    private func buildPhotoGeometry(in parent: SCNNode) {
        // Frame
        let frame = SCNBox(width: 0.20, height: 0.24, length: 0.018, chamferRadius: 0.006)
        let frameMat = SCNMaterial()
        frameMat.diffuse.contents = NSColor(red: 0.62, green: 0.48, blue: 0.36, alpha: 1.0) // Warm oak frame
        frame.materials = [frameMat]
        let frameNode = SCNNode(geometry: frame)
        frameNode.position = SCNVector3(0, 0.12, 0)
        frameNode.eulerAngles.x = -0.18 // Leaning back slightly
        parent.addChildNode(frameNode)
        
        // Picture canvas
        let canvas = SCNPlane(width: 0.16, height: 0.20)
        let canvasMat = SCNMaterial()
        canvasMat.diffuse.contents = NSColor(red: 0.88, green: 0.84, blue: 0.78, alpha: 1.0)
        canvas.materials = [canvasMat]
        let canvasNode = SCNNode(geometry: canvas)
        canvasNode.position = SCNVector3(0, 0.12, 0.01)
        canvasNode.eulerAngles.x = -0.18
        parent.addChildNode(canvasNode)
    }
    
    // MARK: - State Updates
    
    private func updateHoverState() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        if isHovered && !isItemSelected {
            visualNode.position.y = 0.03
            shadowPlateNode?.scale = SCNVector3(1.15, 1.15, 1.15)
        } else if !isItemSelected {
            visualNode.position.y = 0.0
            shadowPlateNode?.scale = SCNVector3(1.0, 1.0, 1.0)
        }
        
        SCNTransaction.commit()
    }
    
    private func updateSelectedState() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        if isItemSelected {
            visualNode.position.y = 0.08
            shadowPlateNode?.scale = SCNVector3(1.3, 1.3, 1.3)
            visualNode.runAction(
                SCNAction.repeatForever(
                    SCNAction.sequence([
                        SCNAction.moveBy(x: 0, y: 0.015, z: 0, duration: 1.2),
                        SCNAction.moveBy(x: 0, y: -0.015, z: 0, duration: 1.2)
                    ])
                ),
                forKey: "levitate"
            )
        } else {
            visualNode.removeAction(forKey: "levitate")
            visualNode.position.y = isHovered ? 0.03 : 0.0
            shadowPlateNode?.scale = isHovered ? SCNVector3(1.15, 1.15, 1.15) : SCNVector3(1.0, 1.0, 1.0)
        }
        
        SCNTransaction.commit()
    }
}

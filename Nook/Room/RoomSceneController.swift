import SceneKit
import SwiftUI
import SwiftData
import AppKit

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
    private var sconceLight: SCNLight?
    private var outdoorSkyNode: SCNNode?
    private var dustParticles: SCNParticleSystem?
    
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
    
    var isWallSconceOn: Bool = false {
        didSet {
            updateSconceLighting()
        }
    }
    
    var isRecordSpinning: Bool = true {
        didSet {
            updateRecordSpinning()
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
    
    // Performance lifecycle notification observers
    nonisolated(unsafe) private var lifecycleObservers: [NSObjectProtocol] = []
    
    init() {
        setupScene()
        setupLifecycleObservers()
    }
    
    deinit {
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Scene Initialization
    
    private func setupScene() {
        let reduceMotion = PreferencesManager.shared.reduceMotion
        let lights = RoomDioramaBuilder.buildDiorama(
            in: scene,
            environment: timeOfDay,
            reduceMotion: reduceMotion
        )
        self.lampLight = lights.lampLight
        self.sconceLight = lights.sconceLight
        self.sunLight = lights.sunLight
        self.ambientLight = lights.ambientLight
        self.outdoorSkyNode = lights.outdoorSkyNode
        self.dustParticles = lights.dustParticles
        
        self.isDeskLampOn = timeOfDay.isDeskLampDefaultOn
        self.isWallSconceOn = timeOfDay.isDeskLampDefaultOn
        
        // Bind Cookie character node to behavior controller
        if let cat = scene.rootNode.childNode(withName: "cookie_character", recursively: true) as? CookieNode {
            cookieController.bind(node: cat)
        }
    }
    
    // MARK: - Dimensions for Desk Surface Item Placement
    
    static let deskWidthSpan: CGFloat = 1.65
    static let deskDepthSpan: CGFloat = 0.82
    
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
                if !PreferencesManager.shared.reduceMotion {
                    node.scale = SCNVector3(0.01, 0.01, 0.01)
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.35
                    SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                    node.scale = SCNVector3(1.0, 1.0, 1.0)
                    SCNTransaction.commit()
                }
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
        SCNTransaction.animationDuration = PreferencesManager.shared.reduceMotion ? 0.0 : 0.40
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
        SCNTransaction.animationDuration = PreferencesManager.shared.reduceMotion ? 0.0 : 0.8
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        sunLight?.color = tod.sunlightColor
        sunLight?.intensity = tod.sunlightIntensity
        ambientLight?.color = tod.ambientColor
        ambientLight?.intensity = tod.ambientIntensity
        
        outdoorSkyNode?.geometry?.firstMaterial?.diffuse.contents = tod.skyTopColor
        
        // Auto-turn on lamps during Golden Hour and Night
        self.isDeskLampOn = tod.isDeskLampDefaultOn
        self.isWallSconceOn = tod.isDeskLampDefaultOn
        
        SCNTransaction.commit()
    }
    
    func toggleDeskLamp() {
        isDeskLampOn.toggle()
        AudioManager.shared.playObjectPlaced()
    }
    
    private func updateLampLighting() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        lampLight?.intensity = isDeskLampOn ? 950 : 0
        SCNTransaction.commit()
    }
    
    func toggleWallSconce() {
        isWallSconceOn.toggle()
        AudioManager.shared.playObjectPlaced()
    }
    
    private func updateSconceLighting() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        sconceLight?.intensity = isWallSconceOn ? 750 : 0
        SCNTransaction.commit()
    }
    
    func toggleRecordPlayer() {
        isRecordSpinning.toggle()
        AudioManager.shared.playObjectSelected()
    }
    
    private func updateRecordSpinning() {
        guard let disc = scene.rootNode.childNode(withName: "vinyl_record_disc", recursively: true) else { return }
        if isRecordSpinning {
            let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.2)
            disc.runAction(SCNAction.repeatForever(spin), forKey: "vinyl_spin")
        } else {
            disc.removeAction(forKey: "vinyl_spin")
        }
    }
    
    /// Cycles display background on the computer monitor.
    func cycleMonitorWallpaper() {
        guard let monitor = scene.rootNode.childNode(withName: "monitor_display", recursively: true) else { return }
        AudioManager.shared.playObjectSelected()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        monitor.opacity = 0.8
        SCNTransaction.commit()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            monitor.opacity = 1.0
            SCNTransaction.commit()
        }
    }
    
    /// Gently nudges the skateboard on the floor.
    func nudgeSkateboard() {
        guard let board = scene.rootNode.childNode(withName: "skateboard", recursively: true) else { return }
        guard !PreferencesManager.shared.reduceMotion else { return }
        AudioManager.shared.playObjectSelected()
        
        let rollForward = SCNAction.moveBy(x: -0.06, y: 0, z: 0.08, duration: 0.35)
        rollForward.timingMode = .easeOut
        let rollBack = SCNAction.moveBy(x: 0.06, y: 0, z: -0.08, duration: 0.45)
        rollBack.timingMode = .easeInEaseOut
        board.runAction(SCNAction.sequence([rollForward, rollBack]))
    }
    
    /// Bounces or wobbles a fixture/prop with gentle tactile animation and subtle sound.
    func wobbleProp(_ node: SCNNode) {
        guard !PreferencesManager.shared.reduceMotion else { return }
        AudioManager.shared.playObjectSelected()
        
        let rot1 = SCNAction.rotateBy(x: 0, y: 0.10, z: 0.06, duration: 0.08)
        let rot2 = SCNAction.rotateBy(x: 0, y: -0.20, z: -0.12, duration: 0.12)
        let rot3 = SCNAction.rotateBy(x: 0, y: 0.10, z: 0.06, duration: 0.08)
        node.runAction(SCNAction.sequence([rot1, rot2, rot3]))
    }
    
    /// Bounces a pillow or pouf with gentle tactile squash and stretch.
    func bounceProp(_ node: SCNNode) {
        guard !PreferencesManager.shared.reduceMotion else { return }
        AudioManager.shared.playObjectSelected()
        
        let squash = SCNAction.scale(to: 0.94, duration: 0.08)
        squash.timingMode = .easeOut
        let stretch = SCNAction.scale(to: 1.05, duration: 0.12)
        stretch.timingMode = .easeInEaseOut
        let normal = SCNAction.scale(to: 1.0, duration: 0.10)
        normal.timingMode = .easeOut
        node.runAction(SCNAction.sequence([squash, stretch, normal]))
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
    /// and frames camera toward it smoothly.
    func focusItem(id: UUID) {
        selectedItemID = id
        guard let node = itemNodes[id] else { return }
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
        cameraNode.position = SCNVector3(5.8, 5.2, 6.2)
        SCNTransaction.commit()
    }
    
    // MARK: - Performance Lifecycle Management
    
    private func setupLifecycleObservers() {
        let center = NotificationCenter.default
        
        let resign = center.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pauseHeavyAnimations()
            }
        }
        
        let becomeActive = center.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.resumeHeavyAnimations()
            }
        }
        
        let miniaturize = center.addObserver(
            forName: NSWindow.didMiniaturizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pauseHeavyAnimations()
            }
        }
        
        let deminiaturize = center.addObserver(
            forName: NSWindow.didDeminiaturizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.resumeHeavyAnimations()
            }
        }
        
        lifecycleObservers = [resign, becomeActive, miniaturize, deminiaturize]
    }
    
    private func pauseHeavyAnimations() {
        dustParticles?.birthRate = 0
    }
    
    private func resumeHeavyAnimations() {
        if !PreferencesManager.shared.reduceMotion {
            dustParticles?.birthRate = 8
        }
    }
}

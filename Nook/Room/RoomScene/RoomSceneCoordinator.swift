import RealityKit
import SwiftUI
import AppKit

/// Central orchestrator for the Nook 3D RealityKit miniature room diorama.
///
/// Builds the scene graph, synchronizes user data, manages lighting and time-of-day,
/// and handles high-level user actions.
@MainActor
@Observable
final class RoomSceneCoordinator {
    
    let rootEntity = Entity()
    
    // Core Sub-systems
    let cameraRig: RoomCameraRig
    private(set) var lightingSystem: RoomLightingSystem?
    private(set) var interactionSystem: RoomInteractionSystem?
    
    // Core Entities
    private(set) var architecture: RoomArchitectureEntity?
    private(set) var windowSetup: RoomWindowEntity?
    private(set) var desk: DeskEntity?
    private(set) var bed: BedEntity?
    private(set) var bookshelves: BookshelvesEntity?
    private(set) var chair: ChairEntity?
    private(set) var audioLounge: AudioLoungeEntity?
    private(set) var plants: PlantEntities?
    private(set) var skateboard: SkateboardEntity?
    private(set) var wallDecor: WallDecorEntities?
    private(set) var rug: RugEntity?
    private(set) var cookie: CookieRealityEntity?
    
    // Thought items group entity
    private let thoughtsContainer = Entity()
    private var thoughtEntities: [UUID: ModelEntity] = [:]
    
    // State Properties
    var timeOfDay: RoomTimeOfDay = .morning {
        didSet {
            lightingSystem?.applyTimeOfDay(timeOfDay)
        }
    }
    
    var isDeskLampOn: Bool = true {
        didSet {
            desk?.setLampEnabled(isDeskLampOn)
        }
    }
    
    var isWallSconceOn: Bool = true {
        didSet {
            wallDecor?.setSconceEnabled(isWallSconceOn)
        }
    }
    
    var isRecordSpinning: Bool = true
    
    var selectedItemID: UUID? {
        didSet {
            updateSelectionVisuals()
        }
    }
    
    var hoveredItemID: UUID?
    
    // Callbacks to SwiftUI layer
    var onSelectItem: ((UUID?) -> Void)?
    var onItemMoved: ((UUID, RoomPosition) -> Void)?
    var onOpenItem: ((UUID) -> Void)?
    var onToggleLamp: (() -> Void)?
    var onPetCookie: (() -> Void)?
    
    init() {
        self.cameraRig = RoomCameraRig()
        self.interactionSystem = RoomInteractionSystem()
        
        buildScene()
        self.interactionSystem?.coordinator = self
        startRecordSpinAnimation()
    }
    
    private func buildScene() {
        rootEntity.name = "room_diorama_root"
        
        // 1. Camera
        rootEntity.addChild(cameraRig.cameraEntity)
        
        // 2. Lighting System
        self.lightingSystem = RoomLightingSystem(root: rootEntity)
        lightingSystem?.applyTimeOfDay(timeOfDay)
        
        // 3. Architectural Shell
        let arch = RoomArchitectureEntity()
        rootEntity.addChild(arch)
        self.architecture = arch
        
        // 4. Window & Outdoor Scenery
        let win = RoomWindowEntity()
        rootEntity.addChild(win)
        self.windowSetup = win
        
        // 5. Furniture Elements
        let d = DeskEntity()
        rootEntity.addChild(d)
        self.desk = d
        
        let b = BedEntity()
        rootEntity.addChild(b)
        self.bed = b
        
        let bs = BookshelvesEntity()
        rootEntity.addChild(bs)
        self.bookshelves = bs
        
        let ch = ChairEntity()
        rootEntity.addChild(ch)
        self.chair = ch
        
        let al = AudioLoungeEntity()
        rootEntity.addChild(al)
        self.audioLounge = al
        
        // 6. Decorations
        let pl = PlantEntities()
        rootEntity.addChild(pl)
        self.plants = pl
        
        let sk = SkateboardEntity()
        rootEntity.addChild(sk)
        self.skateboard = sk
        
        let wd = WallDecorEntities()
        rootEntity.addChild(wd)
        self.wallDecor = wd
        
        let rg = RugEntity()
        rootEntity.addChild(rg)
        self.rug = rg
        
        // 7. Cookie the Cat
        let ck = CookieRealityEntity()
        rootEntity.addChild(ck)
        self.cookie = ck
        
        // 8. Thoughts Container
        thoughtsContainer.name = "thoughts_container"
        rootEntity.addChild(thoughtsContainer)
    }
    
    // MARK: - Synchronizing SwiftData Items
    
    func syncItems(_ items: [NookItem]) {
        let currentItemIDs = Set(items.map(\.id))
        
        // Remove entities for deleted or archived items
        for (id, entity) in thoughtEntities where !currentItemIDs.contains(id) {
            entity.removeFromParent()
            thoughtEntities.removeValue(forKey: id)
        }
        
        // Add or update entities for items
        for item in items {
            if let existing = thoughtEntities[item.id] {
                // Update position if changed
                let targetPos = SIMD3<Float>(Float(item.roomPosition.x), Float(item.roomPosition.y), Float(item.roomPosition.z))
                if distance(existing.position, targetPos) > 0.001 {
                    existing.position = targetPos
                }
            } else {
                let entity = ThoughtEntityBuilder.buildThoughtEntity(for: item)
                thoughtsContainer.addChild(entity)
                thoughtEntities[item.id] = entity
            }
        }
    }
    
    // MARK: - User Interactions
    
    func selectItem(_ id: UUID?) {
        self.selectedItemID = id
        onSelectItem?(id)
    }
    
    func updateItemPosition(id: UUID, position: SIMD3<Float>) {
        if let entity = thoughtEntities[id] {
            entity.position = position
        }
        let roomPos = RoomPosition(x: Double(position.x), y: Double(position.y), z: Double(position.z))
        onItemMoved?(id, roomPos)
    }
    
    func toggleDeskLamp() {
        isDeskLampOn.toggle()
        onToggleLamp?()
    }
    
    func toggleRecordPlayer() {
        isRecordSpinning.toggle()
    }
    
    func petCookie() {
        cookie?.pet()
        onPetCookie?()
    }
    
    func focusItem(id: UUID) {
        selectItem(id)
        if let entity = thoughtEntities[id] {
            cameraRig.frameItem(at: entity.position)
        }
    }
    
    func resetCameraFraming() {
        cameraRig.resetToDefaultFraming()
    }
    
    // MARK: - Visual Feedback
    
    private func updateSelectionVisuals() {
        for (id, entity) in thoughtEntities {
            if id == selectedItemID {
                // Gentle elevation and scale pop
                entity.scale = [1.08, 1.08, 1.08]
            } else {
                entity.scale = [1.0, 1.0, 1.0]
            }
        }
    }
    
    // Continuous subtle turntable record spinning animation loop
    private func startRecordSpinAnimation() {
        Task { @MainActor [weak self] in
            var angle: Float = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_333_333) // ~30fps
                guard let self = self, self.isRecordSpinning,
                      let vinyl = self.audioLounge?.vinylRecordEntity else { continue }
                angle += 0.04
                vinyl.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            }
        }
    }
}

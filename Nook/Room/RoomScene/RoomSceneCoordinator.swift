import RealityKit
import SwiftUI
import AppKit

/// Central orchestrator for the Nook 3D RealityKit miniature room diorama.
///
/// Builds the scene graph hierarchy, synchronizes user data, manages lighting and time-of-day,
/// and handles high-level user actions, prop transforms persistence, and native macOS undo.
@MainActor
@Observable
final class RoomSceneCoordinator {
    
    let rootEntity = Entity()
    
    // Core Sub-systems
    let cameraRig: RoomCameraRig
    private(set) var lightingSystem: RoomLightingSystem?
    private(set) var interactionSystem: RoomInteractionSystem?
    
    // Area Hierarchy Nodes (Matching exact requested diorama hierarchy)
    private(set) var architectureArea: RoomArchitectureEntity?
    private(set) var windowArea: RoomWindowEntity?
    private(set) var deskArea: DeskAreaEntity?
    private(set) var bedArea: BedAreaEntity?
    private(set) var shelfArea: ShelfAreaEntity?
    private(set) var recordArea: RecordAreaEntity?
    private(set) var floorObjectsArea: FloorObjectsAreaEntity?
    private(set) var cookie: CookieRealityEntity?
    private(set) var chair: ChairEntity?
    
    // Registry of all interactive room props keyed by propId
    private(set) var propEntities: [String: Entity] = [:]
    
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
            deskArea?.lampEntity.setEnabled(isDeskLampOn)
        }
    }
    
    var isWallSconceOn: Bool = true {
        didSet {
            floorObjectsArea?.wallDecor.setSconceEnabled(isWallSconceOn)
        }
    }
    
    var isRecordSpinning: Bool = true
    
    var selectedItemID: UUID? {
        didSet {
            updateSelectionVisuals()
        }
    }
    
    var hoveredItemID: UUID?
    
    // Cookie State-Driven Behavior Engine
    let cookieController = CookieBehaviorController()
    private var hasConfiguredFromSavedState = false
    
    // Callbacks to SwiftUI layer
    var onSelectItem: ((UUID?) -> Void)?
    var onItemMoved: ((UUID, RoomPosition) -> Void)?
    var onOpenItem: ((UUID) -> Void)?
    var onToggleLamp: (() -> Void)?
    var onPetCookie: (() -> Void)?
    var onPropSelected: ((String?) -> Void)?
    var onPropTransformSaved: ((RoomPropTransform) -> Void)?
    var onPropTransformReset: ((String) -> Void)?
    
    init() {
        self.cameraRig = RoomCameraRig()
        self.interactionSystem = RoomInteractionSystem()
        
        buildScene()
        self.interactionSystem?.coordinator = self
        startRecordSpinAnimation()
    }
    
    // MARK: - Scene Construction
    
    private func buildScene() {
        rootEntity.name = "RoomRoot"
        
        // 1. Camera Rig
        rootEntity.addChild(cameraRig.cameraEntity)
        
        // 2. Lighting System
        self.lightingSystem = RoomLightingSystem(root: rootEntity)
        lightingSystem?.applyTimeOfDay(timeOfDay)
        
        // 3. Architecture (Floor, BackWall, LeftWall, Trim - Immovable)
        let arch = RoomArchitectureEntity()
        rootEntity.addChild(arch)
        self.architectureArea = arch
        
        // 4. WindowArea (Window, Curtains, OutdoorEnvironment - Immovable)
        let win = RoomWindowEntity()
        rootEntity.addChild(win)
        self.windowArea = win
        
        // 5. DeskArea (Desk, Monitor, Laptop, Keyboard, Mouse, Phone, Notebook, Lamp, Mug, Plant, Headphones)
        let desk = DeskAreaEntity()
        rootEntity.addChild(desk)
        self.deskArea = desk
        
        // Ergonomic office chair in desk area
        let ch = ChairEntity()
        rootEntity.addChild(ch)
        self.chair = ch
        
        // 6. BedArea (Bed, Mattress, Sheets, Pillows, Blanket, BedDecor)
        let bed = BedAreaEntity()
        rootEntity.addChild(bed)
        self.bedArea = bed
        
        // 7. ShelfArea (Shelf, Books, Plants, Clock, Decorations)
        let shelf = ShelfAreaEntity()
        rootEntity.addChild(shelf)
        self.shelfArea = shelf
        
        // 8. RecordArea (Ottoman, RecordPlayer, Vinyl, Records)
        let record = RecordAreaEntity()
        rootEntity.addChild(record)
        self.recordArea = record
        
        // 9. FloorObjects (Skateboard, BouclePouf, Monstera, FloorPlant, StepBooks, StepSucculent, Rug, WallDecor)
        let floor = FloorObjectsAreaEntity()
        rootEntity.addChild(floor)
        self.floorObjectsArea = floor
        
        // 10. Cookie the Cat
        let ck = CookieRealityEntity()
        rootEntity.addChild(ck)
        self.cookie = ck
        
        // 11. Thoughts Container
        thoughtsContainer.name = "thoughts_container"
        rootEntity.addChild(thoughtsContainer)
        
        // Register all interactive props
        registerAllProps()
    }
    
    private func registerAllProps() {
        guard let desk = deskArea,
              let bed = bedArea,
              let shelf = shelfArea,
              let record = recordArea,
              let floor = floorObjectsArea,
              let ck = cookie else { return }
        
        let allEntities: [Entity] = [
            desk.monitorEntity,
            desk.laptopEntity,
            desk.keyboardEntity,
            desk.mouseEntity,
            desk.phoneEntity,
            desk.notebookEntity,
            desk.lampEntity,
            desk.mugEntity,
            desk.pencilCupEntity,
            desk.plantEntity,
            desk.headphonesEntity,
            bed.daisyPillow,
            bed.sagePillow,
            bed.sleepingPillows,
            bed.bedDecor,
            shelf.clock,
            shelf.catFigurine,
            shelf.storageBox,
            shelf.books,
            shelf.shelfPlant,
            record.recordPlayer,
            record.albumStack,
            floor.skateboard,
            floor.bouclePouf,
            floor.monstera,
            floor.deskFloorPlant,
            floor.stepBooks,
            floor.stepSucculent,
            ck
        ]
        
        for entity in allEntities {
            if let prop = entity.components[InteractivePropComponent.self] {
                propEntities[prop.propId] = entity
            }
        }
    }
    
    func findPropEntity(id: String) -> Entity? {
        return propEntities[id]
    }
    
    // MARK: - Persistence Synchronization
    
    func applySavedRoomState(_ roomState: RoomState) {
        guard !hasConfiguredFromSavedState else { return }
        hasConfiguredFromSavedState = true
        
        self.timeOfDay = roomState.timeOfDay
        self.isDeskLampOn = roomState.isDeskLampOn
        self.isWallSconceOn = roomState.isWallSconceOn
        self.isRecordSpinning = roomState.isRecordSpinning
        
        // Apply saved prop transforms
        let savedTransforms = roomState.getPropTransforms()
        applySavedPropTransforms(savedTransforms)
    }
    
    func applySavedPropTransforms(_ transforms: [String: RoomPropTransform]) {
        for (propId, transform) in transforms {
            if let entity = propEntities[propId] {
                entity.position = transform.position
                entity.orientation = transform.orientation
                entity.scale = transform.scale
            }
        }
    }
    
    func syncToRoomState(_ roomState: RoomState) {
        roomState.timeOfDay = self.timeOfDay
        roomState.isDeskLampOn = self.isDeskLampOn
        roomState.isWallSconceOn = self.isWallSconceOn
        roomState.isRecordSpinning = self.isRecordSpinning
        roomState.cookieLastInteractedAt = cookieController.state.lastInteraction
        roomState.updatedAt = .now
    }
    
    func savePropTransform(_ transform: RoomPropTransform) {
        onPropTransformSaved?(transform)
    }
    
    func resetPropTransform(id: String) {
        onPropTransformReset?(id)
    }
    
    func applyPropTransform(_ transform: RoomPropTransform, animated: Bool = false) {
        guard let entity = propEntities[transform.propId] else { return }
        entity.position = transform.position
        entity.orientation = transform.orientation
        entity.scale = transform.scale
        savePropTransform(transform)
    }
    
    func setTimeOfDay(_ tod: RoomTimeOfDay) {
        withAnimation(NookDesign.Animation.gentle) {
            self.timeOfDay = tod
        }
    }
    
    func toggleWallSconce() {
        isWallSconceOn.toggle()
    }
    
    func moveItem(_ id: UUID, to position: RoomPosition) {
        let worldPos = ThoughtEntityBuilder.worldPosition(for: position)
        updateItemPosition(id: id, position: worldPos)
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
        let roomPos = ThoughtEntityBuilder.roomPosition(from: position)
        onItemMoved?(id, roomPos)
    }
    
    func toggleDeskLamp() {
        isDeskLampOn.toggle()
        onToggleLamp?()
    }
    
    func toggleRecordPlayer() {
        isRecordSpinning.toggle()
        recordArea?.recordPlayer.togglePlayback()
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
                      let vinyl = self.recordArea?.recordPlayer.vinylRecord else { continue }
                angle += 0.04
                vinyl.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            }
        }
    }
}

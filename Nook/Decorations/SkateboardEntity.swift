import RealityKit
import AppKit

/// Builds the miniature 3D skateboard resting on the front floor platform:
/// - Curved wooden deck with black grip tape on top
/// - Natural honey-oak underside and beveled edge
/// - Dual silver/aluminum trucks with axle pins
/// - Four miniature polyurethane wheels
/// - Collision & InputTarget components for physical dragging and rotation
@MainActor
final class SkateboardEntity: Entity {
    
    static let defaultPos = SIMD3<Float>(0.08, RoomArchitectureEntity.upperFloorY + 0.025, 0.44)
    static let defaultRot = simd_quatf(angle: -Float.pi * 0.16, axis: [0, 1, 0])
    
    required init() {
        super.init()
        self.name = "prop_skateboard"
        buildSkateboard()
    }
    
    private func buildSkateboard() {
        let mats = RoomMaterials.shared
        self.position = Self.defaultPos
        self.orientation = Self.defaultRot
        
        let deckLength: Float = 0.44
        let deckWidth: Float = 0.12
        let deckThickness: Float = 0.012
        
        // 1. Deck Base (Honey Oak wood core)
        let deckMesh = MeshResource.generateBox(size: [deckLength, deckThickness, deckWidth], cornerRadius: 0.018)
        let deck = ModelEntity(mesh: deckMesh, materials: [mats.honeyOakWood])
        deck.position = [0, 0, 0]
        addChild(deck)
        
        // 2. Black Grip Tape on Top
        let gripMesh = MeshResource.generateBox(size: [deckLength - 0.01, 0.002, deckWidth - 0.008], cornerRadius: 0.012)
        let grip = ModelEntity(mesh: gripMesh, materials: [mats.skateboardGrip])
        grip.position = [0, deckThickness * 0.5 + 0.001, 0]
        deck.addChild(grip)
        
        // 3. Front & Rear Trucks (Brushed Aluminum)
        let truckDist: Float = 0.13
        let truckMesh = MeshResource.generateBox(size: [0.02, 0.018, deckWidth * 0.75], cornerRadius: 0.003)
        
        let frontTruck = ModelEntity(mesh: truckMesh, materials: [mats.brushedAluminum])
        frontTruck.position = [truckDist, -deckThickness * 0.5 - 0.009, 0]
        deck.addChild(frontTruck)
        
        let rearTruck = ModelEntity(mesh: truckMesh, materials: [mats.brushedAluminum])
        rearTruck.position = [-truckDist, -deckThickness * 0.5 - 0.009, 0]
        deck.addChild(rearTruck)
        
        // 4. Four Polyurethane Wheels
        let wheelRadius: Float = 0.018
        let wheelWidth: Float = 0.014
        let wheelMesh = MeshResource.generateCylinder(height: wheelWidth, radius: wheelRadius)
        
        let wheelPositions: [(truck: ModelEntity, z: Float)] = [
            (frontTruck, -deckWidth * 0.38),
            (frontTruck, deckWidth * 0.38),
            (rearTruck, -deckWidth * 0.38),
            (rearTruck, deckWidth * 0.38)
        ]
        
        for w in wheelPositions {
            let wheel = ModelEntity(mesh: wheelMesh, materials: [mats.glazedWhiteCeramic])
            wheel.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
            wheel.position = [0, -0.006, w.z]
            w.truck.addChild(wheel)
        }
        
        let colShape = ShapeResource.generateBox(size: [0.46, 0.06, 0.16])
        self.components.set(CollisionComponent(shapes: [colShape]))
        self.components.set(InputTargetComponent())
        self.components.set(InteractivePropComponent(
            propId: "prop_skateboard",
            displayName: "Skateboard",
            accessibilityLabel: "Honey oak skateboard with black grip tape and white wheels",
            category: .movable,
            allowsDragging: true,
            allowsRotation: true,
            defaultPosition: Self.defaultPos,
            defaultOrientation: Self.defaultRot,
            restingSurfaceY: RoomArchitectureEntity.upperFloorY
        ))
    }
}

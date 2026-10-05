import RealityKit
import AppKit

/// Builds the miniature 3D skateboard resting on the front floor platform:
/// - Curved wooden deck with black grip tape on top
/// - Natural honey-oak underside and beveled edge
/// - Dual silver/aluminum trucks with axle pins
/// - Four miniature polyurethane wheels
@MainActor
final class SkateboardEntity: Entity {
    
    required init() {
        super.init()
        self.name = "skateboard"
        buildSkateboard()
    }
    
    private func buildSkateboard() {
        let mats = RoomMaterials.shared
        let lowerFloorY = RoomArchitectureEntity.lowerFloorY
        
        // Positioned on the lower floor platform near the steps
        // X = +0.12, Z = +0.55
        self.position = [0.12, lowerFloorY + 0.035, 0.55]
        self.orientation = simd_quatf(angle: -Float.pi * 0.14, axis: [0, 1, 0])
        
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
    }
}

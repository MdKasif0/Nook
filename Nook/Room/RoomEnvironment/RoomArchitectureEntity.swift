import RealityKit
import AppKit

/// Builds the physical architectural structure of the Nook miniature diorama:
/// - Raised wooden base plinth
/// - Upper floor platform (desk & bed area)
/// - Lower sunken floor platform (lounge & entry area)
/// - 3 wide wooden steps connecting platforms
/// - Ivory plaster back wall & left wall
/// - Right cutaway wall housing window
/// - Chunky rounded honey-oak top trim beams wrapping the walls
@MainActor
final class RoomArchitectureEntity: Entity {
    
    // Key architectural dimensions
    static let roomSpanX: Float = 2.7
    static let roomSpanZ: Float = 2.7
    static let wallHeight: Float = 1.85
    static let wallThickness: Float = 0.12
    static let upperFloorY: Float = 0.16
    static let lowerFloorY: Float = 0.02
    static let trimHeight: Float = 0.12
    static let trimDepth: Float = 0.16
    
    required init() {
        super.init()
        self.name = "room_architecture"
        buildArchitecture()
    }
    
    private func buildArchitecture() {
        let mats = RoomMaterials.shared
        
        // 1. Raised Wooden Diorama Plinth / Foundation (Sits underneath entire room)
        let plinthMesh = MeshResource.generateBox(size: [Self.roomSpanX + 0.1, 0.16, Self.roomSpanZ + 0.1], cornerRadius: 0.015)
        let plinthEntity = ModelEntity(mesh: plinthMesh, materials: [mats.honeyOakWood])
        plinthEntity.position = [0, -0.08, 0]
        plinthEntity.name = "base_plinth"
        addChild(plinthEntity)
        
        // 2. Upper Main Floor Platform (Y = 0.16, covering desk and bed)
        // Extends from back wall (Z = -1.25) to transition ledge (Z = 0.15)
        let upperWidth: Float = Self.roomSpanX
        let upperDepth: Float = 1.55
        let upperFloorMesh = MeshResource.generateBox(size: [upperWidth, 0.18, upperDepth], cornerRadius: 0.01)
        let upperFloorEntity = ModelEntity(mesh: upperFloorMesh, materials: [mats.hardwoodPlankFloor])
        upperFloorEntity.position = [0, Self.upperFloorY - 0.09, -0.47]
        upperFloorEntity.name = "floor_upper_platform"
        addChild(upperFloorEntity)
        
        // 3. Lower Front Lounge Platform (Y = 0.02, foreground area with skateboard & pouf)
        // Extends from Z = 0.15 to front edge (Z = 1.25)
        let lowerWidth: Float = Self.roomSpanX
        let lowerDepth: Float = 1.15
        let lowerFloorMesh = MeshResource.generateBox(size: [lowerWidth, 0.04, lowerDepth], cornerRadius: 0.01)
        let lowerFloorEntity = ModelEntity(mesh: lowerFloorMesh, materials: [mats.hardwoodPlankFloor])
        lowerFloorEntity.position = [0, Self.lowerFloorY - 0.02, 0.72]
        lowerFloorEntity.name = "floor_lower_platform"
        addChild(lowerFloorEntity)
        
        // 4. Stepped Wooden Stairs (Connecting upper platform to lower platform)
        // Positioned centrally right in front of the bed/desk divide
        let stepWidth: Float = 0.85
        let stepDepth: Float = 0.14
        let stepHeights: [Float] = [0.05, 0.09, 0.13]
        for (i, h) in stepHeights.enumerated() {
            let stepMesh = MeshResource.generateBox(size: [stepWidth, 0.045, stepDepth], cornerRadius: 0.008)
            let stepEntity = ModelEntity(mesh: stepMesh, materials: [mats.honeyOakWood])
            // Stepping forward from upper to lower
            let zPos = 0.15 + Float(i) * 0.10
            stepEntity.position = [-0.08, h, zPos]
            stepEntity.name = "stair_step_\(i + 1)"
            addChild(stepEntity)
        }
        
        // Step risers side trim / fascia
        let stepRiserMesh = MeshResource.generateBox(size: [0.04, 0.15, 0.35], cornerRadius: 0.008)
        let leftRiser = ModelEntity(mesh: stepRiserMesh, materials: [mats.honeyOakWood])
        leftRiser.position = [-0.08 - stepWidth * 0.5 - 0.02, 0.075, 0.28]
        addChild(leftRiser)
        
        let rightRiser = ModelEntity(mesh: stepRiserMesh, materials: [mats.honeyOakWood])
        rightRiser.position = [-0.08 + stepWidth * 0.5 + 0.02, 0.075, 0.28]
        addChild(rightRiser)
        
        // 5. Back Wall (Ivory Plaster)
        // Runs along X axis at Z = -1.25, from X = -1.30 to +1.30
        let backWallMesh = MeshResource.generateBox(size: [Self.roomSpanX, Self.wallHeight, Self.wallThickness], cornerRadius: 0.01)
        let backWallEntity = ModelEntity(mesh: backWallMesh, materials: [mats.ivoryPlasterWall])
        backWallEntity.position = [0, Self.upperFloorY + Self.wallHeight * 0.5, -1.25]
        backWallEntity.name = "back_wall"
        addChild(backWallEntity)
        
        // 6. Left Wall (Ivory Plaster)
        // Runs along Z axis at X = -1.30, from Z = -1.25 to Z = +1.10
        let leftWallLength: Float = 2.45
        let leftWallMesh = MeshResource.generateBox(size: [Self.wallThickness, Self.wallHeight, leftWallLength], cornerRadius: 0.01)
        let leftWallEntity = ModelEntity(mesh: leftWallMesh, materials: [mats.ivoryPlasterWall])
        leftWallEntity.position = [-Self.roomSpanX * 0.5, Self.upperFloorY + Self.wallHeight * 0.5, -0.05]
        leftWallEntity.name = "left_wall"
        addChild(leftWallEntity)
        
        // 7. Right Wall with Window Cutout (Ivory Plaster)
        // Runs along Z axis at X = +1.30, from Z = -1.25 to Z = +0.25 (leaving front open)
        let rightWallLength: Float = 1.60
        let rightWallMesh = MeshResource.generateBox(size: [Self.wallThickness, Self.wallHeight, rightWallLength], cornerRadius: 0.01)
        let rightWallEntity = ModelEntity(mesh: rightWallMesh, materials: [mats.ivoryPlasterWall])
        rightWallEntity.position = [Self.roomSpanX * 0.5, Self.upperFloorY + Self.wallHeight * 0.5, -0.45]
        rightWallEntity.name = "right_wall"
        addChild(rightWallEntity)
        
        // 8. Thick Rounded Honey-Oak Top Trim Beams
        // Back Wall Top Trim
        let backTrimMesh = MeshResource.generateBox(size: [Self.roomSpanX + 0.16, Self.trimHeight, Self.trimDepth], cornerRadius: 0.035)
        let backTrimEntity = ModelEntity(mesh: backTrimMesh, materials: [mats.honeyOakWood])
        backTrimEntity.position = [0, Self.upperFloorY + Self.wallHeight + Self.trimHeight * 0.5, -1.25]
        backTrimEntity.name = "top_trim_back"
        addChild(backTrimEntity)
        
        // Left Wall Top Trim
        let leftTrimMesh = MeshResource.generateBox(size: [Self.trimDepth, Self.trimHeight, leftWallLength + 0.16], cornerRadius: 0.035)
        let leftTrimEntity = ModelEntity(mesh: leftTrimMesh, materials: [mats.honeyOakWood])
        leftTrimEntity.position = [-Self.roomSpanX * 0.5, Self.upperFloorY + Self.wallHeight + Self.trimHeight * 0.5, -0.05]
        leftTrimEntity.name = "top_trim_left"
        addChild(leftTrimEntity)
        
        // Right Wall Top Trim
        let rightTrimMesh = MeshResource.generateBox(size: [Self.trimDepth, Self.trimHeight, rightWallLength + 0.16], cornerRadius: 0.035)
        let rightTrimEntity = ModelEntity(mesh: rightTrimMesh, materials: [mats.honeyOakWood])
        rightTrimEntity.position = [Self.roomSpanX * 0.5, Self.upperFloorY + Self.wallHeight + Self.trimHeight * 0.5, -0.45]
        rightTrimEntity.name = "top_trim_right"
        addChild(rightTrimEntity)
        
        // Baseboard Moldings (along wall bases for clean architectural craft)
        let baseboardBack = ModelEntity(
            mesh: .generateBox(size: [Self.roomSpanX - 0.1, 0.08, 0.02], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        baseboardBack.position = [0, Self.upperFloorY + 0.04, -1.18]
        addChild(baseboardBack)
        
        let baseboardLeft = ModelEntity(
            mesh: .generateBox(size: [0.02, 0.08, leftWallLength - 0.1], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        baseboardLeft.position = [-Self.roomSpanX * 0.5 + 0.07, Self.upperFloorY + 0.04, -0.05]
        addChild(baseboardLeft)
    }
}

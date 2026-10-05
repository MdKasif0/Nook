import RealityKit
import AppKit

/// Builds the physical architectural structure of the Nook miniature diorama:
/// - Raised wooden base plinth (diorama foundation)
/// - Upper floor platform (desk & bed area)
/// - Lower sunken floor platform (lounge & entry area)
/// - 3 wide wooden steps connecting platforms
/// - Left wall (ivory plaster, desk workstation)
/// - Back wall (ivory plaster, bookcase & window above bed)
/// - Chunky rounded honey-oak top trim beams wrapping the two main walls
@MainActor
final class RoomArchitectureEntity: Entity {
    
    // Key architectural dimensions
    static let wallSpan: Float = 2.45
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
        let plinthMesh = MeshResource.generateBox(size: [Self.wallSpan + 0.15, 0.16, Self.wallSpan + 0.15], cornerRadius: 0.015)
        let plinthEntity = ModelEntity(mesh: plinthMesh, materials: [mats.honeyOakWood])
        plinthEntity.position = [0, -0.08, 0]
        plinthEntity.name = "base_plinth"
        addChild(plinthEntity)
        
        // 2. Upper Main Floor Platform (Y = 0.16, covering desk and bed)
        // L-shaped / diagonal coverage from corner (-1.25, -1.25) to mid-room
        let upperFloorMesh = MeshResource.generateBox(size: [Self.wallSpan, 0.18, Self.wallSpan * 0.65], cornerRadius: 0.01)
        let upperFloorEntity = ModelEntity(mesh: upperFloorMesh, materials: [mats.hardwoodPlankFloor])
        upperFloorEntity.position = [0, Self.upperFloorY - 0.09, -0.38]
        upperFloorEntity.name = "floor_upper_platform"
        addChild(upperFloorEntity)
        
        // 3. Lower Front Lounge Platform (Y = 0.02, foreground area with skateboard & pouf)
        let lowerFloorMesh = MeshResource.generateBox(size: [Self.wallSpan, 0.04, Self.wallSpan * 0.40], cornerRadius: 0.01)
        let lowerFloorEntity = ModelEntity(mesh: lowerFloorMesh, materials: [mats.hardwoodPlankFloor])
        lowerFloorEntity.position = [0, Self.lowerFloorY - 0.02, 0.72]
        lowerFloorEntity.name = "floor_lower_platform"
        addChild(lowerFloorEntity)
        
        // 4. Stepped Wooden Stairs (Connecting upper platform to lower platform)
        // Positioned centrally in front of the bed/desk area
        let stepWidth: Float = 0.82
        let stepDepth: Float = 0.14
        let stepHeights: [Float] = [0.05, 0.09, 0.13]
        for (i, h) in stepHeights.enumerated() {
            let stepMesh = MeshResource.generateBox(size: [stepWidth, 0.045, stepDepth], cornerRadius: 0.008)
            let stepEntity = ModelEntity(mesh: stepMesh, materials: [mats.honeyOakWood])
            let zPos: Float = 0.12 + Float(i) * 0.10
            stepEntity.position = [-0.10, h, zPos]
            stepEntity.name = "stair_step_\(i + 1)"
            addChild(stepEntity)
        }
        
        // Step risers side trim / fascia
        let stepRiserMesh = MeshResource.generateBox(size: [0.04, 0.15, 0.35], cornerRadius: 0.008)
        let leftRiser = ModelEntity(mesh: stepRiserMesh, materials: [mats.honeyOakWood])
        leftRiser.position = [-0.10 - stepWidth * 0.5 - 0.02, 0.075, 0.25]
        addChild(leftRiser)
        
        let rightRiser = ModelEntity(mesh: stepRiserMesh, materials: [mats.honeyOakWood])
        rightRiser.position = [-0.10 + stepWidth * 0.5 + 0.02, 0.075, 0.25]
        addChild(rightRiser)
        
        // 5. Left Wall (Ivory Plaster, runs from Z = -1.25 to Z = +1.15 at X = -1.20)
        let leftWallMesh = MeshResource.generateBox(size: [Self.wallThickness, Self.wallHeight, Self.wallSpan], cornerRadius: 0.01)
        let leftWallEntity = ModelEntity(mesh: leftWallMesh, materials: [mats.ivoryPlasterWall])
        leftWallEntity.position = [-Self.wallSpan * 0.5, Self.upperFloorY + Self.wallHeight * 0.5, 0]
        leftWallEntity.name = "left_wall"
        addChild(leftWallEntity)
        
        // 6. Back Wall with Real Window Opening Aperture
        // The window cutout is centered at X = 0.55, Y = 1.25, size: 0.86m x 0.96m
        let backWallRoot = Entity()
        backWallRoot.name = "back_wall"
        addChild(backWallRoot)
        
        let wallZ = -Self.wallSpan * 0.5
        
        // 6a. Left section of back wall (behind bookcase & headboard, X = -1.225 to 0.12)
        let leftSectionWidth: Float = 1.345
        let leftSectionMesh = MeshResource.generateBox(size: [leftSectionWidth, Self.wallHeight, Self.wallThickness], cornerRadius: 0.01)
        let leftSection = ModelEntity(mesh: leftSectionMesh, materials: [mats.ivoryPlasterWall])
        leftSection.position = [-Self.wallSpan * 0.5 + leftSectionWidth * 0.5, Self.upperFloorY + Self.wallHeight * 0.5, wallZ]
        backWallRoot.addChild(leftSection)
        
        // 6b. Right section of back wall (to right of window, X = 0.98 to 1.225)
        let rightSectionWidth: Float = 0.245
        let rightSectionMesh = MeshResource.generateBox(size: [rightSectionWidth, Self.wallHeight, Self.wallThickness], cornerRadius: 0.01)
        let rightSection = ModelEntity(mesh: rightSectionMesh, materials: [mats.ivoryPlasterWall])
        rightSection.position = [Self.wallSpan * 0.5 - rightSectionWidth * 0.5, Self.upperFloorY + Self.wallHeight * 0.5, wallZ]
        backWallRoot.addChild(rightSection)
        
        // 6c. Sill / spandrel section (under window, X = 0.12 to 0.98, below Y = 0.77)
        let sillSectionHeight: Float = 0.61
        let sillSectionMesh = MeshResource.generateBox(size: [0.86, sillSectionHeight, Self.wallThickness], cornerRadius: 0.005)
        let sillSection = ModelEntity(mesh: sillSectionMesh, materials: [mats.ivoryPlasterWall])
        sillSection.position = [0.55, Self.upperFloorY + sillSectionHeight * 0.5, wallZ]
        backWallRoot.addChild(sillSection)
        
        // 6d. Header section (above window, X = 0.12 to 0.98, above Y = 1.73)
        let headerSectionHeight: Float = 0.28
        let headerSectionMesh = MeshResource.generateBox(size: [0.86, headerSectionHeight, Self.wallThickness], cornerRadius: 0.005)
        let headerSection = ModelEntity(mesh: headerSectionMesh, materials: [mats.ivoryPlasterWall])
        headerSection.position = [0.55, Self.upperFloorY + Self.wallHeight - headerSectionHeight * 0.5, wallZ]
        backWallRoot.addChild(headerSection)
        
        // 7. Thick Rounded Honey-Oak Top Trim Beams
        // Left Wall Top Trim
        let leftTrimMesh = MeshResource.generateBox(size: [Self.trimDepth, Self.trimHeight, Self.wallSpan + 0.12], cornerRadius: 0.035)
        let leftTrimEntity = ModelEntity(mesh: leftTrimMesh, materials: [mats.honeyOakWood])
        leftTrimEntity.position = [-Self.wallSpan * 0.5, Self.upperFloorY + Self.wallHeight + Self.trimHeight * 0.5, 0]
        leftTrimEntity.name = "top_trim_left"
        addChild(leftTrimEntity)
        
        // Back Wall Top Trim
        let backTrimMesh = MeshResource.generateBox(size: [Self.wallSpan + 0.12, Self.trimHeight, Self.trimDepth], cornerRadius: 0.035)
        let backTrimEntity = ModelEntity(mesh: backTrimMesh, materials: [mats.honeyOakWood])
        backTrimEntity.position = [0, Self.upperFloorY + Self.wallHeight + Self.trimHeight * 0.5, -Self.wallSpan * 0.5]
        backTrimEntity.name = "top_trim_back"
        addChild(backTrimEntity)
        
        // Baseboard Moldings along wall bases
        let baseboardLeft = ModelEntity(
            mesh: .generateBox(size: [0.02, 0.08, Self.wallSpan - 0.08], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        baseboardLeft.position = [-Self.wallSpan * 0.5 + 0.07, Self.upperFloorY + 0.04, 0]
        addChild(baseboardLeft)
        
        let baseboardBack = ModelEntity(
            mesh: .generateBox(size: [Self.wallSpan - 0.08, 0.08, 0.02], cornerRadius: 0.005),
            materials: [mats.honeyOakWood]
        )
        baseboardBack.position = [0, Self.upperFloorY + 0.04, -Self.wallSpan * 0.5 + 0.07]
        addChild(baseboardBack)
    }
}

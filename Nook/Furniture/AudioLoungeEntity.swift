import RealityKit
import AppKit

/// Builds the audio & lounge setup matching the reference image:
/// - Muted sage green upholstered bench / low ottoman near the foot of the bed
/// - Vintage retro suitcase turntable / record player
/// - Semi-gloss black vinyl record with red center label
/// - Brass tonearm and miniature speed control dials
/// - Stack of vinyl album sleeves resting on the bench
/// - White fluffy boucle round floor pouf / beanbag with daisy center button
@MainActor
final class AudioLoungeEntity: Entity {
    
    private(set) var vinylRecordEntity: ModelEntity?
    
    required init() {
        super.init()
        self.name = "audio_lounge_setup"
        buildAudioLounge()
    }
    
    private func buildAudioLounge() {
        let mats = RoomMaterials.shared
        let upperFloorY = RoomArchitectureEntity.upperFloorY
        let lowerFloorY = RoomArchitectureEntity.lowerFloorY
        
        // 1. Muted Sage Green Upholstered Bench / Ottoman
        // Sits at the foot of the bed on the right side: X = +0.78, Z = -0.18
        let benchWidth: Float = 0.38   // along X
        let benchLength: Float = 0.52  // along Z
        let benchHeight: Float = 0.22
        let legHeight: Float = 0.10
        
        let benchRoot = Entity()
        benchRoot.position = [0.78, upperFloorY, -0.18]
        benchRoot.name = "record_bench"
        addChild(benchRoot)
        
        // 4 Honey Oak Wooden Legs
        let legRadius: Float = 0.016
        let legMesh = MeshResource.generateCylinder(height: legHeight, radius: legRadius)
        let legPositions: [SIMD3<Float>] = [
            [-benchWidth * 0.5 + 0.04, legHeight * 0.5, -benchLength * 0.5 + 0.04],
            [benchWidth * 0.5 - 0.04, legHeight * 0.5, -benchLength * 0.5 + 0.04],
            [-benchWidth * 0.5 + 0.04, legHeight * 0.5, benchLength * 0.5 - 0.04],
            [benchWidth * 0.5 - 0.04, legHeight * 0.5, benchLength * 0.5 - 0.04]
        ]
        for pos in legPositions {
            let leg = ModelEntity(mesh: legMesh, materials: [mats.honeyOakWood])
            leg.position = pos
            benchRoot.addChild(leg)
        }
        
        // Wooden frame base
        let frameMesh = MeshResource.generateBox(size: [benchWidth, 0.025, benchLength], cornerRadius: 0.005)
        let benchFrame = ModelEntity(mesh: frameMesh, materials: [mats.honeyOakWood])
        benchFrame.position = [0, legHeight + 0.012, 0]
        benchRoot.addChild(benchFrame)
        
        // Thick Sage Green Upholstered Cushion
        let cushionHeight: Float = benchHeight - legHeight - 0.025
        let cushionMesh = MeshResource.generateBox(size: [benchWidth - 0.02, cushionHeight, benchLength - 0.02], cornerRadius: 0.02)
        let cushion = ModelEntity(mesh: cushionMesh, materials: [mats.sageGreenFabric])
        cushion.position = [0, legHeight + 0.025 + cushionHeight * 0.5, 0]
        benchRoot.addChild(cushion)
        
        // 2. Vintage Suitcase Turntable (Record Player)
        let playerWidth: Float = 0.26
        let playerLength: Float = 0.28
        let playerHeight: Float = 0.07
        let playerY: Float = legHeight + 0.025 + cushionHeight
        
        let playerRoot = Entity()
        playerRoot.position = [0, playerY, -0.06]
        playerRoot.name = "record_player"
        benchRoot.addChild(playerRoot)
        
        // Chassis (cream/pastel)
        let caseMesh = MeshResource.generateBox(size: [playerWidth, playerHeight, playerLength], cornerRadius: 0.012)
        let playerCase = ModelEntity(mesh: caseMesh, materials: [mats.creamLinenFabric])
        playerCase.position = [0, playerHeight * 0.5, 0]
        playerRoot.addChild(playerCase)
        
        // Open lid propped up at 80 degrees
        let lidMesh = MeshResource.generateBox(size: [playerWidth, 0.012, playerLength], cornerRadius: 0.008)
        let lid = ModelEntity(mesh: lidMesh, materials: [mats.creamLinenFabric])
        lid.position = [0, playerHeight + 0.10, -playerLength * 0.5 + 0.01]
        lid.orientation = simd_quatf(angle: -Float.pi * 0.42, axis: [1, 0, 0])
        playerRoot.addChild(lid)
        
        // Turntable Platter
        let platterMesh = MeshResource.generateCylinder(height: 0.006, radius: 0.09)
        let platter = ModelEntity(mesh: platterMesh, materials: [mats.brushedAluminum])
        platter.position = [-0.02, playerHeight + 0.004, 0]
        playerRoot.addChild(platter)
        
        // Black Vinyl Record
        let vinylMesh = MeshResource.generateCylinder(height: 0.003, radius: 0.085)
        let vinyl = ModelEntity(mesh: vinylMesh, materials: [mats.vinylRecord])
        vinyl.position = [0, 0.004, 0]
        platter.addChild(vinyl)
        self.vinylRecordEntity = vinyl
        
        // Red Center Record Label
        let labelMesh = MeshResource.generateCylinder(height: 0.002, radius: 0.028)
        let label = ModelEntity(mesh: labelMesh, materials: [mats.vinylLabelMaterial])
        label.position = [0, 0.002, 0]
        vinyl.addChild(label)
        
        let spindle = ModelEntity(mesh: .generateCylinder(height: 0.012, radius: 0.004), materials: [mats.warmBrass])
        spindle.position = [0, 0.006, 0]
        vinyl.addChild(spindle)
        
        // Brass Tonearm
        let armBase = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: 0.008), materials: [mats.warmBrass])
        armBase.position = [0.08, playerHeight + 0.01, -0.06]
        playerRoot.addChild(armBase)
        
        let armTube = ModelEntity(mesh: .generateCylinder(height: 0.11, radius: 0.003), materials: [mats.warmBrass])
        armTube.position = [-0.035, 0.018, 0.035]
        armTube.orientation = simd_quatf(angle: Float.pi * 0.38, axis: [0, 1, 0]) * simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        armBase.addChild(armTube)
        
        // Miniature Control Dials
        let dialMesh = MeshResource.generateCylinder(height: 0.008, radius: 0.007)
        let dial1 = ModelEntity(mesh: dialMesh, materials: [mats.warmBrass])
        dial1.position = [0.08, playerHeight + 0.005, 0.06]
        playerRoot.addChild(dial1)
        
        let dial2 = ModelEntity(mesh: dialMesh, materials: [mats.warmBrass])
        dial2.position = [0.08, playerHeight + 0.005, 0.09]
        playerRoot.addChild(dial2)
        
        // 3. Stack of Vinyl Record Albums on the bench
        for i in 0..<3 {
            let albumMesh = MeshResource.generateBox(size: [0.16, 0.012, 0.16], cornerRadius: 0.003)
            let albumMat = (i == 0) ? mats.terracottaClay : ((i == 1) ? mats.creamLinenFabric : mats.sageGreenFabric)
            let album = ModelEntity(mesh: albumMesh, materials: [albumMat])
            album.position = [0, playerY + 0.006 + Float(i) * 0.013, 0.16]
            album.orientation = simd_quatf(angle: Float(i) * 0.06, axis: [0, 1, 0])
            benchRoot.addChild(album)
        }
        
        // 4. Boucle Daisy Floor Pouf / Beanbag (Lower platform foreground right)
        // Positioned at X = +0.75, Z = +0.62, Y = lowerFloorY
        let poufRoot = Entity()
        poufRoot.position = [0.75, lowerFloorY, 0.62]
        poufRoot.name = "boucle_pouf"
        addChild(poufRoot)
        
        let poufRadius: Float = 0.22
        let poufHeight: Float = 0.16
        let poufMesh = MeshResource.generateBox(size: [poufRadius * 2.0, poufHeight, poufRadius * 2.0], cornerRadius: 0.08)
        let pouf = ModelEntity(mesh: poufMesh, materials: [mats.whiteBoucleFabric])
        pouf.position = [0, poufHeight * 0.5, 0]
        poufRoot.addChild(pouf)
        
        // Flower / Daisy tufting button on top center
        let button = ModelEntity(mesh: .generateCylinder(height: 0.018, radius: 0.038), materials: [mats.daisyYellow])
        button.position = [0, poufHeight + 0.002, 0]
        poufRoot.addChild(button)
        
        let petalMesh = MeshResource.generateSphere(radius: 0.024)
        for i in 0..<6 {
            let angle = Float(i) * (Float.pi * 2.0 / 6.0)
            let petal = ModelEntity(mesh: petalMesh, materials: [mats.whiteBoucleFabric])
            petal.position = [cos(angle) * 0.055, poufHeight, sin(angle) * 0.055]
            poufRoot.addChild(petal)
        }
    }
}

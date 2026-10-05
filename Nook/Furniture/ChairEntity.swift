import RealityKit
import AppKit

/// Builds the modern ergonomic office chair matching the reference image:
/// - Light warm-gray/cream upholstered seat cushion
/// - Curved mesh backrest with lumbar support
/// - Sleek white/cream frame and armrests
/// - Central pneumatic cylinder column
/// - Five-point star base with realistic caster wheels
@MainActor
final class ChairEntity: Entity {
    
    required init() {
        super.init()
        self.name = "ergonomic_chair"
        buildChair()
    }
    
    private func buildChair() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        
        // Positioned directly in front of the desk, angled slightly towards it
        // X = -0.58, Z = -0.05
        self.position = [-0.58, floorY, -0.05]
        self.orientation = simd_quatf(angle: -Float.pi * 0.18, axis: [0, 1, 0])
        
        // 1. Five-Point Star Base & Caster Wheels
        let baseRadius: Float = 0.22
        let armThickness: Float = 0.018
        
        for i in 0..<5 {
            let angle = Float(i) * (Float.pi * 2.0 / 5.0)
            let legMesh = MeshResource.generateBox(size: [baseRadius, armThickness, armThickness], cornerRadius: 0.004)
            let leg = ModelEntity(mesh: legMesh, materials: [mats.creamLinenFabric])
            leg.position = [cos(angle) * (baseRadius * 0.5), 0.035, sin(angle) * (baseRadius * 0.5)]
            leg.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
            addChild(leg)
            
            // Caster wheel at the tip
            let wheelMesh = MeshResource.generateCylinder(height: 0.015, radius: 0.018)
            let wheel = ModelEntity(mesh: wheelMesh, materials: [mats.vinylRecord])
            wheel.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1])
            wheel.position = [cos(angle) * baseRadius, 0.018, sin(angle) * baseRadius]
            addChild(wheel)
        }
        
        // 2. Central Pneumatic Column
        let columnMesh = MeshResource.generateCylinder(height: 0.22, radius: 0.018)
        let column = ModelEntity(mesh: columnMesh, materials: [mats.brushedAluminum])
        column.position = [0, 0.14, 0]
        addChild(column)
        
        // 3. Seat Base & Cushion
        let seatWidth: Float = 0.36
        let seatDepth: Float = 0.34
        let seatHeight: Float = 0.06
        let seatMesh = MeshResource.generateBox(size: [seatWidth, seatHeight, seatDepth], cornerRadius: 0.02)
        let seat = ModelEntity(mesh: seatMesh, materials: [mats.creamLinenFabric])
        seat.position = [0, 0.26, 0]
        addChild(seat)
        
        // 4. Curved Backrest with Lumbar Support
        let backWidth: Float = 0.32
        let backHeight: Float = 0.38
        let backThickness: Float = 0.035
        let backMesh = MeshResource.generateBox(size: [backWidth, backHeight, backThickness], cornerRadius: 0.02)
        let backrest = ModelEntity(mesh: backMesh, materials: [mats.sageGreenFabric])
        // Tilted slightly back
        backrest.position = [0, 0.44, -seatDepth * 0.5 + 0.02]
        backrest.orientation = simd_quatf(angle: -Float.pi * 0.08, axis: [1, 0, 0])
        addChild(backrest)
        
        // Back frame spine
        let spineMesh = MeshResource.generateBox(size: [0.035, 0.28, 0.025], cornerRadius: 0.005)
        let spine = ModelEntity(mesh: spineMesh, materials: [mats.creamLinenFabric])
        spine.position = [0, 0.38, -seatDepth * 0.5 - 0.01]
        addChild(spine)
        
        // 5. Left & Right Armrests
        let armrestMesh = MeshResource.generateBox(size: [0.045, 0.018, 0.22], cornerRadius: 0.008)
        let armPostMesh = MeshResource.generateCylinder(height: 0.16, radius: 0.01)
        
        // Left armrest
        let leftPost = ModelEntity(mesh: armPostMesh, materials: [mats.creamLinenFabric])
        leftPost.position = [-seatWidth * 0.5 - 0.02, 0.33, 0]
        addChild(leftPost)
        
        let leftPad = ModelEntity(mesh: armrestMesh, materials: [mats.creamLinenFabric])
        leftPad.position = [-seatWidth * 0.5 - 0.02, 0.41, 0]
        addChild(leftPad)
        
        // Right armrest
        let rightPost = ModelEntity(mesh: armPostMesh, materials: [mats.creamLinenFabric])
        rightPost.position = [seatWidth * 0.5 + 0.02, 0.33, 0]
        addChild(rightPost)
        
        let rightPad = ModelEntity(mesh: armrestMesh, materials: [mats.creamLinenFabric])
        rightPad.position = [seatWidth * 0.5 + 0.02, 0.41, 0]
        addChild(rightPad)
    }
}

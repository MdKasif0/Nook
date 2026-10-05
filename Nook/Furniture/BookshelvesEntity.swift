import RealityKit
import AppKit

/// Builds the built-in honey-oak shelving and pegboard system matching the reference image:
/// - Pegboard mounted on the Left Wall above the desk with white headphones & pinned polaroids
/// - Upper shelf above desk along Left Wall with books and plant
/// - Tall built-in bookcase on the Back Wall between desk and bed with storage box, cat figurine, alarm clock, books, and under-shelf lighting
@MainActor
final class BookshelvesEntity: Entity {
    
    private(set) var shelfLight: PointLight?
    
    required init() {
        super.init()
        self.name = "built_in_shelving"
        buildShelving()
    }
    
    private func buildShelving() {
        let mats = RoomMaterials.shared
        let floorY = RoomArchitectureEntity.upperFloorY
        
        let leftWallX: Float = -1.16
        let backWallZ: Float = -1.16
        let shelfThickness: Float = 0.028
        let shelfDepth: Float = 0.20
        
        // 1. Pegboard Mounted on Left Wall Above Desk
        let pegboardWidth: Float = 0.58  // along Z
        let pegboardHeight: Float = 0.44
        let pegboardMesh = MeshResource.generateBox(size: [0.015, pegboardHeight, pegboardWidth], cornerRadius: 0.005)
        let pegboard = ModelEntity(mesh: pegboardMesh, materials: [mats.pegboardPatternMaterial])
        pegboard.position = [leftWallX + 0.01, floorY + DeskEntity.deskHeight + 0.32, -0.32]
        pegboard.name = "desk_pegboard"
        addChild(pegboard)
        
        // White Over-Ear Headphones hanging on peg
        let headphoneMesh = MeshResource.generateCylinder(height: 0.04, radius: 0.035)
        let leftCup = ModelEntity(mesh: headphoneMesh, materials: [mats.creamLinenFabric])
        leftCup.position = [0.025, 0.06, 0.15]
        
        let rightCup = ModelEntity(mesh: headphoneMesh, materials: [mats.creamLinenFabric])
        rightCup.position = [0.025, 0.06, 0.23]
        
        let headband = ModelEntity(mesh: .generateCylinder(height: 0.08, radius: 0.005), materials: [mats.brushedAluminum])
        headband.position = [0.025, 0.10, 0.19]
        headband.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        
        pegboard.addChild(leftCup)
        pegboard.addChild(rightCup)
        pegboard.addChild(headband)
        
        // Pinned Polaroid Photo Prints on Pegboard
        let photo1 = ModelEntity(mesh: .generateBox(size: [0.003, 0.07, 0.06], cornerRadius: 0.002), materials: [mats.creamLinenFabric])
        photo1.position = [0.01, 0.08, -0.15]
        photo1.orientation = simd_quatf(angle: Float.pi * 0.06, axis: [1, 0, 0])
        pegboard.addChild(photo1)
        
        let photo2 = ModelEntity(mesh: .generateBox(size: [0.003, 0.07, 0.06], cornerRadius: 0.002), materials: [mats.botanicalArt1Material])
        photo2.position = [0.01, -0.05, -0.16]
        pegboard.addChild(photo2)
        
        // Small Yellow Sticky Note
        let sticky = ModelEntity(mesh: .generateBox(size: [0.002, 0.045, 0.045], cornerRadius: 0.002), materials: [mats.daisyYellow])
        sticky.position = [0.01, 0.02, -0.04]
        pegboard.addChild(sticky)
        
        // 2. Upper Shelf Above Desk along Left Wall
        let deskShelfLength: Float = 0.95
        let upperDeskShelf = ModelEntity(
            mesh: .generateBox(size: [shelfDepth, shelfThickness, deskShelfLength], cornerRadius: 0.006),
            materials: [mats.honeyOakWood]
        )
        upperDeskShelf.position = [leftWallX + shelfDepth * 0.5, floorY + DeskEntity.deskHeight + 0.60, -0.32]
        upperDeskShelf.name = "shelf_desk_upper"
        addChild(upperDeskShelf)
        
        // Books on Upper Desk Shelf
        buildBooksRowZ(on: upperDeskShelf, startZ: -0.35, count: 7, materials: mats)
        
        // Potted Plant on Upper Desk Shelf
        let shelfPlantPot = ModelEntity(mesh: .generateCylinder(height: 0.06, radius: 0.038), materials: [mats.glazedWhiteCeramic])
        shelfPlantPot.position = [0, shelfThickness * 0.5 + 0.03, 0.25]
        let shelfFoliage = ModelEntity(mesh: .generateSphere(radius: 0.042), materials: [mats.foliageLight])
        shelfFoliage.position = [0, 0.035, 0]
        shelfPlantPot.addChild(shelfFoliage)
        upperDeskShelf.addChild(shelfPlantPot)
        
        // 3. Tall Built-in Bookcase on Back Wall (between desk corner and bed)
        let bookcaseWidth: Float = 0.55  // along X
        let bookcaseCenterX: Float = -0.35
        let bookcaseShelfY: [Float] = [
            floorY + DeskEntity.deskHeight + 0.35,
            floorY + DeskEntity.deskHeight + 0.60,
            floorY + DeskEntity.deskHeight + 0.88
        ]
        
        for (i, y) in bookcaseShelfY.enumerated() {
            let shelf = ModelEntity(
                mesh: .generateBox(size: [bookcaseWidth, shelfThickness, shelfDepth], cornerRadius: 0.006),
                materials: [mats.honeyOakWood]
            )
            shelf.position = [bookcaseCenterX, y, backWallZ + shelfDepth * 0.5]
            shelf.name = "bookcase_shelf_\(i + 1)"
            addChild(shelf)
            
            if i == 0 {
                // Lower shelf: Books and vintage brass alarm clock
                buildBooksRowX(on: shelf, startX: -0.22, count: 5, materials: mats)
                
                let clock = buildAlarmClock(materials: mats)
                clock.position = [0.15, shelfThickness * 0.5 + 0.05, 0]
                shelf.addChild(clock)
            } else if i == 1 {
                // Middle shelf: Stack of horizontal books and cute ceramic cat head
                buildBooksRowX(on: shelf, startX: 0.02, count: 4, materials: mats)
                
                for b in 0..<3 {
                    let book = ModelEntity(
                        mesh: .generateBox(size: [0.14, 0.022, 0.11], cornerRadius: 0.003),
                        materials: [b % 2 == 0 ? mats.terracottaClay : mats.sageGreenFabric]
                    )
                    book.position = [-0.14, shelfThickness * 0.5 + 0.011 + Float(b) * 0.024, 0]
                    shelf.addChild(book)
                }
            } else if i == 2 {
                // Top shelf: Lidded storage box and white cat figurine
                let boxMesh = MeshResource.generateBox(size: [0.22, 0.14, 0.16], cornerRadius: 0.008)
                let storageBox = ModelEntity(mesh: boxMesh, materials: [mats.honeyOakWood])
                storageBox.position = [0.10, shelfThickness * 0.5 + 0.07, 0]
                shelf.addChild(storageBox)
                
                let catFigurine = buildCatHeadFigurine(materials: mats)
                catFigurine.position = [-0.14, shelfThickness * 0.5 + 0.045, 0]
                shelf.addChild(catFigurine)
            }
        }
        
        // 4. Built-in Under-Shelf Warm LED Light Strip
        let light = PointLight()
        light.light.color = .init(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0)
        light.light.intensity = 1400
        light.light.attenuationRadius = 1.6
        light.position = [bookcaseCenterX, bookcaseShelfY[1] - 0.03, backWallZ + shelfDepth * 0.5]
        light.name = "under_shelf_light"
        addChild(light)
        self.shelfLight = light
    }
    
    private func buildBooksRowZ(on parent: Entity, startZ: Float, count: Int, materials: RoomMaterials) {
        let bookMaterials = [materials.creamLinenFabric, materials.terracottaClay, materials.sageGreenFabric, materials.honeyOakWood]
        var curZ = startZ
        for i in 0..<count {
            let depth: Float = Float.random(in: 0.025...0.038)
            let height: Float = Float.random(in: 0.14...0.19)
            let width: Float = 0.13
            let mat = bookMaterials[i % bookMaterials.count]
            let book = ModelEntity(mesh: .generateBox(size: [width, height, depth], cornerRadius: 0.003), materials: [mat])
            book.position = [0, 0.014 + height * 0.5, curZ + depth * 0.5]
            parent.addChild(book)
            curZ += depth + 0.003
        }
    }
    
    private func buildBooksRowX(on parent: Entity, startX: Float, count: Int, materials: RoomMaterials) {
        let bookMaterials = [materials.creamLinenFabric, materials.terracottaClay, materials.sageGreenFabric, materials.honeyOakWood]
        var curX = startX
        for i in 0..<count {
            let width: Float = Float.random(in: 0.025...0.038)
            let height: Float = Float.random(in: 0.14...0.19)
            let depth: Float = 0.13
            let mat = bookMaterials[i % bookMaterials.count]
            let book = ModelEntity(mesh: .generateBox(size: [width, height, depth], cornerRadius: 0.003), materials: [mat])
            book.position = [curX + width * 0.5, 0.014 + height * 0.5, 0]
            parent.addChild(book)
            curX += width + 0.003
        }
    }
    
    private func buildAlarmClock(materials: RoomMaterials) -> Entity {
        let clockRoot = Entity()
        clockRoot.name = "alarm_clock"
        let body = ModelEntity(mesh: .generateCylinder(height: 0.035, radius: 0.04), materials: [materials.warmBrass])
        body.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        clockRoot.addChild(body)
        
        let face = ModelEntity(mesh: .generatePlane(width: 0.07, depth: 0.07, cornerRadius: 0.035), materials: [materials.creamLinenFabric])
        face.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        face.position = [0, 0, 0.018]
        clockRoot.addChild(face)
        
        let leftBell = ModelEntity(mesh: .generateSphere(radius: 0.014), materials: [materials.warmBrass])
        leftBell.position = [-0.025, 0.045, 0]
        clockRoot.addChild(leftBell)
        
        let rightBell = ModelEntity(mesh: .generateSphere(radius: 0.014), materials: [materials.warmBrass])
        rightBell.position = [0.025, 0.045, 0]
        clockRoot.addChild(rightBell)
        
        return clockRoot
    }
    
    private func buildCatHeadFigurine(materials: RoomMaterials) -> Entity {
        let catRoot = Entity()
        catRoot.name = "cat_figurine"
        let head = ModelEntity(mesh: .generateSphere(radius: 0.042), materials: [materials.glazedWhiteCeramic])
        catRoot.addChild(head)
        
        let leftEar = ModelEntity(mesh: .generateBox(size: [0.022, 0.028, 0.018], cornerRadius: 0.004), materials: [materials.glazedWhiteCeramic])
        leftEar.position = [-0.025, 0.038, 0]
        leftEar.orientation = simd_quatf(angle: Float.pi * 0.2, axis: [0, 0, 1])
        catRoot.addChild(leftEar)
        
        let rightEar = ModelEntity(mesh: .generateBox(size: [0.022, 0.028, 0.018], cornerRadius: 0.004), materials: [materials.glazedWhiteCeramic])
        rightEar.position = [0.025, 0.038, 0]
        rightEar.orientation = simd_quatf(angle: -Float.pi * 0.2, axis: [0, 0, 1])
        catRoot.addChild(rightEar)
        
        return catRoot
    }
}

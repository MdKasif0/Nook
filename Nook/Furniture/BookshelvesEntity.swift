import RealityKit
import AppKit

/// Builds the built-in honey-oak shelving and back wall pegboard system matching the reference image:
/// - Wall shelving above the desk and bed
/// - Muted books (cream, terracotta, muted sage, warm gray)
/// - Wooden storage box with lid
/// - Cute ceramic cat head figurine
/// - Vintage brass twin-bell alarm clock
/// - Framed mini photo prints
/// - Pegboard mounted above desk with hanging white over-ear headphones and polaroids
/// - Built-in warm under-shelf light strips
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
        
        // Shelving mounted against the back wall (Z = -1.18)
        let shelfZ: Float = -1.18
        
        // 1. Pegboard Mounted on Back Wall Above Desk
        let pegboardWidth: Float = 0.58
        let pegboardHeight: Float = 0.44
        let pegboardMesh = MeshResource.generateBox(size: [pegboardWidth, pegboardHeight, 0.015], cornerRadius: 0.005)
        let pegboard = ModelEntity(mesh: pegboardMesh, materials: [mats.pegboardPatternMaterial])
        pegboard.position = [-0.72, floorY + DeskEntity.deskHeight + 0.32, shelfZ + 0.01]
        pegboard.name = "desk_pegboard"
        addChild(pegboard)
        
        // White Over-Ear Headphones hanging on peg
        let headphoneMesh = MeshResource.generateCylinder(height: 0.04, radius: 0.035)
        let leftCup = ModelEntity(mesh: headphoneMesh, materials: [mats.creamLinenFabric])
        leftCup.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1])
        leftCup.position = [0.15, 0.06, 0.025]
        
        let rightCup = ModelEntity(mesh: headphoneMesh, materials: [mats.creamLinenFabric])
        rightCup.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [0, 0, 1])
        rightCup.position = [0.23, 0.06, 0.025]
        
        let headband = ModelEntity(mesh: .generateCylinder(height: 0.08, radius: 0.005), materials: [mats.brushedAluminum])
        headband.position = [0.19, 0.10, 0.025]
        headband.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        
        pegboard.addChild(leftCup)
        pegboard.addChild(rightCup)
        pegboard.addChild(headband)
        
        // Pinned Polaroid Photo Prints on Pegboard
        let photo1 = ModelEntity(mesh: .generateBox(size: [0.06, 0.07, 0.003], cornerRadius: 0.002), materials: [mats.creamLinenFabric])
        photo1.position = [-0.15, 0.08, 0.01]
        photo1.orientation = simd_quatf(angle: Float.pi * 0.06, axis: [0, 0, 1])
        pegboard.addChild(photo1)
        
        let photo2 = ModelEntity(mesh: .generateBox(size: [0.06, 0.07, 0.003], cornerRadius: 0.002), materials: [mats.botanicalArt1Material])
        photo2.position = [-0.16, -0.05, 0.01]
        pegboard.addChild(photo2)
        
        // Small Yellow Sticky Note
        let sticky = ModelEntity(mesh: .generateBox(size: [0.045, 0.045, 0.002], cornerRadius: 0.002), materials: [mats.daisyYellow])
        sticky.position = [-0.04, 0.02, 0.01]
        sticky.orientation = simd_quatf(angle: -Float.pi * 0.08, axis: [0, 0, 1])
        pegboard.addChild(sticky)
        
        // 2. Upper Shelves Above Desk (Running horizontally)
        let deskShelfWidth: Float = 0.95
        let shelfDepth: Float = 0.22
        let shelfThickness: Float = 0.028
        
        let upperDeskShelf = ModelEntity(
            mesh: .generateBox(size: [deskShelfWidth, shelfThickness, shelfDepth], cornerRadius: 0.006),
            materials: [mats.honeyOakWood]
        )
        upperDeskShelf.position = [-0.72, floorY + DeskEntity.deskHeight + 0.60, shelfZ + shelfDepth * 0.5]
        upperDeskShelf.name = "shelf_desk_upper"
        addChild(upperDeskShelf)
        
        // Books on Upper Desk Shelf
        buildBooksRow(on: upperDeskShelf, startX: -0.38, count: 8, materials: mats)
        
        // Potted Plant on Upper Desk Shelf
        let shelfPlantPot = ModelEntity(mesh: .generateCylinder(height: 0.06, radius: 0.038), materials: [mats.glazedWhiteCeramic])
        shelfPlantPot.position = [0.12, shelfThickness * 0.5 + 0.03, 0]
        let shelfFoliage = ModelEntity(mesh: .generateSphere(radius: 0.042), materials: [mats.foliageLight])
        shelfFoliage.position = [0, 0.035, 0]
        shelfPlantPot.addChild(shelfFoliage)
        upperDeskShelf.addChild(shelfPlantPot)
        
        // 3. Tall Built-in Bookcase Above Bed & Center Wall
        let bookcaseWidth: Float = 0.92
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
            shelf.position = [0.35, y, shelfZ + shelfDepth * 0.5]
            shelf.name = "bookcase_shelf_\(i + 1)"
            addChild(shelf)
            
            if i == 0 {
                // Lower shelf: Books and vintage brass alarm clock
                buildBooksRow(on: shelf, startX: -0.32, count: 6, materials: mats)
                
                // Vintage Brass Twin-Bell Alarm Clock
                let clock = buildAlarmClock(materials: mats)
                clock.position = [0.22, shelfThickness * 0.5 + 0.05, 0]
                shelf.addChild(clock)
                
                // Small framed print
                let frame = ModelEntity(mesh: .generateBox(size: [0.10, 0.12, 0.012], cornerRadius: 0.003), materials: [mats.honeyOakWood])
                frame.position = [0.02, shelfThickness * 0.5 + 0.06, -0.02]
                shelf.addChild(frame)
            } else if i == 1 {
                // Middle shelf: Stack of horizontal books and cute ceramic cat head
                buildBooksRow(on: shelf, startX: 0.05, count: 5, materials: mats)
                
                // Stack of 3 horizontal books
                for b in 0..<3 {
                    let book = ModelEntity(
                        mesh: .generateBox(size: [0.14, 0.022, 0.11], cornerRadius: 0.003),
                        materials: [b % 2 == 0 ? mats.terracottaClay : mats.sageGreenFabric]
                    )
                    book.position = [-0.22, shelfThickness * 0.5 + 0.011 + Float(b) * 0.024, 0]
                    shelf.addChild(book)
                }
            } else if i == 2 {
                // Top shelf: Lidded storage box and white cat figurine
                let boxMesh = MeshResource.generateBox(size: [0.28, 0.16, 0.18], cornerRadius: 0.008)
                let storageBox = ModelEntity(mesh: boxMesh, materials: [mats.honeyOakWood])
                storageBox.position = [0.18, shelfThickness * 0.5 + 0.08, 0]
                shelf.addChild(storageBox)
                
                // Ceramic Cat Head Figurine
                let catFigurine = buildCatHeadFigurine(materials: mats)
                catFigurine.position = [-0.18, shelfThickness * 0.5 + 0.045, 0]
                shelf.addChild(catFigurine)
            }
        }
        
        // 4. Built-in Under-Shelf Warm LED Light Strip
        let light = PointLight()
        light.light.color = .init(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0)
        light.light.intensity = 1200
        light.light.attenuationRadius = 1.6
        light.position = [0.25, bookcaseShelfY[1] - 0.03, shelfZ + shelfDepth * 0.5]
        light.name = "under_shelf_light"
        addChild(light)
        self.shelfLight = light
    }
    
    // Builds a neat vertical row of books with varied muted colors and heights
    private func buildBooksRow(on parent: Entity, startX: Float, count: Int, materials: RoomMaterials) {
        let bookMaterials = [
            materials.creamLinenFabric,
            materials.terracottaClay,
            materials.sageGreenFabric,
            materials.honeyOakWood,
            materials.creamLinenFabric
        ]
        
        var curX = startX
        for i in 0..<count {
            let width: Float = Float.random(in: 0.025...0.038)
            let height: Float = Float.random(in: 0.14...0.19)
            let depth: Float = 0.13
            let mat = bookMaterials[i % bookMaterials.count]
            
            let bookMesh = MeshResource.generateBox(size: [width, height, depth], cornerRadius: 0.003)
            let book = ModelEntity(mesh: bookMesh, materials: [mat])
            book.position = [curX + width * 0.5, 0.014 + height * 0.5, 0]
            parent.addChild(book)
            curX += width + 0.003
        }
    }
    
    // Builds a vintage brass round alarm clock with twin bells
    private func buildAlarmClock(materials: RoomMaterials) -> Entity {
        let clockRoot = Entity()
        clockRoot.name = "alarm_clock"
        
        // Round clock body
        let bodyMesh = MeshResource.generateCylinder(height: 0.035, radius: 0.04)
        let body = ModelEntity(mesh: bodyMesh, materials: [materials.warmBrass])
        body.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        clockRoot.addChild(body)
        
        // Clock face (cream)
        let faceMesh = MeshResource.generatePlane(width: 0.07, depth: 0.07, cornerRadius: 0.035)
        let face = ModelEntity(mesh: faceMesh, materials: [materials.creamLinenFabric])
        face.orientation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
        face.position = [0, 0, 0.018]
        clockRoot.addChild(face)
        
        // Twin bells on top
        let bellMesh = MeshResource.generateSphere(radius: 0.014)
        let leftBell = ModelEntity(mesh: bellMesh, materials: [materials.warmBrass])
        leftBell.position = [-0.025, 0.045, 0]
        clockRoot.addChild(leftBell)
        
        let rightBell = ModelEntity(mesh: bellMesh, materials: [materials.warmBrass])
        rightBell.position = [0.025, 0.045, 0]
        clockRoot.addChild(rightBell)
        
        // Two angled peg legs
        let legMesh = MeshResource.generateCylinder(height: 0.025, radius: 0.003)
        let leftLeg = ModelEntity(mesh: legMesh, materials: [materials.warmBrass])
        leftLeg.position = [-0.028, -0.04, 0]
        leftLeg.orientation = simd_quatf(angle: Float.pi * 0.15, axis: [0, 0, 1])
        clockRoot.addChild(leftLeg)
        
        let rightLeg = ModelEntity(mesh: legMesh, materials: [materials.warmBrass])
        rightLeg.position = [0.028, -0.04, 0]
        rightLeg.orientation = simd_quatf(angle: -Float.pi * 0.15, axis: [0, 0, 1])
        clockRoot.addChild(rightLeg)
        
        return clockRoot
    }
    
    // Builds a cute ceramic cat head figurine
    private func buildCatHeadFigurine(materials: RoomMaterials) -> Entity {
        let catRoot = Entity()
        catRoot.name = "cat_figurine"
        
        // Rounded head
        let headMesh = MeshResource.generateSphere(radius: 0.042)
        let head = ModelEntity(mesh: headMesh, materials: [materials.glazedWhiteCeramic])
        catRoot.addChild(head)
        
        // Pointy ears
        let earMesh = MeshResource.generateBox(size: [0.022, 0.028, 0.018], cornerRadius: 0.004)
        let leftEar = ModelEntity(mesh: earMesh, materials: [materials.glazedWhiteCeramic])
        leftEar.position = [-0.025, 0.038, 0]
        leftEar.orientation = simd_quatf(angle: Float.pi * 0.2, axis: [0, 0, 1])
        catRoot.addChild(leftEar)
        
        let rightEar = ModelEntity(mesh: earMesh, materials: [materials.glazedWhiteCeramic])
        rightEar.position = [0.025, 0.038, 0]
        rightEar.orientation = simd_quatf(angle: -Float.pi * 0.2, axis: [0, 0, 1])
        catRoot.addChild(rightEar)
        
        return catRoot
    }
}

import SceneKit
import SwiftUI

/// Builds the procedural 3D miniature room diorama using native SceneKit.
///
/// Implements a cozy, dollhouse-style cutaway room featuring:
/// - Back wall and left wall with window
/// - Warm hardwood floor
/// - Window with dynamic outdoor landscape and natural sunlight
/// - Detailed wooden desk as the main focal point
/// - Spindle-back wooden chair
/// - Bookshelf with miniature colorful books
/// - Cozy desk lamp with toggleable warm illumination
/// - Desk accessories (blotter, pencil cup, potted plants)
/// - Cookie's relaxing area with woven rug and curled sleeping cat
final class RoomDioramaBuilder {
    
    // MARK: - Dimensions & Constants
    
    static let roomWidth: CGFloat = 4.4     // X axis (left to right)
    static let roomDepth: CGFloat = 4.0     // Z axis (front to back)
    static let wallHeight: CGFloat = 3.2    // Y axis (floor to ceiling)
    
    // Desk surface coordinate reference
    static let deskSurfaceY: CGFloat = 1.15
    static let deskPosition = SCNVector3(x: 0.1, y: 0.0, z: -0.3)
    
    // MARK: - Scene Construction
    
    /// Constructs the complete room diorama inside the target scene.
    static func buildDiorama(
        in scene: SCNScene,
        environment: RoomTimeOfDay = .morning,
        reduceMotion: Bool = false
    ) -> (lampLight: SCNLight, sunLight: SCNLight, ambientLight: SCNLight, outdoorSkyNode: SCNNode) {
        
        let root = scene.rootNode
        
        // 1. Architecture (Floor, Walls, Trim)
        buildArchitecture(in: root)
        
        // 2. Window & Outdoor Landscape
        let skyNode = buildWindowAndOutdoors(in: root, environment: environment)
        
        // 3. Wooden Desk & Chair (Main Focal Point)
        let lampLight = buildDeskAndChair(in: root, environment: environment)
        
        // 4. Bookshelf & Wall Decor
        buildBookshelf(in: root)
        
        // 5. Cookie's Sleeping Area (Rug & Curled Cat)
        buildCookieArea(in: root, reduceMotion: reduceMotion)
        
        // 6. Lighting & Environment
        let (sunLight, ambientLight) = setupLighting(in: root, environment: environment)
        
        // 7. Isometric Camera
        setupCamera(in: root)
        
        return (lampLight, sunLight, ambientLight, skyNode)
    }
    
    // MARK: - 1. Architecture
    
    private static func buildArchitecture(in root: SCNNode) {
        // Floor — Warm natural hardwood
        let floorGeo = SCNBox(width: roomWidth, height: 0.15, length: roomDepth, chamferRadius: 0.02)
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = NSColor(red: 0.72, green: 0.60, blue: 0.48, alpha: 1.0) // Warm honey oak
        floorMat.roughness.contents = 0.5
        floorMat.specular.contents = NSColor(white: 0.15, alpha: 1.0)
        floorGeo.materials = [floorMat]
        
        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.position = SCNVector3(0, -0.075, 0)
        floorNode.name = "room_floor"
        root.addChildNode(floorNode)
        
        // Back Wall — Soft cream plaster
        let backWallGeo = SCNBox(width: roomWidth, height: wallHeight, length: 0.12, chamferRadius: 0.01)
        let wallMat = SCNMaterial()
        wallMat.diffuse.contents = NSColor(red: 0.965, green: 0.95, blue: 0.92, alpha: 1.0) // Warm ivory cream
        wallMat.roughness.contents = 0.92
        backWallGeo.materials = [wallMat]
        
        let backWallNode = SCNNode(geometry: backWallGeo)
        backWallNode.position = SCNVector3(0, wallHeight / 2, -roomDepth / 2 - 0.06)
        backWallNode.name = "room_back_wall"
        root.addChildNode(backWallNode)
        
        // Left Wall — With window opening cutaway
        let leftWallBottom = SCNBox(width: 0.12, height: 1.0, length: roomDepth, chamferRadius: 0.01)
        leftWallBottom.materials = [wallMat]
        let leftWallBottomNode = SCNNode(geometry: leftWallBottom)
        leftWallBottomNode.position = SCNVector3(-roomWidth / 2 - 0.06, 0.5, 0)
        root.addChildNode(leftWallBottomNode)
        
        let leftWallTop = SCNBox(width: 0.12, height: 0.8, length: roomDepth, chamferRadius: 0.01)
        leftWallTop.materials = [wallMat]
        let leftWallTopNode = SCNNode(geometry: leftWallTop)
        leftWallTopNode.position = SCNVector3(-roomWidth / 2 - 0.06, wallHeight - 0.4, 0)
        root.addChildNode(leftWallTopNode)
        
        let leftWallBackSide = SCNBox(width: 0.12, height: 1.4, length: 0.9, chamferRadius: 0.01)
        leftWallBackSide.materials = [wallMat]
        let leftWallBackSideNode = SCNNode(geometry: leftWallBackSide)
        leftWallBackSideNode.position = SCNVector3(-roomWidth / 2 - 0.06, 1.7, -1.55)
        root.addChildNode(leftWallBackSideNode)
        
        let leftWallFrontSide = SCNBox(width: 0.12, height: 1.4, length: 0.9, chamferRadius: 0.01)
        leftWallFrontSide.materials = [wallMat]
        let leftWallFrontSideNode = SCNNode(geometry: leftWallFrontSide)
        leftWallFrontSideNode.position = SCNVector3(-roomWidth / 2 - 0.06, 1.7, 1.55)
        root.addChildNode(leftWallFrontSideNode)
        
        // Molded Baseboards (Warm off-white trim)
        let trimMat = SCNMaterial()
        trimMat.diffuse.contents = NSColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0)
        trimMat.roughness.contents = 0.6
        
        let backBaseboard = SCNBox(width: roomWidth, height: 0.12, length: 0.03, chamferRadius: 0.005)
        backBaseboard.materials = [trimMat]
        let backBaseboardNode = SCNNode(geometry: backBaseboard)
        backBaseboardNode.position = SCNVector3(0, 0.06, -roomDepth / 2 + 0.015)
        root.addChildNode(backBaseboardNode)
        
        let leftBaseboard = SCNBox(width: 0.03, height: 0.12, length: roomDepth, chamferRadius: 0.005)
        leftBaseboard.materials = [trimMat]
        let leftBaseboardNode = SCNNode(geometry: leftBaseboard)
        leftBaseboardNode.position = SCNVector3(-roomWidth / 2 + 0.015, 0.06, 0)
        root.addChildNode(leftBaseboardNode)
    }
    
    // MARK: - 2. Window & Outdoors
    
    private static func buildWindowAndOutdoors(in root: SCNNode, environment: RoomTimeOfDay) -> SCNNode {
        let windowGroup = SCNNode()
        windowGroup.position = SCNVector3(-roomWidth / 2, 1.7, 0)
        
        let frameMat = SCNMaterial()
        frameMat.diffuse.contents = NSColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 1.0) // Painted wood frame
        frameMat.roughness.contents = 0.7
        
        // Window Sill
        let sill = SCNBox(width: 0.22, height: 0.05, length: 2.3, chamferRadius: 0.008)
        sill.materials = [frameMat]
        let sillNode = SCNNode(geometry: sill)
        sillNode.position = SCNVector3(0.04, -0.7, 0)
        windowGroup.addChildNode(sillNode)
        
        // Window Mullions / Crossbars
        let vBar = SCNBox(width: 0.06, height: 1.4, length: 0.05, chamferRadius: 0.004)
        vBar.materials = [frameMat]
        let vBarNode = SCNNode(geometry: vBar)
        windowGroup.addChildNode(vBarNode)
        
        let hBar = SCNBox(width: 0.06, height: 0.05, length: 2.2, chamferRadius: 0.004)
        hBar.materials = [frameMat]
        let hBarNode = SCNNode(geometry: hBar)
        windowGroup.addChildNode(hBarNode)
        
        // Window Panes (Subtle glass)
        let glass = SCNBox(width: 0.02, height: 1.35, length: 2.15, chamferRadius: 0.002)
        let glassMat = SCNMaterial()
        glassMat.diffuse.contents = NSColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.25)
        glassMat.roughness.contents = 0.1
        glassMat.transparency = 0.35
        glass.materials = [glassMat]
        let glassNode = SCNNode(geometry: glass)
        windowGroup.addChildNode(glassNode)
        
        // Outdoor Sky & Landscape Plane directly behind window glass
        let skyPlane = SCNPlane(width: 2.25, height: 1.45)
        let skyMat = SCNMaterial()
        skyMat.diffuse.contents = environment.skyTopColor
        skyMat.lightingModel = .constant
        skyPlane.materials = [skyMat]
        
        let skyNode = SCNNode(geometry: skyPlane)
        skyNode.position = SCNVector3(-0.08, 0, 0)
        skyNode.eulerAngles.y = .pi / 2
        skyNode.name = "outdoor_sky_node"
        windowGroup.addChildNode(skyNode)
        
        // Distant rolling green hills outside seen through window
        let hillGeo = SCNSphere(radius: 1.1)
        let hillMat = SCNMaterial()
        hillMat.diffuse.contents = NSColor(red: 0.44, green: 0.62, blue: 0.42, alpha: 1.0) // Soft sage hills
        hillMat.lightingModel = .constant
        hillGeo.materials = [hillMat]
        let hillNode = SCNNode(geometry: hillGeo)
        hillNode.position = SCNVector3(-0.22, -0.75, -0.15)
        windowGroup.addChildNode(hillNode)
        
        // Cute miniature succulent on the window sill
        let pot = SCNCylinder(radius: 0.045, height: 0.07)
        let potMat = SCNMaterial()
        potMat.diffuse.contents = NSColor(red: 0.76, green: 0.52, blue: 0.40, alpha: 1.0) // Terracotta pot
        pot.materials = [potMat]
        let potNode = SCNNode(geometry: pot)
        potNode.position = SCNVector3(0.06, -0.64, 0.6)
        
        let plantBall = SCNSphere(radius: 0.048)
        let plantMat = SCNMaterial()
        plantMat.diffuse.contents = NSColor(red: 0.38, green: 0.58, blue: 0.36, alpha: 1.0) // Sage succulent
        plantBall.materials = [plantMat]
        let plantNode = SCNNode(geometry: plantBall)
        plantNode.position = SCNVector3(0, 0.05, 0)
        potNode.addChildNode(plantNode)
        windowGroup.addChildNode(potNode)
        
        root.addChildNode(windowGroup)
        return skyNode
    }
    
    // MARK: - 3. Wooden Desk & Chair (Main Focal Point)
    
    private static func buildDeskAndChair(in root: SCNNode, environment: RoomTimeOfDay) -> SCNLight {
        let deskGroup = SCNNode()
        deskGroup.position = deskPosition
        deskGroup.name = "desk_group"
        
        // Desk Materials
        let woodMat = SCNMaterial()
        woodMat.diffuse.contents = NSColor(red: 0.64, green: 0.48, blue: 0.34, alpha: 1.0) // Warm walnut/oak
        woodMat.roughness.contents = 0.55
        woodMat.specular.contents = NSColor(white: 0.2, alpha: 1.0)
        
        let brassMat = SCNMaterial()
        brassMat.diffuse.contents = NSColor(red: 0.82, green: 0.72, blue: 0.48, alpha: 1.0) // Muted brushed brass
        brassMat.metalness.contents = 0.7
        brassMat.roughness.contents = 0.35
        
        // Tabletop (Thick beveled wooden slab)
        let tabletop = SCNBox(width: 2.2, height: 0.08, length: 1.25, chamferRadius: 0.02)
        tabletop.materials = [woodMat]
        let tabletopNode = SCNNode(geometry: tabletop)
        tabletopNode.position = SCNVector3(0, deskSurfaceY - 0.04, 0)
        tabletopNode.name = "desk_tabletop"
        deskGroup.addChildNode(tabletopNode)
        
        // Left Tapered Legs (Slender wooden legs with brass caps)
        let legPositions: [(CGFloat, CGFloat)] = [
            (-0.95, -0.48), (-0.95, 0.48)
        ]
        for (lx, lz) in legPositions {
            let leg = SCNCylinder(radius: 0.032, height: deskSurfaceY - 0.08)
            leg.materials = [woodMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(lx, (deskSurfaceY - 0.08) / 2, lz)
            deskGroup.addChildNode(legNode)
            
            // Brass bottom ferrule
            let cap = SCNCylinder(radius: 0.034, height: 0.05)
            cap.materials = [brassMat]
            let capNode = SCNNode(geometry: cap)
            capNode.position = SCNVector3(lx, 0.025, lz)
            deskGroup.addChildNode(capNode)
        }
        
        // Right Side: Storage Drawer Cabinet Unit
        let drawerBox = SCNBox(width: 0.55, height: deskSurfaceY - 0.16, length: 1.05, chamferRadius: 0.015)
        drawerBox.materials = [woodMat]
        let drawerUnitNode = SCNNode(geometry: drawerBox)
        drawerUnitNode.position = SCNVector3(0.72, (deskSurfaceY - 0.16) / 2 + 0.04, 0)
        deskGroup.addChildNode(drawerUnitNode)
        
        // Drawer Knobs (Brushed brass)
        for dy in [0.35, 0.65, 0.95] {
            let knob = SCNSphere(radius: 0.022)
            knob.materials = [brassMat]
            let knobNode = SCNNode(geometry: knob)
            knobNode.position = SCNVector3(0.72, CGFloat(dy), 0.53)
            deskGroup.addChildNode(knobNode)
        }
        
        // Leather Desk Blotter (Centered writing surface)
        let blotter = SCNBox(width: 1.05, height: 0.008, length: 0.68, chamferRadius: 0.02)
        let blotterMat = SCNMaterial()
        blotterMat.diffuse.contents = NSColor(red: 0.52, green: 0.56, blue: 0.48, alpha: 1.0) // Muted sage leather
        blotterMat.roughness.contents = 0.85
        blotter.materials = [blotterMat]
        let blotterNode = SCNNode(geometry: blotter)
        blotterNode.position = SCNVector3(-0.15, deskSurfaceY + 0.004, 0.05)
        deskGroup.addChildNode(blotterNode)
        
        // Desk Lamp (Brass stem with cream dome shade)
        let lampNode = SCNNode()
        lampNode.position = SCNVector3(-0.85, deskSurfaceY, -0.35)
        lampNode.name = "desk_lamp"
        
        let lampBase = SCNCylinder(radius: 0.08, height: 0.02)
        lampBase.materials = [brassMat]
        let lampBaseNode = SCNNode(geometry: lampBase)
        lampBaseNode.position = SCNVector3(0, 0.01, 0)
        lampNode.addChildNode(lampBaseNode)
        
        let lampStem = SCNCylinder(radius: 0.014, height: 0.42)
        lampStem.materials = [brassMat]
        let lampStemNode = SCNNode(geometry: lampStem)
        lampStemNode.position = SCNVector3(0.04, 0.22, 0)
        lampStemNode.eulerAngles.z = -0.15
        lampNode.addChildNode(lampStemNode)
        
        let shade = SCNCylinder(radius: 0.085, height: 0.09)
        let shadeMat = SCNMaterial()
        shadeMat.diffuse.contents = NSColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1.0) // Warm cream enamel
        shadeMat.roughness.contents = 0.4
        shade.materials = [shadeMat]
        let shadeNode = SCNNode(geometry: shade)
        shadeNode.position = SCNVector3(0.12, 0.40, 0)
        shadeNode.eulerAngles.z = -0.45
        lampNode.addChildNode(shadeNode)
        
        // Desk Lamp Light Source
        let lampLight = SCNLight()
        lampLight.type = .spot
        lampLight.color = NSColor(red: 1.0, green: 0.88, blue: 0.68, alpha: 1.0)
        lampLight.intensity = environment.isDeskLampDefaultOn ? 900 : 0
        lampLight.spotInnerAngle = 35
        lampLight.spotOuterAngle = 65
        lampLight.castsShadow = true
        lampLight.shadowRadius = 2.0
        
        let lampLightNode = SCNNode()
        lampLightNode.light = lampLight
        lampLightNode.position = SCNVector3(0.12, 0.38, 0)
        lampLightNode.eulerAngles.x = -.pi / 2.3
        lampLightNode.eulerAngles.y = 0.3
        lampNode.addChildNode(lampLightNode)
        
        deskGroup.addChildNode(lampNode)
        
        // Ceramic Pencil Cup with pencils
        let cup = SCNCylinder(radius: 0.04, height: 0.11)
        let cupMat = SCNMaterial()
        cupMat.diffuse.contents = NSColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1.0) // Matte ceramic
        cupMat.roughness.contents = 0.9
        cup.materials = [cupMat]
        let cupNode = SCNNode(geometry: cup)
        cupNode.position = SCNVector3(-0.85, deskSurfaceY + 0.055, 0.25)
        
        let pencil1 = SCNCylinder(radius: 0.007, height: 0.14)
        let penMat1 = SCNMaterial()
        penMat1.diffuse.contents = NSColor(red: 0.82, green: 0.45, blue: 0.35, alpha: 1.0)
        pencil1.materials = [penMat1]
        let penNode1 = SCNNode(geometry: pencil1)
        penNode1.position = SCNVector3(0.01, 0.05, 0.01)
        penNode1.eulerAngles.z = 0.12
        cupNode.addChildNode(penNode1)
        deskGroup.addChildNode(cupNode)
        
        // Small Desk Potted Plant (Fiddle Leaf / Pothos in terracotta pot)
        let deskPlantPot = SCNCylinder(radius: 0.065, height: 0.11)
        let plantPotMat = SCNMaterial()
        plantPotMat.diffuse.contents = NSColor(red: 0.76, green: 0.54, blue: 0.42, alpha: 1.0)
        deskPlantPot.materials = [plantPotMat]
        let deskPlantPotNode = SCNNode(geometry: deskPlantPot)
        deskPlantPotNode.position = SCNVector3(0.85, deskSurfaceY + 0.055, -0.32)
        
        // Leaves
        for i in 0..<5 {
            let leaf = SCNBox(width: 0.07, height: 0.005, length: 0.12, chamferRadius: 0.002)
            let leafMat = SCNMaterial()
            leafMat.diffuse.contents = NSColor(red: 0.32, green: 0.50, blue: 0.32, alpha: 1.0) // Lush olive green
            leaf.materials = [leafMat]
            let leafNode = SCNNode(geometry: leaf)
            let angle = CGFloat(i) * (.pi * 2 / 5)
            leafNode.position = SCNVector3(cos(angle) * 0.04, 0.08, sin(angle) * 0.04)
            leafNode.eulerAngles.y = angle
            leafNode.eulerAngles.x = 0.35
            deskPlantPotNode.addChildNode(leafNode)
        }
        deskGroup.addChildNode(deskPlantPotNode)
        
        root.addChildNode(deskGroup)
        
        // Wooden Spindle-back Chair (Pulled slightly out from the desk)
        let chairGroup = SCNNode()
        chairGroup.position = SCNVector3(0.0, 0, 0.55)
        chairGroup.eulerAngles.y = -0.15 // Slightly angled naturally
        chairGroup.name = "desk_chair"
        
        let chairSeat = SCNBox(width: 0.62, height: 0.04, length: 0.60, chamferRadius: 0.015)
        chairSeat.materials = [woodMat]
        let chairSeatNode = SCNNode(geometry: chairSeat)
        chairSeatNode.position = SCNVector3(0, 0.62, 0)
        chairGroup.addChildNode(chairSeatNode)
        
        // 4 Chair Legs
        for (cx, cz) in [(-0.25, -0.25), (0.25, -0.25), (-0.25, 0.25), (0.25, 0.25)] {
            let cl = SCNCylinder(radius: 0.022, height: 0.60)
            cl.materials = [woodMat]
            let clNode = SCNNode(geometry: cl)
            clNode.position = SCNVector3(cx, 0.30, cz)
            chairGroup.addChildNode(clNode)
        }
        
        // Chair Backrest
        let backrestTop = SCNBox(width: 0.62, height: 0.06, length: 0.04, chamferRadius: 0.01)
        backrestTop.materials = [woodMat]
        let backrestTopNode = SCNNode(geometry: backrestTop)
        backrestTopNode.position = SCNVector3(0, 1.15, 0.26)
        chairGroup.addChildNode(backrestTopNode)
        
        // Spindles
        for sx in [-0.20, -0.10, 0.0, 0.10, 0.20] {
            let spindle = SCNCylinder(radius: 0.012, height: 0.49)
            spindle.materials = [woodMat]
            let spindleNode = SCNNode(geometry: spindle)
            spindleNode.position = SCNVector3(sx, 0.88, 0.26)
            chairGroup.addChildNode(spindleNode)
        }
        
        root.addChildNode(chairGroup)
        
        return lampLight
    }
    
    // MARK: - 4. Bookshelf & Decor
    
    private static func buildBookshelf(in root: SCNNode) {
        let shelfGroup = SCNNode()
        shelfGroup.position = SCNVector3(1.35, 0, -roomDepth / 2 + 0.35)
        shelfGroup.name = "bookshelf"
        
        let woodMat = SCNMaterial()
        woodMat.diffuse.contents = NSColor(red: 0.60, green: 0.46, blue: 0.33, alpha: 1.0)
        woodMat.roughness.contents = 0.6
        
        // Side Uprights
        for sx in [-0.55, 0.55] {
            let side = SCNBox(width: 0.04, height: 2.1, length: 0.40, chamferRadius: 0.008)
            side.materials = [woodMat]
            let sideNode = SCNNode(geometry: side)
            sideNode.position = SCNVector3(sx, 1.05, 0)
            shelfGroup.addChildNode(sideNode)
        }
        
        // Horizontal Shelves (3 shelves)
        let shelfHeights: [CGFloat] = [0.15, 0.85, 1.55, 2.1]
        for sh in shelfHeights {
            let shelf = SCNBox(width: 1.14, height: 0.035, length: 0.40, chamferRadius: 0.006)
            shelf.materials = [woodMat]
            let sNode = SCNNode(geometry: shelf)
            sNode.position = SCNVector3(0, sh, 0)
            shelfGroup.addChildNode(sNode)
        }
        
        // Miniature Books on Shelves (Cozy pastel and earth-tone spines)
        let bookColors: [NSColor] = [
            NSColor(red: 0.52, green: 0.58, blue: 0.48, alpha: 1.0), // Sage
            NSColor(red: 0.76, green: 0.46, blue: 0.36, alpha: 1.0), // Terracotta
            NSColor(red: 0.86, green: 0.78, blue: 0.65, alpha: 1.0), // Linen
            NSColor(red: 0.38, green: 0.44, blue: 0.52, alpha: 1.0), // Slate
            NSColor(red: 0.68, green: 0.56, blue: 0.42, alpha: 1.0), // Ochre
            NSColor(red: 0.48, green: 0.36, blue: 0.28, alpha: 1.0)  // Deep brown
        ]
        
        // Row 1 Books
        var curX: CGFloat = -0.46
        for i in 0..<7 {
            let h = CGFloat.random(in: 0.42...0.54)
            let w = CGFloat.random(in: 0.05...0.08)
            let book = SCNBox(width: w, height: h, length: 0.30, chamferRadius: 0.005)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = bookColors[i % bookColors.count]
            book.materials = [bMat]
            let bNode = SCNNode(geometry: book)
            bNode.position = SCNVector3(curX + w / 2, 0.85 + h / 2 + 0.018, 0)
            shelfGroup.addChildNode(bNode)
            curX += w + 0.015
        }
        
        // Row 2 Books (stacked horizontally + standing)
        for i in 0..<4 {
            let h = CGFloat.random(in: 0.38...0.48)
            let w: CGFloat = 0.065
            let book = SCNBox(width: w, height: h, length: 0.28, chamferRadius: 0.005)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = bookColors[(i + 2) % bookColors.count]
            book.materials = [bMat]
            let bNode = SCNNode(geometry: book)
            bNode.position = SCNVector3(-0.42 + CGFloat(i) * 0.08, 1.55 + h / 2 + 0.018, 0)
            shelfGroup.addChildNode(bNode)
        }
        
        // Small ceramic vase on top shelf
        let vase = SCNCylinder(radius: 0.07, height: 0.18)
        let vaseMat = SCNMaterial()
        vaseMat.diffuse.contents = NSColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1.0) // Cream ceramic
        vaseMat.roughness.contents = 0.8
        vase.materials = [vaseMat]
        let vaseNode = SCNNode(geometry: vase)
        vaseNode.position = SCNVector3(0.25, 2.1 + 0.09, 0)
        shelfGroup.addChildNode(vaseNode)
        
        root.addChildNode(shelfGroup)
    }
    
    // MARK: - 5. Cookie's Sleeping Area (Rug & Curled Cat)
    
    private static func buildCookieArea(in root: SCNNode, reduceMotion: Bool) {
        let cookieGroup = SCNNode()
        cookieGroup.position = SCNVector3(-0.95, 0, 0.70)
        cookieGroup.name = "cookie_area"
        
        // Braided Circular Woven Rug
        let rug = SCNCylinder(radius: 0.50, height: 0.02)
        let rugMat = SCNMaterial()
        rugMat.diffuse.contents = NSColor(red: 0.88, green: 0.84, blue: 0.76, alpha: 1.0) // Warm taupe woven fiber
        rugMat.roughness.contents = 0.95
        rug.materials = [rugMat]
        let rugNode = SCNNode(geometry: rug)
        rugNode.position = SCNVector3(0, 0.01, 0)
        cookieGroup.addChildNode(rugNode)
        
        // Outer concentric rug braid
        let rugRing = SCNTorus(ringRadius: 0.48, pipeRadius: 0.02)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = NSColor(red: 0.78, green: 0.74, blue: 0.66, alpha: 1.0)
        rugRing.materials = [ringMat]
        let ringNode = SCNNode(geometry: rugRing)
        ringNode.position = SCNVector3(0, 0.015, 0)
        cookieGroup.addChildNode(ringNode)
        
        // Curled Cat — "Cookie"
        let catNode = SCNNode()
        catNode.name = "cookie_character"
        catNode.position = SCNVector3(0, 0.03, 0)
        
        let catFurMat = SCNMaterial()
        catFurMat.diffuse.contents = NSColor(red: 0.85, green: 0.58, blue: 0.36, alpha: 1.0) // Warm ginger/apricot
        catFurMat.roughness.contents = 0.88
        
        let catWhiteMat = SCNMaterial()
        catWhiteMat.diffuse.contents = NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0) // Cream belly & muzzle
        catWhiteMat.roughness.contents = 0.88
        
        // Torso (curled oval)
        let body = SCNSphere(radius: 0.16)
        body.materials = [catFurMat]
        let bodyNode = SCNNode(geometry: body)
        bodyNode.scale = SCNVector3(1.2, 0.85, 1.4)
        bodyNode.position = SCNVector3(0, 0.12, 0)
        catNode.addChildNode(bodyNode)
        
        // Cream tummy patch
        let patch = SCNSphere(radius: 0.12)
        patch.materials = [catWhiteMat]
        let patchNode = SCNNode(geometry: patch)
        patchNode.scale = SCNVector3(0.9, 0.7, 1.1)
        patchNode.position = SCNVector3(-0.04, 0.11, 0.02)
        catNode.addChildNode(patchNode)
        
        // Head resting on paws
        let head = SCNSphere(radius: 0.11)
        head.materials = [catFurMat]
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0.12, 0.13, 0.16)
        
        // Cat Ears
        for (ex, ey, ez, tilt) in [(-0.04, 0.09, 0.02, -0.2), (0.05, 0.09, 0.02, 0.2)] {
            let ear = SCNCone(topRadius: 0.002, bottomRadius: 0.035, height: 0.06)
            ear.materials = [catFurMat]
            let earNode = SCNNode(geometry: ear)
            earNode.position = SCNVector3(ex, ey, ez)
            earNode.eulerAngles.z = CGFloat(tilt)
            headNode.addChildNode(earNode)
        }
        catNode.addChildNode(headNode)
        
        // Curled Tail wrapped around body
        let tail = SCNTorus(ringRadius: 0.17, pipeRadius: 0.035)
        tail.materials = [catFurMat]
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(-0.06, 0.08, -0.06)
        tailNode.eulerAngles.x = 0.2
        catNode.addChildNode(tailNode)
        
        // Gentle breathing animation (subtle rhythmic rise and fall)
        if !reduceMotion {
            let breatheIn = SCNAction.scale(to: 1.035, duration: 2.4)
            breatheIn.timingMode = .easeInEaseOut
            let breatheOut = SCNAction.scale(to: 0.975, duration: 2.4)
            breatheOut.timingMode = .easeInEaseOut
            let breathingLoop = SCNAction.repeatForever(SCNAction.sequence([breatheIn, breatheOut]))
            bodyNode.runAction(breathingLoop, forKey: "cat_breathing")
        }
        
        cookieGroup.addChildNode(catNode)
        root.addChildNode(cookieGroup)
    }
    
    // MARK: - 6. Lighting & Environment
    
    private static func setupLighting(in root: SCNNode, environment: RoomTimeOfDay) -> (SCNLight, SCNLight) {
        // Sunlight streaming in through the window
        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.color = environment.sunlightColor
        sunLight.intensity = environment.sunlightIntensity
        sunLight.castsShadow = true
        sunLight.shadowRadius = 3.5
        sunLight.shadowSampleCount = 8
        sunLight.shadowColor = NSColor(white: 0.12, alpha: 0.5)
        
        let sunNode = SCNNode()
        sunNode.light = sunLight
        // Positioned outside window pointing down and into the room
        sunNode.position = SCNVector3(-5.0, 6.0, 2.0)
        sunNode.eulerAngles = SCNVector3(-0.65, -0.85, 0)
        sunNode.name = "sun_light"
        root.addChildNode(sunNode)
        
        // Ambient Fill Light (Soft warm interior daylight)
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = environment.ambientColor
        ambientLight.intensity = environment.ambientIntensity
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        ambientNode.name = "ambient_light"
        root.addChildNode(ambientNode)
        
        return (sunLight, ambientLight)
    }
    
    // MARK: - 7. Isometric Camera
    
    private static func setupCamera(in root: SCNNode) {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        camera.fieldOfView = 36 // Natural dollhouse perspective
        camera.zNear = 0.5
        camera.zFar = 50.0
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.name = "main_room_camera"
        
        // Classic three-quarter isometric dollhouse perspective
        cameraNode.position = SCNVector3(5.2, 5.0, 5.8)
        
        // Look at room center/desk
        let lookAtTarget = SCNNode()
        lookAtTarget.position = SCNVector3(0.0, 1.05, 0.0)
        lookAtTarget.name = "camera_look_at_target"
        root.addChildNode(lookAtTarget)
        
        let constraint = SCNLookAtConstraint(target: lookAtTarget)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        
        root.addChildNode(cameraNode)
    }
}

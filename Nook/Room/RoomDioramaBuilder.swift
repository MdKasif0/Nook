import SceneKit
import SwiftUI
import AppKit

/// Builds the procedural 3D miniature room diorama matching the exact composition of Nook.
///
/// Features:
/// - Chunky rounded oak beam trim along wall tops
/// - Two-tier stepped hardwood platform floor with central steps
/// - Left Workspace: Natural oak desk, 3-drawer cabinet, ergonomic chair, monitor with "hello ♡",
///   open laptop, keyboard, mouse, open notebook, phone stand, smiley mug, pencil cup,
///   pegboard with polaroids & headphones, upper bookshelves with books, clock, ceramic cat,
///   and cascading trailing ivy vines.
/// - Lower Lounge Tier: Skateboard on floor, cream boucle beanbag pouf with daisy cushion,
///   and miniature potted succulents on the step ledge.
/// - Right Daybed Nook: Built-in oak daybed, white linens, sage green throw blanket, daisy cushion,
///   Cookie sleeping peacefully on the bed, record player bench with spinning vinyl,
///   large floor potted monstera plant, framed botanical wall art, and warm wall sconce.
/// - Big Right Window: Large 2-pane oak window, outdoor landscape with trees & sky,
///   draped linen curtains with gentle flutter, window sill succulents, and warm sunlight with dust motes!
@MainActor
final class RoomDioramaBuilder {
    
    // MARK: - Dimensions & Coordinates
    
    static let roomWidth: CGFloat = 4.6      // X axis (-2.3 to +2.3)
    static let roomDepth: CGFloat = 4.2      // Z axis (-2.1 to +2.1)
    static let wallHeight: CGFloat = 3.3     // Y axis (floor to ceiling)
    
    // Desk surface coordinate reference
    static let deskSurfaceY: CGFloat = 1.04
    static let deskPosition = SCNVector3(x: -1.05, y: 0.14, z: -0.65)
    
    // MARK: - Scene Construction
    
    /// Constructs the complete room diorama inside the target scene.
    static func buildDiorama(
        in scene: SCNScene,
        environment: RoomTimeOfDay = .morning,
        reduceMotion: Bool = false
    ) -> (lampLight: SCNLight, sconceLight: SCNLight, sunLight: SCNLight, ambientLight: SCNLight, outdoorSkyNode: SCNNode, dustParticles: SCNParticleSystem?) {
        
        let root = scene.rootNode
        
        // 1. Architecture: Stepped wooden floors, ivory walls, top beams
        buildArchitecture(in: root)
        
        // 2. Right Window, Draped Curtains & Outdoor Horizon
        let (skyNode, curtains) = buildWindowAndOutdoors(in: root, environment: environment, reduceMotion: reduceMotion)
        
        // 3. Left Workspace: Oak desk, drawers, rug, ergonomic chair, monitor, laptop, stationery
        let (lampLight, monitorNode) = buildWorkspace(in: root, environment: environment, reduceMotion: reduceMotion)
        
        // 4. Upper Wall Shelving, Pegboard & Cascading Ivy
        buildShelvesAndPegboard(in: root, reduceMotion: reduceMotion)
        
        // 5. Right Daybed Nook & Cookie
        buildDaybedNook(in: root, reduceMotion: reduceMotion)
        
        // 6. Record Player Bench & Large Floor Monstera
        let (recordNode, sconceLight) = buildRecordBenchAndLighting(in: root, environment: environment, reduceMotion: reduceMotion)
        
        // 7. Lower Sunken Lounge: Skateboard, Boucle Beanbag & Steps Accents
        buildLowerLounge(in: root)
        
        // 8. Environmental Lighting & Sunlight Beam Dust Motes
        let (sunLight, ambientLight, dustSystem) = setupLightingAndAtmosphere(in: root, environment: environment, reduceMotion: reduceMotion)
        
        // 9. Isometric Camera
        setupCamera(in: root)
        
        return (lampLight, sconceLight, sunLight, ambientLight, skyNode, dustSystem)
    }
    
    // MARK: - 1. Architecture (Stepped Floor, Walls & Top Beams)
    
    private static func buildArchitecture(in root: SCNNode) {
        let oakMat = Materials.honeyOak
        let plasterMat = Materials.ivoryPlaster
        
        // Upper Main Floor Platform (Y = 0.14, covering back & left areas)
        // Left platform (under desk & chair): width 2.2, depth 2.3, height 0.28
        let upperLeftGeo = SCNBox(width: 2.2, height: 0.28, length: 2.4, chamferRadius: 0.02)
        upperLeftGeo.materials = [oakMat]
        let upperLeftNode = SCNNode(geometry: upperLeftGeo)
        upperLeftNode.position = SCNVector3(-1.15, 0.0, -0.85)
        upperLeftNode.name = "floor_upper_left"
        root.addChildNode(upperLeftNode)
        
        // Upper Right platform (under bed): width 2.2, depth 2.4, height 0.28
        let upperRightGeo = SCNBox(width: 2.2, height: 0.28, length: 2.4, chamferRadius: 0.02)
        upperRightGeo.materials = [oakMat]
        let upperRightNode = SCNNode(geometry: upperRightGeo)
        upperRightNode.position = SCNVector3(1.15, 0.0, -0.85)
        upperRightNode.name = "floor_upper_right"
        root.addChildNode(upperRightNode)
        
        // Lower Sunken Floor Platform (Y = 0.0, front center & right lounge)
        let lowerFloorGeo = SCNBox(width: 4.5, height: 0.14, length: 1.7, chamferRadius: 0.02)
        lowerFloorGeo.materials = [oakMat]
        let lowerFloorNode = SCNNode(geometry: lowerFloorGeo)
        lowerFloorNode.position = SCNVector3(0.0, -0.07, 1.15)
        lowerFloorNode.name = "floor_lower_lounge"
        root.addChildNode(lowerFloorNode)
        
        // Stepped Wood Stairs connecting upper platform to sunken lounge
        let stepWidth: CGFloat = 1.1
        let stepDepth: CGFloat = 0.24
        let stepHeights: [CGFloat] = [0.05, 0.10, 0.15]
        for (i, h) in stepHeights.enumerated() {
            let stepGeo = SCNBox(width: stepWidth, height: 0.05, length: stepDepth, chamferRadius: 0.01)
            stepGeo.materials = [oakMat]
            let stepNode = SCNNode(geometry: stepGeo)
            stepNode.position = SCNVector3(-0.15, h - 0.025, 0.35 + CGFloat(2 - i) * 0.16)
            root.addChildNode(stepNode)
        }
        
        // Back Wall (Ivory Plaster with cutaway top)
        let backWallGeo = SCNBox(width: roomWidth, height: wallHeight, length: 0.14, chamferRadius: 0.01)
        backWallGeo.materials = [plasterMat]
        let backWallNode = SCNNode(geometry: backWallGeo)
        backWallNode.position = SCNVector3(0, wallHeight / 2, -roomDepth / 2 - 0.07)
        backWallNode.name = "room_back_wall"
        root.addChildNode(backWallNode)
        
        // Vertical oak shiplap slats on back wall behind desk
        let shiplapGeo = SCNBox(width: 2.3, height: 1.8, length: 0.02, chamferRadius: 0.005)
        let shiplapMat = SCNMaterial()
        shiplapMat.diffuse.contents = NSColor(red: 0.88, green: 0.80, blue: 0.70, alpha: 1.0)
        shiplapMat.roughness.contents = 0.75
        shiplapGeo.materials = [shiplapMat]
        let shiplapNode = SCNNode(geometry: shiplapGeo)
        shiplapNode.position = SCNVector3(-1.15, 1.25, -roomDepth / 2 + 0.01)
        root.addChildNode(shiplapNode)
        
        // Right Wall (Ivory Plaster with Window Cutout)
        // Bottom section below window
        let rightWallBottom = SCNBox(width: 0.14, height: 1.15, length: roomDepth, chamferRadius: 0.01)
        rightWallBottom.materials = [plasterMat]
        let rwBottomNode = SCNNode(geometry: rightWallBottom)
        rwBottomNode.position = SCNVector3(roomWidth / 2 + 0.07, 0.575, 0)
        root.addChildNode(rwBottomNode)
        
        // Top section above window
        let rightWallTop = SCNBox(width: 0.14, height: 0.75, length: roomDepth, chamferRadius: 0.01)
        rightWallTop.materials = [plasterMat]
        let rwTopNode = SCNNode(geometry: rightWallTop)
        rwTopNode.position = SCNVector3(roomWidth / 2 + 0.07, wallHeight - 0.375, 0)
        root.addChildNode(rwTopNode)
        
        // Back edge of window
        let rightWallBack = SCNBox(width: 0.14, height: 1.40, length: 0.75, chamferRadius: 0.01)
        rightWallBack.materials = [plasterMat]
        let rwBackNode = SCNNode(geometry: rightWallBack)
        rwBackNode.position = SCNVector3(roomWidth / 2 + 0.07, 1.85, -1.65)
        root.addChildNode(rwBackNode)
        
        // Front edge of window
        let rightWallFront = SCNBox(width: 0.14, height: 1.40, length: 1.35, chamferRadius: 0.01)
        rightWallFront.materials = [plasterMat]
        let rwFrontNode = SCNNode(geometry: rightWallFront)
        rwFrontNode.position = SCNVector3(roomWidth / 2 + 0.07, 1.85, 1.35)
        root.addChildNode(rwFrontNode)
        
        // Left cutaway pillar / wall edge
        let leftPillar = SCNBox(width: 0.14, height: wallHeight, length: 0.55, chamferRadius: 0.01)
        leftPillar.materials = [plasterMat]
        let leftPillarNode = SCNNode(geometry: leftPillar)
        leftPillarNode.position = SCNVector3(-roomWidth / 2 - 0.07, wallHeight / 2, -roomDepth / 2 + 0.275)
        root.addChildNode(leftPillarNode)
        
        // Chunky Rounded Oak Top Beams along wall tops (Signature aesthetic from reference image)
        let beamMat = Materials.honeyOak
        
        // Back wall top beam
        let backBeam = SCNBox(width: roomWidth + 0.30, height: 0.16, length: 0.22, chamferRadius: 0.035)
        backBeam.materials = [beamMat]
        let backBeamNode = SCNNode(geometry: backBeam)
        backBeamNode.position = SCNVector3(0, wallHeight + 0.08, -roomDepth / 2 - 0.06)
        root.addChildNode(backBeamNode)
        
        // Right wall top beam
        let rightBeam = SCNBox(width: 0.22, height: 0.16, length: roomDepth + 0.30, chamferRadius: 0.035)
        rightBeam.materials = [beamMat]
        let rightBeamNode = SCNNode(geometry: rightBeam)
        rightBeamNode.position = SCNVector3(roomWidth / 2 + 0.06, wallHeight + 0.08, 0)
        root.addChildNode(rightBeamNode)
    }
    
    // MARK: - 2. Big Right Window, Draped Curtains & Outdoor Horizon
    
    private static func buildWindowAndOutdoors(
        in root: SCNNode,
        environment: RoomTimeOfDay,
        reduceMotion: Bool
    ) -> (SCNNode, [SCNNode]) {
        let windowGroup = SCNNode()
        let windowX = roomWidth / 2
        windowGroup.position = SCNVector3(windowX, 1.85, -0.35)
        
        let frameMat = Materials.honeyOak
        let windowWidth: CGFloat = 1.95
        let windowHeight: CGFloat = 1.35
        
        // Window Sill (Warm thick oak ledge with chamfer)
        let sill = SCNBox(width: 0.26, height: 0.06, length: windowWidth + 0.15, chamferRadius: 0.015)
        sill.materials = [frameMat]
        let sillNode = SCNNode(geometry: sill)
        sillNode.position = SCNVector3(0.04, -windowHeight / 2 - 0.03, 0)
        windowGroup.addChildNode(sillNode)
        
        // Window Frame Perimeter
        let topBar = SCNBox(width: 0.16, height: 0.06, length: windowWidth, chamferRadius: 0.01)
        topBar.materials = [frameMat]
        let topBarNode = SCNNode(geometry: topBar)
        topBarNode.position = SCNVector3(0, windowHeight / 2 + 0.03, 0)
        windowGroup.addChildNode(topBarNode)
        
        // Center Mullion (Splits window into 2 panes)
        let centerMullion = SCNBox(width: 0.14, height: windowHeight, length: 0.06, chamferRadius: 0.008)
        centerMullion.materials = [frameMat]
        let mullionNode = SCNNode(geometry: centerMullion)
        mullionNode.position = SCNVector3(0, 0, 0)
        windowGroup.addChildNode(mullionNode)
        
        // Horizontal transom bars
        for zOffset in [-windowWidth * 0.25, windowWidth * 0.25] {
            let hBar = SCNBox(width: 0.12, height: 0.045, length: windowWidth * 0.46, chamferRadius: 0.006)
            hBar.materials = [frameMat]
            let hBarNode = SCNNode(geometry: hBar)
            hBarNode.position = SCNVector3(0, 0.12, zOffset)
            windowGroup.addChildNode(hBarNode)
        }
        
        // Window Panes (Subtle, realistic non-glare glass)
        let glassGeo = SCNBox(width: 0.02, height: windowHeight - 0.04, length: windowWidth - 0.04, chamferRadius: 0.002)
        let glassMat = SCNMaterial()
        glassMat.diffuse.contents = NSColor(white: 0.98, alpha: 0.18)
        glassMat.roughness.contents = 0.08
        glassMat.specular.contents = NSColor(white: 0.35, alpha: 1.0)
        glassMat.transparency = 0.25
        glassGeo.materials = [glassMat]
        let glassNode = SCNNode(geometry: glassGeo)
        glassNode.position = SCNVector3(0, 0, 0)
        windowGroup.addChildNode(glassNode)
        
        // Outdoor Sky & Foliage Backdrop Plane
        let outdoorPlane = SCNPlane(width: 2.6, height: 1.8)
        let skyMat = SCNMaterial()
        skyMat.lightingModel = .constant
        skyMat.diffuse.contents = Textures.makeOutdoorBackdrop(environment: environment)
        outdoorPlane.materials = [skyMat]
        
        let skyNode = SCNNode(geometry: outdoorPlane)
        skyNode.position = SCNVector3(0.25, 0, 0)
        skyNode.eulerAngles.y = -.pi / 2
        skyNode.name = "outdoor_sky_node"
        windowGroup.addChildNode(skyNode)
        
        // Window Sill Accessories: Succulent pots & tiny cat figurine
        let sillPots = [
            (z: CGFloat(-0.55), r: CGFloat(0.038), h: CGFloat(0.065), color: NSColor(red: 0.78, green: 0.52, blue: 0.40, alpha: 1.0)),
            (z: CGFloat(-0.35), r: CGFloat(0.045), h: CGFloat(0.080), color: NSColor(white: 0.92, alpha: 1.0))
        ]
        for sp in sillPots {
            let pot = SCNCylinder(radius: sp.r, height: sp.h)
            let pMat = SCNMaterial()
            pMat.diffuse.contents = sp.color
            pMat.roughness.contents = 0.6
            pot.materials = [pMat]
            let pNode = SCNNode(geometry: pot)
            pNode.position = SCNVector3(0.06, -windowHeight / 2 + sp.h / 2, sp.z)
            
            // Succulent foliage
            let succ = SCNSphere(radius: sp.r * 1.05)
            let sMat = SCNMaterial()
            sMat.diffuse.contents = NSColor(red: 0.42, green: 0.60, blue: 0.42, alpha: 1.0)
            succ.materials = [sMat]
            let sNode = SCNNode(geometry: succ)
            sNode.position = SCNVector3(0, sp.h * 0.5, 0)
            pNode.addChildNode(sNode)
            windowGroup.addChildNode(pNode)
        }
        
        // Tiny ceramic cat figurine on the window sill (cute easter egg)
        let catFig = SCNSphere(radius: 0.032)
        let catFigMat = SCNMaterial()
        catFigMat.diffuse.contents = NSColor(white: 0.96, alpha: 1.0)
        catFigMat.roughness.contents = 0.3
        catFig.materials = [catFigMat]
        let catFigNode = SCNNode(geometry: catFig)
        catFigNode.position = SCNVector3(0.06, -windowHeight / 2 + 0.032, 0.45)
        windowGroup.addChildNode(catFigNode)
        
        // Draped Linen Curtains (Left & Right of Window, gathered with ties)
        var curtains: [SCNNode] = []
        let curtainPositions: [(CGFloat, CGFloat)] = [
            (-windowWidth * 0.52, -1.0),
            (windowWidth * 0.52, 1.0)
        ]
        
        for (zPos, dir) in curtainPositions {
            let curtainNode = SCNNode()
            curtainNode.position = SCNVector3(-0.06, 0.05, zPos)
            curtainNode.name = "curtain_\(dir > 0 ? "right" : "left")"
            
            // Curtain rod & rings
            let rod = SCNCylinder(radius: 0.014, height: 0.35)
            rod.materials = [Materials.brushedBrass]
            let rodNode = SCNNode(geometry: rod)
            rodNode.eulerAngles.x = .pi / 2
            rodNode.position = SCNVector3(0, windowHeight / 2 + 0.12, 0)
            curtainNode.addChildNode(rodNode)
            
            // Linen curtain fabric (gathered column with subtle folds)
            let foldCount = 4
            for f in 0..<foldCount {
                let fold = SCNCylinder(radius: 0.032, height: windowHeight + 0.15)
                fold.materials = [Materials.linenWhite]
                let fNode = SCNNode(geometry: fold)
                fNode.position = SCNVector3(0, 0, CGFloat(f) * 0.045 * dir)
                curtainNode.addChildNode(fNode)
            }
            
            // Curtain tie-back loop
            let tie = SCNTorus(ringRadius: 0.08, pipeRadius: 0.012)
            tie.materials = [Materials.honeyOak]
            let tieNode = SCNNode(geometry: tie)
            tieNode.position = SCNVector3(0, -0.15, dir * 0.08)
            tieNode.eulerAngles.x = .pi / 2
            curtainNode.addChildNode(tieNode)
            
            // Subtle curtain flutter environmental animation
            if !reduceMotion {
                let sway1 = SCNAction.rotateBy(x: 0, y: 0.02 * dir, z: 0.015, duration: 3.5)
                let sway2 = SCNAction.rotateBy(x: 0, y: -0.02 * dir, z: -0.015, duration: 4.2)
                let gentleFlutter = SCNAction.sequence([sway1, sway2])
                curtainNode.runAction(SCNAction.repeatForever(gentleFlutter), forKey: "curtain_breeze")
            }
            
            windowGroup.addChildNode(curtainNode)
            curtains.append(curtainNode)
        }
        
        root.addChildNode(windowGroup)
        return (skyNode, curtains)
    }
    
    // MARK: - 3. Left Workspace (Desk, Rug, Ergonomic Chair, Monitor, Laptop, Stationery)
    
    private static func buildWorkspace(
        in root: SCNNode,
        environment: RoomTimeOfDay,
        reduceMotion: Bool
    ) -> (SCNLight, SCNNode) {
        let deskGroup = SCNNode()
        deskGroup.position = deskPosition
        deskGroup.name = "desk_group"
        
        let woodMat = Materials.honeyOak
        let brassMat = Materials.brushedBrass
        
        // Desk Dimensions
        let deskW: CGFloat = 1.95
        let deskD: CGFloat = 0.95
        let deskH: CGFloat = 0.90 // Surface height above upper platform
        
        // Tabletop (Thick warm honey oak beveled slab)
        let tabletop = SCNBox(width: deskW, height: 0.065, length: deskD, chamferRadius: 0.015)
        tabletop.materials = [woodMat]
        let tabletopNode = SCNNode(geometry: tabletop)
        tabletopNode.position = SCNVector3(0, deskH - 0.0325, 0)
        tabletopNode.name = "desk_tabletop"
        deskGroup.addChildNode(tabletopNode)
        
        // Left 3-Drawer Filing Pedestal
        let drawerW: CGFloat = 0.52
        let drawerH: CGFloat = deskH - 0.08
        let drawerD: CGFloat = deskD * 0.92
        let drawerBox = SCNBox(width: drawerW, height: drawerH, length: drawerD, chamferRadius: 0.012)
        drawerBox.materials = [woodMat]
        let drawerNode = SCNNode(geometry: drawerBox)
        drawerNode.position = SCNVector3(-deskW / 2 + drawerW / 2 + 0.08, drawerH / 2, 0)
        deskGroup.addChildNode(drawerNode)
        
        // 3 Horizontal Brass Drawer Pulls
        let drawerYOffsets: [CGFloat] = [0.22, 0.48, 0.74]
        for dy in drawerYOffsets {
            let handle = SCNBox(width: 0.16, height: 0.018, length: 0.02, chamferRadius: 0.005)
            handle.materials = [brassMat]
            let hNode = SCNNode(geometry: handle)
            hNode.position = SCNVector3(-deskW / 2 + drawerW / 2 + 0.08, dy, drawerD / 2 + 0.01)
            deskGroup.addChildNode(hNode)
        }
        
        // Right Side Desk Frame & Tapered Oak Legs
        for lz in [-deskD * 0.42, deskD * 0.42] {
            let leg = SCNCylinder(radius: 0.032, height: deskH - 0.065)
            leg.materials = [woodMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(deskW / 2 - 0.08, (deskH - 0.065) / 2, lz)
            deskGroup.addChildNode(legNode)
        }
        
        // Desk Stretcher Bar
        let stretcher = SCNBox(width: 0.04, height: 0.04, length: deskD * 0.84, chamferRadius: 0.008)
        stretcher.materials = [woodMat]
        let sNode = SCNNode(geometry: stretcher)
        sNode.position = SCNVector3(deskW / 2 - 0.08, 0.18, 0)
        deskGroup.addChildNode(sNode)
        
        // Large Computer Monitor displaying cursive "hello ♡" with landscape
        let (monitorNode, screenLight) = buildComputerMonitor()
        monitorNode.position = SCNVector3(-0.35, deskH, -0.15)
        deskGroup.addChildNode(monitorNode)
        
        // Open Laptop to the right of the monitor displaying scenic wallpaper
        let laptopNode = buildOpenLaptop()
        laptopNode.position = SCNVector3(0.42, deskH, 0.02)
        laptopNode.eulerAngles.y = -0.22 // Naturally angled toward chair
        deskGroup.addChildNode(laptopNode)
        
        // Chiclet Mechanical Keyboard & Ergonomic Mouse on Desk Blotter
        let blotterGeo = SCNBox(width: 1.15, height: 0.006, length: 0.48, chamferRadius: 0.015)
        let blotterMat = SCNMaterial()
        blotterMat.diffuse.contents = NSColor(red: 0.90, green: 0.88, blue: 0.84, alpha: 1.0) // Soft linen blotter
        blotterMat.roughness.contents = 0.9
        blotterGeo.materials = [blotterMat]
        let blotterNode = SCNNode(geometry: blotterGeo)
        blotterNode.position = SCNVector3(-0.05, deskH + 0.003, 0.20)
        deskGroup.addChildNode(blotterNode)
        
        // Compact White Keyboard
        let kbdGeo = SCNBox(width: 0.38, height: 0.015, length: 0.14, chamferRadius: 0.006)
        let kbdMat = SCNMaterial()
        kbdMat.diffuse.contents = NSColor(white: 0.95, alpha: 1.0)
        kbdMat.roughness.contents = 0.4
        kbdGeo.materials = [kbdMat]
        let kbdNode = SCNNode(geometry: kbdGeo)
        kbdNode.position = SCNVector3(-0.15, deskH + 0.014, 0.20)
        deskGroup.addChildNode(kbdNode)
        
        // White Mouse
        let mouseGeo = SCNSphere(radius: 0.038)
        let mouseMat = SCNMaterial()
        mouseMat.diffuse.contents = NSColor(white: 0.96, alpha: 1.0)
        mouseMat.roughness.contents = 0.3
        mouseGeo.materials = [mouseMat]
        let mouseNode = SCNNode(geometry: mouseGeo)
        mouseNode.scale = SCNVector3(0.65, 0.32, 1.0)
        mouseNode.position = SCNVector3(0.22, deskH + 0.012, 0.20)
        deskGroup.addChildNode(mouseNode)
        
        // Open Notebook / Planner on left side with bookmark ribbon
        let notebookGeo = SCNBox(width: 0.24, height: 0.018, length: 0.32, chamferRadius: 0.006)
        let nbMat = SCNMaterial()
        nbMat.diffuse.contents = NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
        nbMat.roughness.contents = 0.95
        notebookGeo.materials = [nbMat]
        let nbNode = SCNNode(geometry: notebookGeo)
        nbNode.position = SCNVector3(-0.68, deskH + 0.009, 0.18)
        nbNode.eulerAngles.y = 0.08
        deskGroup.addChildNode(nbNode)
        
        // Smartphone in Wooden Stand
        let phoneStand = SCNBox(width: 0.07, height: 0.05, length: 0.08, chamferRadius: 0.008)
        phoneStand.materials = [woodMat]
        let phoneStandNode = SCNNode(geometry: phoneStand)
        phoneStandNode.position = SCNVector3(-0.80, deskH + 0.025, -0.15)
        
        let phone = SCNBox(width: 0.065, height: 0.13, length: 0.008, chamferRadius: 0.004)
        let phoneMat = SCNMaterial()
        phoneMat.diffuse.contents = NSColor(white: 0.15, alpha: 1.0)
        phone.materials = [phoneMat]
        let phoneNode = SCNNode(geometry: phone)
        phoneNode.eulerAngles.x = 0.25
        phoneNode.position = SCNVector3(0, 0.045, 0)
        phoneStandNode.addChildNode(phoneNode)
        deskGroup.addChildNode(phoneStandNode)
        
        // Ceramic Pencil Cup with Colored Pencils
        let cup = SCNCylinder(radius: 0.042, height: 0.11)
        cup.materials = [Materials.satinCeramic]
        let cupNode = SCNNode(geometry: cup)
        cupNode.position = SCNVector3(-0.85, deskH + 0.055, 0.02)
        
        let penColors: [NSColor] = [
            NSColor(red: 0.78, green: 0.45, blue: 0.35, alpha: 1.0),
            NSColor(red: 0.42, green: 0.58, blue: 0.48, alpha: 1.0),
            NSColor(red: 0.88, green: 0.75, blue: 0.45, alpha: 1.0)
        ]
        for (i, c) in penColors.enumerated() {
            let pencil = SCNCylinder(radius: 0.006, height: 0.15)
            let pMat = SCNMaterial()
            pMat.diffuse.contents = c
            pencil.materials = [pMat]
            let pNode = SCNNode(geometry: pencil)
            pNode.position = SCNVector3(CGFloat(i - 1) * 0.015, 0.05, 0)
            pNode.eulerAngles.z = CGFloat(i - 1) * 0.12
            cupNode.addChildNode(pNode)
        }
        deskGroup.addChildNode(cupNode)
        
        // Cute White Ceramic Mug with Smiley Face
        let mugNode = buildSmileyMug()
        mugNode.position = SCNVector3(0.12, deskH + 0.045, -0.15)
        deskGroup.addChildNode(mugNode)
        
        // Articulated Cream Desk Lamp with Warm Spotlight
        let (lampNode, lampLight) = buildDeskLamp(environment: environment)
        lampNode.position = SCNVector3(0.70, deskH, -0.22)
        deskGroup.addChildNode(lampNode)
        
        // Miniature desk succulent
        let deskSuccPot = SCNCylinder(radius: 0.045, height: 0.075)
        deskSuccPot.materials = [Materials.satinCeramic]
        let deskSuccNode = SCNNode(geometry: deskSuccPot)
        deskSuccNode.position = SCNVector3(0.78, deskH + 0.038, 0.15)
        let succBall = SCNSphere(radius: 0.045)
        let succBallMat = SCNMaterial()
        succBallMat.diffuse.contents = NSColor(red: 0.38, green: 0.55, blue: 0.38, alpha: 1.0)
        succBall.materials = [succBallMat]
        let sbNode = SCNNode(geometry: succBall)
        sbNode.position = SCNVector3(0, 0.045, 0)
        deskSuccNode.addChildNode(sbNode)
        deskGroup.addChildNode(deskSuccNode)
        
        root.addChildNode(deskGroup)
        
        // Soft Woven Desk Rug (under desk & ergonomic chair)
        let rugGeo = SCNBox(width: 1.65, height: 0.012, length: 1.45, chamferRadius: 0.04)
        let rugMat = SCNMaterial()
        rugMat.diffuse.contents = Textures.makeBotanicalRugTexture()
        rugMat.roughness.contents = 0.95
        rugGeo.materials = [rugMat]
        let rugNode = SCNNode(geometry: rugGeo)
        rugNode.position = SCNVector3(-0.95, 0.145, 0.42)
        rugNode.name = "desk_rug"
        root.addChildNode(rugNode)
        
        // High-Back Ergonomic Office Chair (White frame, 5-star base, sage fabric)
        let chairNode = buildErgonomicChair()
        chairNode.position = SCNVector3(-0.95, 0.14, 0.48)
        chairNode.eulerAngles.y = 0.18 // Angled naturally toward desk
        root.addChildNode(chairNode)
        
        // Potted Floor Plant beside desk drawers
        let floorPot = SCNCylinder(radius: 0.11, height: 0.18)
        floorPot.materials = [Materials.satinCeramic]
        let floorPotNode = SCNNode(geometry: floorPot)
        floorPotNode.position = SCNVector3(-2.0, 0.23, 0.45)
        
        for i in 0..<6 {
            let leaf = SCNBox(width: 0.10, height: 0.005, length: 0.18, chamferRadius: 0.004)
            let leafMat = SCNMaterial()
            leafMat.diffuse.contents = NSColor(red: 0.30, green: 0.48, blue: 0.32, alpha: 1.0)
            leaf.materials = [leafMat]
            let leafNode = SCNNode(geometry: leaf)
            let angle = CGFloat(i) * (.pi * 2 / 6)
            leafNode.position = SCNVector3(cos(angle) * 0.06, 0.12, sin(angle) * 0.06)
            leafNode.eulerAngles.y = angle
            leafNode.eulerAngles.x = 0.45
            floorPotNode.addChildNode(leafNode)
        }
        root.addChildNode(floorPotNode)
        
        return (lampLight, monitorNode)
    }
    
    // MARK: - 4. Shelves, Pegboard & Cascading Ivy
    
    private static func buildShelvesAndPegboard(in root: SCNNode, reduceMotion: Bool) {
        let shelfGroup = SCNNode()
        let woodMat = Materials.honeyOak
        let brassMat = Materials.brushedBrass
        
        // Light Wood Pegboard mounted on back wall behind the monitor
        let pegboardGeo = SCNBox(width: 0.85, height: 0.95, length: 0.02, chamferRadius: 0.01)
        let pbMat = SCNMaterial()
        pbMat.diffuse.contents = Textures.makePegboardTexture()
        pbMat.roughness.contents = 0.85
        pegboardGeo.materials = [pbMat]
        let pegboardNode = SCNNode(geometry: pegboardGeo)
        pegboardNode.position = SCNVector3(-0.95, 2.05, -roomDepth / 2 + 0.03)
        shelfGroup.addChildNode(pegboardNode)
        
        // Pinned Mini Polaroids & Notes on pegboard
        let noteColors: [NSColor] = [
            NSColor(red: 0.96, green: 0.92, blue: 0.85, alpha: 1.0),
            NSColor(red: 0.92, green: 0.94, blue: 0.88, alpha: 1.0),
            NSColor(red: 0.98, green: 0.88, blue: 0.82, alpha: 1.0)
        ]
        let noteCoords: [(CGFloat, CGFloat, CGFloat)] = [
            (-0.25, 0.22, 0.08),
            (0.18, 0.28, -0.05),
            (-0.18, -0.15, 0.04)
        ]
        for (i, coord) in noteCoords.enumerated() {
            let noteGeo = SCNBox(width: 0.14, height: 0.18, length: 0.005, chamferRadius: 0.002)
            let nMat = SCNMaterial()
            nMat.diffuse.contents = noteColors[i % noteColors.count]
            noteGeo.materials = [nMat]
            let nNode = SCNNode(geometry: noteGeo)
            nNode.position = SCNVector3(coord.0, coord.1, 0.015)
            nNode.eulerAngles.z = coord.2
            pegboardNode.addChildNode(nNode)
        }
        
        // Hanging White Studio Headphones on wooden peg
        let headphonePeg = SCNCylinder(radius: 0.012, height: 0.08)
        headphonePeg.materials = [woodMat]
        let pegNode = SCNNode(geometry: headphonePeg)
        pegNode.eulerAngles.x = .pi / 2
        pegNode.position = SCNVector3(0.22, -0.08, 0.04)
        pegboardNode.addChildNode(pegNode)
        
        let headphoneBand = SCNTorus(ringRadius: 0.12, pipeRadius: 0.016)
        let hpMat = SCNMaterial()
        hpMat.diffuse.contents = NSColor(white: 0.94, alpha: 1.0)
        hpMat.roughness.contents = 0.4
        headphoneBand.materials = [hpMat]
        let hpNode = SCNNode(geometry: headphoneBand)
        hpNode.position = SCNVector3(0, -0.04, 0.03)
        hpNode.eulerAngles.z = .pi / 2
        pegNode.addChildNode(hpNode)
        
        // Two Sturdy Wall Shelves above desk
        let shelfWidth: CGFloat = 2.15
        let shelfHeights: [CGFloat] = [2.62, 3.05]
        for sh in shelfHeights {
            let shelf = SCNBox(width: shelfWidth, height: 0.035, length: 0.32, chamferRadius: 0.008)
            shelf.materials = [woodMat]
            let sNode = SCNNode(geometry: shelf)
            sNode.position = SCNVector3(-1.10, sh, -roomDepth / 2 + 0.17)
            shelfGroup.addChildNode(sNode)
            
            // Shelf vertical brackets
            for bx in [-shelfWidth * 0.42, 0.0, shelfWidth * 0.42] {
                let bracket = SCNBox(width: 0.035, height: 0.14, length: 0.28, chamferRadius: 0.005)
                bracket.materials = [woodMat]
                let bNode = SCNNode(geometry: bracket)
                bNode.position = SCNVector3(sNode.position.x + bx, sh - 0.08, -roomDepth / 2 + 0.15)
                shelfGroup.addChildNode(bNode)
            }
        }
        
        // Rows of Books on Shelves (sage, terracotta, linen, and cream tones)
        let bookSpineColors: [NSColor] = [
            NSColor(red: 0.52, green: 0.60, blue: 0.50, alpha: 1.0), // Sage
            NSColor(red: 0.78, green: 0.48, blue: 0.38, alpha: 1.0), // Terracotta
            NSColor(red: 0.88, green: 0.82, blue: 0.70, alpha: 1.0), // Linen
            NSColor(red: 0.68, green: 0.58, blue: 0.45, alpha: 1.0), // Ochre
            NSColor(red: 0.42, green: 0.46, blue: 0.50, alpha: 1.0)  // Slate
        ]
        
        // Shelf 1 Books
        var startX: CGFloat = -1.95
        for i in 0..<10 {
            let h: CGFloat = 0.28 + CGFloat(i % 3) * 0.03
            let w: CGFloat = 0.045 + CGFloat((i * 7) % 4) * 0.012
            let book = SCNBox(width: w, height: h, length: 0.22, chamferRadius: 0.004)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = bookSpineColors[i % bookSpineColors.count]
            book.materials = [bMat]
            let bNode = SCNNode(geometry: book)
            bNode.position = SCNVector3(startX + w / 2, 2.62 + h / 2 + 0.018, -roomDepth / 2 + 0.14)
            shelfGroup.addChildNode(bNode)
            startX += w + 0.008
        }
        
        // Wooden Storage Keepsake Box with Lid on top shelf
        let boxGeo = SCNBox(width: 0.38, height: 0.22, length: 0.26, chamferRadius: 0.01)
        boxGeo.materials = [woodMat]
        let boxNode = SCNNode(geometry: boxGeo)
        boxNode.position = SCNVector3(-0.35, 3.05 + 0.11 + 0.018, -roomDepth / 2 + 0.15)
        shelfGroup.addChildNode(boxNode)
        
        // Small White Cat Figurine on top shelf
        let catFigGeo = SCNSphere(radius: 0.055)
        let cfMat = SCNMaterial()
        cfMat.diffuse.contents = NSColor(white: 0.96, alpha: 1.0)
        catFigGeo.materials = [cfMat]
        let cfNode = SCNNode(geometry: catFigGeo)
        cfNode.position = SCNVector3(-0.75, 3.05 + 0.055 + 0.018, -roomDepth / 2 + 0.15)
        shelfGroup.addChildNode(cfNode)
        
        // Vintage Brass Alarm Clock
        let clock = SCNCylinder(radius: 0.065, height: 0.045)
        clock.materials = [brassMat]
        let clockNode = SCNNode(geometry: clock)
        clockNode.eulerAngles.x = .pi / 2
        clockNode.position = SCNVector3(-0.25, 2.62 + 0.075, -roomDepth / 2 + 0.12)
        shelfGroup.addChildNode(clockNode)
        
        // Cascading Trailing Ivy Vines (tumbling down shelf edges & left wall)
        buildCascadingIvy(in: shelfGroup, reduceMotion: reduceMotion)
        
        root.addChildNode(shelfGroup)
    }
    
    // MARK: - 5. Right Daybed Nook & Cookie Character
    
    private static func buildDaybedNook(in root: SCNNode, reduceMotion: Bool) {
        let bedGroup = SCNNode()
        let woodMat = Materials.honeyOak
        let linenMat = Materials.linenWhite
        let sageMat = Materials.fabricSage
        
        // Daybed Dimensions
        let bedW: CGFloat = 1.45 // X span
        let bedL: CGFloat = 1.95 // Z span
        let bedBaseH: CGFloat = 0.32
        
        bedGroup.position = SCNVector3(1.15, 0.14, -0.85)
        bedGroup.name = "daybed_nook"
        
        // Solid Oak Bed Frame Base
        let bedFrame = SCNBox(width: bedW, height: bedBaseH, length: bedL, chamferRadius: 0.02)
        bedFrame.materials = [woodMat]
        let bedFrameNode = SCNNode(geometry: bedFrame)
        bedFrameNode.position = SCNVector3(0, bedBaseH / 2, 0)
        bedGroup.addChildNode(bedFrameNode)
        
        // Solid Oak Headboard against back wall
        let headboard = SCNBox(width: bedW, height: 0.75, length: 0.08, chamferRadius: 0.015)
        headboard.materials = [woodMat]
        let hbNode = SCNNode(geometry: headboard)
        hbNode.position = SCNVector3(0, bedBaseH + 0.375, -bedL / 2 + 0.04)
        bedGroup.addChildNode(hbNode)
        
        // Plump White Mattress & Sheets
        let mattress = SCNBox(width: bedW - 0.08, height: 0.22, length: bedL - 0.12, chamferRadius: 0.04)
        mattress.materials = [linenMat]
        let matNode = SCNNode(geometry: mattress)
        matNode.position = SCNVector3(0, bedBaseH + 0.11, 0.02)
        bedGroup.addChildNode(matNode)
        
        // Stacked White Sleeping Pillows at head of bed
        let pillowGeo = SCNBox(width: 0.52, height: 0.12, length: 0.36, chamferRadius: 0.05)
        pillowGeo.materials = [linenMat]
        
        for px in [-bedW * 0.22, bedW * 0.22] {
            let pNode = SCNNode(geometry: pillowGeo)
            pNode.position = SCNVector3(px, bedBaseH + 0.25, -bedL / 2 + 0.30)
            pNode.eulerAngles.x = 0.15
            bedGroup.addChildNode(pNode)
        }
        
        // Folded Soft Sage Green Throw Blanket with subtle fringe at foot of bed
        let blanketGeo = SCNBox(width: bedW - 0.06, height: 0.08, length: 0.85, chamferRadius: 0.035)
        blanketGeo.materials = [sageMat]
        let blanketNode = SCNNode(geometry: blanketGeo)
        blanketNode.position = SCNVector3(0, bedBaseH + 0.23, bedL * 0.18)
        bedGroup.addChildNode(blanketNode)
        
        // Daisy Flower Pillow on bed (White petals with yellow center)
        let daisyNode = buildDaisyPillow()
        daisyNode.position = SCNVector3(-0.35, bedBaseH + 0.24, -0.15)
        daisyNode.eulerAngles.x = 0.20
        bedGroup.addChildNode(daisyNode)
        
        // Cookie the Cat curled up sleeping soundly on the sage green blanket
        let catNode = CookieNode()
        catNode.reduceMotion = reduceMotion
        catNode.position = SCNVector3(0.08, bedBaseH + 0.27, 0.15)
        catNode.eulerAngles.y = -0.35 // Angled warmly toward the room
        catNode.name = "cookie_character"
        
        // Sleeping breathing animation (chest rises and falls every 3.2s)
        if !reduceMotion {
            let inhale = SCNAction.scale(to: 1.03, duration: 1.8)
            inhale.timingMode = .easeInEaseOut
            let exhale = SCNAction.scale(to: 0.98, duration: 2.0)
            exhale.timingMode = .easeInEaseOut
            let breathe = SCNAction.sequence([inhale, exhale])
            catNode.runAction(SCNAction.repeatForever(breathe), forKey: "cookie_breathing")
        }
        
        bedGroup.addChildNode(catNode)
        
        // Small Oak Nightstand beside the bed
        let nightstand = SCNBox(width: 0.42, height: bedBaseH + 0.12, length: 0.42, chamferRadius: 0.012)
        nightstand.materials = [woodMat]
        let nsNode = SCNNode(geometry: nightstand)
        nsNode.position = SCNVector3(-bedW / 2 - 0.25, (bedBaseH + 0.12) / 2, 0.45)
        
        let nsPot = SCNCylinder(radius: 0.042, height: 0.065)
        nsPot.materials = [Materials.satinCeramic]
        let nsPotNode = SCNNode(geometry: nsPot)
        nsPotNode.position = SCNVector3(0, (bedBaseH + 0.12) / 2 + 0.035, 0)
        nsNode.addChildNode(nsPotNode)
        bedGroup.addChildNode(nsNode)
        
        root.addChildNode(bedGroup)
    }
    
    // MARK: - 6. Record Player Bench, Floor Monstera & Sconce Lighting
    
    private static func buildRecordBenchAndLighting(
        in root: SCNNode,
        environment: RoomTimeOfDay,
        reduceMotion: Bool
    ) -> (SCNNode, SCNLight) {
        let benchGroup = SCNNode()
        let woodMat = Materials.honeyOak
        let sageMat = Materials.fabricSage
        let brassMat = Materials.brushedBrass
        
        // Positioned at the foot of the bed on the upper platform
        benchGroup.position = SCNVector3(1.15, 0.14, 0.45)
        benchGroup.name = "record_bench_group"
        
        // Low Oak Bench Base
        let benchW: CGFloat = 0.95
        let benchL: CGFloat = 0.65
        let benchH: CGFloat = 0.28
        let benchBase = SCNBox(width: benchW, height: 0.06, length: benchL, chamferRadius: 0.01)
        benchBase.materials = [woodMat]
        let bbNode = SCNNode(geometry: benchBase)
        bbNode.position = SCNVector3(0, benchH - 0.03, 0)
        benchGroup.addChildNode(bbNode)
        
        // Bench Legs
        for (lx, lz) in [(-benchW * 0.42, -benchL * 0.42), (benchW * 0.42, -benchL * 0.42), (-benchW * 0.42, benchL * 0.42), (benchW * 0.42, benchL * 0.42)] {
            let leg = SCNCylinder(radius: 0.024, height: benchH - 0.06)
            leg.materials = [woodMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(lx, (benchH - 0.06) / 2, lz)
            benchGroup.addChildNode(legNode)
        }
        
        // Sage Green Upholstered Bench Cushion Top
        let cushion = SCNBox(width: benchW - 0.04, height: 0.09, length: benchL - 0.04, chamferRadius: 0.03)
        cushion.materials = [sageMat]
        let cNode = SCNNode(geometry: cushion)
        cNode.position = SCNVector3(0, benchH + 0.045, 0)
        benchGroup.addChildNode(cNode)
        
        // Vintage Portable Suitcase Record Player (Pastel cream/rose body with spinning vinyl)
        let (recordPlayerNode, recordDiscNode) = buildRecordPlayer(reduceMotion: reduceMotion)
        recordPlayerNode.position = SCNVector3(0.08, benchH + 0.09, 0.02)
        benchGroup.addChildNode(recordPlayerNode)
        
        // Stack of Vinyl Record Sleeves / Art Books next to player
        let recordStackGeo = SCNBox(width: 0.28, height: 0.045, length: 0.28, chamferRadius: 0.006)
        let rsMat = SCNMaterial()
        rsMat.diffuse.contents = NSColor(red: 0.82, green: 0.60, blue: 0.48, alpha: 1.0)
        recordStackGeo.materials = [rsMat]
        let rsNode = SCNNode(geometry: recordStackGeo)
        rsNode.position = SCNVector3(-benchW * 0.28, benchH + 0.09 + 0.0225, 0.02)
        rsNode.eulerAngles.y = 0.12
        benchGroup.addChildNode(rsNode)
        
        root.addChildNode(benchGroup)
        
        // Large Floor Potted Monstera Deliciosa Plant (Right of bench)
        let monsteraNode = buildMonsteraPlant(reduceMotion: reduceMotion)
        monsteraNode.position = SCNVector3(1.75, 0.14, 0.72)
        root.addChildNode(monsteraNode)
        
        // Bronze Wall Sconce Lamp above bed on the right wall
        let sconceGroup = SCNNode()
        sconceGroup.position = SCNVector3(roomWidth / 2 - 0.02, 2.25, 0.42)
        sconceGroup.name = "wall_sconce"
        
        let sconcePlate = SCNCylinder(radius: 0.055, height: 0.015)
        sconcePlate.materials = [brassMat]
        let spNode = SCNNode(geometry: sconcePlate)
        spNode.eulerAngles.z = .pi / 2
        sconceGroup.addChildNode(spNode)
        
        let sconceArm = SCNCylinder(radius: 0.012, height: 0.14)
        sconceArm.materials = [brassMat]
        let saNode = SCNNode(geometry: sconceArm)
        saNode.position = SCNVector3(-0.07, -0.02, 0)
        saNode.eulerAngles.z = .pi / 4
        sconceGroup.addChildNode(saNode)
        
        let sconceShade = SCNCylinder(radius: 0.055, height: 0.08)
        let ssMat = SCNMaterial()
        ssMat.diffuse.contents = NSColor(red: 0.55, green: 0.42, blue: 0.32, alpha: 1.0) // Warm bronze
        ssMat.roughness.contents = 0.5
        sconceShade.materials = [ssMat]
        let ssNode = SCNNode(geometry: sconceShade)
        ssNode.position = SCNVector3(-0.14, -0.07, 0)
        ssNode.eulerAngles.z = .pi / 6
        sconceGroup.addChildNode(ssNode)
        
        // Wall Sconce Light Source
        let sconceLight = SCNLight()
        sconceLight.type = .omni
        sconceLight.color = NSColor(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0)
        sconceLight.intensity = environment.isDeskLampDefaultOn ? 750 : 0
        sconceLight.castsShadow = true
        sconceLight.shadowRadius = 3.0
        
        let slNode = SCNNode()
        slNode.light = sconceLight
        slNode.position = SCNVector3(-0.16, -0.10, 0)
        sconceGroup.addChildNode(slNode)
        
        // Framed Wall Art Prints hung on the right wall
        let artFrames: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.18, 2.35, 0.28, 0.38),
            (-0.35, 2.15, 0.22, 0.30),
            (0.55, 1.85, 0.20, 0.25)
        ]
        for (i, af) in artFrames.enumerated() {
            let frame = SCNBox(width: 0.015, height: af.3, length: af.2, chamferRadius: 0.005)
            frame.materials = [woodMat]
            let fNode = SCNNode(geometry: frame)
            fNode.position = SCNVector3(roomWidth / 2 - 0.01, af.1, af.0)
            
            // Botanical art print content
            let printGeo = SCNPlane(width: af.2 - 0.04, height: af.3 - 0.04)
            let prMat = SCNMaterial()
            prMat.diffuse.contents = (i % 2 == 0) ? NSColor(red: 0.86, green: 0.88, blue: 0.82, alpha: 1.0) : NSColor(red: 0.94, green: 0.88, blue: 0.80, alpha: 1.0)
            prMat.roughness.contents = 0.9
            printGeo.materials = [prMat]
            let prNode = SCNNode(geometry: printGeo)
            prNode.eulerAngles.y = -.pi / 2
            prNode.position = SCNVector3(-0.01, 0, 0)
            fNode.addChildNode(prNode)
            root.addChildNode(fNode)
        }
        
        root.addChildNode(sconceGroup)
        return (recordPlayerNode, sconceLight)
    }
    
    // MARK: - 7. Lower Sunken Lounge (Skateboard, Boucle Pouf & Step Accents)
    
    private static func buildLowerLounge(in root: SCNNode) {
        let loungeGroup = SCNNode()
        loungeGroup.name = "lower_lounge_group"
        
        // Skateboard resting naturally at an angle on the floor
        let skateboardNode = buildSkateboard()
        skateboardNode.position = SCNVector3(0.28, 0.045, 0.92)
        skateboardNode.eulerAngles.y = -0.32
        skateboardNode.name = "skateboard"
        loungeGroup.addChildNode(skateboardNode)
        
        // Cream Boucle Beanbag Chair / Pouf
        let pouf = SCNSphere(radius: 0.38)
        pouf.materials = [Materials.linenWhite]
        let poufNode = SCNNode(geometry: pouf)
        poufNode.scale = SCNVector3(1.15, 0.65, 1.15)
        poufNode.position = SCNVector3(1.35, 0.22, 1.25)
        
        // White daisy flower pillow on the pouf
        let poufDaisy = buildDaisyPillow()
        poufDaisy.position = SCNVector3(0, 0.32, 0)
        poufDaisy.eulerAngles.x = 0.15
        poufNode.addChildNode(poufDaisy)
        loungeGroup.addChildNode(poufNode)
        
        // Miniature Potted Succulent on the step corner
        let stepPot = SCNCylinder(radius: 0.045, height: 0.075)
        stepPot.materials = [Materials.satinCeramic]
        let stepPotNode = SCNNode(geometry: stepPot)
        stepPotNode.position = SCNVector3(-0.75, 0.14 + 0.038, 0.42)
        
        let spSucc = SCNSphere(radius: 0.045)
        let spMat = SCNMaterial()
        spMat.diffuse.contents = NSColor(red: 0.45, green: 0.62, blue: 0.42, alpha: 1.0)
        spSucc.materials = [spMat]
        let spSuccNode = SCNNode(geometry: spSucc)
        spSuccNode.position = SCNVector3(0, 0.04, 0)
        stepPotNode.addChildNode(spSuccNode)
        loungeGroup.addChildNode(stepPotNode)
        
        // Small Stack of Books on step edge with tiny plant
        for i in 0..<2 {
            let book = SCNBox(width: 0.18, height: 0.035, length: 0.24, chamferRadius: 0.005)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = (i == 0) ? NSColor(red: 0.72, green: 0.52, blue: 0.42, alpha: 1.0) : NSColor(red: 0.52, green: 0.60, blue: 0.52, alpha: 1.0)
            book.materials = [bMat]
            let bNode = SCNNode(geometry: book)
            bNode.position = SCNVector3(-1.05, 0.14 + CGFloat(i) * 0.038 + 0.018, 0.95)
            bNode.eulerAngles.y = CGFloat(i) * 0.12
            loungeGroup.addChildNode(bNode)
        }
        
        let tinyPot = SCNCylinder(radius: 0.028, height: 0.045)
        tinyPot.materials = [Materials.satinCeramic]
        let tpNode = SCNNode(geometry: tinyPot)
        tpNode.position = SCNVector3(-1.05, 0.14 + 0.076 + 0.023, 0.95)
        loungeGroup.addChildNode(tpNode)
        
        root.addChildNode(loungeGroup)
    }
    
    // MARK: - 8. Atmospheric Lighting & Dust Motes Particle System
    
    private static func setupLightingAndAtmosphere(
        in root: SCNNode,
        environment: RoomTimeOfDay,
        reduceMotion: Bool
    ) -> (SCNLight, SCNLight, SCNParticleSystem?) {
        
        // 1. Natural Directional Sunlight streaming in through the right window
        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.color = environment.sunlightColor
        sunLight.intensity = environment.sunlightIntensity
        sunLight.castsShadow = true
        sunLight.shadowRadius = 4.0
        sunLight.shadowSampleCount = 16
        sunLight.shadowColor = NSColor(white: 0.10, alpha: 0.45)
        
        let sunNode = SCNNode()
        sunNode.light = sunLight
        // Positioned outside right window, slanting into bed & desk
        sunNode.position = SCNVector3(5.5, 5.8, -0.35)
        sunNode.eulerAngles = SCNVector3(-0.62, 1.25, 0)
        sunNode.name = "sun_light"
        
        // Very subtle daylight angle drift over time (calm, organic room aliveness)
        if !reduceMotion {
            let driftRight = SCNAction.rotateBy(x: 0.02, y: -0.04, z: 0, duration: 60)
            let driftLeft = SCNAction.rotateBy(x: -0.02, y: 0.04, z: 0, duration: 60)
            sunNode.runAction(SCNAction.repeatForever(SCNAction.sequence([driftRight, driftLeft])), forKey: "daylight_drift")
        }
        root.addChildNode(sunNode)
        
        // 2. Ambient Fill Light (Soft warm interior daylight)
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = environment.ambientColor
        ambientLight.intensity = environment.ambientIntensity
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        ambientNode.name = "ambient_light"
        root.addChildNode(ambientNode)
        
        // 3. Tiny Dust Particles floating lazily in the sunlight beam
        var dustParticles: SCNParticleSystem? = nil
        if !reduceMotion {
            let particles = SCNParticleSystem()
            particles.birthRate = 8
            particles.particleLifeSpan = 8.0
            particles.particleLifeSpanVariation = 2.0
            particles.particleVelocity = 0.025
            particles.particleVelocityVariation = 0.015
            particles.emissionDurationVariation = 0.5
            particles.particleSize = 0.016
            particles.particleSizeVariation = 0.008
            particles.particleColor = NSColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.40)
            particles.blendMode = .additive
            particles.isLightingEnabled = false
            
            // Confined to the diagonal sunbeam cone inside the window
            particles.emitterShape = SCNBox(width: 1.4, height: 1.8, length: 1.8, chamferRadius: 0)
            particles.spreadingAngle = 25
            particles.acceleration = SCNVector3(x: -0.003, y: -0.002, z: 0.002)
            
            let dustNode = SCNNode()
            dustNode.position = SCNVector3(1.2, 1.6, -0.15)
            dustNode.addParticleSystem(particles)
            dustNode.name = "dust_motes_node"
            root.addChildNode(dustNode)
            dustParticles = particles
        }
        
        return (sunLight, ambientLight, dustParticles)
    }
    
    // MARK: - 9. Isometric Camera
    
    private static func setupCamera(in root: SCNNode) {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        camera.fieldOfView = 35 // Dollhouse miniature perspective matching the reference image
        camera.zNear = 0.5
        camera.zFar = 50.0
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.name = "main_room_camera"
        
        // Classic three-quarter isometric perspective looking into the cutaway corner
        cameraNode.position = SCNVector3(5.8, 5.2, 6.2)
        
        let lookAtTarget = SCNNode()
        lookAtTarget.position = SCNVector3(-0.15, 0.95, -0.10)
        lookAtTarget.name = "camera_look_at_target"
        root.addChildNode(lookAtTarget)
        
        let constraint = SCNLookAtConstraint(target: lookAtTarget)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        
        root.addChildNode(cameraNode)
    }
    
    // MARK: - Reusable Procedural Fixture Builders
    
    /// Constructs the sleek computer monitor displaying cursive "hello ♡".
    private static func buildComputerMonitor() -> (SCNNode, SCNLight) {
        let monitorGroup = SCNNode()
        monitorGroup.name = "computer_monitor"
        
        let whiteMat = SCNMaterial()
        whiteMat.diffuse.contents = NSColor(white: 0.94, alpha: 1.0)
        whiteMat.roughness.contents = 0.3
        
        // Metal Rectangular Base
        let base = SCNBox(width: 0.28, height: 0.012, length: 0.18, chamferRadius: 0.006)
        base.materials = [whiteMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.006, 0)
        monitorGroup.addChildNode(baseNode)
        
        // Metal Curved Neck
        let neck = SCNBox(width: 0.045, height: 0.24, length: 0.035, chamferRadius: 0.008)
        neck.materials = [whiteMat]
        let neckNode = SCNNode(geometry: neck)
        neckNode.position = SCNVector3(0, 0.12, -0.02)
        neckNode.eulerAngles.x = -0.15
        monitorGroup.addChildNode(neckNode)
        
        // Monitor Screen Housing
        let width: CGFloat = 0.88
        let height: CGFloat = 0.54
        let housing = SCNBox(width: width, height: height, length: 0.03, chamferRadius: 0.012)
        housing.materials = [whiteMat]
        let housingNode = SCNNode(geometry: housing)
        housingNode.position = SCNVector3(0, 0.36, 0)
        
        // Display Plane with "hello ♡" signature wallpaper
        let screenPlane = SCNPlane(width: width - 0.03, height: height - 0.03)
        let screenMat = SCNMaterial()
        screenMat.diffuse.contents = Textures.makeMonitorScreenTexture()
        screenMat.emission.contents = Textures.makeMonitorScreenTexture()
        screenMat.emission.intensity = 0.25
        screenMat.lightingModel = .constant
        screenPlane.materials = [screenMat]
        let screenNode = SCNNode(geometry: screenPlane)
        screenNode.position = SCNVector3(0, 0, 0.016)
        screenNode.name = "monitor_display"
        housingNode.addChildNode(screenNode)
        
        // Subtle screen soft glow
        let glow = SCNLight()
        glow.type = .omni
        glow.color = NSColor(red: 0.95, green: 0.98, blue: 0.95, alpha: 1.0)
        glow.intensity = 180
        let glowNode = SCNNode()
        glowNode.light = glow
        glowNode.position = SCNVector3(0, 0, 0.12)
        housingNode.addChildNode(glowNode)
        
        monitorGroup.addChildNode(housingNode)
        return (monitorGroup, glow)
    }
    
    /// Constructs the open laptop displaying matching scenic wallpaper.
    private static func buildOpenLaptop() -> SCNNode {
        let laptopGroup = SCNNode()
        laptopGroup.name = "open_laptop"
        
        let silverMat = SCNMaterial()
        silverMat.diffuse.contents = NSColor(white: 0.88, alpha: 1.0)
        silverMat.metalness.contents = 0.5
        silverMat.roughness.contents = 0.35
        
        // Laptop Base with keyboard & trackpad
        let baseW: CGFloat = 0.38
        let baseD: CGFloat = 0.26
        let base = SCNBox(width: baseW, height: 0.012, length: baseD, chamferRadius: 0.005)
        base.materials = [silverMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.006, 0)
        laptopGroup.addChildNode(baseNode)
        
        // Laptop Lid / Screen open at 115 degrees
        let lid = SCNBox(width: baseW, height: baseD, length: 0.008, chamferRadius: 0.004)
        lid.materials = [silverMat]
        let lidNode = SCNNode(geometry: lid)
        lidNode.position = SCNVector3(0, baseD / 2, -baseD / 2)
        lidNode.eulerAngles.x = -0.45
        
        // Screen display plane
        let screen = SCNPlane(width: baseW - 0.02, height: baseD - 0.02)
        let sMat = SCNMaterial()
        sMat.diffuse.contents = Textures.makeLaptopScreenTexture()
        sMat.emission.contents = Textures.makeLaptopScreenTexture()
        sMat.emission.intensity = 0.3
        sMat.lightingModel = .constant
        screen.materials = [sMat]
        let sNode = SCNNode(geometry: screen)
        sNode.position = SCNVector3(0, 0, 0.005)
        sNode.name = "laptop_display"
        lidNode.addChildNode(sNode)
        
        laptopGroup.addChildNode(lidNode)
        return laptopGroup
    }
    
    /// Constructs the high-back ergonomic office chair.
    private static func buildErgonomicChair() -> SCNNode {
        let chairGroup = SCNNode()
        chairGroup.name = "ergonomic_chair"
        
        let whiteMat = SCNMaterial()
        whiteMat.diffuse.contents = NSColor(white: 0.94, alpha: 1.0)
        whiteMat.roughness.contents = 0.4
        let sageMat = Materials.fabricSage
        
        // 5-Star Casters Base
        for i in 0..<5 {
            let angle = CGFloat(i) * (.pi * 2 / 5)
            let leg = SCNCylinder(radius: 0.016, height: 0.28)
            leg.materials = [whiteMat]
            let legNode = SCNNode(geometry: leg)
            legNode.eulerAngles.z = .pi / 2
            legNode.eulerAngles.y = angle
            legNode.position = SCNVector3(cos(angle) * 0.14, 0.035, sin(angle) * 0.14)
            chairGroup.addChildNode(legNode)
            
            // Tiny caster wheels
            let wheel = SCNSphere(radius: 0.022)
            let wMat = SCNMaterial()
            wMat.diffuse.contents = NSColor(white: 0.25, alpha: 1.0)
            wheel.materials = [wMat]
            let wNode = SCNNode(geometry: wheel)
            wNode.position = SCNVector3(cos(angle) * 0.27, 0.022, sin(angle) * 0.27)
            chairGroup.addChildNode(wNode)
        }
        
        // Center Cylinder / Gas Lift
        let cylinder = SCNCylinder(radius: 0.028, height: 0.38)
        let cMat = SCNMaterial()
        cMat.diffuse.contents = NSColor(white: 0.85, alpha: 1.0)
        cMat.metalness.contents = 0.8
        cylinder.materials = [cMat]
        let cylNode = SCNNode(geometry: cylinder)
        cylNode.position = SCNVector3(0, 0.22, 0)
        chairGroup.addChildNode(cylNode)
        
        // Sage Fabric Contoured Seat Cushion
        let seat = SCNBox(width: 0.54, height: 0.08, length: 0.52, chamferRadius: 0.04)
        seat.materials = [sageMat]
        let seatNode = SCNNode(geometry: seat)
        seatNode.position = SCNVector3(0, 0.44, 0)
        chairGroup.addChildNode(seatNode)
        
        // Arched White Backrest Frame with Sage Fabric Mesh
        let backrest = SCNBox(width: 0.50, height: 0.58, length: 0.05, chamferRadius: 0.03)
        backrest.materials = [sageMat]
        let brNode = SCNNode(geometry: backrest)
        brNode.position = SCNVector3(0, 0.76, 0.24)
        brNode.eulerAngles.x = 0.12
        chairGroup.addChildNode(brNode)
        
        // White Curved Armrests
        for ax in [-0.28, 0.28] {
            let arm = SCNBox(width: 0.045, height: 0.025, length: 0.30, chamferRadius: 0.01)
            arm.materials = [whiteMat]
            let armNode = SCNNode(geometry: arm)
            armNode.position = SCNVector3(ax, 0.62, 0.05)
            chairGroup.addChildNode(armNode)
        }
        
        return chairGroup
    }
    
    /// Constructs the cute ceramic mug with yellow smiling face.
    private static func buildSmileyMug() -> SCNNode {
        let mugNode = SCNNode()
        let cup = SCNCylinder(radius: 0.045, height: 0.09)
        let cupMat = SCNMaterial()
        cupMat.diffuse.contents = NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        cupMat.roughness.contents = 0.35
        cup.materials = [cupMat]
        let cupNode = SCNNode(geometry: cup)
        mugNode.addChildNode(cupNode)
        
        // Handle
        let handle = SCNTorus(ringRadius: 0.032, pipeRadius: 0.008)
        handle.materials = [cupMat]
        let handleNode = SCNNode(geometry: handle)
        handleNode.position = SCNVector3(0.048, 0, 0)
        handleNode.eulerAngles.x = .pi / 2
        mugNode.addChildNode(handleNode)
        
        // Yellow Smiley Face decal badge
        let smiley = SCNSphere(radius: 0.024)
        let smMat = SCNMaterial()
        smMat.diffuse.contents = NSColor(red: 0.98, green: 0.82, blue: 0.32, alpha: 1.0)
        smiley.materials = [smMat]
        let smNode = SCNNode(geometry: smiley)
        smNode.scale = SCNVector3(0.3, 1.0, 1.0)
        smNode.position = SCNVector3(0, 0, 0.046)
        mugNode.addChildNode(smNode)
        
        return mugNode
    }
    
    /// Constructs the articulated cream desk lamp with warm spotlight.
    private static func buildDeskLamp(environment: RoomTimeOfDay) -> (SCNNode, SCNLight) {
        let lampNode = SCNNode()
        lampNode.name = "desk_lamp"
        
        let creamMat = SCNMaterial()
        creamMat.diffuse.contents = NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
        creamMat.roughness.contents = 0.4
        let brassMat = Materials.brushedBrass
        
        // Round Base
        let base = SCNCylinder(radius: 0.085, height: 0.02)
        base.materials = [brassMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.01, 0)
        lampNode.addChildNode(baseNode)
        
        // Articulated Stem with brass joints
        let stem1 = SCNCylinder(radius: 0.014, height: 0.28)
        stem1.materials = [brassMat]
        let s1Node = SCNNode(geometry: stem1)
        s1Node.position = SCNVector3(-0.04, 0.14, 0)
        s1Node.eulerAngles.z = 0.25
        lampNode.addChildNode(s1Node)
        
        let stem2 = SCNCylinder(radius: 0.014, height: 0.24)
        stem2.materials = [brassMat]
        let s2Node = SCNNode(geometry: stem2)
        s2Node.position = SCNVector3(-0.10, 0.32, 0)
        s2Node.eulerAngles.z = -0.55
        lampNode.addChildNode(s2Node)
        
        // Cream Dome Shade
        let shade = SCNCylinder(radius: 0.08, height: 0.09)
        shade.materials = [creamMat]
        let shadeNode = SCNNode(geometry: shade)
        shadeNode.position = SCNVector3(-0.18, 0.38, 0)
        shadeNode.eulerAngles.z = -0.85
        lampNode.addChildNode(shadeNode)
        
        // Lamp Spotlight
        let lampLight = SCNLight()
        lampLight.type = .spot
        lampLight.color = NSColor(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0)
        lampLight.intensity = environment.isDeskLampDefaultOn ? 950 : 0
        lampLight.spotInnerAngle = 38
        lampLight.spotOuterAngle = 72
        lampLight.castsShadow = true
        lampLight.shadowRadius = 2.5
        
        let lightNode = SCNNode()
        lightNode.light = lampLight
        lightNode.position = SCNVector3(-0.20, 0.36, 0)
        lightNode.eulerAngles.x = -.pi / 2.2
        lightNode.eulerAngles.y = 0.25
        lampNode.addChildNode(lightNode)
        
        return (lampNode, lampLight)
    }
    
    /// Constructs the white 6-petal daisy cushion with sunny yellow center.
    private static func buildDaisyPillow() -> SCNNode {
        let daisyGroup = SCNNode()
        let petalMat = Materials.linenWhite
        let centerMat = SCNMaterial()
        centerMat.diffuse.contents = NSColor(red: 0.98, green: 0.82, blue: 0.30, alpha: 1.0)
        centerMat.roughness.contents = 0.85
        
        // 6 Petals
        for i in 0..<6 {
            let angle = CGFloat(i) * (.pi * 2 / 6)
            let petal = SCNSphere(radius: 0.075)
            petal.materials = [petalMat]
            let pNode = SCNNode(geometry: petal)
            pNode.scale = SCNVector3(1.2, 0.45, 0.75)
            pNode.position = SCNVector3(cos(angle) * 0.10, 0, sin(angle) * 0.10)
            pNode.eulerAngles.y = angle
            daisyGroup.addChildNode(pNode)
        }
        
        // Plump Yellow Center
        let center = SCNSphere(radius: 0.072)
        center.materials = [centerMat]
        let cNode = SCNNode(geometry: center)
        cNode.scale = SCNVector3(1.0, 0.55, 1.0)
        cNode.position = SCNVector3(0, 0.015, 0)
        daisyGroup.addChildNode(cNode)
        
        return daisyGroup
    }
    
    /// Constructs the vintage suitcase record player with spinning black vinyl record.
    private static func buildRecordPlayer(reduceMotion: Bool) -> (SCNNode, SCNNode) {
        let playerGroup = SCNNode()
        playerGroup.name = "record_player"
        
        let caseMat = SCNMaterial()
        caseMat.diffuse.contents = NSColor(red: 0.92, green: 0.82, blue: 0.78, alpha: 1.0) // Vintage blush cream
        caseMat.roughness.contents = 0.55
        let brassMat = Materials.brushedBrass
        
        // Suitcase Body Base
        let bodyW: CGFloat = 0.36
        let bodyL: CGFloat = 0.32
        let bodyH: CGFloat = 0.07
        let body = SCNBox(width: bodyW, height: bodyH, length: bodyL, chamferRadius: 0.015)
        body.materials = [caseMat]
        let bNode = SCNNode(geometry: body)
        bNode.position = SCNVector3(0, bodyH / 2, 0)
        playerGroup.addChildNode(bNode)
        
        // Open Suitcase Lid
        let lid = SCNBox(width: bodyW, height: 0.035, length: bodyL, chamferRadius: 0.015)
        lid.materials = [caseMat]
        let lidNode = SCNNode(geometry: lid)
        lidNode.position = SCNVector3(0, bodyH + 0.14, -bodyL / 2)
        lidNode.eulerAngles.x = 0.85
        playerGroup.addChildNode(lidNode)
        
        // Turntable Platter & Vinyl Record
        let recordDisc = SCNCylinder(radius: 0.115, height: 0.008)
        let recordMat = SCNMaterial()
        recordMat.diffuse.contents = NSColor(white: 0.12, alpha: 1.0)
        recordMat.specular.contents = NSColor(white: 0.35, alpha: 1.0)
        recordMat.roughness.contents = 0.25
        recordDisc.materials = [recordMat]
        let discNode = SCNNode(geometry: recordDisc)
        discNode.position = SCNVector3(-0.04, bodyH + 0.005, 0)
        discNode.name = "vinyl_record_disc"
        
        // Pastel Center Label
        let label = SCNCylinder(radius: 0.042, height: 0.009)
        let lMat = SCNMaterial()
        lMat.diffuse.contents = NSColor(red: 0.95, green: 0.65, blue: 0.55, alpha: 1.0)
        label.materials = [lMat]
        let labelNode = SCNNode(geometry: label)
        discNode.addChildNode(labelNode)
        
        // Spinning Vinyl Animation
        if !reduceMotion {
            let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.2)
            discNode.runAction(SCNAction.repeatForever(spin), forKey: "vinyl_spin")
        }
        playerGroup.addChildNode(discNode)
        
        // Tonearm
        let arm = SCNCylinder(radius: 0.006, height: 0.16)
        arm.materials = [brassMat]
        let armNode = SCNNode(geometry: arm)
        armNode.position = SCNVector3(0.11, bodyH + 0.02, -0.02)
        armNode.eulerAngles.z = .pi / 2
        armNode.eulerAngles.y = 0.45
        playerGroup.addChildNode(armNode)
        
        return (playerGroup, discNode)
    }
    
    /// Constructs the skateboard with black grip-tape and birch ply edge.
    private static func buildSkateboard() -> SCNNode {
        let boardGroup = SCNNode()
        
        // Birch Ply Deck with Black Grip-Tape Top
        let deckW: CGFloat = 0.18
        let deckL: CGFloat = 0.68
        let deck = SCNBox(width: deckW, height: 0.016, length: deckL, chamferRadius: 0.02)
        let gripMat = SCNMaterial()
        gripMat.diffuse.contents = NSColor(white: 0.16, alpha: 1.0) // Black grip-tape
        gripMat.roughness.contents = 0.95
        deck.materials = [gripMat]
        let deckNode = SCNNode(geometry: deck)
        deckNode.position = SCNVector3(0, 0.04, 0)
        boardGroup.addChildNode(deckNode)
        
        // Metal Trucks & 4 Wheels
        for z in [-deckL * 0.35, deckL * 0.35] {
            let truck = SCNBox(width: deckW * 0.75, height: 0.018, length: 0.025, chamferRadius: 0.004)
            truck.materials = [Materials.brushedBrass]
            let tNode = SCNNode(geometry: truck)
            tNode.position = SCNVector3(0, 0.024, z)
            boardGroup.addChildNode(tNode)
            
            for x in [-deckW * 0.45, deckW * 0.45] {
                let wheel = SCNCylinder(radius: 0.024, height: 0.024)
                let wMat = SCNMaterial()
                wMat.diffuse.contents = NSColor(red: 0.94, green: 0.92, blue: 0.85, alpha: 1.0) // Ivory urethane
                wheel.materials = [wMat]
                let wNode = SCNNode(geometry: wheel)
                wNode.eulerAngles.z = .pi / 2
                wNode.position = SCNVector3(x, 0.024, z)
                boardGroup.addChildNode(wNode)
            }
        }
        
        return boardGroup
    }
    
    /// Constructs the large potted Monstera Deliciosa with split tropical leaves.
    private static func buildMonsteraPlant(reduceMotion: Bool) -> SCNNode {
        let plantGroup = SCNNode()
        plantGroup.name = "monstera_plant"
        
        // Ceramic Cylinder Pot
        let pot = SCNCylinder(radius: 0.15, height: 0.28)
        pot.materials = [Materials.satinCeramic]
        let potNode = SCNNode(geometry: pot)
        potNode.position = SCNVector3(0, 0.14, 0)
        plantGroup.addChildNode(potNode)
        
        // 7 Lush Broad Monstera Leaves at varying heights and angles
        let leafMat = SCNMaterial()
        leafMat.diffuse.contents = NSColor(red: 0.24, green: 0.45, blue: 0.26, alpha: 1.0)
        leafMat.roughness.contents = 0.55
        
        for i in 0..<7 {
            let angle = CGFloat(i) * (.pi * 2 / 7)
            let stemLen: CGFloat = 0.35 + CGFloat(i % 3) * 0.08
            
            let stem = SCNCylinder(radius: 0.008, height: stemLen)
            stem.materials = [leafMat]
            let stemNode = SCNNode(geometry: stem)
            stemNode.position = SCNVector3(cos(angle) * 0.05, 0.14 + stemLen * 0.4, sin(angle) * 0.05)
            stemNode.eulerAngles.y = angle
            stemNode.eulerAngles.z = 0.35
            
            // Broad Leaf Blade
            let leaf = SCNBox(width: 0.22, height: 0.006, length: 0.34, chamferRadius: 0.02)
            leaf.materials = [leafMat]
            let leafNode = SCNNode(geometry: leaf)
            leafNode.position = SCNVector3(0, stemLen * 0.48, 0)
            leafNode.eulerAngles.x = 0.55
            stemNode.addChildNode(leafNode)
            
            // Gentle leaf swaying environmental animation
            if !reduceMotion {
                let sway = SCNAction.rotateBy(x: 0.03, y: 0, z: 0.02, duration: 3.5 + Double(i) * 0.3)
                sway.timingMode = .easeInEaseOut
                let reverse = sway.reversed()
                stemNode.runAction(SCNAction.repeatForever(SCNAction.sequence([sway, reverse])), forKey: "monstera_sway")
            }
            
            plantGroup.addChildNode(stemNode)
        }
        
        return plantGroup
    }
    
    /// Constructs the cascading trailing ivy vines tumbling down over shelves & wall.
    private static func buildCascadingIvy(in parent: SCNNode, reduceMotion: Bool) {
        let vineGroup = SCNNode()
        vineGroup.name = "cascading_ivy"
        vineGroup.position = SCNVector3(-2.15, 3.05, -roomDepth / 2 + 0.25)
        
        let leafMat = SCNMaterial()
        leafMat.diffuse.contents = NSColor(red: 0.32, green: 0.54, blue: 0.30, alpha: 1.0)
        leafMat.roughness.contents = 0.6
        
        // 4 Trailing vine strands hanging down to different levels
        let strandLengths: [Int] = [12, 16, 9, 14]
        for (si, count) in strandLengths.enumerated() {
            let strandNode = SCNNode()
            strandNode.position = SCNVector3(CGFloat(si) * 0.09, 0, CGFloat(si % 2) * 0.04)
            
            for j in 0..<count {
                let leaf = SCNBox(width: 0.055, height: 0.004, length: 0.075, chamferRadius: 0.002)
                leaf.materials = [leafMat]
                let lNode = SCNNode(geometry: leaf)
                lNode.position = SCNVector3(sin(CGFloat(j)) * 0.02, -CGFloat(j) * 0.065, cos(CGFloat(j)) * 0.015)
                lNode.eulerAngles.y = CGFloat(j) * 0.4
                lNode.eulerAngles.x = 0.35
                strandNode.addChildNode(lNode)
            }
            
            // Soft breeze sway on trailing vines
            if !reduceMotion {
                let sway = SCNAction.rotateBy(x: 0.04, y: 0.02, z: 0.03, duration: 4.0 + Double(si) * 0.4)
                sway.timingMode = .easeInEaseOut
                let rev = sway.reversed()
                strandNode.runAction(SCNAction.repeatForever(SCNAction.sequence([sway, rev])), forKey: "ivy_sway")
            }
            
            vineGroup.addChildNode(strandNode)
        }
        
        parent.addChildNode(vineGroup)
    }
}

// MARK: - Procedural PBR Material Definitions

private enum Materials {
    
    /// Warm Honey-Oak Hardwood (Natural grain warmth, matte satin finish)
    static var honeyOak: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.76, green: 0.58, blue: 0.42, alpha: 1.0)
        mat.roughness.contents = 0.68
        mat.specular.contents = NSColor(white: 0.14, alpha: 1.0)
        return mat
    }
    
    /// Soft Ivory Plaster for room diorama walls
    static var ivoryPlaster: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.965, green: 0.952, blue: 0.925, alpha: 1.0)
        mat.roughness.contents = 0.92
        return mat
    }
    
    /// Muted Brushed Brass for lamp stems, handles, and fixtures
    static var brushedBrass: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.82, green: 0.72, blue: 0.48, alpha: 1.0)
        mat.metalness.contents = 0.65
        mat.roughness.contents = 0.38
        return mat
    }
    
    /// Soft Off-White Linen for bedding, pillows, pouf, and curtains
    static var linenWhite: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1.0)
        mat.roughness.contents = 0.94
        return mat
    }
    
    /// Soft Muted Sage Fabric for chair cushion, throw blanket, and bench
    static var fabricSage: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.55, green: 0.64, blue: 0.55, alpha: 1.0)
        mat.roughness.contents = 0.92
        return mat
    }
    
    /// Satin Glazed Ceramic for plant pots and accessories
    static var satinCeramic: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.95, green: 0.93, blue: 0.89, alpha: 1.0)
        mat.roughness.contents = 0.35
        mat.specular.contents = NSColor(white: 0.30, alpha: 1.0)
        return mat
    }
}

// MARK: - Procedural High-Res Texture Generators

private enum Textures {
    
    /// Generates the crisp monitor screen texture displaying "hello ♡" with landscape.
    static func makeMonitorScreenTexture() -> NSImage {
        let size = CGSize(width: 880, height: 540)
        let img = NSImage(size: size)
        img.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }
        
        // Soft mint/sage gradient sky
        let colors = [
            NSColor(red: 0.92, green: 0.95, blue: 0.90, alpha: 1.0).cgColor,
            NSColor(red: 0.82, green: 0.90, blue: 0.84, alpha: 1.0).cgColor
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: 540), end: CGPoint(x: 0, y: 0), options: [])
        }
        
        // Distant sage mountain silhouettes
        ctx.setFillColor(NSColor(red: 0.48, green: 0.62, blue: 0.50, alpha: 0.45).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: 0, y: 160))
        ctx.addLine(to: CGPoint(x: 220, y: 260))
        ctx.addLine(to: CGPoint(x: 520, y: 140))
        ctx.addLine(to: CGPoint(x: 720, y: 240))
        ctx.addLine(to: CGPoint(x: 880, y: 170))
        ctx.addLine(to: CGPoint(x: 880, y: 0))
        ctx.addLine(to: CGPoint(x: 0, y: 0))
        ctx.closePath()
        ctx.fillPath()
        
        // Elegant cursive "hello ♡" text centered
        let str = "hello ♡"
        let font = NSFont(name: "Snell Roundhand", size: 92) ?? NSFont.systemFont(ofSize: 84, weight: .light)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 0.22, green: 0.32, blue: 0.25, alpha: 1.0)
        ]
        let attrStr = NSAttributedString(string: str, attributes: attrs)
        let textSize = attrStr.size()
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2 + 35,
            width: textSize.width,
            height: textSize.height
        )
        attrStr.draw(in: textRect)
        
        img.unlockFocus()
        return img
    }
    
    /// Generates the open laptop nature wallpaper.
    static func makeLaptopScreenTexture() -> NSImage {
        let size = CGSize(width: 640, height: 440)
        let img = NSImage(size: size)
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }
        
        let colors = [
            NSColor(red: 0.88, green: 0.92, blue: 0.85, alpha: 1.0).cgColor,
            NSColor(red: 0.42, green: 0.58, blue: 0.44, alpha: 1.0).cgColor
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: 440), end: CGPoint(x: 0, y: 0), options: [])
        }
        
        img.unlockFocus()
        return img
    }
    
    /// Generates the woven area rug with subtle sage leaf/botanical patterns.
    static func makeBotanicalRugTexture() -> NSImage {
        let size = CGSize(width: 512, height: 512)
        let img = NSImage(size: size)
        img.lockFocus()
        
        // Warm ivory woven base
        NSColor(red: 0.94, green: 0.92, blue: 0.86, alpha: 1.0).setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Subtle pale sage botanical sprigs
        let sage = NSColor(red: 0.62, green: 0.70, blue: 0.62, alpha: 0.35)
        sage.setFill()
        for x in stride(from: 48, to: 480, by: 96) {
            for y in stride(from: 48, to: 480, by: 96) {
                let leaf = NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 28, height: 16))
                leaf.fill()
            }
        }
        
        img.unlockFocus()
        return img
    }
    
    /// Generates the wooden pegboard hole pattern texture.
    static func makePegboardTexture() -> NSImage {
        let size = CGSize(width: 256, height: 256)
        let img = NSImage(size: size)
        img.lockFocus()
        
        // Warm light birch wood base
        NSColor(red: 0.86, green: 0.78, blue: 0.68, alpha: 1.0).setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Evenly spaced peg holes
        NSColor(red: 0.48, green: 0.40, blue: 0.32, alpha: 0.50).setFill()
        for x in stride(from: 16, to: 248, by: 32) {
            for y in stride(from: 16, to: 248, by: 32) {
                let dot = NSBezierPath(ovalIn: NSRect(x: x - 4, y: y - 4, width: 8, height: 8))
                dot.fill()
            }
        }
        
        img.unlockFocus()
        return img
    }
    
    /// Generates the outdoor sky and tree landscape seen through the window.
    static func makeOutdoorBackdrop(environment: RoomTimeOfDay) -> NSImage {
        let size = CGSize(width: 600, height: 420)
        let img = NSImage(size: size)
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }
        
        // Time-aware sky gradient
        let colors = [
            environment.skyTopColor.cgColor,
            environment.skyHorizonColor.cgColor
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: 420), end: CGPoint(x: 0, y: 120), options: [])
        }
        
        // Lush green treetops and warm rooftops in the lower portion
        ctx.setFillColor(NSColor(red: 0.36, green: 0.54, blue: 0.35, alpha: 1.0).cgColor)
        for i in 0..<7 {
            let cx = CGFloat(i) * 90 + 30
            let cy: CGFloat = 85 + CGFloat((i * 13) % 25)
            let r: CGFloat = 65 + CGFloat((i * 7) % 20)
            ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }
        
        // Soft foreground rooftop accents
        ctx.setFillColor(NSColor(red: 0.72, green: 0.48, blue: 0.38, alpha: 0.85).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: 420, y: 50))
        ctx.addLine(to: CGPoint(x: 500, y: 125))
        ctx.addLine(to: CGPoint(x: 580, y: 50))
        ctx.closePath()
        ctx.fillPath()
        
        // Subtle stars if night mode
        if environment == .night {
            ctx.setFillColor(NSColor(white: 0.90, alpha: 0.65).cgColor)
            for s in 0..<20 {
                let sx = CGFloat((s * 137) % 580) + 10
                let sy = CGFloat((s * 211) % 260) + 150
                ctx.fillEllipse(in: CGRect(x: sx, y: sy, width: 2.2, height: 2.2))
            }
        }
        
        img.unlockFocus()
        return img
    }
}

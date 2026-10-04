import SceneKit
import SwiftUI
import AppKit

/// Builds the procedural 3D miniature room diorama matching the exact composition of Nook.
///
/// Orientation:
/// - Isometric diamond cutaway viewed from open front (+X, +Z) looking toward back corner (-X, -Z).
/// - Left Wall (X = -2.2): Oak desk, drawers, ergonomic chair, monitor with "hello ♡",
///   open laptop, chiclet keyboard, notebook, smiley mug, desk lamp, pegboard with polaroids & headphones,
///   upper shelves with books, clock, ceramic cat, and cascading trailing ivy vines.
/// - Right Wall (Z = -2.2): Large 2-pane oak window, outdoor sky & trees, draped linen curtains,
///   window sill succulents, framed botanical prints, and warm wall sconce.
/// - Daybed Nook: Built-in oak daybed under window, white linens, sage green throw blanket, daisy cushion,
///   and Cookie sleeping soundly on the bed.
/// - Audio Lounge: Oak bench with sage cushion, vintage turntable with spinning vinyl record, and floor monstera.
/// - Lower Sunken Lounge (Foreground): Stepped wooden floor, skateboard, boucle pouf with daisy cushion,
///   and potted succulent on step ledge.
/// - Atmosphere: Golden sunlight slanting from window with drifting dust motes, curtain flutter, and plant sway.
@MainActor
final class RoomDioramaBuilder {
    
    // MARK: - Dimensions & Coordinates
    
    static let roomSpan: CGFloat = 4.4       // Room width/depth
    static let wallHeight: CGFloat = 3.3     // Floor to ceiling
    
    // Desk surface coordinate reference
    static let deskSurfaceY: CGFloat = 1.04
    static let deskPosition = SCNVector3(x: -1.35, y: 0.14, z: -0.65)
    
    // MARK: - Scene Construction
    
    /// Constructs the complete room diorama inside the target scene.
    static func buildDiorama(
        in scene: SCNScene,
        environment: RoomTimeOfDay = .morning,
        reduceMotion: Bool = false
    ) -> (lampLight: SCNLight, sconceLight: SCNLight, sunLight: SCNLight, ambientLight: SCNLight, outdoorSkyNode: SCNNode, dustParticles: SCNParticleSystem?) {
        
        let root = scene.rootNode
        
        // 1. Architecture: Stepped wooden floors, background walls, top beams
        buildArchitecture(in: root)
        
        // 2. Right Wall: Window, Draped Curtains, Outdoor Horizon & Wall Sconce
        let (skyNode, sconceLight) = buildRightWallAndWindow(in: root, environment: environment, reduceMotion: reduceMotion)
        
        // 3. Left Wall: Workspace Desk, Ergonomic Chair, Monitor, Laptop, Pegboard & Shelves
        let lampLight = buildLeftWallAndWorkspace(in: root, environment: environment, reduceMotion: reduceMotion)
        
        // 4. Daybed Nook: Oak bed, white linens, sage blanket, daisy cushion & Cookie
        buildDaybedNook(in: root, reduceMotion: reduceMotion)
        
        // 5. Audio Lounge: Bench with spinning vinyl turntable & Floor Monstera
        buildRecordBenchAndMonstera(in: root, reduceMotion: reduceMotion)
        
        // 6. Lower Sunken Lounge: Skateboard, Boucle Pouf & Step Accents
        buildLowerLounge(in: root)
        
        // 7. Lighting & Dust Motes Particle System
        let (sunLight, ambientLight, dustSystem) = setupLightingAndAtmosphere(in: root, environment: environment, reduceMotion: reduceMotion)
        
        // 8. Isometric Camera (Classic 45° diamond dollhouse perspective)
        setupCamera(in: root)
        
        return (lampLight, sconceLight, sunLight, ambientLight, skyNode, dustSystem)
    }
    
    // MARK: - 1. Architecture (Stepped Floor, Background Walls & Chunky Top Beams)
    
    private static func buildArchitecture(in root: SCNNode) {
        let floorMat = Materials.hardwoodFloor
        let plasterMat = Materials.ivoryPlaster
        let beamMat = Materials.honeyOak
        let slatMat = Materials.verticalWoodSlat
        
        // Upper Main Floor Platform (Y = 0.14, covering workspace and daybed)
        let upperFloorGeo = SCNBox(width: 4.4, height: 0.28, length: 2.8, chamferRadius: 0.02)
        upperFloorGeo.materials = [floorMat]
        let upperFloorNode = SCNNode(geometry: upperFloorGeo)
        upperFloorNode.position = SCNVector3(-0.10, 0.0, -0.90)
        upperFloorNode.name = "floor_upper_platform"
        root.addChildNode(upperFloorNode)
        
        // Lower Sunken Floor Platform (Y = 0.0, foreground lounge)
        let lowerFloorGeo = SCNBox(width: 4.4, height: 0.14, length: 1.6, chamferRadius: 0.02)
        lowerFloorGeo.materials = [floorMat]
        let lowerFloorNode = SCNNode(geometry: lowerFloorGeo)
        lowerFloorNode.position = SCNVector3(-0.10, -0.07, 1.25)
        lowerFloorNode.name = "floor_lower_lounge"
        root.addChildNode(lowerFloorNode)
        
        // Stepped Wood Stairs connecting upper platform to lower sunken lounge
        let stepWidth: CGFloat = 1.35
        let stepDepth: CGFloat = 0.22
        let stepHeights: [CGFloat] = [0.045, 0.09, 0.135]
        for (i, h) in stepHeights.enumerated() {
            let stepGeo = SCNBox(width: stepWidth, height: 0.045, length: stepDepth, chamferRadius: 0.01)
            stepGeo.materials = [floorMat]
            let stepNode = SCNNode(geometry: stepGeo)
            stepNode.position = SCNVector3(-0.25, h - 0.022, 0.50 + CGFloat(2 - i) * 0.15)
            stepNode.name = "stairs_step_\(i)"
            root.addChildNode(stepNode)
        }
        
        // Left Background Wall (X = -2.2, running along Z from -2.2 to +1.6)
        let leftWallGeo = SCNBox(width: 0.14, height: wallHeight, length: 3.9, chamferRadius: 0.01)
        leftWallGeo.materials = [plasterMat]
        let leftWallNode = SCNNode(geometry: leftWallGeo)
        leftWallNode.position = SCNVector3(-2.27, wallHeight / 2, -0.25)
        leftWallNode.name = "room_left_wall"
        
        // Vertical wood wainscot paneling on left wall behind desk (up to height 1.95m)
        let leftWainscotGeo = SCNBox(width: 0.02, height: 1.95, length: 3.86, chamferRadius: 0.005)
        leftWainscotGeo.materials = [slatMat]
        let leftWainscotNode = SCNNode(geometry: leftWainscotGeo)
        leftWainscotNode.position = SCNVector3(0.075, -wallHeight / 2 + 1.95 / 2, 0)
        leftWallNode.addChildNode(leftWainscotNode)
        
        // Horizontal chair rail trim moulding at Y = 1.95
        let chairRail = SCNBox(width: 0.04, height: 0.04, length: 3.88, chamferRadius: 0.008)
        chairRail.materials = [beamMat]
        let crNode = SCNNode(geometry: chairRail)
        crNode.position = SCNVector3(0.08, -wallHeight / 2 + 1.95, 0)
        leftWallNode.addChildNode(crNode)
        root.addChildNode(leftWallNode)
        
        // Right Background Wall (Z = -2.2, running along X from -2.2 to +2.1 with window cutout)
        // Left portion behind corner
        let rightWallLeft = SCNBox(width: 1.25, height: wallHeight, length: 0.14, chamferRadius: 0.01)
        rightWallLeft.materials = [plasterMat]
        let rwlNode = SCNNode(geometry: rightWallLeft)
        rwlNode.position = SCNVector3(-1.60, wallHeight / 2, -2.27)
        root.addChildNode(rwlNode)
        
        // Bottom portion below window (Vertical Oak Wainscoting matching reference photo!)
        let rightWallBottom = SCNBox(width: 3.15, height: 1.25, length: 0.14, chamferRadius: 0.01)
        rightWallBottom.materials = [slatMat]
        let rwbNode = SCNNode(geometry: rightWallBottom)
        rwbNode.position = SCNVector3(0.55, 0.625, -2.27)
        rwbNode.name = "window_wall_wainscoting"
        root.addChildNode(rwbNode)
        
        // Top portion above window
        let rightWallTop = SCNBox(width: 3.15, height: 0.70, length: 0.14, chamferRadius: 0.01)
        rightWallTop.materials = [plasterMat]
        let rwtNode = SCNNode(geometry: rightWallTop)
        rwtNode.position = SCNVector3(0.55, wallHeight - 0.35, -2.27)
        root.addChildNode(rwtNode)
        
        // Right pillar edge of window
        let rightWallPillar = SCNBox(width: 0.45, height: 1.35, length: 0.14, chamferRadius: 0.01)
        rightWallPillar.materials = [plasterMat]
        let rwpNode = SCNNode(geometry: rightWallPillar)
        rwpNode.position = SCNVector3(1.90, 1.925, -2.27)
        root.addChildNode(rwpNode)
        
        // Chunky Rounded Oak Top Beams along wall tops (Signature aesthetic from reference image)
        // Left Wall top beam
        let leftBeam = SCNBox(width: 0.22, height: 0.16, length: 4.1, chamferRadius: 0.035)
        leftBeam.materials = [beamMat]
        let leftBeamNode = SCNNode(geometry: leftBeam)
        leftBeamNode.position = SCNVector3(-2.27, wallHeight + 0.08, -0.25)
        root.addChildNode(leftBeamNode)
        
        // Right Wall top beam
        let rightBeam = SCNBox(width: 4.6, height: 0.16, length: 0.22, chamferRadius: 0.035)
        rightBeam.materials = [beamMat]
        let rightBeamNode = SCNNode(geometry: rightBeam)
        rightBeamNode.position = SCNVector3(0.0, wallHeight + 0.08, -2.27)
        root.addChildNode(rightBeamNode)
    }
    
    // MARK: - 2. Right Wall, Window, Draped Curtains, Horizon & Wall Sconce
    
    private static func buildRightWallAndWindow(
        in root: SCNNode,
        environment: RoomTimeOfDay,
        reduceMotion: Bool
    ) -> (SCNNode, SCNLight) {
        let windowGroup = SCNNode()
        let winX: CGFloat = 0.55
        let winY: CGFloat = 1.95
        let winZ: CGFloat = -2.27
        windowGroup.position = SCNVector3(winX, winY, winZ)
        
        let frameMat = Materials.honeyOak
        let brassMat = Materials.brushedBrass
        let winWidth: CGFloat = 2.25
        let winHeight: CGFloat = 1.35
        
        // Thick Oak Window Sill
        let sill = SCNBox(width: winWidth + 0.15, height: 0.06, length: 0.28, chamferRadius: 0.015)
        sill.materials = [frameMat]
        let sillNode = SCNNode(geometry: sill)
        sillNode.position = SCNVector3(0, -winHeight / 2 - 0.03, 0.05)
        windowGroup.addChildNode(sillNode)
        
        // Window Frame Top Bar
        let topBar = SCNBox(width: winWidth, height: 0.06, length: 0.16, chamferRadius: 0.01)
        topBar.materials = [frameMat]
        let topBarNode = SCNNode(geometry: topBar)
        topBarNode.position = SCNVector3(0, winHeight / 2 + 0.03, 0)
        windowGroup.addChildNode(topBarNode)
        
        // Window Center Mullion (Splits window into 2 large panes)
        let mullion = SCNBox(width: 0.06, height: winHeight, length: 0.14, chamferRadius: 0.008)
        mullion.materials = [frameMat]
        let mullionNode = SCNNode(geometry: mullion)
        mullionNode.position = SCNVector3(0, 0, 0)
        windowGroup.addChildNode(mullionNode)
        
        // Transom horizontal dividers
        for wx in [-winWidth * 0.25, winWidth * 0.25] {
            let hBar = SCNBox(width: winWidth * 0.46, height: 0.045, length: 0.12, chamferRadius: 0.006)
            hBar.materials = [frameMat]
            let hBarNode = SCNNode(geometry: hBar)
            hBarNode.position = SCNVector3(wx, 0.12, 0)
            windowGroup.addChildNode(hBarNode)
        }
        
        // Glass Panes
        let glassGeo = SCNBox(width: winWidth - 0.04, height: winHeight - 0.04, length: 0.02, chamferRadius: 0.002)
        let glassMat = SCNMaterial()
        glassMat.diffuse.contents = NSColor(white: 0.98, alpha: 0.18)
        glassMat.roughness.contents = 0.08
        glassMat.specular.contents = NSColor(white: 0.35, alpha: 1.0)
        glassMat.transparency = 0.25
        glassGeo.materials = [glassMat]
        let glassNode = SCNNode(geometry: glassGeo)
        glassNode.position = SCNVector3(0, 0, 0)
        windowGroup.addChildNode(glassNode)
        
        // Outdoor Sky & Foliage Backdrop Plane directly behind the window
        let outdoorPlane = SCNPlane(width: 2.8, height: 1.8)
        let skyMat = SCNMaterial()
        skyMat.lightingModel = .constant
        skyMat.diffuse.contents = Textures.makeOutdoorBackdrop(environment: environment)
        outdoorPlane.materials = [skyMat]
        
        let skyNode = SCNNode(geometry: outdoorPlane)
        skyNode.position = SCNVector3(0, 0, -0.22)
        skyNode.name = "outdoor_sky_node"
        windowGroup.addChildNode(skyNode)
        
        // Window Sill Potted Plants
        let sillPots: [(CGFloat, NSColor)] = [
            (-0.65, NSColor(red: 0.78, green: 0.52, blue: 0.40, alpha: 1.0)),
            (-0.35, NSColor(white: 0.92, alpha: 1.0)),
            (0.55, NSColor(white: 0.94, alpha: 1.0))
        ]
        for sp in sillPots {
            let pot = SCNCylinder(radius: 0.042, height: 0.075)
            let pMat = SCNMaterial()
            pMat.diffuse.contents = sp.1
            pMat.roughness.contents = 0.6
            pot.materials = [pMat]
            let pNode = SCNNode(geometry: pot)
            pNode.position = SCNVector3(sp.0, -winHeight / 2 + 0.038, 0.08)
            
            let succ = SCNSphere(radius: 0.045)
            let sMat = SCNMaterial()
            sMat.diffuse.contents = NSColor(red: 0.40, green: 0.58, blue: 0.40, alpha: 1.0)
            succ.materials = [sMat]
            let sNode = SCNNode(geometry: succ)
            sNode.position = SCNVector3(0, 0.04, 0)
            pNode.addChildNode(sNode)
            windowGroup.addChildNode(pNode)
        }
        
        // Draped White Linen Curtains on both sides of the window
        let curtainPositions: [(CGFloat, CGFloat)] = [
            (-winWidth * 0.52, -1.0),
            (winWidth * 0.52, 1.0)
        ]
        for (xPos, dir) in curtainPositions {
            let curtainNode = SCNNode()
            curtainNode.position = SCNVector3(xPos, 0.05, 0.12)
            curtainNode.name = "curtain_\(dir > 0 ? "right" : "left")"
            
            // Linen folds
            for f in 0..<4 {
                let fold = SCNCylinder(radius: 0.034, height: winHeight + 0.18)
                fold.materials = [Materials.linenWhite]
                let fNode = SCNNode(geometry: fold)
                fNode.position = SCNVector3(CGFloat(f) * 0.045 * dir, 0, 0)
                curtainNode.addChildNode(fNode)
            }
            
            // Tie-back ring
            let tie = SCNTorus(ringRadius: 0.08, pipeRadius: 0.012)
            tie.materials = [Materials.honeyOak]
            let tieNode = SCNNode(geometry: tie)
            tieNode.position = SCNVector3(dir * 0.08, -0.15, 0)
            curtainNode.addChildNode(tieNode)
            
            if !reduceMotion {
                let sway1 = SCNAction.rotateBy(x: 0.015, y: 0.02 * dir, z: 0, duration: 3.8)
                let sway2 = SCNAction.rotateBy(x: -0.015, y: -0.02 * dir, z: 0, duration: 4.4)
                curtainNode.runAction(SCNAction.repeatForever(SCNAction.sequence([sway1, sway2])), forKey: "curtain_breeze")
            }
            windowGroup.addChildNode(curtainNode)
        }
        root.addChildNode(windowGroup)
        
        // Bronze Wall Sconce Lamp beside window on the right wall
        let sconceGroup = SCNNode()
        sconceGroup.position = SCNVector3(1.85, 2.35, -2.20)
        sconceGroup.name = "wall_sconce"
        
        let sconcePlate = SCNCylinder(radius: 0.055, height: 0.015)
        sconcePlate.materials = [brassMat]
        let spNode = SCNNode(geometry: sconcePlate)
        sconcePlate.materials = [brassMat]
        sconceGroup.addChildNode(spNode)
        
        let sconceArm = SCNCylinder(radius: 0.012, height: 0.14)
        sconceArm.materials = [brassMat]
        let saNode = SCNNode(geometry: sconceArm)
        saNode.position = SCNVector3(0, -0.02, 0.07)
        saNode.eulerAngles.x = .pi / 4
        sconceGroup.addChildNode(saNode)
        
        let sconceShade = SCNCylinder(radius: 0.055, height: 0.08)
        let ssMat = SCNMaterial()
        ssMat.diffuse.contents = NSColor(red: 0.58, green: 0.44, blue: 0.32, alpha: 1.0)
        ssMat.roughness.contents = 0.5
        sconceShade.materials = [ssMat]
        let ssNode = SCNNode(geometry: sconceShade)
        ssNode.position = SCNVector3(0, -0.07, 0.14)
        ssNode.eulerAngles.x = .pi / 6
        sconceGroup.addChildNode(ssNode)
        
        // Warm Sconce Light Source
        let sconceLight = SCNLight()
        sconceLight.type = .omni
        sconceLight.color = NSColor(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0)
        sconceLight.intensity = environment.isDeskLampDefaultOn ? 750 : 0
        sconceLight.castsShadow = true
        sconceLight.shadowRadius = 3.0
        
        let slNode = SCNNode()
        slNode.light = sconceLight
        slNode.position = SCNVector3(0, -0.10, 0.16)
        sconceGroup.addChildNode(slNode)
        
        // Framed Wall Art Prints hung to the right of window
        let artFrames: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (1.85, 1.85, 0.22, 0.28),
            (1.85, 1.45, 0.18, 0.22)
        ]
        for (i, af) in artFrames.enumerated() {
            let frame = SCNBox(width: af.2, height: af.3, length: 0.015, chamferRadius: 0.005)
            frame.materials = [frameMat]
            let fNode = SCNNode(geometry: frame)
            fNode.position = SCNVector3(af.0, af.1, -2.19)
            
            let printGeo = SCNPlane(width: af.2 - 0.04, height: af.3 - 0.04)
            let prMat = SCNMaterial()
            prMat.diffuse.contents = (i == 0) ? NSColor(red: 0.88, green: 0.90, blue: 0.84, alpha: 1.0) : NSColor(red: 0.94, green: 0.88, blue: 0.82, alpha: 1.0)
            printGeo.materials = [prMat]
            let prNode = SCNNode(geometry: printGeo)
            prNode.position = SCNVector3(0, 0, 0.01)
            fNode.addChildNode(prNode)
            root.addChildNode(fNode)
        }
        
        root.addChildNode(sconceGroup)
        return (skyNode, sconceLight)
    }
    
    // MARK: - 3. Left Wall & Workspace Desk
    
    private static func buildLeftWallAndWorkspace(
        in root: SCNNode,
        environment: RoomTimeOfDay,
        reduceMotion: Bool
    ) -> SCNLight {
        let deskGroup = SCNNode()
        deskGroup.position = deskPosition
        deskGroup.name = "desk_group"
        
        let woodMat = Materials.honeyOak
        let brassMat = Materials.brushedBrass
        
        // Desk Dimensions (aligned along Left Wall)
        let deskW: CGFloat = 0.92 // Depth from wall
        let deskL: CGFloat = 2.05 // Length along wall
        let deskH: CGFloat = 0.90 // Surface height above upper platform
        
        // Desk Tabletop (Honey oak beveled slab)
        let tabletop = SCNBox(width: deskW, height: 0.065, length: deskL, chamferRadius: 0.015)
        tabletop.materials = [woodMat]
        let tabletopNode = SCNNode(geometry: tabletop)
        tabletopNode.position = SCNVector3(0, deskH - 0.0325, 0)
        tabletopNode.name = "desk_tabletop"
        deskGroup.addChildNode(tabletopNode)
        
        // 3-Drawer Filing Pedestal under front edge (Z = +0.65)
        let drawerW: CGFloat = deskW * 0.92
        let drawerH: CGFloat = deskH - 0.08
        let drawerL: CGFloat = 0.54
        let drawerBox = SCNBox(width: drawerW, height: drawerH, length: drawerL, chamferRadius: 0.012)
        drawerBox.materials = [woodMat]
        let drawerNode = SCNNode(geometry: drawerBox)
        drawerNode.position = SCNVector3(0, drawerH / 2, deskL / 2 - drawerL / 2 - 0.06)
        deskGroup.addChildNode(drawerNode)
        
        // Brass Drawer Pulls
        for dy in [0.22, 0.48, 0.74] {
            let handle = SCNBox(width: 0.02, height: 0.018, length: 0.16, chamferRadius: 0.005)
            handle.materials = [brassMat]
            let hNode = SCNNode(geometry: handle)
            hNode.position = SCNVector3(drawerW / 2 + 0.01, dy, deskL / 2 - drawerL / 2 - 0.06)
            deskGroup.addChildNode(hNode)
        }
        
        // Back Legs (near Z = -0.85)
        for lx in [-deskW * 0.40, deskW * 0.40] {
            let leg = SCNCylinder(radius: 0.032, height: deskH - 0.065)
            leg.materials = [woodMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(lx, (deskH - 0.065) / 2, -deskL / 2 + 0.08)
            deskGroup.addChildNode(legNode)
        }
        
        // Large Computer Monitor displaying cursive "hello ♡"
        let (monitorNode, _) = buildComputerMonitor()
        monitorNode.position = SCNVector3(-0.18, deskH, -0.35)
        monitorNode.eulerAngles.y = 0.35 // Angled warmly toward room & camera
        deskGroup.addChildNode(monitorNode)
        
        // Open Laptop to the right of monitor
        let laptopNode = buildOpenLaptop()
        laptopNode.position = SCNVector3(-0.05, deskH, 0.35)
        laptopNode.eulerAngles.y = 0.25
        deskGroup.addChildNode(laptopNode)
        
        // Chiclet Mechanical Keyboard & Mouse on Desk Blotter
        let blotterGeo = SCNBox(width: 0.46, height: 0.006, length: 1.15, chamferRadius: 0.015)
        let blotterMat = SCNMaterial()
        blotterMat.diffuse.contents = NSColor(red: 0.90, green: 0.88, blue: 0.84, alpha: 1.0)
        blotterMat.roughness.contents = 0.9
        blotterGeo.materials = [blotterMat]
        let blotterNode = SCNNode(geometry: blotterGeo)
        blotterNode.position = SCNVector3(0.18, deskH + 0.003, -0.05)
        deskGroup.addChildNode(blotterNode)
        
        let kbdGeo = SCNBox(width: 0.14, height: 0.015, length: 0.38, chamferRadius: 0.006)
        let kbdMat = SCNMaterial()
        kbdMat.diffuse.contents = NSColor(white: 0.95, alpha: 1.0)
        kbdGeo.materials = [kbdMat]
        let kbdNode = SCNNode(geometry: kbdGeo)
        kbdNode.position = SCNVector3(0.18, deskH + 0.014, -0.15)
        deskGroup.addChildNode(kbdNode)
        
        let mouseGeo = SCNSphere(radius: 0.038)
        let mouseMat = SCNMaterial()
        mouseMat.diffuse.contents = NSColor(white: 0.96, alpha: 1.0)
        mouseGeo.materials = [mouseMat]
        let mouseNode = SCNNode(geometry: mouseGeo)
        mouseNode.scale = SCNVector3(1.0, 0.32, 0.65)
        mouseNode.position = SCNVector3(0.18, deskH + 0.012, 0.22)
        deskGroup.addChildNode(mouseNode)
        
        // Open Notebook / Planner
        let nbGeo = SCNBox(width: 0.30, height: 0.018, length: 0.22, chamferRadius: 0.006)
        let nbMat = SCNMaterial()
        nbMat.diffuse.contents = NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
        nbGeo.materials = [nbMat]
        let nbNode = SCNNode(geometry: nbGeo)
        nbNode.position = SCNVector3(0.16, deskH + 0.009, -0.72)
        nbNode.name = "open_notebook"
        deskGroup.addChildNode(nbNode)
        
        // Cute White Ceramic Mug with Smiley Face
        let mugNode = buildSmileyMug()
        mugNode.position = SCNVector3(-0.15, deskH + 0.045, 0.05)
        mugNode.name = "smiley_mug"
        deskGroup.addChildNode(mugNode)
        
        // Articulated Cream Desk Lamp with Warm Spotlight
        let (lampNode, lampLight) = buildDeskLamp(environment: environment)
        lampNode.position = SCNVector3(-0.24, deskH, -0.82)
        deskGroup.addChildNode(lampNode)
        
        // Pencil cup & phone stand
        let cup = SCNCylinder(radius: 0.042, height: 0.11)
        cup.materials = [Materials.satinCeramic]
        let cupNode = SCNNode(geometry: cup)
        cupNode.position = SCNVector3(0.05, deskH + 0.055, -0.85)
        cupNode.name = "pencil_cup"
        deskGroup.addChildNode(cupNode)
        
        // Potted succulent plant on desk next to laptop (matching reference photo)
        let deskPlant = buildPottedSucculent(potColor: NSColor(white: 0.95, alpha: 1.0))
        deskPlant.position = SCNVector3(-0.12, deskH, 0.68)
        deskPlant.name = "desk_plant"
        deskGroup.addChildNode(deskPlant)
        
        root.addChildNode(deskGroup)
        
        // Potted plant on floor next to desk drawers (matching reference photo)
        let floorDeskPlant = buildFloorDeskPlant()
        floorDeskPlant.position = SCNVector3(-1.05, 0.14, 0.95)
        floorDeskPlant.name = "floor_plant"
        root.addChildNode(floorDeskPlant)
        
        // Botanical Area Rug on floor under desk & chair
        let rugGeo = SCNBox(width: 1.45, height: 0.012, length: 1.65, chamferRadius: 0.04)
        let rugMat = SCNMaterial()
        rugMat.diffuse.contents = Textures.makeBotanicalRugTexture()
        rugMat.roughness.contents = 0.95
        rugGeo.materials = [rugMat]
        let rugNode = SCNNode(geometry: rugGeo)
        rugNode.position = SCNVector3(-0.65, 0.145, -0.65)
        rugNode.name = "desk_rug"
        root.addChildNode(rugNode)
        
        // Ergonomic Office Chair
        let chairNode = buildErgonomicChair()
        chairNode.position = SCNVector3(-0.55, 0.14, -0.65)
        chairNode.eulerAngles.y = -.pi / 2 + 0.25 // Angled naturally toward desk
        root.addChildNode(chairNode)
        
        // Pegboard & Wall Shelves mounted on Left Wall (X = -2.20)
        buildLeftWallShelving(in: root, reduceMotion: reduceMotion)
        
        return lampLight
    }
    
    /// Constructs the pegboard, double shelves, books, clock, and cascading ivy on the Left Wall.
    private static func buildLeftWallShelving(in root: SCNNode, reduceMotion: Bool) {
        let shelfGroup = SCNNode()
        let woodMat = Materials.honeyOak
        let brassMat = Materials.brushedBrass
        
        // Pegboard mounted on left wall behind monitor
        let pegboardGeo = SCNBox(width: 0.02, height: 0.95, length: 0.85, chamferRadius: 0.01)
        let pbMat = SCNMaterial()
        pbMat.diffuse.contents = Textures.makePegboardTexture()
        pbMat.roughness.contents = 0.85
        pegboardGeo.materials = [pbMat]
        let pegboardNode = SCNNode(geometry: pegboardGeo)
        pegboardNode.position = SCNVector3(-2.19, 2.05, -0.75)
        shelfGroup.addChildNode(pegboardNode)
        
        // Hanging White Studio Headphones on wooden peg
        let headphonePeg = SCNCylinder(radius: 0.012, height: 0.08)
        headphonePeg.materials = [woodMat]
        let pegNode = SCNNode(geometry: headphonePeg)
        pegNode.eulerAngles.z = .pi / 2
        pegNode.position = SCNVector3(0.04, -0.08, 0.18)
        pegboardNode.addChildNode(pegNode)
        
        let headphoneBand = SCNTorus(ringRadius: 0.12, pipeRadius: 0.016)
        let hpMat = SCNMaterial()
        hpMat.diffuse.contents = NSColor(white: 0.94, alpha: 1.0)
        hpMat.roughness.contents = 0.4
        headphoneBand.materials = [hpMat]
        let hpNode = SCNNode(geometry: headphoneBand)
        hpNode.position = SCNVector3(0.03, -0.04, 0)
        pegNode.addChildNode(hpNode)
        
        // Two Sturdy Wall Shelves above desk
        let shelfLength: CGFloat = 2.15
        let shelfHeights: [CGFloat] = [2.62, 3.05]
        for sh in shelfHeights {
            let shelf = SCNBox(width: 0.32, height: 0.035, length: shelfLength, chamferRadius: 0.008)
            shelf.materials = [woodMat]
            let sNode = SCNNode(geometry: shelf)
            sNode.position = SCNVector3(-2.03, sh, -0.90)
            shelfGroup.addChildNode(sNode)
            
            // Shelf brackets
            for bz in [-shelfLength * 0.42, 0.0, shelfLength * 0.42] {
                let bracket = SCNBox(width: 0.28, height: 0.14, length: 0.035, chamferRadius: 0.005)
                bracket.materials = [woodMat]
                let bNode = SCNNode(geometry: bracket)
                bNode.position = SCNVector3(-2.05, sh - 0.08, sNode.position.z + bz)
                shelfGroup.addChildNode(bNode)
            }
        }
        
        // Rows of Books on Shelves
        let bookSpineColors: [NSColor] = [
            NSColor(red: 0.52, green: 0.60, blue: 0.50, alpha: 1.0), // Sage
            NSColor(red: 0.78, green: 0.48, blue: 0.38, alpha: 1.0), // Terracotta
            NSColor(red: 0.88, green: 0.82, blue: 0.70, alpha: 1.0), // Linen
            NSColor(red: 0.68, green: 0.58, blue: 0.45, alpha: 1.0), // Ochre
            NSColor(red: 0.42, green: 0.46, blue: 0.50, alpha: 1.0)  // Slate
        ]
        
        var startZ: CGFloat = -1.75
        for i in 0..<10 {
            let h: CGFloat = 0.28 + CGFloat(i % 3) * 0.03
            let w: CGFloat = 0.045 + CGFloat((i * 7) % 4) * 0.012
            let book = SCNBox(width: 0.22, height: h, length: w, chamferRadius: 0.004)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = bookSpineColors[i % bookSpineColors.count]
            book.materials = [bMat]
            let bNode = SCNNode(geometry: book)
            bNode.position = SCNVector3(-2.04, 2.62 + h / 2 + 0.018, startZ + w / 2)
            shelfGroup.addChildNode(bNode)
            startZ += w + 0.008
        }
        
        // Small White Cat Figurine on top shelf
        let catFigGeo = SCNSphere(radius: 0.055)
        let cfMat = SCNMaterial()
        cfMat.diffuse.contents = NSColor(white: 0.96, alpha: 1.0)
        catFigGeo.materials = [cfMat]
        let cfNode = SCNNode(geometry: catFigGeo)
        cfNode.position = SCNVector3(-2.03, 3.05 + 0.055 + 0.018, -0.65)
        shelfGroup.addChildNode(cfNode)
        
        // Vintage Brass Alarm Clock
        let clock = SCNCylinder(radius: 0.065, height: 0.045)
        clock.materials = [brassMat]
        let clockNode = SCNNode(geometry: clock)
        clockNode.eulerAngles.z = .pi / 2
        clockNode.position = SCNVector3(-2.04, 2.62 + 0.075, -0.25)
        shelfGroup.addChildNode(clockNode)
        
        // Cascading Trailing Ivy Vines tumbling over shelf edge and down Left Wall
        buildCascadingIvy(in: shelfGroup, reduceMotion: reduceMotion)
        
        root.addChildNode(shelfGroup)
    }
    
    // MARK: - 4. Daybed Nook & Cookie
    
    private static func buildDaybedNook(in root: SCNNode, reduceMotion: Bool) {
        let bedGroup = SCNNode()
        let woodMat = Materials.honeyOak
        let linenMat = Materials.linenWhite
        let sageMat = Materials.fabricSage
        
        // Positioned in back-right corner under the window
        bedGroup.position = SCNVector3(0.95, 0.14, -1.35)
        bedGroup.name = "daybed_nook"
        
        let bedW: CGFloat = 1.65 // X span
        let bedL: CGFloat = 1.35 // Z span
        let bedBaseH: CGFloat = 0.32
        
        // Built-in Floor-to-Ceiling Oak Bookcase Unit behind the headboard (matching reference photo!)
        let bookcase = buildHeadboardBookcase(reduceMotion: reduceMotion)
        bookcase.position = SCNVector3(-bedW / 2 - 0.20, 0, 0)
        bedGroup.addChildNode(bookcase)
        
        // Solid Oak Bed Frame Base
        let bedFrame = SCNBox(width: bedW, height: bedBaseH, length: bedL, chamferRadius: 0.02)
        bedFrame.materials = [woodMat]
        let bedFrameNode = SCNNode(geometry: bedFrame)
        bedFrameNode.position = SCNVector3(0, bedBaseH / 2, 0)
        bedGroup.addChildNode(bedFrameNode)
        
        // Solid Oak Headboard integrated with the bookcase
        let headboard = SCNBox(width: 0.08, height: 0.75, length: bedL, chamferRadius: 0.015)
        headboard.materials = [woodMat]
        let hbNode = SCNNode(geometry: headboard)
        hbNode.position = SCNVector3(-bedW / 2 + 0.04, bedBaseH + 0.375, 0)
        bedGroup.addChildNode(hbNode)
        
        // Plump White Mattress & Sheets
        let mattress = SCNBox(width: bedW - 0.10, height: 0.22, length: bedL - 0.08, chamferRadius: 0.04)
        mattress.materials = [linenMat]
        let matNode = SCNNode(geometry: mattress)
        matNode.position = SCNVector3(0.02, bedBaseH + 0.11, 0)
        bedGroup.addChildNode(matNode)
        
        // Stacked White Pillows
        let pillowGeo = SCNBox(width: 0.36, height: 0.12, length: 0.52, chamferRadius: 0.05)
        pillowGeo.materials = [linenMat]
        for pz in [-bedL * 0.22, bedL * 0.22] {
            let pNode = SCNNode(geometry: pillowGeo)
            pNode.position = SCNVector3(-bedW / 2 + 0.28, bedBaseH + 0.25, pz)
            pNode.eulerAngles.z = -0.15
            bedGroup.addChildNode(pNode)
        }
        
        // Folded Soft Sage Green Throw Blanket with subtle fringe
        let blanketGeo = SCNBox(width: 0.75, height: 0.08, length: bedL - 0.06, chamferRadius: 0.035)
        blanketGeo.materials = [sageMat]
        let blanketNode = SCNNode(geometry: blanketGeo)
        blanketNode.position = SCNVector3(bedW * 0.22, bedBaseH + 0.23, 0)
        bedGroup.addChildNode(blanketNode)
        
        // Daisy Flower Pillow on the bed
        let daisyNode = buildDaisyPillow()
        daisyNode.position = SCNVector3(-0.15, bedBaseH + 0.24, -0.32)
        daisyNode.eulerAngles.z = 0.20
        daisyNode.name = "daisy_pillow_bed"
        bedGroup.addChildNode(daisyNode)
        
        // Cookie the Cat curled up sleeping peacefully on top of the sage blanket
        let catNode = CookieNode()
        catNode.reduceMotion = reduceMotion
        catNode.position = SCNVector3(0.20, bedBaseH + 0.27, 0.10)
        catNode.eulerAngles.y = 0.85 // Angled warmly toward the room
        catNode.name = "cookie_character"
        catNode.sleep() // Sleep curled up as shown in reference photo!
        
        bedGroup.addChildNode(catNode)
        root.addChildNode(bedGroup)
    }
    
    // MARK: - 5. Audio Lounge (Record Player Bench & Floor Monstera)
    
    private static func buildRecordBenchAndMonstera(in root: SCNNode, reduceMotion: Bool) {
        let benchGroup = SCNNode()
        let woodMat = Materials.honeyOak
        let sageMat = Materials.fabricSage
        
        // Positioned at foot of bed
        benchGroup.position = SCNVector3(1.05, 0.14, -0.15)
        benchGroup.name = "record_bench_group"
        
        let benchW: CGFloat = 0.95
        let benchL: CGFloat = 0.62
        let benchH: CGFloat = 0.28
        
        // Oak Bench Base & Legs
        let benchBase = SCNBox(width: benchW, height: 0.06, length: benchL, chamferRadius: 0.01)
        benchBase.materials = [woodMat]
        let bbNode = SCNNode(geometry: benchBase)
        bbNode.position = SCNVector3(0, benchH - 0.03, 0)
        benchGroup.addChildNode(bbNode)
        
        for (lx, lz) in [(-benchW * 0.42, -benchL * 0.42), (benchW * 0.42, -benchL * 0.42), (-benchW * 0.42, benchL * 0.42), (benchW * 0.42, benchL * 0.42)] {
            let leg = SCNCylinder(radius: 0.024, height: benchH - 0.06)
            leg.materials = [woodMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(lx, (benchH - 0.06) / 2, lz)
            benchGroup.addChildNode(legNode)
        }
        
        // Sage Upholstered Cushion
        let cushion = SCNBox(width: benchW - 0.04, height: 0.09, length: benchL - 0.04, chamferRadius: 0.03)
        cushion.materials = [sageMat]
        let cNode = SCNNode(geometry: cushion)
        cNode.position = SCNVector3(0, benchH + 0.045, 0)
        benchGroup.addChildNode(cNode)
        
        // Vintage Portable Suitcase Record Player with Spinning Vinyl Record
        let (recordPlayerNode, _) = buildRecordPlayer(reduceMotion: reduceMotion)
        recordPlayerNode.position = SCNVector3(-0.08, benchH + 0.09, 0.02)
        benchGroup.addChildNode(recordPlayerNode)
        
        // Stack of Vinyl Record Sleeves
        let rsGeo = SCNBox(width: 0.26, height: 0.045, length: 0.26, chamferRadius: 0.006)
        let rsMat = SCNMaterial()
        rsMat.diffuse.contents = NSColor(red: 0.82, green: 0.60, blue: 0.48, alpha: 1.0)
        rsGeo.materials = [rsMat]
        let rsNode = SCNNode(geometry: rsGeo)
        rsNode.position = SCNVector3(benchW * 0.28, benchH + 0.09 + 0.0225, 0.02)
        benchGroup.addChildNode(rsNode)
        
        root.addChildNode(benchGroup)
        
        // Large Floor Potted Monstera Deliciosa Plant (Right of bench)
        let monsteraNode = buildMonsteraPlant(reduceMotion: reduceMotion)
        monsteraNode.position = SCNVector3(1.80, 0.14, -0.15)
        root.addChildNode(monsteraNode)
    }
    
    // MARK: - 6. Lower Sunken Lounge (Foreground Skateboard, Boucle Pouf & Step Accents)
    
    private static func buildLowerLounge(in root: SCNNode) {
        let loungeGroup = SCNNode()
        loungeGroup.name = "lower_lounge_group"
        
        // Skateboard on the floor
        let skateboardNode = buildSkateboard()
        skateboardNode.position = SCNVector3(0.15, 0.045, 0.95)
        skateboardNode.eulerAngles.y = -0.35
        skateboardNode.name = "skateboard"
        loungeGroup.addChildNode(skateboardNode)
        
        // Fluffy Cream Boucle Beanbag Pouf
        let pouf = SCNSphere(radius: 0.38)
        pouf.materials = [Materials.linenWhite]
        let poufNode = SCNNode(geometry: pouf)
        poufNode.scale = SCNVector3(1.15, 0.65, 1.15)
        poufNode.position = SCNVector3(1.25, 0.22, 1.25)
        poufNode.name = "boucle_pouf"
        
        // White daisy flower pillow on pouf
        let poufDaisy = buildDaisyPillow()
        poufDaisy.position = SCNVector3(0, 0.32, 0)
        poufDaisy.eulerAngles.x = 0.15
        poufDaisy.name = "daisy_pillow_pouf"
        poufNode.addChildNode(poufDaisy)
        loungeGroup.addChildNode(poufNode)
        
        // Miniature Potted Succulent on step ledge
        let stepPot = buildPottedSucculent(potColor: NSColor(white: 0.94, alpha: 1.0))
        stepPot.position = SCNVector3(-0.95, 0.14, 0.48)
        stepPot.name = "step_succulent"
        loungeGroup.addChildNode(stepPot)
        
        // Small Stack of Books on step edge
        for i in 0..<2 {
            let book = SCNBox(width: 0.24, height: 0.035, length: 0.18, chamferRadius: 0.005)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = (i == 0) ? NSColor(red: 0.72, green: 0.52, blue: 0.42, alpha: 1.0) : NSColor(red: 0.52, green: 0.60, blue: 0.52, alpha: 1.0)
            book.materials = [bMat]
            let bNode = SCNNode(geometry: book)
            bNode.position = SCNVector3(-0.75, 0.14 + CGFloat(i) * 0.038 + 0.018, 0.52)
            bNode.eulerAngles.y = CGFloat(i) * 0.15
            bNode.name = "step_books"
            loungeGroup.addChildNode(bNode)
        }
        
        // Tiny Succulent Pot on lower floor ledge in foreground (matching reference photo)
        let floorPot = buildPottedSucculent(potColor: NSColor(red: 0.88, green: 0.86, blue: 0.82, alpha: 1.0))
        floorPot.position = SCNVector3(-0.70, 0.0, 1.75)
        floorPot.name = "floor_succulent"
        loungeGroup.addChildNode(floorPot)
        
        root.addChildNode(loungeGroup)
    }
    
    /// Constructs the built-in floor-to-ceiling wooden bookcase behind the bed headboard.
    private static func buildHeadboardBookcase(reduceMotion: Bool) -> SCNNode {
        let bookcaseGroup = SCNNode()
        bookcaseGroup.name = "headboard_bookcase"
        
        let woodMat = Materials.honeyOak
        let brassMat = Materials.brushedBrass
        let slatMat = Materials.verticalWoodSlat
        
        let unitW: CGFloat = 0.40 // Depth along X
        let unitL: CGFloat = 1.35 // Length along Z matching bed
        let unitH: CGFloat = 3.16 // Height up to ceiling beam
        
        // Vertical wood slat backing
        let backPanel = SCNBox(width: 0.02, height: unitH, length: unitL, chamferRadius: 0.005)
        backPanel.materials = [slatMat]
        let bpNode = SCNNode(geometry: backPanel)
        bpNode.position = SCNVector3(-unitW / 2 + 0.01, unitH / 2, 0)
        bookcaseGroup.addChildNode(bpNode)
        
        // Two side upright panels
        for sz in [-unitL / 2 + 0.02, unitL / 2 - 0.02] {
            let upright = SCNBox(width: unitW, height: unitH, length: 0.04, chamferRadius: 0.008)
            upright.materials = [woodMat]
            let uNode = SCNNode(geometry: upright)
            uNode.position = SCNVector3(0, unitH / 2, sz)
            bookcaseGroup.addChildNode(uNode)
        }
        
        // Shelves at varying heights
        let shelfHeights: [CGFloat] = [1.25, 1.95, 2.65, 3.12]
        for sh in shelfHeights {
            let shelf = SCNBox(width: unitW, height: 0.035, length: unitL - 0.04, chamferRadius: 0.006)
            shelf.materials = [woodMat]
            let sNode = SCNNode(geometry: shelf)
            sNode.position = SCNVector3(0, sh, 0)
            bookcaseGroup.addChildNode(sNode)
        }
        
        // Middle shelf (Y = 1.95): Stack of books + Brass Alarm Clock + White Cat Figurine
        let bookColors: [NSColor] = [
            NSColor(red: 0.78, green: 0.48, blue: 0.38, alpha: 1.0),
            NSColor(red: 0.52, green: 0.60, blue: 0.50, alpha: 1.0),
            NSColor(red: 0.88, green: 0.82, blue: 0.70, alpha: 1.0),
            NSColor(red: 0.68, green: 0.58, blue: 0.45, alpha: 1.0)
        ]
        var bz: CGFloat = -unitL * 0.35
        for i in 0..<5 {
            let bh: CGFloat = 0.26 + CGFloat(i % 3) * 0.04
            let bw: CGFloat = 0.045
            let book = SCNBox(width: unitW * 0.75, height: bh, length: bw, chamferRadius: 0.004)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = bookColors[i % bookColors.count]
            book.materials = [bMat]
            let bNode = SCNNode(geometry: book)
            bNode.position = SCNVector3(0, 1.95 + bh / 2 + 0.018, bz)
            bookcaseGroup.addChildNode(bNode)
            bz += bw + 0.008
        }
        
        // Vintage Brass Clock on middle shelf
        let clock = SCNCylinder(radius: 0.062, height: 0.042)
        clock.materials = [brassMat]
        let clockNode = SCNNode(geometry: clock)
        clockNode.eulerAngles.x = .pi / 2
        clockNode.position = SCNVector3(0, 1.95 + 0.075, 0.12)
        bookcaseGroup.addChildNode(clockNode)
        
        // Small White Ceramic Cat figurine on shelf
        let catFig = SCNSphere(radius: 0.048)
        let cfMat = SCNMaterial()
        cfMat.diffuse.contents = NSColor(white: 0.96, alpha: 1.0)
        catFig.materials = [cfMat]
        let cfNode = SCNNode(geometry: catFig)
        cfNode.position = SCNVector3(0, 1.95 + 0.048 + 0.018, 0.36)
        bookcaseGroup.addChildNode(cfNode)
        
        // Upper shelf (Y = 2.65): Wooden keepsake box with lid + books
        let boxGeo = SCNBox(width: unitW * 0.85, height: 0.16, length: 0.32, chamferRadius: 0.012)
        boxGeo.materials = [woodMat]
        let boxNode = SCNNode(geometry: boxGeo)
        boxNode.position = SCNVector3(0, 2.65 + 0.08 + 0.018, -unitL * 0.22)
        bookcaseGroup.addChildNode(boxNode)
        
        // Ivy cascading from upper shelf down over the side
        let vineGeo = SCNNode()
        vineGeo.position = SCNVector3(unitW / 2 - 0.02, 2.65, 0.15)
        buildCascadingIvy(in: vineGeo, reduceMotion: reduceMotion)
        bookcaseGroup.addChildNode(vineGeo)
        
        return bookcaseGroup
    }
    
    /// Constructs a cute small potted succulent plant for desk/step.
    private static func buildPottedSucculent(potColor: NSColor = NSColor(white: 0.94, alpha: 1.0)) -> SCNNode {
        let plantGroup = SCNNode()
        
        let pot = SCNCylinder(radius: 0.048, height: 0.085)
        let pMat = SCNMaterial()
        pMat.diffuse.contents = potColor
        pMat.roughness.contents = 0.4
        pot.materials = [pMat]
        let potNode = SCNNode(geometry: pot)
        potNode.position = SCNVector3(0, 0.0425, 0)
        plantGroup.addChildNode(potNode)
        
        let succ = SCNSphere(radius: 0.052)
        let sMat = SCNMaterial()
        sMat.diffuse.contents = NSColor(red: 0.38, green: 0.58, blue: 0.38, alpha: 1.0)
        sMat.roughness.contents = 0.7
        succ.materials = [sMat]
        let sNode = SCNNode(geometry: succ)
        sNode.scale = SCNVector3(1.1, 0.75, 1.1)
        sNode.position = SCNVector3(0, 0.085, 0)
        plantGroup.addChildNode(sNode)
        
        return plantGroup
    }
    
    /// Constructs the floor potted plant beside the desk drawers.
    private static func buildFloorDeskPlant() -> SCNNode {
        let plantGroup = SCNNode()
        plantGroup.name = "floor_plant"
        
        let pot = SCNCylinder(radius: 0.09, height: 0.18)
        pot.materials = [Materials.satinCeramic]
        let potNode = SCNNode(geometry: pot)
        potNode.position = SCNVector3(0, 0.09, 0)
        plantGroup.addChildNode(potNode)
        
        let leafMat = SCNMaterial()
        leafMat.diffuse.contents = NSColor(red: 0.30, green: 0.52, blue: 0.32, alpha: 1.0)
        leafMat.roughness.contents = 0.6
        
        for i in 0..<5 {
            let angle = CGFloat(i) * (.pi * 2 / 5)
            let leaf = SCNBox(width: 0.09, height: 0.005, length: 0.16, chamferRadius: 0.01)
            leaf.materials = [leafMat]
            let leafNode = SCNNode(geometry: leaf)
            leafNode.position = SCNVector3(cos(angle) * 0.06, 0.18, sin(angle) * 0.06)
            leafNode.eulerAngles.y = angle
            leafNode.eulerAngles.z = 0.35
            plantGroup.addChildNode(leafNode)
        }
        
        return plantGroup
    }
    
    // MARK: - 7. Atmospheric Lighting & Dust Motes Particle System
    
    private static func setupLightingAndAtmosphere(
        in root: SCNNode,
        environment: RoomTimeOfDay,
        reduceMotion: Bool
    ) -> (SCNLight, SCNLight, SCNParticleSystem?) {
        
        // Directional Sunlight streaming through window from outside
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
        // Positioned outside the right-back window, slanting down into room
        sunNode.position = SCNVector3(1.2, 5.8, -5.5)
        sunNode.eulerAngles = SCNVector3(-0.62, 0.25, 0)
        sunNode.name = "sun_light"
        
        if !reduceMotion {
            let driftRight = SCNAction.rotateBy(x: 0.02, y: -0.03, z: 0, duration: 60)
            let driftLeft = SCNAction.rotateBy(x: -0.02, y: 0.03, z: 0, duration: 60)
            sunNode.runAction(SCNAction.repeatForever(SCNAction.sequence([driftRight, driftLeft])), forKey: "daylight_drift")
        }
        root.addChildNode(sunNode)
        
        // Ambient Fill Light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = environment.ambientColor
        ambientLight.intensity = environment.ambientIntensity
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        ambientNode.name = "ambient_light"
        root.addChildNode(ambientNode)
        
        // Tiny Dust Particles floating in the sunlight beam
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
            
            particles.emitterShape = SCNBox(width: 1.8, height: 1.8, length: 1.8, chamferRadius: 0)
            particles.spreadingAngle = 25
            particles.acceleration = SCNVector3(x: 0.002, y: -0.002, z: 0.003)
            
            let dustNode = SCNNode()
            dustNode.position = SCNVector3(0.55, 1.85, -1.2)
            dustNode.addParticleSystem(particles)
            dustNode.name = "dust_motes_node"
            root.addChildNode(dustNode)
            dustParticles = particles
        }
        
        return (sunLight, ambientLight, dustParticles)
    }
    
    // MARK: - 8. Isometric Camera
    
    private static func setupCamera(in root: SCNNode) {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        camera.fieldOfView = 36
        camera.zNear = 0.5
        camera.zFar = 50.0
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.name = "main_room_camera"
        
        // Classic isometric diamond perspective looking from (+X, +Z) into (-X, -Z)
        cameraNode.position = SCNVector3(5.6, 5.2, 5.8)
        
        let lookAtTarget = SCNNode()
        lookAtTarget.position = SCNVector3(-0.10, 0.95, -0.20)
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
        
        let base = SCNBox(width: 0.18, height: 0.012, length: 0.28, chamferRadius: 0.006)
        base.materials = [whiteMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.006, 0)
        monitorGroup.addChildNode(baseNode)
        
        let neck = SCNBox(width: 0.035, height: 0.24, length: 0.045, chamferRadius: 0.008)
        neck.materials = [whiteMat]
        let neckNode = SCNNode(geometry: neck)
        neckNode.position = SCNVector3(-0.02, 0.12, 0)
        neckNode.eulerAngles.z = -0.15
        monitorGroup.addChildNode(neckNode)
        
        let width: CGFloat = 0.88
        let height: CGFloat = 0.54
        let housing = SCNBox(width: 0.03, height: height, length: width, chamferRadius: 0.012)
        housing.materials = [whiteMat]
        let housingNode = SCNNode(geometry: housing)
        housingNode.position = SCNVector3(0, 0.36, 0)
        
        let screenPlane = SCNPlane(width: width - 0.03, height: height - 0.03)
        let screenMat = SCNMaterial()
        screenMat.diffuse.contents = Textures.makeMonitorScreenTexture()
        screenMat.emission.contents = Textures.makeMonitorScreenTexture()
        screenMat.emission.intensity = 0.25
        screenMat.lightingModel = .constant
        screenPlane.materials = [screenMat]
        let screenNode = SCNNode(geometry: screenPlane)
        screenNode.eulerAngles.y = .pi / 2
        screenNode.position = SCNVector3(0.016, 0, 0)
        screenNode.name = "monitor_display"
        housingNode.addChildNode(screenNode)
        
        let glow = SCNLight()
        glow.type = .omni
        glow.color = NSColor(red: 0.95, green: 0.98, blue: 0.95, alpha: 1.0)
        glow.intensity = 180
        let glowNode = SCNNode()
        glowNode.light = glow
        glowNode.position = SCNVector3(0.12, 0, 0)
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
        
        let baseW: CGFloat = 0.26
        let baseD: CGFloat = 0.38
        let base = SCNBox(width: baseW, height: 0.012, length: baseD, chamferRadius: 0.005)
        base.materials = [silverMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.006, 0)
        laptopGroup.addChildNode(baseNode)
        
        let lid = SCNBox(width: 0.008, height: baseW, length: baseD, chamferRadius: 0.004)
        lid.materials = [silverMat]
        let lidNode = SCNNode(geometry: lid)
        lidNode.position = SCNVector3(-baseW / 2, baseW / 2, 0)
        lidNode.eulerAngles.z = 0.45
        
        let screen = SCNPlane(width: baseD - 0.02, height: baseW - 0.02)
        let sMat = SCNMaterial()
        sMat.diffuse.contents = Textures.makeLaptopScreenTexture()
        sMat.emission.contents = Textures.makeLaptopScreenTexture()
        sMat.emission.intensity = 0.3
        sMat.lightingModel = .constant
        screen.materials = [sMat]
        let sNode = SCNNode(geometry: screen)
        sNode.eulerAngles.y = .pi / 2
        sNode.position = SCNVector3(0.005, 0, 0)
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
            
            let wheel = SCNSphere(radius: 0.022)
            let wMat = SCNMaterial()
            wMat.diffuse.contents = NSColor(white: 0.25, alpha: 1.0)
            wheel.materials = [wMat]
            let wNode = SCNNode(geometry: wheel)
            wNode.position = SCNVector3(cos(angle) * 0.27, 0.022, sin(angle) * 0.27)
            chairGroup.addChildNode(wNode)
        }
        
        let cylinder = SCNCylinder(radius: 0.028, height: 0.38)
        let cMat = SCNMaterial()
        cMat.diffuse.contents = NSColor(white: 0.85, alpha: 1.0)
        cMat.metalness.contents = 0.8
        cylinder.materials = [cMat]
        let cylNode = SCNNode(geometry: cylinder)
        cylNode.position = SCNVector3(0, 0.22, 0)
        chairGroup.addChildNode(cylNode)
        
        let seat = SCNBox(width: 0.54, height: 0.08, length: 0.52, chamferRadius: 0.04)
        seat.materials = [sageMat]
        let seatNode = SCNNode(geometry: seat)
        seatNode.position = SCNVector3(0, 0.44, 0)
        chairGroup.addChildNode(seatNode)
        
        let backrest = SCNBox(width: 0.05, height: 0.58, length: 0.50, chamferRadius: 0.03)
        backrest.materials = [sageMat]
        let brNode = SCNNode(geometry: backrest)
        brNode.position = SCNVector3(0.24, 0.76, 0)
        brNode.eulerAngles.z = -0.12
        chairGroup.addChildNode(brNode)
        
        for az in [-0.26, 0.26] {
            let arm = SCNBox(width: 0.30, height: 0.025, length: 0.045, chamferRadius: 0.01)
            arm.materials = [whiteMat]
            let armNode = SCNNode(geometry: arm)
            armNode.position = SCNVector3(0.05, 0.62, az)
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
        
        let handle = SCNTorus(ringRadius: 0.032, pipeRadius: 0.008)
        handle.materials = [cupMat]
        let handleNode = SCNNode(geometry: handle)
        handleNode.position = SCNVector3(0, 0, 0.048)
        handleNode.eulerAngles.y = .pi / 2
        mugNode.addChildNode(handleNode)
        
        let smiley = SCNSphere(radius: 0.024)
        let smMat = SCNMaterial()
        smMat.diffuse.contents = NSColor(red: 0.98, green: 0.82, blue: 0.32, alpha: 1.0)
        smiley.materials = [smMat]
        let smNode = SCNNode(geometry: smiley)
        smNode.scale = SCNVector3(1.0, 1.0, 0.3)
        smNode.position = SCNVector3(0.046, 0, 0)
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
        
        let base = SCNCylinder(radius: 0.085, height: 0.02)
        base.materials = [brassMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.01, 0)
        lampNode.addChildNode(baseNode)
        
        let stem1 = SCNCylinder(radius: 0.014, height: 0.28)
        stem1.materials = [brassMat]
        let s1Node = SCNNode(geometry: stem1)
        s1Node.position = SCNVector3(0, 0.14, 0.04)
        s1Node.eulerAngles.x = 0.25
        lampNode.addChildNode(s1Node)
        
        let stem2 = SCNCylinder(radius: 0.014, height: 0.24)
        stem2.materials = [brassMat]
        let s2Node = SCNNode(geometry: stem2)
        s2Node.position = SCNVector3(0, 0.32, 0.10)
        s2Node.eulerAngles.x = -0.55
        lampNode.addChildNode(s2Node)
        
        let shade = SCNCylinder(radius: 0.08, height: 0.09)
        shade.materials = [creamMat]
        let shadeNode = SCNNode(geometry: shade)
        shadeNode.position = SCNVector3(0, 0.38, 0.18)
        shadeNode.eulerAngles.x = -0.85
        lampNode.addChildNode(shadeNode)
        
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
        lightNode.position = SCNVector3(0, 0.36, 0.20)
        lightNode.eulerAngles.y = .pi / 2
        lightNode.eulerAngles.x = -.pi / 2.2
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
        caseMat.diffuse.contents = NSColor(red: 0.92, green: 0.82, blue: 0.78, alpha: 1.0)
        caseMat.roughness.contents = 0.55
        let brassMat = Materials.brushedBrass
        
        let bodyW: CGFloat = 0.36
        let bodyL: CGFloat = 0.32
        let bodyH: CGFloat = 0.07
        let body = SCNBox(width: bodyW, height: bodyH, length: bodyL, chamferRadius: 0.015)
        body.materials = [caseMat]
        let bNode = SCNNode(geometry: body)
        bNode.position = SCNVector3(0, bodyH / 2, 0)
        playerGroup.addChildNode(bNode)
        
        let lid = SCNBox(width: bodyW, height: 0.035, length: bodyL, chamferRadius: 0.015)
        lid.materials = [caseMat]
        let lidNode = SCNNode(geometry: lid)
        lidNode.position = SCNVector3(0, bodyH + 0.14, -bodyL / 2)
        lidNode.eulerAngles.x = 0.85
        playerGroup.addChildNode(lidNode)
        
        let recordDisc = SCNCylinder(radius: 0.115, height: 0.008)
        let recordMat = SCNMaterial()
        recordMat.diffuse.contents = NSColor(white: 0.12, alpha: 1.0)
        recordMat.specular.contents = NSColor(white: 0.35, alpha: 1.0)
        recordMat.roughness.contents = 0.25
        recordDisc.materials = [recordMat]
        let discNode = SCNNode(geometry: recordDisc)
        discNode.position = SCNVector3(-0.04, bodyH + 0.005, 0)
        discNode.name = "vinyl_record_disc"
        
        let label = SCNCylinder(radius: 0.042, height: 0.009)
        let lMat = SCNMaterial()
        lMat.diffuse.contents = NSColor(red: 0.95, green: 0.65, blue: 0.55, alpha: 1.0)
        label.materials = [lMat]
        let labelNode = SCNNode(geometry: label)
        discNode.addChildNode(labelNode)
        
        if !reduceMotion {
            let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.2)
            discNode.runAction(SCNAction.repeatForever(spin), forKey: "vinyl_spin")
        }
        playerGroup.addChildNode(discNode)
        
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
        
        let deckW: CGFloat = 0.18
        let deckL: CGFloat = 0.68
        let deck = SCNBox(width: deckW, height: 0.016, length: deckL, chamferRadius: 0.02)
        let gripMat = SCNMaterial()
        gripMat.diffuse.contents = NSColor(white: 0.16, alpha: 1.0)
        gripMat.roughness.contents = 0.95
        deck.materials = [gripMat]
        let deckNode = SCNNode(geometry: deck)
        deckNode.position = SCNVector3(0, 0.04, 0)
        boardGroup.addChildNode(deckNode)
        
        for z in [-deckL * 0.35, deckL * 0.35] {
            let truck = SCNBox(width: deckW * 0.75, height: 0.018, length: 0.025, chamferRadius: 0.004)
            truck.materials = [Materials.brushedBrass]
            let tNode = SCNNode(geometry: truck)
            tNode.position = SCNVector3(0, 0.024, z)
            boardGroup.addChildNode(tNode)
            
            for x in [-deckW * 0.45, deckW * 0.45] {
                let wheel = SCNCylinder(radius: 0.024, height: 0.024)
                let wMat = SCNMaterial()
                wMat.diffuse.contents = NSColor(red: 0.94, green: 0.92, blue: 0.85, alpha: 1.0)
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
        
        let pot = SCNCylinder(radius: 0.15, height: 0.28)
        pot.materials = [Materials.satinCeramic]
        let potNode = SCNNode(geometry: pot)
        potNode.position = SCNVector3(0, 0.14, 0)
        plantGroup.addChildNode(potNode)
        
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
            
            let leaf = SCNBox(width: 0.22, height: 0.006, length: 0.34, chamferRadius: 0.02)
            leaf.materials = [leafMat]
            let leafNode = SCNNode(geometry: leaf)
            leafNode.position = SCNVector3(0, stemLen * 0.48, 0)
            leafNode.eulerAngles.x = 0.55
            stemNode.addChildNode(leafNode)
            
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
        vineGroup.position = SCNVector3(-2.03, 3.05, -1.80)
        
        let leafMat = SCNMaterial()
        leafMat.diffuse.contents = NSColor(red: 0.32, green: 0.54, blue: 0.30, alpha: 1.0)
        leafMat.roughness.contents = 0.6
        
        let strandLengths: [Int] = [14, 18, 11, 16]
        for (si, count) in strandLengths.enumerated() {
            let strandNode = SCNNode()
            strandNode.position = SCNVector3(CGFloat(si % 2) * 0.03, 0, CGFloat(si) * 0.10)
            
            for j in 0..<count {
                let leaf = SCNBox(width: 0.075, height: 0.004, length: 0.055, chamferRadius: 0.002)
                leaf.materials = [leafMat]
                let lNode = SCNNode(geometry: leaf)
                lNode.position = SCNVector3(sin(CGFloat(j)) * 0.02, -CGFloat(j) * 0.065, cos(CGFloat(j)) * 0.015)
                lNode.eulerAngles.y = CGFloat(j) * 0.4
                lNode.eulerAngles.z = 0.35
                strandNode.addChildNode(lNode)
            }
            
            if !reduceMotion {
                let sway = SCNAction.rotateBy(x: 0.03, y: 0.02, z: 0.04, duration: 4.0 + Double(si) * 0.4)
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
    
    /// Rich Warm Honey-Oak Hardwood Planks with individual board variation and beveled seams
    static var hardwoodFloor: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = Textures.makeHardwoodPlanksTexture()
        mat.roughness.contents = 0.58
        mat.specular.contents = NSColor(white: 0.16, alpha: 1.0)
        return mat
    }
    
    /// Vertical Honey-Oak Tongue-and-Groove Wood Slats for wainscoting and wall panels
    static var verticalWoodSlat: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = Textures.makeVerticalWoodSlatTexture()
        mat.roughness.contents = 0.65
        mat.specular.contents = NSColor(white: 0.12, alpha: 1.0)
        return mat
    }
    
    /// Warm Honey-Oak Hardwood (Natural grain warmth, matte satin finish)
    static var honeyOak: SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = NSColor(red: 0.77, green: 0.58, blue: 0.42, alpha: 1.0)
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
    
    /// Generates the rich honey-oak hardwood floor planks texture with dark seams and natural woodgrain.
    static func makeHardwoodPlanksTexture() -> NSImage {
        let size = CGSize(width: 1024, height: 1024)
        let img = NSImage(size: size)
        img.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }
        
        // Base honey oak fill
        ctx.setFillColor(NSColor(red: 0.77, green: 0.58, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        
        let plankCount = 22
        let plankHeight = size.height / CGFloat(plankCount)
        
        for i in 0..<plankCount {
            let y = CGFloat(i) * plankHeight
            
            // Subtle warm tone variation per plank
            let toneShift = CGFloat((i * 19) % 7 - 3) * 0.018
            let r = min(0.90, max(0.68, 0.77 + toneShift))
            let g = min(0.72, max(0.50, 0.58 + toneShift * 0.9))
            let b = min(0.55, max(0.35, 0.42 + toneShift * 0.8))
            
            ctx.setFillColor(NSColor(red: r, green: g, blue: b, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 0, y: y, width: size.width, height: plankHeight))
            
            // Faint natural wood grain streaks along the plank
            ctx.setStrokeColor(NSColor(red: r * 0.88, green: g * 0.88, blue: b * 0.88, alpha: 0.20).cgColor)
            ctx.setLineWidth(1.2)
            for g in 0..<4 {
                let gy = y + CGFloat(g + 1) * (plankHeight / 5.0)
                ctx.beginPath()
                ctx.move(to: CGPoint(x: 0, y: gy))
                ctx.addCurve(
                    to: CGPoint(x: size.width, y: gy + CGFloat((i * 3 + g) % 5 - 2)),
                    control1: CGPoint(x: size.width * 0.33, y: gy + CGFloat((i * 7) % 5 - 2)),
                    control2: CGPoint(x: size.width * 0.66, y: gy - CGFloat((i * 5) % 5 - 2))
                )
                ctx.strokePath()
            }
            
            // Staggered vertical end-butt joint between planks
            let jointX1 = CGFloat((i * 317 + 120) % Int(size.width * 0.85)) + 40
            ctx.setStrokeColor(NSColor(red: 0.38, green: 0.26, blue: 0.16, alpha: 0.75).cgColor)
            ctx.setLineWidth(2.0)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: jointX1, y: y))
            ctx.addLine(to: CGPoint(x: jointX1, y: y + plankHeight))
            ctx.strokePath()
            
            // Dark horizontal groove seam at the top of each plank
            ctx.setStrokeColor(NSColor(red: 0.38, green: 0.26, blue: 0.16, alpha: 0.85).cgColor)
            ctx.setLineWidth(2.2)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: size.width, y: y))
            ctx.strokePath()
            
            // Subtle warm highlight bevel line directly below seam for physical depth
            ctx.setStrokeColor(NSColor(red: 0.88, green: 0.72, blue: 0.54, alpha: 0.35).cgColor)
            ctx.setLineWidth(1.0)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 0, y: y + 2.0))
            ctx.addLine(to: CGPoint(x: size.width, y: y + 2.0))
            ctx.strokePath()
        }
        
        img.unlockFocus()
        return img
    }
    
    /// Generates vertical honey-oak tongue-and-groove wooden slats for wainscoting and wall panels.
    static func makeVerticalWoodSlatTexture() -> NSImage {
        let size = CGSize(width: 512, height: 512)
        let img = NSImage(size: size)
        img.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }
        
        ctx.setFillColor(NSColor(red: 0.76, green: 0.57, blue: 0.41, alpha: 1.0).cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        
        let slatCount = 20
        let slatWidth = size.width / CGFloat(slatCount)
        
        for i in 0..<slatCount {
            let x = CGFloat(i) * slatWidth
            let toneShift = CGFloat((i * 11) % 5 - 2) * 0.015
            let r = 0.76 + toneShift
            let g = 0.57 + toneShift * 0.9
            let b = 0.41 + toneShift * 0.8
            
            ctx.setFillColor(NSColor(red: r, green: g, blue: b, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: x, y: 0, width: slatWidth, height: size.height))
            
            // Dark vertical tongue-and-groove joint line
            ctx.setStrokeColor(NSColor(red: 0.36, green: 0.25, blue: 0.16, alpha: 0.80).cgColor)
            ctx.setLineWidth(2.0)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: size.height))
            ctx.strokePath()
            
            // Subtle vertical highlight line on right edge of joint
            ctx.setStrokeColor(NSColor(red: 0.88, green: 0.72, blue: 0.54, alpha: 0.30).cgColor)
            ctx.setLineWidth(1.0)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x + 1.8, y: 0))
            ctx.addLine(to: CGPoint(x: x + 1.8, y: size.height))
            ctx.strokePath()
        }
        
        img.unlockFocus()
        return img
    }
    
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
